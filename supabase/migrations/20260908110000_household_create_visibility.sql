-- =============================================================================
-- Migration 6 - make "Create household" work.
--
-- Symptom: the button appeared to do nothing. No error, no navigation.
--
-- There were two separate causes. The first was in the app and is already
-- fixed: every text field carried a 2-second debounce on its change action, so
-- the page state behind "Household name" was still empty when the button ran,
-- and the guard `if householdName != ''` skipped the insert entirely. With that
-- cleared the insert now actually fires - and returns 403:
--
--   {"code":"42501","message":"new row violates row-level security policy
--     for table \"households\""}
--
-- That is the second cause, and it is in the database. It reproduces against
-- the REST API with owner_id passed explicitly and equal to auth.uid(), which
-- is exactly what households_insert_own is supposed to allow:
--
--   POST /rest/v1/households  {"name":"Probe","owner_id":"<auth.uid()>"}  -> 403
--
-- So the policy that is actually live does not match what the init migration
-- declares. SELECT policies on the same table do work and auth.uid() resolves
-- correctly (notification_preferences returns the caller's own row), so this is
-- specific to the INSERT policy rather than anything broader.
--
-- Section 1 reports what is really there - please send me that output. Section 2
-- puts all four households policies back to a known-good state regardless, and
-- is safe to run whatever section 1 shows.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Diagnostic. Read this before and after; the "before" tells us what broke.
-- -----------------------------------------------------------------------------
select
  policyname,
  cmd,
  permissive,                       -- RESTRICTIVE here would explain the 403
  roles,
  qual        as using_expression,
  with_check  as with_check_expression
from pg_policies
where schemaname = 'public'
  and tablename = 'households'
order by cmd, policyname;

select
  relrowsecurity  as rls_enabled,
  relforcerowsecurity as rls_forced   -- forced RLS also applies to the owner,
from pg_class                          -- which would break the SECURITY DEFINER
where oid = 'public.households'::regclass;  -- trigger as well

-- -----------------------------------------------------------------------------
-- 2. Reset the households policies.
--
-- Dropping by both the old and new names so this is idempotent whichever state
-- the table is in.
-- -----------------------------------------------------------------------------
drop policy if exists "households_select_member"          on public.households;
drop policy if exists "households_select_member_or_owner" on public.households;
drop policy if exists "households_insert_own"             on public.households;
drop policy if exists "households_update_admin"           on public.households;
drop policy if exists "households_delete_owner"           on public.households;

-- SELECT: members can read their household, and the owner can read it directly.
--
-- The owner clause is not a widening of access. owner_id is set from auth.uid()
-- by the column default and the insert policy requires owner_id = auth.uid(),
-- so anyone this admits could already insert the row. It is here because the
-- app inserts with a RETURNING clause - Supabase always does, the client needs
-- the new id - and Postgres applies the SELECT policy to the returned row as it
-- is inserted, before the AFTER INSERT trigger has added the owner as a member.
-- Without this, a successful insert still hands the client nothing back, and
-- the app reads that as a failure. Membership still governs everything else.
create policy "households_select_member_or_owner" on public.households
  for select to authenticated using (
    app_private.is_household_member(id)
    or owner_id = auth.uid()
  );

create policy "households_insert_own" on public.households
  for insert to authenticated with check (owner_id = auth.uid());

create policy "households_update_admin" on public.households
  for update to authenticated using (app_private.is_household_admin(id))
  with check (app_private.is_household_admin(id));

create policy "households_delete_owner" on public.households
  for delete to authenticated using (owner_id = auth.uid());

-- Forced RLS would apply to the table owner too, which would break the
-- SECURITY DEFINER trigger that seeds members, storage locations and the
-- shopping list. Nothing in this schema wants that.
alter table public.households no force row level security;

-- -----------------------------------------------------------------------------
-- 3. Verify. Run as a signed-in user, not with the service role - the service
--    role bypasses RLS and would pass even if the policies were still wrong.
-- -----------------------------------------------------------------------------
--   insert into public.households (name) values ('Test') returning id, name;
--
-- A row must come back. Then confirm the trigger did its work:
--   select count(*) from public.household_members   where household_id = '<id>';  -- 1
--   select count(*) from public.storage_locations   where household_id = '<id>';  -- 3
--   select count(*) from public.shopping_lists      where household_id = '<id>';  -- 1

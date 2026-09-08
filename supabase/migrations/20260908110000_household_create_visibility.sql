-- =============================================================================
-- Migration 6 — let the creator see the household they just created.
--
-- Symptom: "Create household" appeared to do nothing. No error, no navigation,
-- and nothing usable afterwards.
--
-- Cause: a timing conflict between RLS and the trigger, not a fault in either.
--
--   households_select_member allows SELECT only where the caller is already a
--   member: app_private.is_household_member(id).
--
--   Membership is created by on_household_created, which is an AFTER INSERT
--   trigger.
--
-- The app inserts with a RETURNING clause — Supabase always does, because the
-- client needs the new row's id. Postgres evaluates RETURNING as each row is
-- inserted, and applies the SELECT policy to it at that moment: BEFORE the
-- AFTER trigger has run. So the caller is not a member yet, the returned row is
-- filtered away, and the client receives nothing back from a write that did
-- happen. The app treats that as a failure and never navigates.
--
-- Fix: let an owner see their own household directly, rather than only through
-- membership. This is not a widening of access — owner_id is set from
-- auth.uid() by the column default and the insert policy already requires
-- owner_id = auth.uid(), so anyone this admits could already insert the row.
-- It simply removes the dependency on a trigger that has not fired yet.
--
-- The membership row is still created, and everything else still routes through
-- it; this only covers the instant between the insert and the trigger.
-- =============================================================================

drop policy if exists "households_select_member" on public.households;

create policy "households_select_member_or_owner" on public.households
  for select using (
    app_private.is_household_member(id)
    or owner_id = auth.uid()
  );

comment on policy "households_select_member_or_owner" on public.households is
  'Members can read their household. The owner can also read it directly, so '
  'the RETURNING clause on INSERT is not filtered away before the '
  'on_household_created trigger has added the owner as a member.';

-- Check:
--   As a signed-in user, insert a household and confirm a row comes back:
--     insert into public.households (name) values ('Test') returning id, name;
--   Then confirm the trigger did its work:
--     select count(*) from public.household_members where household_id = '<id>';  -- 1
--     select count(*) from public.storage_locations where household_id = '<id>';  -- 3
--     select count(*) from public.shopping_lists   where household_id = '<id>';  -- 1

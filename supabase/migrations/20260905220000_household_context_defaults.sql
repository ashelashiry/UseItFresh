-- =============================================================================
-- UseItFresh — migration 3: household context defaults
--
-- Purpose
--   Phase 2 needs to INSERT rows (storage locations, food items, events). RLS
--   requires household_id on insert (`is_household_member(household_id)`), and
--   food_items additionally requires `created_by = auth.uid()`.
--
--   Rather than teach the FlutterFlow client to resolve and carry household_id
--   on every screen — fragile, and spoofable by a modified client — this
--   migration resolves it server-side and applies it as a column DEFAULT. The
--   client simply omits the column and Postgres fills it from the session.
--
--   Explicit values still win: passing household_id continues to work, so this
--   stays forward-compatible with multi-household support later.
--
-- Safe to re-run. Idempotent throughout.
-- Run in: Supabase dashboard -> SQL Editor -> paste -> Run.
-- =============================================================================

-- 1. Resolve the caller's household ------------------------------------------
--
-- Deterministic when a user belongs to more than one household: oldest
-- membership wins. Today the app creates exactly one household per user, so
-- this is unambiguous; when H2 (invites) lands, the app should pass
-- household_id explicitly and the default becomes a fallback only.

create or replace function app_private.current_household_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select household_id
  from public.household_members
  where profile_id = auth.uid()
  order by joined_at asc, household_id asc
  limit 1;
$$;

comment on function app_private.current_household_id() is
  'The household of the authenticated user (oldest membership wins). Used as a '
  'column default so clients never have to carry household_id.';

revoke all on function app_private.current_household_id() from public;
grant execute on function app_private.current_household_id() to authenticated;

-- Readable from the client too, for screens that want to show which household
-- is active without a round trip through household_members.
create or replace function public.current_household_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select app_private.current_household_id();
$$;

revoke all on function public.current_household_id() from public;
grant execute on function public.current_household_id() to authenticated;

-- 2. Column defaults ----------------------------------------------------------

alter table public.storage_locations
  alter column household_id set default app_private.current_household_id();

alter table public.food_items
  alter column household_id set default app_private.current_household_id();

-- food_items.created_by must equal auth.uid() to satisfy the insert policy.
alter table public.food_items
  alter column created_by set default auth.uid();

-- food_item_events.profile_id is nullable, but attributing the actor is the
-- whole point of the table (H4: "who added, opened, consumed or discarded what").
alter table public.food_item_events
  alter column profile_id set default auth.uid();

-- 3. Verification -------------------------------------------------------------
--
-- After running, this should return your household's uuid (not null) while
-- signed in as an authenticated user:
--
--   select public.current_household_id();
--
-- And these should all show a default expression:
--
--   select table_name, column_name, column_default
--   from information_schema.columns
--   where table_schema = 'public'
--     and (table_name, column_name) in (
--       ('storage_locations', 'household_id'),
--       ('food_items', 'household_id'),
--       ('food_items', 'created_by'),
--       ('food_item_events', 'profile_id')
--     );
--
-- NOTE: `select public.current_household_id()` run from the SQL Editor returns
-- NULL, because the editor connects as the postgres role with no auth.uid().
-- That is expected and not a failure — it resolves correctly from the app.
-- =============================================================================

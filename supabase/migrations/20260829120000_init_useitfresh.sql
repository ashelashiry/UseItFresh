-- ============================================================================
-- Use It Fresh — Phase 1 foundation migration
-- Spec: AI_FRIDGE_FLUTTERFLOW_BUILD_SPEC §11 (data model) + §12 (RLS)
-- Run once in the Supabase SQL editor (or via `supabase db push`).
-- Safe to run on a brand-new project only.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 0. Extensions & private helper schema
-- ---------------------------------------------------------------------------
create extension if not exists pgcrypto;

-- Helpers live outside `public` so PostgREST never exposes them directly.
create schema if not exists app_private;

-- ---------------------------------------------------------------------------
-- 1. Utility functions
-- ---------------------------------------------------------------------------

-- Keep updated_at columns honest.
create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Human-friendly invite codes (no 0/O/1/I ambiguity).
create or replace function app_private.generate_invite_code()
returns text
language plpgsql
as $$
declare
  chars constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  code text := '';
  i int;
begin
  for i in 1..8 loop
    code := code || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return code;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2. Core tables (spec §11)
-- ---------------------------------------------------------------------------

-- profiles ------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url text,
  country_code text,
  locale text,
  unit_system text not null default 'metric'
    check (unit_system in ('metric', 'imperial')),
  dietary_preferences jsonb not null default '[]',
  allergens jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- households ----------------------------------------------------------------
create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null default auth.uid() references public.profiles(id),
  invite_code text not null unique default app_private.generate_invite_code(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- household_members ---------------------------------------------------------
create table public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member'
    check (role in ('owner', 'admin', 'member', 'child')),
  joined_at timestamptz not null default now(),
  primary key (household_id, profile_id)
);

-- storage_locations ---------------------------------------------------------
create table public.storage_locations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null,
  location_type text not null
    check (location_type in ('fridge', 'freezer', 'pantry', 'other')),
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

-- food_items ----------------------------------------------------------------
create table public.food_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  storage_location_id uuid references public.storage_locations(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  name text not null,
  brand text,
  category text,
  barcode text,
  quantity numeric not null default 1,
  unit text not null default 'item',
  image_url text,
  purchase_date date,
  printed_date date,
  printed_date_type text
    check (printed_date_type in ('use_by', 'best_before', 'sell_by', 'unknown')),
  opened_at timestamptz,
  cooked_at timestamptz,
  frozen_at timestamptz,
  estimated_expiry_at timestamptz,
  expiry_source text
    check (expiry_source in ('printed', 'ai_estimate', 'opened_rule', 'user')),
  status text not null default 'fresh'
    check (status in ('fresh', 'use_soon', 'use_today', 'past_best_before',
                      'past_use_by', 'frozen', 'consumed', 'discarded', 'unknown')),
  confidence numeric check (confidence >= 0 and confidence <= 1),
  notes text,
  source_type text
    check (source_type in ('photo', 'barcode', 'receipt', 'fridge_scan', 'manual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  archived_at timestamptz
);

-- food_item_events (immutable activity history) -----------------------------
create table public.food_item_events (
  id uuid primary key default gen_random_uuid(),
  food_item_id uuid not null references public.food_items(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete set null,
  event_type text not null
    check (event_type in ('created', 'opened', 'moved', 'consumed', 'discarded',
                          'quantity_changed', 'assessment', 'frozen', 'donated',
                          'updated')),
  from_value jsonb,
  to_value jsonb,
  created_at timestamptz not null default now()
);

-- scan_sessions (per-user, spec §12.5) --------------------------------------
create table public.scan_sessions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households(id) on delete cascade,
  profile_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  scan_type text not null
    check (scan_type in ('photo', 'barcode', 'receipt', 'fridge_scan')),
  image_url text,
  raw_ai_response jsonb,
  status text not null default 'processing'
    check (status in ('processing', 'ready', 'reviewed', 'failed', 'discarded')),
  created_at timestamptz not null default now()
);

-- scan_candidates -----------------------------------------------------------
create table public.scan_candidates (
  id uuid primary key default gen_random_uuid(),
  scan_session_id uuid not null references public.scan_sessions(id) on delete cascade,
  suggested_name text,
  suggested_category text,
  suggested_brand text,
  suggested_quantity numeric,
  suggested_unit text,
  suggested_printed_date date,
  suggested_date_type text
    check (suggested_date_type in ('use_by', 'best_before', 'sell_by', 'unknown')),
  suggested_storage_type text
    check (suggested_storage_type in ('fridge', 'freezer', 'pantry', 'other')),
  confidence numeric check (confidence >= 0 and confidence <= 1),
  bounding_box jsonb,
  accepted boolean,
  created_food_item_id uuid references public.food_items(id) on delete set null
);

-- freshness_assessments (per-user, spec §12.5) ------------------------------
create table public.freshness_assessments (
  id uuid primary key default gen_random_uuid(),
  food_item_id uuid references public.food_items(id) on delete set null,
  profile_id uuid not null default auth.uid() references public.profiles(id) on delete cascade,
  household_id uuid references public.households(id) on delete cascade,
  answers jsonb not null,
  result_category text not null
    check (result_category in ('discard', 'use_immediately', 'likely_usable',
                               'quality_reduced', 'insufficient_information')),
  confidence numeric check (confidence >= 0 and confidence <= 1),
  reasoning_summary text,
  missing_information jsonb,
  guidance text,
  model_version text,
  created_at timestamptz not null default now()
);

-- shopping_lists ------------------------------------------------------------
create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null default 'Shopping List',
  created_at timestamptz not null default now()
);

-- shopping_list_items -------------------------------------------------------
create table public.shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  shopping_list_id uuid not null references public.shopping_lists(id) on delete cascade,
  name text not null,
  quantity numeric,
  unit text,
  source text not null default 'manual'
    check (source in ('manual', 'recipe', 'replacement')),
  is_purchased boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

-- saved_recipes -------------------------------------------------------------
create table public.saved_recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete set null,
  title text not null,
  recipe_data jsonb not null,
  inventory_item_ids jsonb,
  created_at timestamptz not null default now()
);

-- notification_preferences --------------------------------------------------
create table public.notification_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  expiry_enabled boolean not null default true,
  expiry_days_before int not null default 2,
  opened_item_enabled boolean not null default true,
  weekly_summary_enabled boolean not null default true,
  quiet_hours_start time,
  quiet_hours_end time,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 3. Indexes
-- ---------------------------------------------------------------------------
create index idx_household_members_profile on public.household_members (profile_id);
create index idx_storage_locations_household on public.storage_locations (household_id);
create index idx_food_items_household_status on public.food_items (household_id, status);
create index idx_food_items_household_expiry on public.food_items (household_id, estimated_expiry_at)
  where archived_at is null;
create index idx_food_item_events_item on public.food_item_events (food_item_id, created_at);
create index idx_scan_sessions_profile on public.scan_sessions (profile_id, created_at);
create index idx_scan_candidates_session on public.scan_candidates (scan_session_id);
create index idx_assessments_profile on public.freshness_assessments (profile_id, created_at);
create index idx_shopping_items_list on public.shopping_list_items (shopping_list_id);
create index idx_saved_recipes_household on public.saved_recipes (household_id, created_at);

-- ---------------------------------------------------------------------------
-- 4. Membership helpers (SECURITY DEFINER avoids RLS recursion)
-- ---------------------------------------------------------------------------
create or replace function app_private.is_household_member(hid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.household_members
    where household_id = hid and profile_id = auth.uid()
  );
$$;

create or replace function app_private.is_household_admin(hid uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.household_members
    where household_id = hid
      and profile_id = auth.uid()
      and role in ('owner', 'admin')
  );
$$;

-- True when the current user shares at least one household with `other`.
create or replace function app_private.shares_household_with(other uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.household_members mine
    join public.household_members theirs
      on mine.household_id = theirs.household_id
    where mine.profile_id = auth.uid()
      and theirs.profile_id = other
  );
$$;

-- Membership of the household that owns a shopping list.
create or replace function app_private.is_list_household_member(list_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.shopping_lists sl
    join public.household_members hm on hm.household_id = sl.household_id
    where sl.id = list_id and hm.profile_id = auth.uid()
  );
$$;

-- Membership of the household that owns a food item.
create or replace function app_private.is_item_household_member(item_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.food_items fi
    join public.household_members hm on hm.household_id = fi.household_id
    where fi.id = item_id and hm.profile_id = auth.uid()
  );
$$;

-- Ownership of the scan session that owns a candidate.
create or replace function app_private.owns_scan_session(session_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.scan_sessions
    where id = session_id and profile_id = auth.uid()
  );
$$;

-- ---------------------------------------------------------------------------
-- 5. Automation triggers
-- ---------------------------------------------------------------------------

-- 5a. New auth user -> profile + notification preferences.
create or replace function app_private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name',
             split_part(coalesce(new.email, 'user'), '@', 1)),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;

  insert into public.notification_preferences (profile_id)
  values (new.id)
  on conflict (profile_id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_user();

-- 5b. New household -> owner membership + default locations + default list.
create or replace function app_private.handle_new_household()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.household_members (household_id, profile_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict do nothing;

  insert into public.storage_locations (household_id, name, location_type, is_default)
  values
    (new.id, 'Fridge',  'fridge',  true),
    (new.id, 'Freezer', 'freezer', false),
    (new.id, 'Pantry',  'pantry',  false);

  insert into public.shopping_lists (household_id, name)
  values (new.id, 'Shopping List');

  return new;
end;
$$;

create trigger on_household_created
  after insert on public.households
  for each row execute function app_private.handle_new_household();

-- 5c. updated_at maintenance.
create trigger set_profiles_updated_at
  before update on public.profiles
  for each row execute function app_private.set_updated_at();

create trigger set_households_updated_at
  before update on public.households
  for each row execute function app_private.set_updated_at();

create trigger set_food_items_updated_at
  before update on public.food_items
  for each row execute function app_private.set_updated_at();

create trigger set_notification_prefs_updated_at
  before update on public.notification_preferences
  for each row execute function app_private.set_updated_at();

-- ---------------------------------------------------------------------------
-- 6. Join-by-invite RPC
--    (Non-members cannot SELECT a household, so joining goes through a
--     SECURITY DEFINER function that validates the code server-side.)
-- ---------------------------------------------------------------------------
create or replace function public.join_household_by_code(code text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  target uuid;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  select id into target
  from public.households
  where invite_code = upper(trim(code));

  if target is null then
    raise exception 'Invalid invite code';
  end if;

  insert into public.household_members (household_id, profile_id, role)
  values (target, auth.uid(), 'member')
  on conflict (household_id, profile_id) do nothing;

  return target;
end;
$$;

revoke execute on function public.join_household_by_code(text) from anon;

-- ---------------------------------------------------------------------------
-- 7. Row Level Security (spec §12)
-- ---------------------------------------------------------------------------
alter table public.profiles                 enable row level security;
alter table public.households               enable row level security;
alter table public.household_members        enable row level security;
alter table public.storage_locations        enable row level security;
alter table public.food_items               enable row level security;
alter table public.food_item_events         enable row level security;
alter table public.scan_sessions            enable row level security;
alter table public.scan_candidates          enable row level security;
alter table public.freshness_assessments    enable row level security;
alter table public.shopping_lists           enable row level security;
alter table public.shopping_list_items      enable row level security;
alter table public.saved_recipes            enable row level security;
alter table public.notification_preferences enable row level security;

-- profiles: own profile, plus read-only view of housemates (§12.1)
create policy "profiles_select_own_or_housemate" on public.profiles
  for select using (id = auth.uid() or app_private.shares_household_with(id));
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- households (§12.2, §12.4)
create policy "households_select_member" on public.households
  for select using (app_private.is_household_member(id));
create policy "households_insert_own" on public.households
  for insert with check (owner_id = auth.uid());
create policy "households_update_admin" on public.households
  for update using (app_private.is_household_admin(id))
  with check (app_private.is_household_admin(id));
create policy "households_delete_owner" on public.households
  for delete using (owner_id = auth.uid());

-- household_members (§12.4; joining goes via join_household_by_code RPC)
create policy "members_select_member" on public.household_members
  for select using (app_private.is_household_member(household_id));
create policy "members_insert_admin" on public.household_members
  for insert with check (app_private.is_household_admin(household_id));
create policy "members_update_admin" on public.household_members
  for update using (app_private.is_household_admin(household_id))
  with check (app_private.is_household_admin(household_id));
create policy "members_delete_admin_or_self" on public.household_members
  for delete using (
    app_private.is_household_admin(household_id) or profile_id = auth.uid()
  );

-- storage_locations (§12.2, §12.3)
create policy "locations_select_member" on public.storage_locations
  for select using (app_private.is_household_member(household_id));
create policy "locations_write_member" on public.storage_locations
  for insert with check (app_private.is_household_member(household_id));
create policy "locations_update_member" on public.storage_locations
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
create policy "locations_delete_admin" on public.storage_locations
  for delete using (app_private.is_household_admin(household_id));

-- food_items (§12.2, §12.3)
create policy "food_select_member" on public.food_items
  for select using (app_private.is_household_member(household_id));
create policy "food_insert_member" on public.food_items
  for insert with check (
    app_private.is_household_member(household_id) and created_by = auth.uid()
  );
create policy "food_update_member" on public.food_items
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
create policy "food_delete_member" on public.food_items
  for delete using (app_private.is_household_member(household_id));

-- food_item_events: immutable history — insert + read only (§20.12)
create policy "events_select_member" on public.food_item_events
  for select using (app_private.is_item_household_member(food_item_id));
create policy "events_insert_member" on public.food_item_events
  for insert with check (
    app_private.is_item_household_member(food_item_id) and profile_id = auth.uid()
  );

-- scan_sessions: private to the scanning user (§12.5)
create policy "scans_select_own" on public.scan_sessions
  for select using (profile_id = auth.uid());
create policy "scans_insert_own" on public.scan_sessions
  for insert with check (profile_id = auth.uid());
create policy "scans_update_own" on public.scan_sessions
  for update using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
create policy "scans_delete_own" on public.scan_sessions
  for delete using (profile_id = auth.uid());

-- scan_candidates: via owning session (§12.5)
create policy "candidates_select_own" on public.scan_candidates
  for select using (app_private.owns_scan_session(scan_session_id));
create policy "candidates_insert_own" on public.scan_candidates
  for insert with check (app_private.owns_scan_session(scan_session_id));
create policy "candidates_update_own" on public.scan_candidates
  for update using (app_private.owns_scan_session(scan_session_id))
  with check (app_private.owns_scan_session(scan_session_id));
create policy "candidates_delete_own" on public.scan_candidates
  for delete using (app_private.owns_scan_session(scan_session_id));

-- freshness_assessments: private to the asking user (§12.5)
create policy "assessments_select_own" on public.freshness_assessments
  for select using (profile_id = auth.uid());
create policy "assessments_insert_own" on public.freshness_assessments
  for insert with check (profile_id = auth.uid());

-- shopping_lists (§12.2, §12.3)
create policy "lists_select_member" on public.shopping_lists
  for select using (app_private.is_household_member(household_id));
create policy "lists_insert_member" on public.shopping_lists
  for insert with check (app_private.is_household_member(household_id));
create policy "lists_update_member" on public.shopping_lists
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
create policy "lists_delete_admin" on public.shopping_lists
  for delete using (app_private.is_household_admin(household_id));

-- shopping_list_items (§12.2, §12.3)
create policy "list_items_select_member" on public.shopping_list_items
  for select using (app_private.is_list_household_member(shopping_list_id));
create policy "list_items_insert_member" on public.shopping_list_items
  for insert with check (
    app_private.is_list_household_member(shopping_list_id) and created_by = auth.uid()
  );
create policy "list_items_update_member" on public.shopping_list_items
  for update using (app_private.is_list_household_member(shopping_list_id))
  with check (app_private.is_list_household_member(shopping_list_id));
create policy "list_items_delete_member" on public.shopping_list_items
  for delete using (app_private.is_list_household_member(shopping_list_id));

-- saved_recipes (§12.2, §12.3)
create policy "recipes_select_member" on public.saved_recipes
  for select using (app_private.is_household_member(household_id));
create policy "recipes_insert_member" on public.saved_recipes
  for insert with check (
    app_private.is_household_member(household_id) and profile_id = auth.uid()
  );
create policy "recipes_update_member" on public.saved_recipes
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
create policy "recipes_delete_member" on public.saved_recipes
  for delete using (app_private.is_household_member(household_id));

-- notification_preferences: own only
create policy "notif_prefs_select_own" on public.notification_preferences
  for select using (profile_id = auth.uid());
create policy "notif_prefs_insert_own" on public.notification_preferences
  for insert with check (profile_id = auth.uid());
create policy "notif_prefs_update_own" on public.notification_preferences
  for update using (profile_id = auth.uid())
  with check (profile_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 8. Storage buckets + object policies (§12.6)
--    Path conventions:
--      food-images/<household_id>/<file>   (household-scoped)
--      receipts/<user_id>/<file>           (user-scoped, like scan sessions)
--      avatars/<user_id>/<file>            (public read, owner write)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values
  ('food-images', 'food-images', false),
  ('receipts', 'receipts', false),
  ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "food_images_rw_household" on storage.objects
  for all using (
    bucket_id = 'food-images'
    and app_private.is_household_member(((storage.foldername(name))[1])::uuid)
  )
  with check (
    bucket_id = 'food-images'
    and app_private.is_household_member(((storage.foldername(name))[1])::uuid)
  );

create policy "receipts_rw_own" on storage.objects
  for all using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_read_all" on storage.objects
  for select using (bucket_id = 'avatars');

create policy "avatars_write_own" on storage.objects
  for insert with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_update_own" on storage.objects
  for update using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_delete_own" on storage.objects
  for delete using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- 9. Realtime for shared household data (§6, §8.10)
-- ---------------------------------------------------------------------------
alter publication supabase_realtime add table public.food_items;
alter publication supabase_realtime add table public.food_item_events;
alter publication supabase_realtime add table public.shopping_list_items;
alter publication supabase_realtime add table public.household_members;

-- ============================================================================
-- Done. Phase 1 surface area:
--   13 tables · 45 RLS policies · 3 storage buckets · 4 realtime tables
--   Auto: profile + notification prefs on signup; owner membership,
--   Fridge/Freezer/Pantry locations, and a default shopping list on
--   household creation; join_household_by_code(code) RPC for invites.
-- ============================================================================

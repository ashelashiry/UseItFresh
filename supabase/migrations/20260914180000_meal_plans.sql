-- =============================================================================
-- Migration 7 - Plan my week, and "I ate this".
--
-- Two tables, kept apart on purpose (owner, 14 Sep: "planned food must stay
-- separate from food actually eaten"):
--
--   meal_plan_entries  what a household means to cook, on which day. Shared by
--                      everyone in the household, like kept ideas.
--   meal_log_entries   what one person says they ate, and how much. Private to
--                      that person: nobody else in the household sees it.
--
-- Nutrition is stored as the estimate the idea carried (per serving), with the
-- portions eaten, so a later, better nutrition source can recalculate it. It is
-- never presented as measured.
--
-- Safe to run more than once. Run it all in the Supabase SQL editor.
-- =============================================================================

-- 1. What the household plans to cook ----------------------------------------
create table if not exists public.meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  plan_date date not null,
  meal text not null default 'dinner'
    check (meal in ('breakfast', 'lunch', 'dinner', 'snack')),
  title text not null check (char_length(title) between 1 and 120),
  -- uses, extras, steps, minutes, calories, protein: the idea as it was chosen
  recipe_data jsonb not null default '{}'::jsonb,
  servings int not null default 2 check (servings between 1 and 12),
  -- Cook once, eat twice: the extra portions this meal is planned to leave.
  extra_portions int not null default 0 check (extra_portions between 0 and 12),
  status text not null default 'planned'
    check (status in ('planned', 'cooked', 'skipped')),
  cooked_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_meal_plan_household_date
  on public.meal_plan_entries (household_id, plan_date);

drop trigger if exists set_meal_plan_entries_updated_at on public.meal_plan_entries;
create trigger set_meal_plan_entries_updated_at
  before update on public.meal_plan_entries
  for each row execute function app_private.set_updated_at();

alter table public.meal_plan_entries enable row level security;

drop policy if exists "meal_plan_select_member" on public.meal_plan_entries;
create policy "meal_plan_select_member" on public.meal_plan_entries
  for select using (app_private.is_household_member(household_id));
drop policy if exists "meal_plan_insert_member" on public.meal_plan_entries;
create policy "meal_plan_insert_member" on public.meal_plan_entries
  for insert with check (
    app_private.is_household_member(household_id) and created_by = auth.uid()
  );
drop policy if exists "meal_plan_update_member" on public.meal_plan_entries;
create policy "meal_plan_update_member" on public.meal_plan_entries
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "meal_plan_delete_member" on public.meal_plan_entries;
create policy "meal_plan_delete_member" on public.meal_plan_entries
  for delete using (app_private.is_household_member(household_id));

-- 2. What one person ate -----------------------------------------------------
create table if not exists public.meal_log_entries (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  household_id uuid references public.households(id) on delete set null,
  plan_entry_id uuid references public.meal_plan_entries(id) on delete set null,
  eaten_on date not null default current_date,
  meal text not null default 'dinner'
    check (meal in ('breakfast', 'lunch', 'dinner', 'snack')),
  title text not null check (char_length(title) between 1 and 120),
  portions numeric(4, 2) not null default 1 check (portions > 0 and portions <= 10),
  -- Estimates per serving, as the idea carried them; null when it had none.
  calories_per_serving int check (calories_per_serving between 0 and 5000),
  protein_per_serving int check (protein_per_serving between 0 and 500),
  created_at timestamptz not null default now()
);

create index if not exists idx_meal_log_profile_date
  on public.meal_log_entries (profile_id, eaten_on);

alter table public.meal_log_entries enable row level security;

drop policy if exists "meal_log_select_own" on public.meal_log_entries;
create policy "meal_log_select_own" on public.meal_log_entries
  for select using (profile_id = auth.uid());
drop policy if exists "meal_log_insert_own" on public.meal_log_entries;
create policy "meal_log_insert_own" on public.meal_log_entries
  for insert with check (
    profile_id = auth.uid()
    and (household_id is null or app_private.is_household_member(household_id))
  );
drop policy if exists "meal_log_update_own" on public.meal_log_entries;
create policy "meal_log_update_own" on public.meal_log_entries
  for update using (profile_id = auth.uid())
  with check (profile_id = auth.uid());
drop policy if exists "meal_log_delete_own" on public.meal_log_entries;
create policy "meal_log_delete_own" on public.meal_log_entries
  for delete using (profile_id = auth.uid());

-- 3. Check: both tables exist with row-level security on (expect two rows, true)
select relname, relrowsecurity
from pg_class
where relname in ('meal_plan_entries', 'meal_log_entries');

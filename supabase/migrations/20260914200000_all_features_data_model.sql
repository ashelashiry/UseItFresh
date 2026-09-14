-- =============================================================================
-- Migration 8 - the data model for every remaining feature, in one go.
--
-- Owner, 14 Sep: design the tables first, run them once, then build.
-- Migration 7 (meal_plan_entries, meal_log_entries) must already be run.
--
--   A. Your day              user_settings (daily targets; private)
--   B. Receipt history       receipts, receipt_items, food_items.receipt_id
--   C. Budget meal planning  household_budgets, known_prices
--   D. Household planning    household_diners, meal_plan_diners
--   E. Recipe collection     more columns on saved_recipes
--   F. Product pictures      product_images (+ share consent in user_settings)
--   G. Live week plan        meal_plan_entries in realtime
--
-- Rules kept from the rest of the schema: household data is visible to the
-- household's members only (app_private.is_household_member); personal data
-- (targets, what someone ate, sharing consent) to that person only. Money is
-- numeric with a currency code, never a float. Nothing here stores a receipt
-- photo or a card number.
--
-- Safe to run more than once. Paste it all into the Supabase SQL editor and
-- run. The last query lists every new table with row-level security (all true).
-- =============================================================================


-- -----------------------------------------------------------------------------
-- A + F. user_settings: one row per person, private to them
-- -----------------------------------------------------------------------------
create table if not exists public.user_settings (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  -- Your day: the person's own targets. Null = not set (progress shows totals).
  daily_calorie_target int check (daily_calorie_target between 800 and 6000),
  daily_protein_target int check (daily_protein_target between 0 and 400),
  -- F: may crops and photos of packaged products this person adds be shared
  -- beyond their household (the product-image idea)? Off unless they say yes.
  share_product_photos boolean not null default false,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_user_settings_updated_at on public.user_settings;
create trigger set_user_settings_updated_at
  before update on public.user_settings
  for each row execute function app_private.set_updated_at();

alter table public.user_settings enable row level security;

drop policy if exists "user_settings_select_own" on public.user_settings;
create policy "user_settings_select_own" on public.user_settings
  for select using (profile_id = auth.uid());
drop policy if exists "user_settings_insert_own" on public.user_settings;
create policy "user_settings_insert_own" on public.user_settings
  for insert with check (profile_id = auth.uid());
drop policy if exists "user_settings_update_own" on public.user_settings;
create policy "user_settings_update_own" on public.user_settings
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());
drop policy if exists "user_settings_delete_own" on public.user_settings;
create policy "user_settings_delete_own" on public.user_settings
  for delete using (profile_id = auth.uid());


-- -----------------------------------------------------------------------------
-- B. Receipt history (owner, 14 Sep: "summary of how many items, scanned date,
--    purchase date/time and location of the receipt")
-- -----------------------------------------------------------------------------
create table if not exists public.receipts (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  scanned_by uuid references public.profiles(id) on delete set null,
  shop_name text check (char_length(shop_name) <= 120),
  -- As printed: the branch, suburb or address on the receipt. Not GPS.
  shop_location text check (char_length(shop_location) <= 200),
  purchased_at timestamptz,           -- date and time printed on the receipt
  scanned_at timestamptz not null default now(),
  item_count int not null default 0 check (item_count between 0 and 500),
  total_amount numeric(10, 2) check (total_amount >= 0),
  currency text check (currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now()
);

create index if not exists idx_receipts_household_scanned
  on public.receipts (household_id, scanned_at desc);

alter table public.receipts enable row level security;

drop policy if exists "receipts_select_member" on public.receipts;
create policy "receipts_select_member" on public.receipts
  for select using (app_private.is_household_member(household_id));
drop policy if exists "receipts_insert_member" on public.receipts;
create policy "receipts_insert_member" on public.receipts
  for insert with check (
    app_private.is_household_member(household_id) and scanned_by = auth.uid()
  );
drop policy if exists "receipts_update_member" on public.receipts;
create policy "receipts_update_member" on public.receipts
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "receipts_delete_member" on public.receipts;
create policy "receipts_delete_member" on public.receipts
  for delete using (app_private.is_household_member(household_id));

create table if not exists public.receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references public.receipts(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  quantity numeric(8, 2) not null default 1 check (quantity > 0),
  unit_price numeric(10, 2) check (unit_price >= 0),
  line_total numeric(10, 2) check (line_total >= 0),
  -- The food this line became in the kitchen, if it was added.
  food_item_id uuid references public.food_items(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_receipt_items_receipt
  on public.receipt_items (receipt_id);

alter table public.receipt_items enable row level security;

drop policy if exists "receipt_items_select_member" on public.receipt_items;
create policy "receipt_items_select_member" on public.receipt_items
  for select using (app_private.is_household_member(household_id));
drop policy if exists "receipt_items_insert_member" on public.receipt_items;
create policy "receipt_items_insert_member" on public.receipt_items
  for insert with check (app_private.is_household_member(household_id));
drop policy if exists "receipt_items_update_member" on public.receipt_items;
create policy "receipt_items_update_member" on public.receipt_items
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "receipt_items_delete_member" on public.receipt_items;
create policy "receipt_items_delete_member" on public.receipt_items
  for delete using (app_private.is_household_member(household_id));

-- Which receipt a food came from.
alter table public.food_items
  add column if not exists receipt_id uuid references public.receipts(id) on delete set null;


-- -----------------------------------------------------------------------------
-- C. Budget meal planning
-- -----------------------------------------------------------------------------
create table if not exists public.household_budgets (
  household_id uuid primary key references public.households(id) on delete cascade,
  weekly_amount numeric(10, 2) check (weekly_amount >= 0),
  currency text not null default 'AUD' check (currency ~ '^[A-Z]{3}$'),
  updated_by uuid references public.profiles(id) on delete set null,
  updated_at timestamptz not null default now()
);

drop trigger if exists set_household_budgets_updated_at on public.household_budgets;
create trigger set_household_budgets_updated_at
  before update on public.household_budgets
  for each row execute function app_private.set_updated_at();

alter table public.household_budgets enable row level security;

drop policy if exists "budgets_select_member" on public.household_budgets;
create policy "budgets_select_member" on public.household_budgets
  for select using (app_private.is_household_member(household_id));
drop policy if exists "budgets_insert_member" on public.household_budgets;
create policy "budgets_insert_member" on public.household_budgets
  for insert with check (app_private.is_household_member(household_id));
drop policy if exists "budgets_update_member" on public.household_budgets;
create policy "budgets_update_member" on public.household_budgets
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "budgets_delete_member" on public.household_budgets;
create policy "budgets_delete_member" on public.household_budgets
  for delete using (app_private.is_household_member(household_id));

-- The last price the household paid (from a receipt) or typed, per item name.
create table if not exists public.known_prices (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name_key text not null check (char_length(name_key) between 1 and 120), -- lower-case, trimmed
  display_name text not null check (char_length(display_name) between 1 and 120),
  price numeric(10, 2) not null check (price >= 0),
  currency text not null default 'AUD' check (currency ~ '^[A-Z]{3}$'),
  source text not null default 'receipt' check (source in ('receipt', 'typed')),
  receipt_item_id uuid references public.receipt_items(id) on delete set null,
  seen_at timestamptz not null default now(),
  unique (household_id, name_key)
);

alter table public.known_prices enable row level security;

drop policy if exists "known_prices_select_member" on public.known_prices;
create policy "known_prices_select_member" on public.known_prices
  for select using (app_private.is_household_member(household_id));
drop policy if exists "known_prices_insert_member" on public.known_prices;
create policy "known_prices_insert_member" on public.known_prices
  for insert with check (app_private.is_household_member(household_id));
drop policy if exists "known_prices_update_member" on public.known_prices;
create policy "known_prices_update_member" on public.known_prices
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "known_prices_delete_member" on public.known_prices;
create policy "known_prices_delete_member" on public.known_prices
  for delete using (app_private.is_household_member(household_id));


-- -----------------------------------------------------------------------------
-- D. Household meal planning: who eats, how much, and what they avoid
-- -----------------------------------------------------------------------------
-- Everyone who eats at home, with or without the app (children included).
create table if not exists public.household_diners (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete set null, -- null: no account
  name text not null check (char_length(name) between 1 and 60),
  -- Portion compared with an adult serving: 0.5 a small child, 1.5 a big eater.
  default_portion numeric(3, 2) not null default 1
    check (default_portion between 0.25 and 3),
  allergens jsonb not null default '[]',
  dietary_preferences jsonb not null default '[]',
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (household_id, profile_id)
);

drop trigger if exists set_household_diners_updated_at on public.household_diners;
create trigger set_household_diners_updated_at
  before update on public.household_diners
  for each row execute function app_private.set_updated_at();

alter table public.household_diners enable row level security;

drop policy if exists "diners_select_member" on public.household_diners;
create policy "diners_select_member" on public.household_diners
  for select using (app_private.is_household_member(household_id));
drop policy if exists "diners_insert_member" on public.household_diners;
create policy "diners_insert_member" on public.household_diners
  for insert with check (app_private.is_household_member(household_id));
drop policy if exists "diners_update_member" on public.household_diners;
create policy "diners_update_member" on public.household_diners
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "diners_delete_member" on public.household_diners;
create policy "diners_delete_member" on public.household_diners
  for delete using (app_private.is_household_member(household_id));

-- Who is eating a planned meal, and how much each has.
create table if not exists public.meal_plan_diners (
  plan_entry_id uuid not null references public.meal_plan_entries(id) on delete cascade,
  diner_id uuid not null references public.household_diners(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  portions numeric(3, 2) not null default 1 check (portions between 0.25 and 3),
  primary key (plan_entry_id, diner_id)
);

alter table public.meal_plan_diners enable row level security;

drop policy if exists "plan_diners_select_member" on public.meal_plan_diners;
create policy "plan_diners_select_member" on public.meal_plan_diners
  for select using (app_private.is_household_member(household_id));
drop policy if exists "plan_diners_insert_member" on public.meal_plan_diners;
create policy "plan_diners_insert_member" on public.meal_plan_diners
  for insert with check (app_private.is_household_member(household_id));
drop policy if exists "plan_diners_update_member" on public.meal_plan_diners;
create policy "plan_diners_update_member" on public.meal_plan_diners
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "plan_diners_delete_member" on public.meal_plan_diners;
create policy "plan_diners_delete_member" on public.meal_plan_diners
  for delete using (app_private.is_household_member(household_id));


-- -----------------------------------------------------------------------------
-- E. Recipe collection: kept ideas become a collection
-- -----------------------------------------------------------------------------
alter table public.saved_recipes
  add column if not exists source text not null default 'idea';
alter table public.saved_recipes
  add column if not exists servings int;
alter table public.saved_recipes
  add column if not exists is_favourite boolean not null default false;
alter table public.saved_recipes
  add column if not exists notes text;
alter table public.saved_recipes
  add column if not exists updated_at timestamptz not null default now();

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'saved_recipes_source_check') then
    alter table public.saved_recipes
      add constraint saved_recipes_source_check check (source in ('idea', 'own'));
  end if;
  if not exists (select 1 from pg_constraint where conname = 'saved_recipes_servings_check') then
    alter table public.saved_recipes
      add constraint saved_recipes_servings_check check (servings is null or servings between 1 and 12);
  end if;
end $$;

drop trigger if exists set_saved_recipes_updated_at on public.saved_recipes;
create trigger set_saved_recipes_updated_at
  before update on public.saved_recipes
  for each row execute function app_private.set_updated_at();


-- -----------------------------------------------------------------------------
-- F. Product pictures: one row per picture the app knows for a product
-- -----------------------------------------------------------------------------
create table if not exists public.product_images (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  barcode text check (barcode ~ '^[0-9]{6,14}$'),
  name_key text not null check (char_length(name_key) between 1 and 120),
  country_code text check (country_code ~ '^[A-Z]{2}$'),
  -- Path in the private food-images bucket (<household>/...), not a URL.
  storage_path text not null,
  source text not null
    check (source in ('open_food_facts', 'shelf_crop', 'own_photo')),
  -- Credit owed to the source, e.g. "Open Food Facts, CC BY-SA".
  licence text,
  -- Copied from the person's user_settings.share_product_photos when added.
  share_consent boolean not null default false,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_product_images_lookup
  on public.product_images (household_id, name_key);
create index if not exists idx_product_images_barcode
  on public.product_images (barcode) where barcode is not null;

alter table public.product_images enable row level security;

drop policy if exists "product_images_select_member" on public.product_images;
create policy "product_images_select_member" on public.product_images
  for select using (app_private.is_household_member(household_id));
drop policy if exists "product_images_insert_member" on public.product_images;
create policy "product_images_insert_member" on public.product_images
  for insert with check (
    app_private.is_household_member(household_id) and created_by = auth.uid()
  );
drop policy if exists "product_images_update_member" on public.product_images;
create policy "product_images_update_member" on public.product_images
  for update using (app_private.is_household_member(household_id))
  with check (app_private.is_household_member(household_id));
drop policy if exists "product_images_delete_member" on public.product_images;
create policy "product_images_delete_member" on public.product_images
  for delete using (app_private.is_household_member(household_id));


-- -----------------------------------------------------------------------------
-- G. The week plan updates live on every phone in the household
-- -----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and tablename = 'meal_plan_entries'
  ) then
    alter publication supabase_realtime add table public.meal_plan_entries;
  end if;
end $$;


-- -----------------------------------------------------------------------------
-- Check: every new table, with row-level security on (all should be true)
-- -----------------------------------------------------------------------------
select relname as table_name, relrowsecurity as row_level_security
from pg_class
where relnamespace = 'public'::regnamespace
  and relname in ('user_settings', 'receipts', 'receipt_items', 'household_budgets',
                  'known_prices', 'household_diners', 'meal_plan_diners',
                  'product_images', 'meal_plan_entries', 'meal_log_entries')
order by relname;

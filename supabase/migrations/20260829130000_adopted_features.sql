-- ============================================================================
-- Use It Fresh — adopted-features migration (additions 1–5 from build review)
-- Run AFTER 20260829120000_init_useitfresh.sql, in the Supabase SQL editor.
--
-- 1. Environmental impact  -> no schema change (computed from food_item_events;
--                             per-recipe impact lives in saved_recipes.recipe_data)
-- 2. Critical-step flags   -> no schema change (recipe_data JSON schema)
-- 3. Recipe metadata       -> no schema change (recipe_data JSON schema)
-- 4. Recipe-linked shopping items -> new column below
-- 5. Food storage & safety tips library -> new table below
-- ============================================================================

-- 4. Link a shopping item to the saved recipe that generated it -------------
alter table public.shopping_list_items
  add column if not exists source_recipe_id uuid
    references public.saved_recipes(id) on delete set null;

create index if not exists idx_shopping_items_source_recipe
  on public.shopping_list_items (source_recipe_id)
  where source_recipe_id is not null;

-- 5. Global food care guide (storage & safety tips per category) -------------
-- App-curated content: readable by every signed-in user, written only via
-- service role / dashboard (no client write policies on purpose).
create table if not exists public.food_care_guides (
  id uuid primary key default gen_random_uuid(),
  category text not null unique,
  display_name text not null,
  storage_tips text not null,
  typical_shelf_life text,
  opened_shelf_life text,
  is_high_risk boolean not null default false,
  safety_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.food_care_guides enable row level security;

create policy "care_guides_read_authenticated" on public.food_care_guides
  for select to authenticated using (true);

create trigger set_food_care_guides_updated_at
  before update on public.food_care_guides
  for each row execute function app_private.set_updated_at();

-- Starter content (safe defaults; expand/curate later) -----------------------
insert into public.food_care_guides
  (category, display_name, storage_tips, typical_shelf_life, opened_shelf_life, is_high_risk, safety_notes)
values
  ('dairy', 'Dairy', 'Keep refrigerated at 5°C or below, in the coldest part of the fridge — not the door.', 'Use by printed date', 'Milk: 3 days after opening. Soft cheese: 5–7 days.', true, 'Discard if sour smell, curdling, or mould. Never taste to test.'),
  ('meat_poultry', 'Meat & poultry', 'Store on the bottom shelf, sealed, at 5°C or below. Freeze if not using within 1–2 days.', 'Use by printed date', 'Cook or freeze within 1–2 days of opening.', true, 'Raw juices contaminate other food. When past use-by, throw it out.'),
  ('seafood', 'Seafood', 'Coldest part of the fridge, use quickly. Best stored on ice or frozen.', '1–2 days fresh', 'Use the day it is opened where possible.', true, 'Strong fishy or ammonia smell means discard.'),
  ('eggs', 'Eggs', 'Refrigerate in the original carton, away from strong odours.', '3–5 weeks refrigerated', 'Hard-boiled: 1 week refrigerated.', true, 'Discard cracked or slimy-shelled eggs.'),
  ('cooked_leftovers', 'Cooked leftovers', 'Cool within 2 hours, store sealed and shallow so it chills fast.', '2–3 days refrigerated', 'Reheat once, until steaming hot throughout.', true, 'Cooked rice and pasta are high-risk — refrigerate fast, discard after 24–48h.'),
  ('fruit', 'Fruit', 'Most fruit lasts longer refrigerated; bananas, stone fruit, and tomatoes ripen at room temperature first.', 'Varies — check daily', 'Cut fruit: 2–3 days sealed in the fridge.', false, 'Trim small bruises; discard anything mouldy or fermenting.'),
  ('vegetables', 'Vegetables', 'Crisper drawer, unwashed, in breathable bags. Keep onions and potatoes dark and dry outside the fridge.', '3–10 days depending on type', 'Cut vegetables: 2–3 days sealed.', false, 'Slimy leaves or soft rot means discard.'),
  ('bread_bakery', 'Bread & bakery', 'Room temperature in a bread bin or sealed bag; freeze what you will not eat in 2–3 days.', '2–5 days', 'Same once opened.', false, 'Any visible mould: discard the whole loaf, not just the slice.'),
  ('pantry_dry', 'Pantry & dry goods', 'Cool, dry, sealed containers. Label opened packets with the date.', 'Months — check best-before', 'Varies; sealed containers extend life.', false, 'Best-before is about quality: inspect, smell, then decide.'),
  ('frozen', 'Frozen food', 'Keep at -18°C. Never refreeze fully thawed raw meat or fish.', '1–12 months depending on type', 'Once thawed, treat as fresh.', false, 'Freezer burn is a quality issue, not a safety one.'),
  ('condiments_sauces', 'Condiments & sauces', 'Refrigerate after opening unless the label says otherwise.', 'Best-before on label', 'Typically 1–3 months refrigerated once opened.', false, 'Swollen lids or fizzing on opening means discard.'),
  ('infant_food', 'Infant food & formula', 'Follow the label exactly. Made-up formula: refrigerate and use within 24 hours.', 'Use by printed date — strict', 'Opened jars: 24–48 hours refrigerated, per label.', true, 'No speculative extension, ever. When in doubt, throw it out.')
on conflict (category) do nothing;

-- ============================================================================
-- Done. Adds: 1 column, 1 index, 1 content table (12 seeded guides), 1 policy.
-- ============================================================================

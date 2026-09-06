# Use It Fresh — Spec Addendum 01 (adopted features)

Amends `.ff-attachments/AI_FRIDGE_FLUTTERFLOW_BUILD_SPEC_3af28b16.md`.
Decided 2026-08-29: adopt prototype features 1–5 from the build review
(https://claude.ai/code/artifact/88abccbb-4d5b-4d7b-befd-974351ea0834).

## A1. Environmental impact (amends §8.12 Insights)
Insights additionally show **estimated food waste avoided (kg)** — monthly and
all-time — computed from `food_item_events` (consumed vs discarded, with
per-category weight estimates). Recipes may carry an estimated `impact_kg`.
Present as estimates, never exact facts (same rule as money figures).

## A2. Critical-step flags (amends §13.5 recipe JSON)
Each recipe step in the structured JSON carries:
- `tip` (optional string) — technique guidance.
- `is_critical` (bool) — marks food-safety-critical steps (e.g. "cook chicken
  to 75°C throughout"). UI renders critical steps with the safety treatment
  (icon + text, never colour alone; §10 rules apply).

## A3. Recipe metadata (amends §13.5 recipe JSON)
Recipe JSON additionally requires `difficulty` (easy|medium|hard),
`prep_time_minutes` (int), and `calories_estimate` (int, labelled an estimate).

## A4. Recipe-linked shopping items (amends §11 `shopping_list_items`)
New column: `source_recipe_id uuid references saved_recipes(id) on delete set null`.
Items added from a recipe link back to it; deleting the recipe keeps the items.
(Applied in migration `20260829130000_adopted_features.sql`.)

## A5. Food care guide (new; complements §8.8)
New global content table `food_care_guides` — per-category storage tips,
typical/opened shelf life, high-risk flag, safety notes. Read-only for clients
(RLS: authenticated select only; writes via dashboard/service role). Surfaces
on item detail pages and as passive education; 12 categories seeded.
(Applied in migration `20260829130000_adopted_features.sql`.)

## Explicitly rejected
Numeric freshness score (0–100) as a safety signal — conflicts with §5/§10.
Discrete statuses remain the only safety language; a derived progress bar may
be used for sorting/visuals but must never be labelled as safety.

# AI Fridge — FlutterFlow Desktop AI Build Specification

## 1. Product definition

Build **AI Fridge**, a cross-platform Flutter app that helps people understand what food they have, what should be used first, what may no longer be safe, and what meals they can make before food is wasted.

Core promise:

> Take a photo of food, a package, a receipt, or the inside of your fridge. AI identifies the items, estimates their useful life, remembers when they were opened, and tells you what to use next.

The app must work from one Flutter codebase on web, iOS, and Android. Use FlutterFlow as the application source of truth and Supabase for authentication, database, storage, and realtime household sharing.

The MVP should be fast to use. Adding an item should take seconds, not require filling out a long form.

---

## 2. Primary user problems

1. People forget what is in the fridge, freezer, and pantry.
2. Printed use-by/best-before dates are missed.
3. Once opened, many products have a shorter safe/useful life that is not tracked.
4. Leftovers and unlabelled containers are forgotten.
5. People throw away usable food because they are unsure whether it is still good.
6. People buy duplicates because they cannot remember what they already have.
7. Households do not share one live food inventory.
8. Meal planning rarely prioritises ingredients that need to be used soon.

---

## 3. MVP goals

The MVP must allow a user to:

1. Sign up and sign in.
2. Create or join a household.
3. Add food using a camera/photo, barcode, receipt, or quick manual entry.
4. Let AI suggest the product name, category, storage location, quantity, package date, and expiry date.
5. Correct every AI suggestion before saving.
6. Mark an item as opened and track the opened date.
7. See a fridge inventory sorted by urgency.
8. Receive reminders before food is likely to expire.
9. Ask, “Is this still good?” and receive a cautious assessment with reasons and safety warnings.
10. Ask what can be cooked from available food, prioritising items that should be used first.
11. Mark items consumed, discarded, frozen, moved, or donated.
12. View simple waste and savings insights.

---

## 4. Non-goals for the first release

Do not attempt to:

- Guarantee that food is safe to eat.
- Diagnose foodborne illness.
- Replace government food-safety guidance.
- Infer safety from a photo alone with certainty.
- Integrate directly with smart-fridge hardware.
- Support restaurant/commercial HACCP compliance.
- Automatically order groceries without explicit confirmation.
- Build a public recipe social network.

---

## 5. Food-safety rules

These rules are mandatory and higher priority than convenience or engagement.

1. Never state that food is definitely safe based only on an image or estimated date.
2. Distinguish clearly between:
   - **Use-by date**: safety-related; recommend disposal after the date unless authoritative guidance explicitly permits otherwise.
   - **Best-before date**: quality-related; may still be usable after inspection.
   - **Estimated freshness window**: app estimate, not a manufacturer date.
3. For high-risk foods, use more conservative guidance:
   - raw meat, poultry, seafood;
   - cooked rice and pasta;
   - dairy;
   - eggs;
   - infant food/formula;
   - leftovers;
   - food stored outside safe temperatures.
4. If storage history, temperature, or opening date is unknown, say so and lower confidence.
5. If mould, swelling, leaking, unusual odour, slime, damaged seals, or temperature abuse is reported, recommend disposal rather than tasting.
6. Never advise tasting food as a safety test.
7. Infant formula and medically sensitive foods must receive strict warnings and no speculative extension.
8. Show local emergency/health advice if the user reports symptoms after eating food.
9. Every assessment must display:
   - result category;
   - confidence;
   - evidence used;
   - missing information;
   - a short disclaimer.
10. Default disclaimer:

> AI Fridge provides general food-management guidance, not a guarantee of safety. When in doubt—especially with high-risk food—throw it out and follow local food-safety advice.

---

## 6. Platforms and architecture

### Client

- FlutterFlow-generated Flutter app.
- One codebase for web, iOS, and Android.
- Mobile-first responsive design.
- Camera, gallery, barcode scanning, notifications, and optional location/locale access.

### Backend

- Supabase Authentication.
- Supabase Postgres.
- Supabase Storage for food, receipt, and fridge images.
- Supabase Realtime for shared household inventory.
- Supabase Edge Functions or a secure backend for AI calls.

### AI

AI calls must be made server-side. Never expose private model API keys in the Flutter client.

Use AI for:

- image classification and OCR;
- product/date extraction;
- receipt parsing;
- fridge-scene item suggestions;
- cautious freshness assessment;
- recipe generation using inventory;
- natural-language inventory queries.

All AI output must be structured JSON and validated before writing to the database.

---

## 7. User types and household model

### User

A signed-in person with a profile.

### Household

A shared inventory space. A user may belong to one or more households in a future release; the MVP may default to one active household.

Roles:

- Owner
- Admin
- Member
- Child/read-only member (future)

Household features:

- Invite by email or link.
- Shared fridge/freezer/pantry inventory.
- Realtime updates.
- Activity history showing who added, opened, consumed, or discarded an item.

---

## 8. Required screens

### 8.1 Splash and startup

- Brand mark and loading state.
- Restore authentication session.
- Route signed-in users to Home and others to Welcome/Auth.

### 8.2 Welcome and authentication

- Product explanation in one sentence.
- Email/password sign-up and sign-in.
- Google sign-in.
- Apple sign-in for iOS before release.
- Password reset.
- Terms, privacy, and food-safety disclaimer links.

### 8.3 Onboarding

Collect:

- display name;
- country/region and locale;
- preferred units (metric/imperial);
- dietary preferences;
- allergies, with explicit warning that recipe filtering is not a medical guarantee;
- notification preferences;
- create household or join household.

### 8.4 Home dashboard

Show:

- greeting;
- **Use first** carousel/list;
- counts: expiring today, expiring soon, fresh, frozen;
- quick actions: Scan Item, Scan Fridge, Scan Receipt, Add Manually;
- meal suggestions using urgent items;
- recent household activity;
- estimated money/food saved this month.

### 8.5 Inventory

Tabs or filters:

- All
- Fridge
- Freezer
- Pantry
- Expiring Soon
- Opened

Capabilities:

- search;
- sort by urgency, date added, name, category;
- category filter;
- household-member filter;
- compact/list/grid modes;
- bulk select and update;
- clear empty, loading, error, and offline states.

### 8.6 Add/scan flow

Entry choices:

1. Photograph one item/package.
2. Scan barcode.
3. Photograph a receipt.
4. Photograph fridge/freezer/pantry contents.
5. Add manually.

Always show a review screen before saving AI-detected data.

### 8.7 Item details

Show and edit:

- image;
- item/product name;
- brand;
- category;
- quantity and unit;
- storage location;
- purchase date;
- printed date and date type;
- opened status/date;
- estimated expiry;
- urgency status;
- notes;
- AI confidence and source of each inferred field;
- household activity history.

Actions:

- Mark opened
- Mark consumed
- Mark discarded
- Move to freezer/fridge/pantry
- Extend quantity
- Duplicate
- Ask “Is this still good?”
- Use in recipe

### 8.8 “Is this still good?” assessment

Ask targeted questions rather than relying only on a photo:

- What is the food?
- Printed use-by/best-before date?
- When opened/cooked?
- Where and how stored?
- Was it left unrefrigerated? For how long?
- Any visible mould, swelling, leaking, slime, discolouration?
- Any unusual smell? Do not ask user to taste.

Result categories:

- **Discard — unsafe or too uncertain**
- **Use immediately/cook thoroughly**
- **Likely usable after normal inspection**
- **Quality may be reduced**
- **Insufficient information**

Result screen must explain the reasoning and show the mandatory disclaimer.

### 8.9 Recipes / “What can I make?”

- Prioritise items expiring soon.
- Let user select meal type, time, servings, dietary preferences, and excluded ingredients.
- Clearly list inventory items used and missing ingredients.
- Never silently assume an allergen is absent.
- Save recipe and add missing ingredients to shopping list.

### 8.10 Shopping list

- Manual items.
- Add missing recipe ingredients.
- Add frequently consumed/replacement items.
- Mark purchased.
- Optional conversion of purchased items into inventory.
- Shared realtime household list.

### 8.11 Notifications/reminders

Views:

- expiring today;
- expiring in 1–3 days;
- opened-item reminders;
- freezer reminders;
- household changes;
- weekly “use first” summary.

Users control reminder timing and quiet hours.

### 8.12 Insights

- Items consumed vs discarded.
- Estimated value saved.
- Estimated value wasted.
- Most discarded categories.
- Monthly trend.
- Suggested behaviour changes.

Do not present estimates as exact financial facts.

### 8.13 Household management

- Household name.
- Members and roles.
- Invite/revoke.
- Activity history.
- Shared preferences.
- Leave/delete household with confirmation and ownership transfer rules.

### 8.14 Profile and settings

- Name and avatar.
- Units and locale.
- Dietary preferences and allergies.
- Notification settings.
- Data export/delete account.
- Privacy policy, terms, AI explanation, food-safety guidance.
- Sign out.

---

## 9. Navigation

Use one canonical bottom navigation component:

1. Home
2. Inventory
3. Scan/Add (prominent centre action)
4. Recipes
5. Profile

Requirements:

- Current destination has a clear selected state.
- Mobile safe-area support.
- Accessible labels on every icon.
- Do not create multiple inconsistent bottom-nav variants.

---

## 10. Inventory status model

Use these user-facing statuses:

- Fresh
- Use Soon
- Use Today
- Past Best Before
- Past Use By
- Frozen
- Consumed
- Discarded
- Unknown

Suggested colour system:

- Fresh: green
- Use Soon: amber
- Use Today: orange
- Past Use By / discard: red
- Past Best Before: muted purple/brown
- Frozen: blue
- Unknown: grey

Do not rely on colour alone. Always include text and an icon.

Urgency should be calculated from:

- printed date and date type;
- opened date;
- storage location;
- item category;
- AI freshness window;
- user corrections;
- authoritative safety rules.

---

## 11. Data model

Use UUID primary keys and timestamps. Enable Row Level Security on every public table.

### `profiles`

- `id uuid primary key references auth.users(id)`
- `display_name text`
- `avatar_url text`
- `country_code text`
- `locale text`
- `unit_system text default 'metric'`
- `dietary_preferences jsonb default '[]'`
- `allergens jsonb default '[]'`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `households`

- `id uuid primary key default gen_random_uuid()`
- `name text not null`
- `owner_id uuid references profiles(id)`
- `invite_code text unique`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

### `household_members`

- `household_id uuid references households(id) on delete cascade`
- `profile_id uuid references profiles(id) on delete cascade`
- `role text default 'member'`
- `joined_at timestamptz default now()`
- primary key (`household_id`, `profile_id`)

### `storage_locations`

- `id uuid primary key default gen_random_uuid()`
- `household_id uuid references households(id) on delete cascade`
- `name text not null`
- `location_type text not null` (`fridge`, `freezer`, `pantry`, `other`)
- `is_default bool default false`
- `created_at timestamptz default now()`

### `food_items`

- `id uuid primary key default gen_random_uuid()`
- `household_id uuid references households(id) on delete cascade`
- `storage_location_id uuid references storage_locations(id)`
- `created_by uuid references profiles(id)`
- `name text not null`
- `brand text`
- `category text`
- `barcode text`
- `quantity numeric default 1`
- `unit text default 'item'`
- `image_url text`
- `purchase_date date`
- `printed_date date`
- `printed_date_type text` (`use_by`, `best_before`, `sell_by`, `unknown`)
- `opened_at timestamptz`
- `cooked_at timestamptz`
- `frozen_at timestamptz`
- `estimated_expiry_at timestamptz`
- `expiry_source text` (`printed`, `ai_estimate`, `opened_rule`, `user`)
- `status text default 'fresh'`
- `confidence numeric`
- `notes text`
- `source_type text` (`photo`, `barcode`, `receipt`, `fridge_scan`, `manual`)
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`
- `archived_at timestamptz`

### `food_item_events`

- `id uuid primary key default gen_random_uuid()`
- `food_item_id uuid references food_items(id) on delete cascade`
- `profile_id uuid references profiles(id)`
- `event_type text not null` (`created`, `opened`, `moved`, `consumed`, `discarded`, `quantity_changed`, `assessment`)
- `from_value jsonb`
- `to_value jsonb`
- `created_at timestamptz default now()`

### `scan_sessions`

- `id uuid primary key default gen_random_uuid()`
- `household_id uuid references households(id)`
- `profile_id uuid references profiles(id)`
- `scan_type text not null`
- `image_url text`
- `raw_ai_response jsonb`
- `status text default 'processing'`
- `created_at timestamptz default now()`

### `scan_candidates`

- `id uuid primary key default gen_random_uuid()`
- `scan_session_id uuid references scan_sessions(id) on delete cascade`
- `suggested_name text`
- `suggested_category text`
- `suggested_brand text`
- `suggested_quantity numeric`
- `suggested_unit text`
- `suggested_printed_date date`
- `suggested_date_type text`
- `suggested_storage_type text`
- `confidence numeric`
- `bounding_box jsonb`
- `accepted bool`
- `created_food_item_id uuid references food_items(id)`

### `freshness_assessments`

- `id uuid primary key default gen_random_uuid()`
- `food_item_id uuid references food_items(id) on delete set null`
- `profile_id uuid references profiles(id)`
- `household_id uuid references households(id)`
- `answers jsonb not null`
- `result_category text not null`
- `confidence numeric`
- `reasoning_summary text`
- `missing_information jsonb`
- `guidance text`
- `model_version text`
- `created_at timestamptz default now()`

### `shopping_lists`

- `id uuid primary key default gen_random_uuid()`
- `household_id uuid references households(id) on delete cascade`
- `name text default 'Shopping List'`
- `created_at timestamptz default now()`

### `shopping_list_items`

- `id uuid primary key default gen_random_uuid()`
- `shopping_list_id uuid references shopping_lists(id) on delete cascade`
- `name text not null`
- `quantity numeric`
- `unit text`
- `source text` (`manual`, `recipe`, `replacement`)
- `is_purchased bool default false`
- `created_by uuid references profiles(id)`
- `created_at timestamptz default now()`

### `saved_recipes`

- `id uuid primary key default gen_random_uuid()`
- `household_id uuid references households(id)`
- `profile_id uuid references profiles(id)`
- `title text not null`
- `recipe_data jsonb not null`
- `inventory_item_ids jsonb`
- `created_at timestamptz default now()`

### `notification_preferences`

- `profile_id uuid primary key references profiles(id)`
- `expiry_enabled bool default true`
- `expiry_days_before int default 2`
- `opened_item_enabled bool default true`
- `weekly_summary_enabled bool default true`
- `quiet_hours_start time`
- `quiet_hours_end time`
- `updated_at timestamptz default now()`

---

## 12. Row Level Security

Required policies:

1. Users can read/update their own profile.
2. Household members can read household, locations, food, shopping, recipes, and activity for households they belong to.
3. Members may create/update inventory in their household.
4. Only household owner/admin may invite/remove members or delete the household.
5. Users may read only their own scan sessions and assessments, unless the record belongs to a shared household and sharing is explicitly intended.
6. Storage objects must be scoped to household/user paths.
7. Never expose service-role credentials in FlutterFlow.

---

## 13. AI workflows

### 13.1 Single-item photo

Input:

- image;
- locale;
- optional barcode/OCR text.

Return strict JSON:

- product name;
- brand;
- category;
- visible printed date;
- printed date type;
- quantity/unit;
- suggested storage;
- confidence per field;
- warnings.

### 13.2 Receipt scan

Return a list of likely food purchases. Ignore non-food unless the user chooses to keep them. The review screen allows multi-select, correction, and batch save.

### 13.3 Fridge-scene scan

Return item candidates with bounding boxes and confidence. Do not claim complete inventory. Label the result as “Items I could identify.” Let users add missed items and merge duplicates.

### 13.4 Freshness assessment

Use deterministic food-safety rules before generative reasoning. The AI may explain and personalise the result but cannot override strict disposal rules.

### 13.5 Recipe generation

Send only relevant inventory metadata, preferences, servings, and constraints. Require structured recipe JSON. Clearly distinguish available and missing ingredients.

### 13.6 Natural-language inventory queries

Examples:

- “What needs using today?”
- “Do we have milk?”
- “What can I make in 20 minutes?”
- “What did we waste most this month?”

Convert intent into safe, household-scoped database queries. Do not let the model generate unrestricted SQL.

---

## 14. Notifications

Implement local/push reminders for:

- use-by date approaching;
- best-before date approaching;
- opened food approaching its estimated window;
- leftovers older than configured threshold;
- weekly use-first digest;
- shared household updates if enabled.

Notification copy must avoid certainty, for example:

> Your opened yoghurt is estimated to be near the end of its recommended storage window. Check the date and condition before use.

---

## 15. Monetisation

Use a freemium model.

### Free

- Manual inventory.
- Limited scans per month.
- Basic expiry reminders.
- One household.
- Basic recipe suggestions.

### Premium

- More/unlimited AI scans subject to fair-use limits.
- Receipt and full-fridge scans.
- Advanced freshness assessments.
- Multiple households/storage locations.
- Household sharing.
- Advanced insights.
- Unlimited recipe generation.
- Export/history.

Do not implement billing before core retention is validated, but design entitlement checks cleanly so RevenueCat can be added later.

---

## 16. Design system

Tone: clean, reassuring, modern, practical, non-judgmental.

Suggested palette:

- Fresh green
- Warm cream/off-white surfaces
- Charcoal text
- Amber/orange urgency
- Red only for clear safety/discard warnings
- Cool blue for frozen/storage information

Requirements:

- Do not use alarming red for ordinary best-before reminders.
- Never rely on colour alone.
- Minimum touch targets around 44×44 logical pixels.
- Accessible contrast.
- Large camera/scan actions.
- Clear AI confidence and correction controls.
- All lists have loading, empty, error, offline, and retry states.

---

## 17. Analytics and privacy

Track privacy-conscious product events:

- onboarding completion;
- item-added method;
- AI suggestion accepted/corrected;
- item consumed/discarded;
- assessment started/completed;
- recipe generated/saved;
- notification opened;
- premium conversion.

Privacy requirements:

- Obtain explicit consent for camera/photo processing.
- Explain whether images are retained.
- Allow users to delete images and account data.
- Do not use household food images for model training without separate opt-in consent.
- Minimise data sent to AI providers.
- Provide privacy policy and AI transparency page.

---

## 18. Testing

Required automated/manual flows:

1. Sign-up, sign-in, reset, sign-out.
2. Create/join household.
3. Add item manually.
4. Photo scan and correction.
5. Barcode scan and unknown barcode fallback.
6. Receipt scan with multiple candidates.
7. Fridge scan with candidate review.
8. Mark opened and verify recalculated estimate.
9. Expiry notification scheduling.
10. “Is this still good?” safe and unsafe scenarios.
11. Recipe generation with allergens/preferences.
12. Shared household realtime updates.
13. RLS: no cross-household access.
14. Offline/error/retry behavior.
15. Responsive web, iOS, and Android layouts.
16. Account deletion and storage cleanup.

---

## 19. Build phases

### Phase 1 — Foundation

- Supabase project, schema, RLS, Storage.
- Auth and profile.
- Household creation.
- Canonical navigation and design system.

### Phase 2 — Inventory MVP

- Manual add/edit.
- Inventory lists/filters.
- Opened/consumed/discarded actions.
- Urgency calculation.

### Phase 3 — AI capture

- Single photo/OCR.
- Barcode.
- Receipt scan.
- Candidate review and correction.
- Storage upload.

### Phase 4 — Freshness and reminders

- Opened-date tracking.
- Rule engine.
- “Is this still good?” questionnaire and assessment.
- Notifications.

### Phase 5 — Recipes and shopping

- Use-first recipes.
- Shopping list.
- Saved recipes.

### Phase 6 — Household and insights

- Invites/realtime sharing.
- Activity history.
- Waste/savings insights.

### Phase 7 — Commercial readiness

- Premium entitlements.
- Privacy/export/delete.
- Store assets, analytics, crash reporting.
- Production security review.

Do not build all phases in one mutation. Finish, generate, test, and verify each phase before continuing.

---

## 20. Guardrails for the FlutterFlow Desktop AI agent

1. Inspect the existing FlutterFlow project before creating resources.
2. Edit existing resources when present; do not create duplicate pages/components/tables.
3. Build one phase at a time.
4. Validate project errors after every change.
5. Generate and inspect Flutter output after structural changes.
6. Never expose private AI, Supabase service-role, OAuth, or payment secrets in client code.
7. Keep all AI calls behind secure server functions.
8. Require review before saving AI-extracted inventory.
9. Never present AI freshness guidance as a safety guarantee.
10. Keep RLS enabled and test policies.
11. Do not silently overwrite user-corrected dates or product information.
12. Preserve event history for opened/consumed/discarded changes.
13. Avoid unsupported raw project mutations; report limitations before attempting them.
14. Use one codebase for web, iOS, and Android.
15. At the end of each phase, report resources changed, migrations, tests, warnings, and the next recommended phase.

---

## 21. Initial agent instruction

Use this exact instruction with the FlutterFlow Desktop AI agent:

> Read `AI_FRIDGE_FLUTTERFLOW_BUILD_SPEC.md` completely. First inspect the active FlutterFlow project and report what already exists. Then implement only Phase 1 from section 19. Do not create duplicates and do not proceed to Phase 2 until Phase 1 has been generated, validated, and tested. Use Supabase with Row Level Security, keep all private AI credentials server-side, and follow the food-safety rules in section 5 as non-negotiable requirements. At completion, report every page, component, table, policy, action, and configuration changed, plus remaining warnings and the exact next step.


# Use It Fresh — hybrid visual system and implementation guide

15 September 2026. Based on supplied IMG_0362–IMG_0389 screenshots.

## Open the design

Open PREVIEW.html in a browser. Select screens from the left menu (horizontal menu on narrow windows). The prototype includes 33 screen states: the supplied screen families, food variants, scan review and explicitly marked proposal screens. Existing screenshots that show scrolled portions of one page are consolidated into that page.

This is an appearance and interaction demonstration. Data is illustrative and does not persist when changing screens. No live authentication, AI capture, inventory, notifications, payments or household actions are connected. Example buttons demonstrate feedback or navigation, not completed production workflows. Do not enter real passwords into the prototype.

The user selected option 2's soft blurred food background combined with option 3's sculpted cream surfaces. This guide supersedes the surface recommendations in the accompanying earlier review. The earlier review's issue list remains applicable. Original app colours and the approved fridge launch experience remain.

## Material and component specification

- Background: a static food-derived blur with a strong cream veil. Current reference uses spinach: cream #F7F7F0 at roughly 70% near the top and 85% near the bottom, over the photograph, then about 16 logical pixels of blur. Use a pre-rendered background for production where possible. No photograph of the user's private kitchen is required. Keep imagery abstract and text readable. Do not add the woven pattern from option 3 on top.
- Cards: opaque warm cream, subtle diagonal gradient #FFFEF9 to #F3F3E9, 22 radius, 1-pixel #CDD4C3 border, a narrow white upper highlight, a 2-pixel lower edge and a soft shadow. This is a restrained bevel, not heavy 3D embossing. Forms and text remain solid and readable.
- Main buttons: 50–52 minimum height, 15–16 radius, forest gradient #176C50 to #07533A, thin upper highlight, darker lower edge of about 3 pixels. White semibold text. A brief 1-pixel press response is enough. One clear primary action per task. Reduced-motion users get tonal feedback without motion.
- Secondary buttons: cream gradient, thin sage border and smaller lower edge. Destructive controls are labelled, separated from ordinary actions and require appropriate quantity/confirmation. Do not make discard look like the main goal.
- Inputs: subtly inset white/cream fields, persistent labels, minimum 50–56 height. Avoid raised effects on editable fields; distinguish them from buttons.
- Metadata: muted #59665D. Primary text #202C24, headings #07533A. Essential text must satisfy contrast checks on its actual background. Small prototype metadata is illustrative; production normal body text should be 16 logical pixels, supporting text generally 13–14, with dynamic text support.
- Layout: 20-pixel horizontal inset, 12–16 between peers, 24–32 between sections. The prototype's phone shape frames the review only; do not build that border into the mobile app. Background and navigation should fill the actual safe-area layout.
- Icons: use the established supplied icon pack or a single native icon family. Some prototype symbols are layout stand-ins, not final navigation or scan artwork. Replace all stand-ins with consistent 22–24 icons and provide labelled tap targets of at least 44 pixels. Do not ship mixed Unicode glyphs as the final icon system.
- Navigation: five destinations retained. Scan is an action with visual prominence, while current-page selection remains distinguishable. No bottom navigation during camera capture or focused secondary forms. In production, use safe-area-aware navigation and sufficient content padding; do not overlay and conceal content.
- Image priority: own photo, authorised exact-product image, matching generic food illustration/photo, then compact fallback. Match food form. Dry pasta must not use a cooked-meal photograph. The sample deliberately shows a compact dry-pasta fallback. Label illustrative imagery in details. Never imply an illustration is the user's actual food.
- Performance: preload only needed imagery; thumbnail grids use appropriately sized cached files. Avoid stacking live blur filters on every tile. Prefer a single static background and solid sculpted cards. Provide image failures and loading states.

## Screens requiring specific treatment

### Camera capture

Use the real live camera feed, a restrained framing guide and high-contrast controls. Photo, Shelf, Receipt and Barcode modes must all be reachable without clipped labels. Barcode uses a short central guide; receipt needs a tall guide and any supported multi-shot flow. One large shutter, Gallery, Close and an available manual alternative. Flash only appears if supported. Respect top/bottom safe areas and camera permission denial. The prototype uses a labelled stock-food placeholder, not a working camera. Review recognition results before adding anything; retakes must not duplicate inventory.

### Profile editing

Use a photo/initial avatar, one friendly name field, a clear two-choice Metric/Imperial control and Save changes. Do not greet people by an email fragment. The avatar control must have remove/cancel behaviour, failure feedback and a non-photo fallback. Avoid onboarding copy when editing an existing profile. Confirm saved state and retain values after errors. Keep account email/security separate from the shared display name.

### Inventory and food detail

Prioritise readable food names, correct image mapping, meaningful quantity and explicit date basis. Large hero photos are useful on details but should not push routine actions below multiple metadata panels. More details can expand. Dates must distinguish pack use-by, pack best-before, estimates and unknowns. A multi-item record needs a partial-use flow. Adding to a shopping list is an independent action, not a radio input. Discard, Undo and restore must have accurate consequences.

### Recipe discovery and recipe detail

Actual recipe imagery or intentional ingredient-based fallback comes first. Keep quick filters compact and use a sheet for detailed criteria. Per-serving nutrition requires reliable amounts and calculation; the prototype deliberately avoids fabricated nutrition numbers. The recipe detail is a layout sample, not a complete cookable recipe: bind actual ingredient quantities, method, serving changes and relevant guidance before shipping. Saved recipes must genuinely persist in production. Only show “in your kitchen” when the actual matching quantity/state supports it.

### Forms, safety and secondary screens

Use consistent Back controls, solid input surfaces, persistent labels, keyboard handling and inline errors. Retain relevant allergy/label guidance, with expandable supporting explanations. Do not change authentication validation to match a visual mockup. Household join needs an explicit active-household consequence. Location deletion must deal with existing items. Reminder settings must reflect real permission and scheduling behaviour. Empty receipts gets a direct Scan action. Shopping has a compact Add row and optional repurchase suggestions. History describes recorded activity without guilt, invented savings or claiming missing data is zero.

## Mapping supplied screenshots

| Screenshots | Prototype destinations |
|---|---|
| 0362 | Shelf camera; other capture mode variants |
| 0363 | Home |
| 0364–0365, 0379–0381 | Inventory with filters and food variants |
| 0366, 0389 | Recipes; recipe detail as a supporting design |
| 0367–0368 | Profile |
| 0369 | Edit profile |
| 0370 | Diet & allergies |
| 0371 | Security |
| 0372 | Household |
| 0373 | Storage |
| 0374 | Shopping list |
| 0375 | Receipts |
| 0376 | Reminders |
| 0377–0378 | Your food history |
| 0382 | Add food |
| 0383–0386 | Food detail, with photo and fallback variants |
| 0387 | Edit / manual food |
| 0388 | Use soon |

Scan review is a supporting proposed layout. Weekly plan and meal-goal controls appear hinted at in the screenshots, but their full behaviour was not supplied. Their prototype layouts are proposals; do not infer the features are absent or complete. Cooking together, Plan notification and Plus are explicitly new backlog concepts.

## QA and implementation sequence

1. Resolve date uncertainty, status consistency and image-mapping issues in SCREEN-REVIEW.md.
2. Create shared FlutterFlow theme/components, then bind Home, Inventory, Recipes and Food detail to real data.
3. Implement camera, form and secondary-screen variants without losing existing functionality.
4. Test at 360/390/430 logical widths, large text, actual iPhone safe areas, keyboard open, image failures and long product names. Verify loading, empty and error states.
5. Verify count refresh, partial use, Undo, household scope, date sorting, allergy exclusions, ingredient matching and duplicate submission protection.
6. Review screenshots with the user before applying any new paywall. New collaboration features require backlog approval and separate functional testing.

The browser prototype is not FlutterFlow source code. Rebuild its reusable components in FlutterFlow and retain the app's data/actions. The six included WebP files and approved SVG logo are reusable assets; the embedded prototype works without a network connection. The supplied imagery is illustrative. Preserve provenance and verify any external product-image licences before distribution.

## Backlog — household cooking coordination

### H01: “Planning to use” — first experiment

As a household member, I can choose food quantities or a recipe, set a meal time and say “I'm planning to use these”. Other members see a compact activity card such as “Ash is planning pasta tonight”. They can respond “I'll help”, “Save me a plate” or flag a clash. These are action responses, not a full chat app.

Planned food stays in inventory. Display total and reserved quantities separately where appropriate. A reservation is an advisory claim, not a safety claim or a hard lock that prevents someone using food. Detect overlapping claims and show who planned what. Warn on insufficient availability and offer another ingredient, time or quantity. Actual consumption is confirmed separately and must not be counted twice by multiple people.

Use the current household's permissions. Store plan author, household, time zone, planned time, servings, item IDs/batches, quantities/units and lifecycle state. Suggested states: draft, planned, cooking, completed, cancelled. Quantity reservations attach only to committed plans. Release or flag stale reservations after an explicit configurable rule; never silently count them as eaten. Edits/cancellations update existing reservations rather than creating duplicates. Do not store raw invite secrets in shared activity payloads.

Acceptance: planning leaves inventory quantity unchanged; members in another household cannot see the plan; concurrent claims show conflict; cancellation releases reservations; completion asks for actual amounts and leftovers; retries are idempotent; users can correct mistakes.

### H02: Notifications — permission-based follow-up

First provide in-app activity; add push only for members who opted in. The author explicitly chooses to notify the household on a committed plan. No notification for every draft keystroke. Support quiet hours, per-household preferences, read state, muted members and deduplication. Push opens the specific plan after checking current access. Use minimal lock-screen text and do not expose diet/allergy details. In-app activity remains available if push is disabled. Test denied permissions and expired membership. This prototype sends nothing.

### H03: Coordinated meal planning — potential Plus

Shared weekly planner, assigned cooking nights, per-person servings/preferences, prep tasks, leftovers and one reviewed shopping list. Start with household members choosing responsibilities; avoid algorithmically assigning people work without agreement. Keep allergies distinct from preferences and handle conflicts explicitly. Multi-household support, if offered, needs clearly separated plans and permissions.

Recommendation: test H01 with existing households before building chat, complex roles or real-time task orchestration. Measure whether it prevents duplicate cooking/shopping and whether people use it repeatedly.

## Proposed free / paid boundary

This is product strategy, not an audit of implemented billing or entitlements. Existing screens show features, not their current access rules. Preserve current users' access until a migration decision is explicit. Do not lock people out of their data when a subscription ends.

| Free foundation | Plus value to validate |
|---|---|
| Manual inventory and corrections | Larger AI scan allowance; advanced receipt/shelf convenience |
| Essential date reminders and honest date/estimate labels | Personalised weekly meal planning |
| Allergy exclusions and basic dietary preferences | Meal calorie ranges and protein-oriented matching |
| Basic recipe ideas and saved access to existing data | Higher recipe-generation allowance; advanced recipe collection tools |
| Shared kitchen and basic shopping list | Advanced household schedules, prep tasks and coordinated meal plans |
| Basic “planning to use” activity if validated | Multi-household planning and expanded history/export tools |
| Account, privacy/security, accessibility and correction/Undo | Budget planning using actual price data where available |

Basic collaboration helps the shared kitchen stay accurate; I recommend testing it free. Charge for automation and planning convenience rather than for essential household conflict visibility. Receipt/shelf capture already appears in the app: a future allowance model must be communicated and measured, not silently retrofitted as a locked button.

Keep one understandable Plus offer initially. Determine scan limits, AI costs, retention and willingness to pay before promising unlimited use or fixing prices. Let users preview the benefit at a relevant moment, retain free alternatives and offer clear restore/manage access when real billing exists. A cancelled plan must never disable allergy exclusions, date clarity or access to previously entered food.

## Additional feature opportunities — later, in order

1. Cook once, eat twice: plan portions, record leftovers and use them in another meal. Strong fit with waste reduction and Plus planning.
2. One-tap meal logging after cooking: confirm actual servings before logging nutrition and inventory usage. Full daily calorie tracking also requires snacks, drinks and meals outside the app; it is a separate project.
3. Budget-aware planning: use verified receipts or user-entered prices; label estimates and avoid invented supermarket comparisons.
4. Recipe import/collection: preserve source attribution and handle recipe rights, parsing failures and serving calculations.
5. Retailer basket transfer: only after authorised retailer access and supported product matching. Shared lists do not require supermarket integration.

Do not add gamified calorie restriction, safety scores from photos, fabricated savings, mandatory social sharing or a notification stream that creates more effort than it saves.

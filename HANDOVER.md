# Use It Fresh — handover

**Written 9 Sep 2026. Read this before touching anything.**

Project `fridge-wise-gvpy0s` · branch `main` · git HEAD `4c18ba6` ·
FlutterFlow at commit `OnSTcWUJlQAw7SSrCFSw`

---

## 1. THE BUILD IS BROKEN. Fix this first.

`flutter build web` fails with:

```
Error: Too few positional arguments: 6 required, 5 given.
```

**Cause.** The custom action `CreateFoodItem` had an `imageUrl` parameter added
to its **Dart body** (now six parameters) but not to its **declared argument
list** (still five). FlutterFlow generates call sites from the declaration, so
it emits a five-argument call against a six-argument function.

**Where:** `generated_code/lib/add_food_review_page/add_food_review_page_widget.dart`,
the `actions.createFoodItem(...)` call inside the `ReviewConfirm` button.

**The fix, in two steps.**

Step 1 — append the argument to the declaration, *keeping the existing five
keys exactly as they are*. Their keys are referenced by every existing call
site's argument values; replacing them orphans those values, which is the trap
I fell into. The live keys are:

| name | key | type |
|---|---|---|
| `name` | `dbf2hnn6` | String |
| `category` | `r4ku934l` | String |
| `locationId` | `rkfhygcw` | String |
| `printedDate` | `2mwin5p4` | DateTime |
| `printedDateType` | `wgdq4egt` | String |

So: read `findCustomAction(project, name: 'CreateFoodItem').arguments`, keep
those five untouched, append a sixth `imageUrl` (String, any fresh key), and
pass the whole list to `updateCustomAction(project, name: 'CreateFoodItem',
arguments: [...])`.

Step 2 — rewire the review screen's confirm button to pass it. Button key
`Button_sm2avojh` on `AddFoodReviewPage`; the page already has an `imageUrl`
param. Use `CallCustomAction.named('CreateFoodItem', args: {...six...},
arguments: {...'imageUrl': Param('imageUrl')}, outputAs: 'saveOutcome')`,
followed by the existing `If(Equals(ActionOutput('saveOutcome'), ''), ...)`.

Then `flutter build web` in `generated_code/` and confirm green before anything
else.

**If you would rather back out than finish:** revert `CreateFoodItem`'s body to
five parameters (drop `imageUrl` and the `image_url` insert line and set
`source_type` back to `'manual'`). The photo capture UI on the add form will
then still work and store nothing, which is a coherent state.

---

## 2. How to work on this project

**Everything goes through the DSL.** Edit `dsl/edit.dart`, then:

```
flutterflow ai run dsl/edit.dart --project-id "fridge-wise-gvpy0s" --commit-message "..."
```

`generated_code/` is a **read-only** snapshot. Never edit it; it is regenerated
on every push. Read it to find out what is actually rendering — the DSL is
intent, the generated Dart is truth.

**The working pattern that made this tractable:**

1. Write the flow body into a scratch file, `cat` it onto the first 155 lines of
   `dsl/edit.dart` (stable CLI boilerplate), `dart analyze` it, then push.
2. Build and **look at it**: `flutter build web --release`, copy
   `build/web` to a served directory, drive it in headless Chrome and read the
   screenshots. There is a harness for this — see §6. Do not trust a green push
   to mean the screen is right; it very often is not.

**Verifying against the real app matters more than anything else here.** Most
of the serious bugs found in this session were invisible in the DSL and in the
generated code, and obvious in a screenshot.

---

## 3. What works, verified in the running app

- **Entrance and auth.** Fridge animation, email sign-in, sign-up, reset. Google
  and Apple are stand-in buttons only — not wired.
- **Home** (v3). "Hi, Ash" / "Fresh today.", a *Use these next* photograph card
  with a real count, use-first items as two-column photograph cards, a compact
  household prompt when there is no household.
- **Inventory** (v3). "Your kitchen." with a real count, All / Fridge / Freezer
  / Pantry chips using the supplied icons, search, photograph cards. Three
  distinct states: loading, empty kitchen, no-matches-with-Clear-filters.
- **Item details.** Tap any card. Dates said as what they are, where the date
  came from, how the status was reached, plus **I used it** / **Throw it out**,
  which write to `food_item_events`.
- **Add food.** Chooser → form → **review** → save. Verified end to end.
- **Household.** Create, invite code, join. Shows the household you are in.
- **Profile** (v3). Name and role, one row per destination, sign out.
- **Storage locations.** Lists and adds, scoped to the household.
- **Navigation.** Component nav bar with the supplied icons, label on every tab,
  filled Scan square, bottom safe area.
- **Widths.** Checked at 390px and 360px, and at 364×564.

**The urgency engine is real and good.** Statuses are computed in the database
from printed dates and storage type, recomputed against today. Do not
second-guess it in the UI; read `computed_status`, `status_label`,
`status_detail`, `status_basis` from the `food_items_status` view.

---

## 4. Outstanding, in the order I would take it

1. **Fix the build** (§1).
2. **Photo capture is built but unverified.** `CaptureFoodPhoto` uploads to
   `food-images/<household_id>/<uuid>.jpg` and returns a **one-year signed
   URL**. The bucket is private on purpose. The year is a compromise that needs
   revisiting — storing the path and signing on read is the stricter answer.
   Nobody has yet taken a photo through this flow.
3. **Barcode → product lookup.** Open Food Facts is free and needs no key.
   `BarcodeScanner` exists in the DSL but is **native-only**, so scanning needs
   a device build; the lookup itself can be built and tested with typed-in
   barcodes.
4. **Expiry reminders.** `notification_preferences` exists in the schema and
   nothing uses it. Needs push, so needs a device build.
5. **AI recognition.** Gemini has a first-class FlutterFlow integration. Needs
   an API key from the owner. Phase 3 in the spec.
6. **Shopping list.** Table exists, no UI. Cheap, self-contained.
7. **Recipes.** Still the old empty state, **deliberately** — the guide forbids
   claiming a recipe's ingredients or nutrition from an illustrative photo, so
   it waits on real recipe data.
8. **Two validator warnings.** The review screen's back button is under the
   recommended tap size; the project's loading indicator is too small.
9. **Large-text accessibility is unverified.** Flutter's text scaling comes from
   the platform, not CSS, so it cannot be emulated against a CanvasKit build in
   headless Chrome. Needs a real device.

---

## 5. Traps in this DSL that cost real time

Every one of these produced a **successful push and a wrong app**.

- **`ensureRemoved` in a batch is unsafe.** Removals shift sibling indices as
  they apply, so later operations in the same batch hit the wrong nodes. One
  batch destroyed a whole section; another overwrote a card's contents. Do
  **one structural operation per push**, or rebuild the child list
  deterministically in `app.raw`.
- **Newly inserted widgets are not selectable until the next push.** Bindings on
  new nodes must either be written inline at construction or deferred a push.
- **`byKey` takes the key, not the `name`.** Easy to mix up; the error is
  "expected exactly one widget, found 0".
- **`patch.maxLines(n)` sets max *characters*.** It rendered a greeting as "Go".
  Real line limits live in `maxLinesValue` on the node.
- **`patch.color` / `.borderRadius` / `.visible` silently do nothing on a
  Container.** They work on Buttons, which makes it look like they worked. Use
  `mutateNode`.
- **A Button's own padding is `FFButton.innerPadding`**, which no patch reaches.
- **Full width is `pixels: Infinity`**, not percent-of-parent. Setting a height
  also clears the width.
- **`ensureActions` skips chains it considers equal** and does not appear to
  weigh a query's filters, so a chain differing only by a filter is left alone.
  Rename the output variable to force it.
- **No conditional-value expression exists.** A container cannot pick its own
  colours from a condition — use a rest/selected variant pair, or a custom
  widget.
- **`Icon` takes a literal name**, so a data-driven icon needs a custom widget.
  See `AppIcon` and `KitchenIcon`.
- **`name` is reserved on a custom widget's parameters.**
- **An action-typed component parameter** is stored correctly but the generated
  typed handle represents it as `json`, so a list of actions will not normalise
  at the call site. Make the component presentational and put the tap on a
  wrapper.
- **A `ListView` with no shrink-wrap inside a Column** fails layout and takes
  everything after it in the column with it. This broke two whole screens. A
  sweep found only those two, but check any new one.
- **`FFPadding` SYMMETRIC reads back as zero** — use `FF_PADDING_ONLY` with
  explicit edges.
- **Sub-messages need `ensureX()`**, not the bare getter, or you get
  "Attempted to change a read-only message".
- **Validation is your friend.** The nav-bar component contract
  (`selectedIndex`, `onItemTapped` taking one int, both non-nullable,
  `selectedIndex` actually referenced) was discovered entirely from validation
  refusals, and nothing broken reached the app.

---

## 6. The verification harness

`<scratchpad>/walk.py` drives the built app in headless Chrome: signs in, taps
through, saves screenshots to `walkframes/`, and prints console errors, uncaught
exceptions and failed requests. Parameterised by `VP_W`, `VP_H`, `VP_TEXT`,
`VP_TAG` environment variables for the width checks.

Two things it taught, worth keeping:

- **Pin the viewport** with `Emulation.setDeviceMetricsOverride`, or screenshot
  pixels and click coordinates are different spaces and every measured tap
  lands somewhere else.
- **Type with `char` key events only.** A `keyDown` that also carries text
  inserts it a second time; `Input.insertText` never reaches Flutter's hidden
  IME input at all.

Serve from a **copy** of `build/web`, not the directory itself — serving it
directly holds a file lock that makes `flutterflow ai run` fail with
"Rename failed".

---

## 7. Data and access

- Supabase project `ltdvxdizjrkgwldbmbbf`. URL and anon key are in
  `generated_code/lib/backend/supabase/supabase.dart` and are safe to read.
- **Secrets never come to the agent.** The service-role key, database password,
  Google client secret, Apple `.p8` and the App Store Connect `.p8` all go into
  Supabase or FlutterFlow directly. `.gitignore` blocks `.p8`, `.env` and
  keystores.
- Test account `ashraf.elashiry@gmail.com` (`5bf86ec0-033f-468d-849e-ae5ca734a094`).
  Its profile is kept; all households, food, locations and shopping lists were
  deleted on 9 Sep at the owner's request, so it starts at "signed in, no
  household".
- **Six migrations exist; migration 6 was never run** and may not be needed —
  household creation started working before it was applied, so its diagnosis is
  unconfirmed. It also contains a diagnostic query worth running to learn why
  the original insert policy was rejecting. See
  `supabase/migrations/20260908110000_household_create_visibility.sql`.
- Storage buckets `food-images`, `receipts`, `avatars` exist and are empty.
  `food-images` and `receipts` are private; `avatars` is public.

## 8. Design sources, in order of authority

1. `design/Chat GPT/Use-It-Fresh-Visual-v3/` — **current.** Photographic
   direction: BUILD-GUIDE.md, tokens.json, the six food photographs, the logo.
2. `design/Chat GPT/Use-It-Fresh-Kitchen-Icons/` — the icon set, with
   FF-INSTRUCTIONS.md. Applied.
3. `design/Chat GPT/Use-It-Fresh-Screen-Guide-v2/` — superseded by v3, but its
   colour system and status palette still hold.

Assets the app loads are committed to `design/v3/` and served over jsDelivr
pinned to a commit SHA. **If you add or change one, you must re-pin the SHA** in
`foodImage`, `heroImage`, `itemPhoto` and `KitchenIcon`.

Two rules from the guides that are not negotiable and are easy to break:
**never invent inventory to fill the design**, and **never derive a food's
status or safety from a photograph**.

## 9. How the owner works

- Screenshots go to `C:\Users\ashel\OneDrive\Pictures\Screenshots`; they cannot
  paste images, so read the newest file yourself.
- Screen recordings go to `design/Screen Recordings/`. Read the DevTools console
  in the frames — that is where most of the signal is.
- Test results may arrive as a Word document in `test/` with **screenshots and
  no text**; extract `word/media/*` from the .docx and diagnose from the images.
- Keep them running on `localhost:8080` and re-copy the build after every push.
- Status board: <https://claude.ai/code/artifact/b5a7bfe7-b7ac-446e-a846-679f567c21ab>
- Screen kit: <https://claude.ai/code/artifact/68c33d07-6057-49f9-ae3d-e6686d2369d1>

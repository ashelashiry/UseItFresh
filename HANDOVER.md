# Use It Fresh — handover

**Written 9 Sep 2026, updated 10 Sep. Read this before touching anything.**

Project `fridge-wise-gvpy0s` · branch `main` ·
FlutterFlow at commit `OKF0DbqxAuEcCjn3ZREM`

---

## 1. The build was broken. It is fixed.

Fixed 10 Sep, FlutterFlow commit `OKF0DbqxAuEcCjn3ZREM`.
`flutter build web --release` is green.

**What it was.** The custom action `CreateFoodItem` had an `imageUrl`
parameter added to its **Dart body** (six parameters) but not to its
**declared argument list** (five). FlutterFlow generates call sites from the
declaration, so it emitted a five-argument call against a six-argument
function: `Too few positional arguments: 6 required, 5 given.`

**The part that made it look harder than it was.** Declaring the argument on
its own does not validate — the validator refuses a declared custom action
argument that any call site does not supply:

```
Button 'ReviewConfirm' [key: Button_sm2avojh] - Custom action argument "imageUrl" is not specified.
```

So the declaration and the call-site wiring **must land in the same push**.
The earlier repair read this as a key problem and replaced all six argument
keys with fresh ones, which produced the same message six times over and
looked like orphaned values. It was really the same single rule each time.

Two things worth keeping from the fix:

- The five live argument keys (`dbf2hnn6`, `r4ku934l`, `rkfhygcw`, `2mwin5p4`,
  `wgdq4egt`) were preserved untouched. Call-site values are filed under them.
- The sixth argument was made by `deepCopy()`ing an existing String argument
  and renaming it, so its data type matches the project's own by construction
  rather than by a hand-rebuilt `FFDataTypeV2`.
- `ensureActions` was given a renamed output variable (`savedOutcome`) to
  force it to replace the chain; an added argument alone is not a difference
  it acts on.

The DSL that did it is in git at the commit below; `dsl/edit.dart` is
overwritten every push, so read it from history, not the working copy.

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

1. **Photo capture is verified** (10 Sep) — camera, upload, signed URL,
   review, item, card and details hero. The **one-year signed URL** is still a
   compromise worth revisiting: storing the path and signing on read is the
   stricter answer.
2. **Barcode → product lookup.** Open Food Facts is free and needs no key.
   `BarcodeScanner` exists in the DSL but is **native-only**, so scanning needs
   a device build; the lookup itself can be built and tested with typed-in
   barcodes.
3. **Expiry reminders.** `notification_preferences` exists in the schema and
   nothing uses it. Needs push, so needs a device build.
4. **AI recognition.** Gemini has a first-class FlutterFlow integration. Needs
   an API key from the owner. Phase 3 in the spec.
5. **Shopping list.** Table exists, no UI. Cheap, self-contained.
6. **Recipes.** Still the old empty state, **deliberately** — the guide forbids
   claiming a recipe's ingredients or nutrition from an illustrative photo, so
   it waits on real recipe data.
7. **Two validator warnings.** The review screen's back button is under the
   recommended tap size; the project's loading indicator is too small.
8. **Large-text accessibility is unverified.** Flutter's text scaling comes from
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
- **A `Row` with `crossAxis: stretch` inside a SCROLLABLE Column** has no
  bounded height to stretch to. It fails layout and takes every sibling after
  it down with it, silently — the same family as the shrink-wrap bug. The tell
  is that the offending row also loses its own decoration. Anything after it
  simply is not drawn, however correct its data and its condition.
- **A `ListView` with no shrink-wrap inside a Column** fails layout and takes
  everything after it in the column with it. This broke two whole screens. A
  sweep found only those two, but check any new one.
- **`FFPadding` SYMMETRIC reads back as zero** — use `FF_PADDING_ONLY` with
  explicit edges.
- **Sub-messages need `ensureX()`**, not the bare getter, or you get
  "Attempted to change a read-only message".
- **A custom function's `code` is the BODY only.** FlutterFlow generates the
  signature from the declared arguments, so passing a whole declaration nests
  one function inside another. The outer one then falls off its end, returns
  null, and the screen dies on a null check before painting anything — a grey
  screen and "Null check operator used on a null value" in the console. Custom
  **actions** are the opposite: a complete function, imports and all.
- **`Page.setInterceptFileChooserDialog` + `DOM.setFileInputFiles`** is how you
  exercise the camera in the harness. `image_picker` on the web is a file
  input, so this drives the real path right up to the picker itself.
- **Actions written after an `If` are nested INTO it, not run after it.** A
  conditional is terminal. `[If(a){x}, y, If(b){z}]` compiles with `y` and the
  second conditional living inside `if (a)`. Anything that must happen on every
  path has to be repeated in every branch. This silently made "I used it" work
  only when an earlier step had failed.
- **An insert and a key-addressed `ensureActions` cannot share a push.** The
  insert shifts sibling indices as it applies, so the action chain lands on the
  newly inserted widget instead of the one you named. Same hazard as batched
  removals, from the other direction.
- **A custom function's `code` is the BODY only.** FlutterFlow generates the
  signature from the declared arguments, so passing a whole declaration nests
  one function inside another. The outer one falls off its end, returns null,
  and the screen dies on a null check before painting anything — a grey screen
  and "Null check operator used on a null value" in the console. Custom
  **actions** are the opposite: a complete function, imports and all.
- **Every new text field arrives with a 2000ms debounce.** Tapping a button
  straight after typing reads the PREVIOUS value. Clear
  `props.textField.debounceTimeValue.inputValue` on every field you add.
- **A text field renders from its own controller, not the state behind it.**
  Setting the state variable leaves the box looking empty; `SetFormField` puts
  the value where it can be seen.
- **Output variable names must be unique across widgets**, and every Postgres
  write action produces one, defaulting to `rows`. Three widgets writing to one
  table is three collisions. Give shared action chains a per-call-site tag.
- **There is no `And` combinator.** Two conditions in one visibility test have
  to become a custom function.
- **An item field access (`item['id']`) is only legal inside a ListView's own
  builder.** A widget inserted into an existing item template cannot see which
  row it is on — the whole list has to be rebuilt.
- **Row security that checks a client-supplied column fails silently.**
  `shopping_list_items` requires `created_by = auth.uid()`; without it every
  insert was refused while the screen looked like it had worked.
- **`Page.setInterceptFileChooserDialog` + `DOM.setFileInputFiles`** is how you
  exercise the camera in the harness. `image_picker` on the web is a file
  input, so this drives the real path right up to the picker itself.
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
- **Migration 6 is not needed** (confirmed 10 Sep). A household insert as the
  signed-in user succeeds against the existing policy, and the SECURITY
  DEFINER trigger seeds the member, three locations and the shopping list. It also contains a diagnostic query worth running to learn why
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

## 10. Reminders are local, not push

Decided 11 Sep. Reminders are scheduled **on the device** with
`flutter_local_notifications`, not sent from a server.

**Why.** FlutterFlow's push is Firebase-based and this project has no Firebase
— adding one for a single feature would mean a second backend to configure,
pay for and reason about alongside Supabase. The phone already holds every
expiry date once the inventory loads, so it can schedule reminders itself.
It is also the more private answer: nothing about what is in someone's fridge
leaves their phone to make reminders work, and it keeps working offline.

**The cost, stated plainly.** The schedule only refreshes while the app is
open. Someone who does not open it for a month gets the schedule as it stood a
month ago. A server-push design would not have that limit. If this becomes the
thing people complain about, that is the reason to revisit — not before.

**How it behaves.** `ScheduleExpiryReminders` cancels everything and rebuilds
from the current inventory rather than diffing, because a diff is the only
place a stale reminder could survive, and a reminder about food eaten last
week is the fastest way to get an app's notifications switched off for good.
Settled items are skipped. Items with neither a printed date nor a category
estimate get no reminder at all — there is nothing to be right about. iOS caps
pending local notifications at 64 and silently drops the rest, so the scheduler
stops deliberately at 60, nearest dates first.

**The wording matters.** A printed date and an app estimate must not read the
same on a lock screen. A printed one says "its date is in two days"; an
estimate says "around two days left, going by a typical shelf life. Worth
checking." Never "this is off" — the status is a guess from a shelf life, not
an inspection.


# Use It Fresh — handover

**Written 9 Sep 2026, updated 11 Sep. Read this before touching anything.**

Project `fridge-wise-gvpy0s` · branch `main` ·
FlutterFlow at commit `VmwmBylmyafXzs4DOCwJ` (11 Sep)

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

Done since the first version of this list (10–11 Sep): photo capture, barcode
lookup and the camera scanner, the shopping list, waste history, replace-what-
you-finish, expiry reminders (local notifications, see section 10), photo
naming, and receipt / fridge-shelf reading with a review screen.

**The photo map (11 Sep, after Build 5's offline work).** The owner's brief:
taking a photo of the fridge or pantry *is* the app; typing things in takes
too long and nobody will do it. A shelf photo comes back with each food
outlined and numbered on the photo itself; the person ticks, crosses or fixes
each one (name, category, and where it is kept), then adds the ticked ones.
Agreed from a clickable mockup before it was built.
- `recognise-food`, mode `shelf`, returns `kind` (carton, jar, loose…) and
  `box` ("ymin,xmin,ymax,xmax" on 0-1000, Gemini's own box_2d scale) per food;
  a box that is not four ordered numbers is dropped, never drawn wrong.
  **Needs the owner's paste** into the Supabase editor; until then foods
  arrive with no outline and the list still works.
- `ShelfReview` is one custom widget: place chips, each photo with its
  outlines, the count, "Yes to the rest", and the rows with in-place editing.
  It reads `mapFoods` / `mapPhotos` / `mapPlace` from app state because
  FlutterFlow cannot pass a list to a custom widget, and imports `provider`
  itself so it redraws on every change.
- `ReadShelfPhoto` keeps the photo (a one-hour signed URL) because the map is
  drawn on it, and deletes it if nothing was found. `SaveMapFoods` adds every
  ticked food in one insert, each in its own place or the photo's, as
  `fridge_scan`, then deletes the photos. `ClearShelfScan` runs when a map
  starts and on Back, so photos do not pile up.
- Receipts keep their list review: a receipt has nothing to outline.
- Verified by a green web build and the generated Dart, not walked (the
  harness no longer signs in). Gaps: a map abandoned without Back keeps its
  photos until the next one starts; a photo left open over an hour stops
  loading (its list still works).
- **The camera is the way in** (same day, after Build 5). The tabs are
  FlutterFlow's generated `NavBarPage`; the nav bar only reports which tab
  was tapped. The Scan tab's page-load clears any unfinished map and opens
  `MapReviewPage`, whose page-load opens the camera when the map is empty.
  Closing the camera pops back to the Scan tab, still mounted underneath so
  its page-load does not re-run: that is the chooser for receipts, barcodes
  and typing. Home's "Add food" had still shown the Phase 2 placeholder in
  every build up to 5; it and the Fridge photo tile now open the review
  screen too. After saving, the kitchen replaces the review screen
  (`replaceRoute`), so Back does not land on an empty map.
- **"What can I make?"** (Recipes tab, 11 Sep). `recognise-food` mode
  `ideas` reads `food_items_status` with the caller's own session, so RLS
  decides what is visible; leaves out past use-by, past best-before, used and
  thrown-out food; sends Gemini only names and a "use first" mark; and moves
  any "from your kitchen" name that is not really in the kitchen to "also
  need". `GetMealIdeas` keeps the ideas in app state (`mealIdeas`,
  `ideasLoading`) so a tab switch does not ask, and pay, again.
  `MealIdeaCards` draws them, with "Add these to your shopping list" reusing
  `AddNameToShoppingList`. Runs only on the "Get ideas" tap. Pasted and
  live on 11 Sep (an unauthenticated probe answers "Sign in first.").
- **Use-by dates on the photo map** (same day). `MapFood.useBy`
  (yyyy-mm-dd, added with `ensureDataStructField` inside `app.raw`, since the
  struct exists); ShelfReview and SaveMapFoods replaced whole with
  `updateCustomWidget` / `updateCustomAction`. Tap a food's name, then "Add
  use-by date". Saved as `printed_date` + `printed_date_type = 'use_by'`,
  which the status engine and reminders already read.
- **Loading rings that turn.** `ProgressBar.circular` generates a
  `CircularPercentIndicator` at 0% with no animation: a grey ring that never
  moves. All four (kitchen loading, Scan reading, photo map reading, ideas)
  are now `BusySpinner`, a small custom widget.
- Traps met on the way: `ensureReplaced` drops the replaced node's own
  padding; `page.update(... patch.padding ...)` on a Container did not reach
  the generated code, and the fast lane has no padding op, so the Recipes
  container was rebuilt with `Container(padding:)`, which works.
- **The next round: A, B and C** (11 Sep, one build, then the owner's big
  test from `docs/useitfresh_test_round.html`, published with a `db` record
  of their marks; read it back with the Artifact tool's `read_db`, collection
  `results`, plus `run/current` for the build number and phone).
  - **B. Shape the ideas.** `IdeaChoices` (custom widget above "Get ideas"):
    meal, time, "For" 1-8 people, "Leave out". Persisted app state
    `ideasMeal` / `ideasMinutes` / `ideasServings` / `ideasLeaveOut`.
    `GetMealIdeas` sends them; `recognise-food` asks for them and then checks
    the answer: an idea mentioning a left-out food anywhere (title, uses,
    extras, steps) or over the time is dropped, and kitchen foods on the
    leave-out list are never sent. Matching is by containment on a plural
    stem, so it errs towards leaving more out. No diet switch on purpose: the
    app must not claim a dish suits a diet. Pasted 12 Sep (the first paste
    was cut short at line 502; the full file went via the clipboard).
  - **C. Keep an idea.** "Keep this idea" on each card; `keptIdeas`
    (persisted, this phone only, 30 at most) shown under the new ideas with
    "Remove". A kept card says "Uses", not "From your kitchen": the food
    may have gone since.
  - **A. Two people, one kitchen.** The Join button showed "Invite joining
    unlocks in the next update". Now `JoinHousehold(code)` calls
    `join_household_by_code` (security definer, in the first migration) and
    sets `currentHouseholdId`; `firstHouseholdId` keeps a current id that is
    still in the list, so every screen stays on the joined kitchen.
    `HouseholdMembers` on the household card: "Just you so far." or
    "2 members: Ash and you". Known edge: someone who creates a household
    and then joins another has two; inserts that omit `household_id` fall
    back to the server default (oldest membership). The app's own inserts
    pass it, but the second person is told to join without creating one.
- **The round after (12 Sep), same build.**
  - **Kept ideas are shared.** Moved from phone-only app state to
    `saved_recipes` (first migration: household, who kept it, title,
    `recipe_data` JSON, member-only RLS), so the household sees them and they
    survive a reinstall. No database change was needed. `keptIdeas` app state
    is now unused; it never reached a build.
  - **Choosing a household.** `HouseholdSwitcher` under the household card,
    for someone in two or more: tap one to show it (clears meal ideas, which
    were for the other kitchen). `CreateHousehold` now switches to the new
    household, reading it back with a second query because the insert's own
    read-back can run before the membership trigger. Profile's line uses
    `householdLineFor` (with the current household); `householdLine` named
    the oldest.
  - **Locations go to the right household.** "Add location" sent no
    household, so the server default (oldest membership) took it, and
    reloaded unfiltered. `AddStorageLocation` sends it; the button then
    reopens the screen, whose load already filters.
  - **The photo function says its version.** `VERSION` in `index.ts` goes into
    every reply and an `x-function-version` header, the signed-out 401
    included. Check a paste with
    `curl -s -X POST https://ltdvxdizjrkgwldbmbbf.supabase.co/functions/v1/recognise-food`.
    **Raise it with every change** (date, then a count for the day). The
    owner asked for this after a paste that stopped at line 502 could not be
    told apart from the working one.
  - **The dashboard editor caps a paste at about 20,000 characters.** Measured:
    two pastes of the same file stopped at 20,214 and 20,287 characters (the
    owner: "it worked before I went beyond 500" lines). So `recognise-food` is
    now five files, each about 5-6 KB: `index.ts` (the handler and the photo
    modes), `shared.ts` (VERSION, reply, CORS, the word helpers, readChoices),
    `prompts.ts` (what Gemini is asked, and the answer schemas), `gemini.ts`
    (model discovery and the call), `ideas.ts`. Paste each into its own file in
    the editor. Splitting also means most later changes touch one small file.
    The alternative, if pasting ever becomes the bottleneck again, is the
    Supabase CLI: `supabase login` then
    `supabase functions deploy recognise-food --project-ref ltdvxdizjrkgwldbmbbf`,
    which the owner runs (it needs their access token; secrets never come here).

1. **Photo naming works** (11 Sep). The 502 was the Gemini project's prepaid
   credit running out, not the code. The function also no longer pins a
   model: it tries `gemini-flash-latest`, then the newest stable Flash the
   key can call (`GET /v1beta/models`). A failure returns `detail`
   ("gemini 429 <model>: <Google's message>") for diagnosis. **One paste
   pending, and the photo map needs it:** the current `supabase/functions/recognise-food/
   index.ts` (the photo map's outlines, plural shelf names, and "not available right now" instead of
   "too many photos" when credit runs out) is not yet deployed from the
   Supabase editor. `verify_receipt.py` tests it after a paste.
2. **Receipt and fridge-shelf reading** — built 11 Sep and walked in the app
   end to end, receipt and shelf both (`rcwalk.py`, `PHOTO=shelf`). One photo → `ReadPhotoFoods`
   (`mode: receipt | shelf`) → `ScanReviewPage` → `SaveScannedFoods`, one
   insert for the lot. The photo is deleted from storage straight after it is
   read. Each food's location comes from its category (`homes` map in the
   action) using the household's own locations. Tapping a line opens
   `ScanLinePage`, which gets the line's position and fields as page
   parameters, prefills the name (`SetFormField` by widget name, in its own
   on-load) and writes the line back with `updateItemAtIndex`, only the name
   changed. A screen of its own, not an editable row: rows are built by
   position, and a text field in a row can stay tied to the wrong line after
   a removal above it. The row's position in an edit flow is
   `const ItemRef().index` (see `lib/src/dsl/references.dart` in the SDK).
3. **Open Food Facts photos are kept in our own storage** since 11 Sep:
   `CreateFoodItem` copies the photo into the household folder on add
   (400px where it exists) and keeps their link if the copy fails.
4. **Home needs no redesign** (checked 11 Sep with six foods in a kitchen).
   "Use these next" already exists; it shows only when `urgentCount` finds
   something close to its date, so an undated kitchen shows just the grid.
   Fixed the same day: the bottom button said "Add your first item" with food
   in the kitchen (now "Add food"), and counts read "2 item" (`quantityLabel`
   now pluralises countable units — loaf/loaves, box/boxes — and never
   weights or volumes; tested locally against ten cases).
5. **Offline, the main screens say something false** (walked 11 Sep with
   `offwalk.py`: a kitchen with three foods, then the network cut). The
   kitchen says "Nothing in here yet… Your fresh start", Home offers "Set up
   your kitchen — create a household" (an invitation to make a duplicate),
   Profile says "No household yet", and the greeting falls back to the email
   name. Back online, the kitchen recovers without a restart. Cause: every
   page's on-load runs `queryRows` with nothing catching a failure, so the
   first failed query aborts the chain and the page keeps its initial empty
   state — which is exactly what the empty states and the household prompt
   are keyed on. "Couldn't load" and "loaded, empty" are indistinguishable.
   **Fix:** empty states and the household prompt only after a load that
   worked (a `loaded` flag set at the END of each on-load chain — the shopping
   list already does this), and a plain "Can't reach your kitchen — check your
   signal" line when it did not. Held until the owner's test build is deployed,
   because it changes how Home and the kitchen load and a push goes live at
   once. Size M, not S: `editPageOnLoad` replaces a whole chain, so each page's
   chain must be reproduced exactly. **`PostgresQuery` has no failure branch**
   (only `ApiCall` takes `onFailure`, see `lib/src/dsl/actions.dart` in the
   SDK), so a failed query can only be detected by what did not happen after
   it: the `loaded` flag at the end of the chain staying false.
   **Shipped 11 Sep** (once Build 3 was deployed) **and walked offline:** the
   kitchen and Home show "Can't reach your kitchen" with Try again, the
   kitchen subtitle says so, Profile's household line is blank, there are no
   uncaught errors, and Try again brings the food back once online. The
   receipt walk still passes online. The subtitle and Profile line then had
   to be replaced rather than rebound (see the `bindText` trap in section 5).
   **Build 5 (11 Sep)** extends it: the item screen (its actions wait for a
   load that worked; card above the name), Add food (card: the form can be
   filled in but not saved; its retry also applies a barcode find that
   arrived offline), and Home's greeting (`hiLineLoaded` says "Hi" until
   the profile loads; `greetingLine` was already taken by the original
   time-of-day greeting, which nothing calls). Verified in the generated
   Dart and by a green web build, not walked: the harness no longer signs
   in (section 6). The owner tests it with Airplane mode. Build 4 is kept
   as a fallback: FlutterFlow branch `build-4-ios`, git tag `build-4-ios`,
   and a full copy in the owner's OneDrive. Sources kept for reference:
   - `dsl/_archive_offline_a.dart.txt` — `CanReachKitchen` (a custom action
     that catches its own failure), four loaded-aware functions
     (`kitchenState`, `kitchenLine`, `householdLine`, `offerHouseholdSetup`;
     the old ones are untouched so no call site can break), `loadedOk` /
     `offline` on Inventory, Home and Profile, their page-loads reproduced
     exactly inside the "reachable" branch, and the rebinds. `flutterflow ai
     validate` dry run passed; the four functions pass 18 local cases.
   - `dsl/_archive_offline_b.dart.txt` — the "Can't reach your kitchen" cards
     with Try again (reruns the screen's own load in place). Validate only
     after A is live: it uses A's flags and functions.
   - `dsl/_archive_offline_walk.py.txt` — `offwalk.py`, the walk that found it.
   How it shipped: A → build → offline walk (the kitchen subtitle should say it
   cannot reach the kitchen, with no empty panel and no household prompt) →
   B → build → offline walk again (cards, and Try again once back online) →
   the receipt walk, to check nothing changed online.
6. **Recipes.** Still the old empty state, **deliberately** — the guide forbids
   claiming a recipe's ingredients or nutrition from an illustrative photo, so
   it waits on real recipe data.
7. **Large-text accessibility is unverified.** Flutter's text scaling comes from
   the platform, not CSS, so it cannot be emulated against a CanvasKit build in
   headless Chrome. Needs a real device.
8. The **one-year signed URL** on photos is still a compromise: storing the path
   and signing on read is the stricter answer.

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
- **Supabase "Verify JWT with legacy secret" is backwards for this project.**
  User sessions are signed with the new ES256 keys; the legacy check rejects
  them and ACCEPTS the anon key, which ships in the app. Left on, an edge
  function blocks every real user and admits anyone who unpacks the app. Deploy
  edge functions with it OFF and check the caller in code with
  `auth.getUser()` — see `supabase/functions/recognise-food/index.ts`.
- **FlutterFlow declares Supabase edge functions but does not deploy them.**
  After a push the function answers 404. Deploy from the Supabase dashboard
  (Edge Functions -> Deploy a new function -> Via Editor), with the source in
  `supabase/functions/`, and keep FlutterFlow's declaration identical.
- **Validation is your friend.** The nav-bar component contract
  (`selectedIndex`, `onItemTapped` taking one int, both non-nullable,
  `selectedIndex` actually referenced) was discovered entirely from validation
  refusals, and nothing broken reached the app.

---

### An empty image address crashes the image widget, silently

FlutterFlow's network `Image` is `CachedNetworkImage`, and it cannot draw an
empty URL. There is no error widget, so the card shows a blank white block.
(An uncaught error seen at the same moment turned out to be the notifications
plugin, below — not this.) `foodImage`, `itemPhoto`
and `heroImage` all returned `''` for meat, fish, bread, frozen and anything
unrecognised; receipts made it common, because nothing read from a receipt has
a photo of its own. Since 11 Sep they return `design/v3/food/placeholder.webp`
(a plain plate, fork and knife) instead — **never return an empty string from
a function that feeds an image.** The same pass removed two borrowed pictures:
fruit used the tomatoes photo, and the "Use these next" card fell back to
spinach for everything.

The food pictures are served from this repo through jsDelivr at a **pinned
commit hash**. A new picture needs its own commit pushed first, and the
functions then point at that hash.

### The notifications plugin throws in a browser

`flutter_local_notifications` has no web implementation. Any call to it, even
`initialize()`, reads a platform instance that was never set and throws an
uncaught `LateInitializationError` with no message. The Inventory page
reschedules reminders on every load, so every visit to the kitchen at
localhost:8080 logged one. Since 11 Sep `ScheduleExpiryReminders` and
`AskNotificationPermission` return straight away when `kIsWeb`. **Guard a
phone-only plugin before its first call, not after.**

The minified stack was enough to find it: the failing function was an
`async` whose first line read a `late` static (`$.x.bU()`, the "not
initialized" getter) and whose next called `"cancelAll"` on a method channel.

### An inserted widget cannot read the list row it lands in

`ItemRef()['id']` compiles only inside a ListView builder the script itself
declares. Inserting a widget into an existing list template and referencing the
row fails with `Bad state: Item field access "id" used outside a ListView
builder`, and attaching the action afterwards by key fails validation instead
(`Custom action argument "itemId" is not set properly`). Either build the list
in the same script, or design the action to need no row: one button for the
whole list, as the shopping basket does.

### `bindText` does not replace a text that is already bound

Pointing an existing Text at a new function with `page.bindText(...)` pushed
cleanly, and the generated code went on calling the OLD function (11 Sep: the
kitchen subtitle kept `kitchenCount`, Profile's line kept `householdRole`, so
both still said "empty" offline). `bindVisible` on the same pages worked. A
node inspect only confirms the widget, not where the old binding lives, so the
mechanism is unconfirmed. **Replace the widget instead** (`ensureReplaced` with
a fresh `Text(CustomFunction(...))`), and check the generated Dart for the new
function name before believing a text binding changed. The DSL `Text` has no
`fontSize`; a size override goes back on with a fast-lane patch afterwards.

---

## 6. The verification harness

- **The harness no longer signs in with a password** (decided 11 Sep). The
  agent must not enter passwords to authenticate, even test ones the owner
  supplied, so `rcwalk.py`, `offwalk.py`, `verify_receipt.py` and
  `verify_ai.py` (all of which sign in) are the owner's to run, or are not
  run. Changes are checked by `validate`/`run`, by reading the generated
  Dart for the new code, by local tests of function logic, and by the owner
  testing on the phone. Walk results recorded before 11 Sep evening stand.
- **Search generated files by their full path.** In the agent's Grep tool a
  brace glob with folders (`{inventory_page,profile_page}/*_widget.dart`)
  silently matches nothing and answers "No matches found" — twice on 11 Sep
  that read as "the code is not there" when it was.
- **Walks that write data use their own household.** `rcwalk.py` creates a
  temporary household through the API (found by diffing ids), then points the
  headless browser at it with
  `localStorage['flutter.ff_currentHouseholdId'] = JSON.stringify(id)` and a
  navigation back to `/`. The owner's kitchen and phone are never involved,
  and the walk deletes only that household (by id and temp name) at the end.
- Navigate to `/` rather than reloading: a reload asks the server for the
  current route (e.g. `/home`), which only `serve.py` answers.

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
  **It is also the owner's real account, on their phone.** **This repository
  is public**, and the account's password was committed in a walk script in
  `799f1f0` (11 Sep) and removed in `3fb5655`; it remains in history until
  the owner changes the password. Never put a login in a tracked file. Since 11 Sep its one
  household is "Ash's kitchen" (`3769cab3…`).
- **A test script deleted the owner's real household on 11 Sep** — its food,
  shopping list and locations went with the cascade. `verify_ai.py` created a
  temporary household and then deleted "the first household in the list",
  which was theirs. Rules since:
  - **A test deletes only rows it created**, identified by diffing ids before
    and after, and stops if it cannot tell which ones are its own.
  - `cleanup.py` and `seed_waste.py` are renamed `.DISABLED`; both delete in
    bulk.
  - **No write-test against this account without telling the owner first.**
  - Before real users: a separate test project, and point-in-time recovery on
    (Pro already takes daily backups; a restore rolls back the whole database).
- The **`receipts` bucket is unused.** Receipt photos go to `food-images` under
  the household folder, because the function accepts signed `food-images`
  links only, and they are deleted as soon as they have been read.
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
  Serve it with the scratchpad's `serve.py`, not `python -m http.server`: the
  plain server answers 404 for `/home` and every other app route, so a browser
  refresh on any screen but the first broke. `serve.py` hands `index.html` to
  any path without a file extension.
- Status board: <https://claude.ai/code/artifact/b5a7bfe7-b7ac-446e-a846-679f567c21ab>
- Screen kit: <https://claude.ai/code/artifact/68c33d07-6057-49f9-ae3d-e6686d2369d1>

**Three more, built while build 6 was being tested (12 Sep).** They are on
FlutterFlow main, not in build 6, so the test round marks their steps "needs
build 7".
- **Leaving a household.** `LeaveHousehold` deletes your own membership row
  (the members delete policy is "an admin, or yourself") and clears
  `currentHouseholdId`, so every screen falls back to the oldest household
  still joined. The owner is refused: leaving would orphan everyone else, and
  handing ownership over is not built. `LeaveHouseholdButton` shows nothing at
  all to an owner, and takes a second tap to confirm.
- **Allergies and diets** (spec §8.9, §184). `profiles.allergens` and
  `dietary_preferences` were in the first migration and nothing ever set them.
  `FoodPreferences` (on the new `FoodPreferencesPage`, reached from Profile)
  saves them and writes the words to leave out into `ideasAvoid`, which
  `GetMealIdeas` joins with the typed "Leave out" box. A diet is stored as the
  ingredients it excludes, never as a claim that a dish suits it, and the
  screen says plainly that this is not a medical check. **No function change,
  so nothing to paste:** it rides the leave-out mechanism that was already
  there. The words are deliberately over-broad ("milk" catches "buttermilk").
- **The basket into the kitchen.** `AddBasketToKitchen` adds every ticked
  shopping line as food (default location, `manual`, no guessed category or
  date) in one insert, then deletes those lines. It started as a button per
  line, which the compiler refused — see the ItemRef trap in section 5 — and
  one button for the whole basket is the better shape anyway.

## 11. Releases: anchoring a build so it can be rolled back

Decided 12 Sep, after the owner pointed out that a build number on the phone
pointed at nothing recoverable. Builds 4 and 5 had hand-made tags; build 6 had
nothing.

`RELEASES.md` is the ledger, and `scripts/release.py <build> --note "..."`
writes a row the moment FlutterFlow finishes deploying. It records three
anchors, because one is never enough:

- **a git tag** `build-<n>-ios` on the commit the build came from, annotated
  with the FlutterFlow commit, the live photo-function version and the date;
- **a FlutterFlow branch** of the same name, from that FlutterFlow commit.
  This is the one that matters: a rollback redeploys from the branch. Branch
  ids so far: build-4-ios `VmwmBylmyafXzs4DOCwJ`, build-5-ios
  `DtQumQwwU4UY9uUudVRl`, build-6-ios `WeJKE7HXMmAfevQmf5NR`;
- **the photo function's own version**, probed from the live function, because
  the app and the function ship separately.

Two things the script deliberately refuses: a dirty tree (a tag would point at
something you cannot get back) and a build number that was already recorded.

Rolling back ships old code as a *new*, higher build number: App Store Connect
never accepts a number it has seen. Migrations are not rolled back; they are
additive and safe to re-run, so older builds keep working against a newer
database.

**The app now says which build it is.** Profile shows "Version 1.0.0 (6)" from
`package_info_plus`, read from the installed app rather than from
`pubspec.yaml`, which lags (it said 1.0.0+5 while build 6 was on the phone).
So a screenshot names its own build. Lands in build 7.

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


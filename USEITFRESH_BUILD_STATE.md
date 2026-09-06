# Use It Fresh — build state (resume notes for the AI agent)

_Last updated: 2026-09-06 (late) — see "Resume here" at the bottom._

_Previously: 2026-09-05 (evening) — Phase 1 shipped; schema synced;
reset-password flow completed; **signup FIXED and verified end-to-end**.
Phase 2 (Inventory MVP) is the active work._

> **Read this first on a cold start.** Live status board (bookmarked by the user):
> https://claude.ai/code/artifact/b5a7bfe7-b7ac-446e-a846-679f567c21ab
> To update it, pass that URL as `url` to the Artifact tool — do not publish a new one.

---

## Where the build actually is

**Phase 1 — Foundation: SHIPPED** (commit `vdRf5mGOqyG5iQFytBYP`).

Path B was taken: the FridgeWise prototype was torn down and Phase 1 was rebuilt
**inside the same project** (`fridge-wise-gvpy0s`) in one atomic push. Do NOT
re-run the Phase 1 create/edit flows — the pages exist. Future work = new edit
flows against the refreshed typed SDK.

Live: 11 pages, 1 component (`EmptyStateCard`), 5-tab bottom nav, design system
per spec §16 (Figtree/Nunito, fresh green, red reserved for safety).

**Phase 2 — Inventory MVP is next, and is now unblocked.**

---

## Blocking right now

1. **Supabase DB password never confirmed rotated** — it was pasted into an old
   chat transcript. Project Settings → Database → Reset database password. The
   build does not need it (URL + anon key only).
2. **Recovery deep link has no redirect target.** `UpdatePasswordPage` now
   exists at `/update-password`, but the DSL's `ResetPassword(email)` action
   takes no `redirectTo`, so Supabase uses the project's Site URL. Set
   **Supabase → Authentication → URL Configuration** so recovery links land on
   `/update-password`. Until then the page is reachable via Profile → "Change
   password" (which works — the user is already signed in there).

---

## Signup: RESOLVED 2026-09-05 (do not re-diagnose)

**Fixed.** Supabase → Authentication → **Sign In / Providers** → User Signups →
**"Confirm email" turned OFF**. Verified end-to-end in FlutterFlow Test Mode:
clean signup landed on Home, signed in, empty states rendering.

Two traps worth remembering if this ever regresses:

- That page has **two controls containing the word "email"**. The *Email
  provider* under Auth Providers must stay **Enabled**; the *Confirm email*
  toggle in the upper User Signups card must be **off**. They are different
  settings and it is easy to switch the wrong one — which happened once,
  briefly disabling all email auth on a PRODUCTION project.
- Accounts created while confirmation was ON stay permanently unconfirmed and
  keep failing after the fix. Delete stale test users in Authentication → Users
  before concluding the fix did not work.

**If email confirmation is ever turned back on** (likely before public launch),
story U9 must ship first — otherwise the exact silent failure below returns.

### Why it failed (retained for reference)

`generated_code/lib/auth/supabase_auth/email_auth.dart`:

```dart
final AuthResponse res = await SupaFlow.client.auth.signUp(email:, password:);
// ...
return res.user?.lastSignInAt == null ? null : res.user;
```

With Supabase **"Confirm email" ON**, `signUp` succeeds and `res.user` is
populated, but `lastSignInAt` is null → this returns **null** → no
`AuthException` is thrown → `SupabaseAuthManager` has nothing to catch and
shows no snackbar → the page's generated `if (user == null) return;` does
nothing. Total silence. That is exactly the reported symptom.

**The migration-1 trigger hypothesis was probably wrong.** A trigger throwing
`Database error saving new user` raises an `AuthException`, and
`SupabaseAuthManager._signInOrCreateAccount` already catches those and shows
`Error: <message>`. A visible error would have appeared. Silence points at the
null-return path, not at an exception.

Two ways forward:

- **Option A (cheap, recommended for MVP):** turn "Confirm email" OFF. Sign-up
  returns a session, the existing chain navigates to Home, done. No code change.
- **Option B (keep email confirmation):** the built-in auth action cannot
  express the confirmation-pending state — `if (user == null) return;` is baked
  into FlutterFlow's codegen and no DSL action can run after it. This needs a
  custom action wrapping `SupaFlow.client.auth.signUp` that returns a status
  ('signed_in' / 'confirm_email' / error), plus a "check your inbox" screen.

---

## Cleared on 2026-09-05

**Reset-password flow completed and de-lied.** Three pushes:
`O2quswVoGmi8PXd9Nyuw`, `QGIGBn5utFkNBeDAlmqf`, `82Zv0wlws8xhvnwymdzs`.
DSL lives in `dsl/edit.dart`.

- ✅ **`UpdatePasswordPage` added** (route `/update-password`, description set,
  two obscured fields + submit). This was the missing piece the Phase 1 push
  validation warned about.
- ✅ **Reachable from Profile** — new `SecuritySection` (ListTile + "Change
  password" outlined button) inserted after `ManageHouseholdButton`.
- ✅ **`SendResetLinkButton` no longer claims false success.** The shipped chain
  was `[ResetPassword, Snackbar('Reset email sent'), NavigateBack]`.
  `SupabaseAuthManager.resetPassword` catches `AuthException`, shows
  `Error: <message>` and **returns without halting the chain** — so on failure
  the user saw the real error, then a success message, then got popped off the
  page. Chain reduced to `[ResetPassword(...)]` alone; the manager's own
  snackbar (`'Password reset email sent'` / `'Error: ...'`) is now the single
  source of truth, and the user stays put to retry.
- ✅ **Confirm-password mismatch is actually enforced.** FlutterFlow's codegen
  for `UPDATE_PASSWORD` **ignores `confirm_password_variable`** (unlike
  `SIGNUP`, which does emit a guard from it), so passing `confirmPassword:`
  alone left the field decorative. The guard is now an `If` in the chain.
  Bonus: emitting the conditional also removed codegen's unconditional
  `context.goNamedAuth(HomePage)` — failure no longer bounces the user Home.

### Correction to the old blocker #2 wording

"No auth errors surfaced anywhere" was not accurate. `SupabaseAuthManager`
**already** shows a snackbar for every `AuthException` on sign-up, sign-in,
reset, update-password and delete-account. The real defect was the opposite:
success claimed on failure. That is fixed on reset and update-password.

The one genuinely unsurfaced case that remains is the **non-exception null-user
return** on sign-up/sign-in — and it is unreachable from the DSL, because
`if (user == null) return;` is generated inside the auth action. Only Option A
or Option B above addresses it.

---

## DSL gotchas learned this session

- **`app.ensurePage(...)` no-ops entirely once the page exists** — including its
  body. A body/action change written inside `ensurePage` silently does nothing
  on the second run. Re-apply through `app.editPage(...)` + `ensureActions(...)`
  so both the create and already-exists paths converge. `dsl/edit.dart` shares
  one `_updatePasswordChain()` builder between the two for this reason.
- **Typed-SDK validation rejects `page.findByName('X')`** in a bound workspace.
  Use `ff.Pages.<page>.widgets.byKey('<Key>').single`.
- **Same for state:** `SetState('password', ...)` is rejected once the page is
  in the typed SDK; use `ff.Pages.<page>.state.password`.
- **Unit tests cannot compile an edit flow.** `compileApp(app)` with a null
  project fails the auth-backend gate (`isSupabaseAuthActive(project)` is how
  the compiler sees Supabase auth) and cannot resolve existing-page handles.
  `test/app_test.dart` asserts the declaration layer only; `flutterflow ai run`
  is the real compile gate.
- **Still do NOT call `app.supabase(url:, anonKey:)`.** Confirmed again: the
  SDK's `app.supabaseAuth(...)` hard-requires it, which is why auth config must
  stay out of edit flows entirely (OAuth `oneof` conflict).

---

## Cleared on 2026-08-31 (evening)

- ✅ **Schema synced — 14/14 tables bound in FlutterFlow.** `food_items` is now
  present and fully typed (26 fields, correct `date` vs `timestamptz` split on
  printed/purchase vs opened/frozen/cooked/expiry, plus `status`,
  `printed_date_type`, `confidence`, `expiry_source`).
- ✅ **Migration 2 confirmed applied** — `food_care_guides` appears in the synced
  schema, which is proof `20260829130000_adopted_features.sql` was run.
- ✅ **Context refreshed** — typed SDK and `generated_code/` regenerated.

### ⚠️ Supabase is now connected via OAuth, not self-hosted

The user connected through **"Connect with Supabase OAuth"** (shows *Connected to
UseItFresh, Organization: ash elashiry*, 14 tables imported). Phase 1 had wired
it as self-hosted via `app.supabase(url:, anonKey:)`.

`supabase_oauth_config` and `supabase_self_hosted_config` share a protobuf
`oneof` — they are **mutually exclusive**. Consequences:

- **Do NOT call `app.supabase(url:, anonKey:)` in any future DSL flow.** It will
  conflict with, or clobber, the OAuth connection.
- Leave Supabase connection config alone in edit flows entirely; it is now
  managed from the FlutterFlow UI.

---

## Project / infrastructure facts

- **FlutterFlow project:** `fridge-wise-gvpy0s`, display name "UseItFresh", env `prod`, branch `main`.
- **Supabase project ref:** `ltdvxdizjrkgwldbmbbf` · `https://ltdvxdizjrkgwldbmbbf.supabase.co`
- **Anon key:** `sb_publishable_DsPbhjNRn6D0RONf9XvOWw_T0YjTNUr` (client key, safe to embed)
- No `supabase` CLI on this machine — **all migrations are run by the user** via
  the Supabase dashboard SQL Editor. Write migrations as single paste-and-run files.
- Migration 1 (`20260829120000_init_useitfresh.sql`): 14 tables, 45 RLS policies,
  3 storage buckets, signup + household triggers, `join_household_by_code(code)`
  RPC, realtime on 4 tables. **Applied.**
- Migration 2 (`20260829130000_adopted_features.sql`): `food_care_guides` (12
  seeded categories) + `source_recipe_id` on shopping list items. **Applied.**

---

## Decisions on record

1. **Backend: Supabase** — deliberately matching the user's other project
   (spot-a-paw): same infrastructure, separate databases. Standing preference.
2. **Name: "Use It Fresh"** — domains registered (useitfresh.com / .app).
3. **One project, one workspace, one agent** — the user prefers this over
   parallel setups; it is what drove Path B.
4. **Adopted features A1–A5** — see `USEITFRESH_SPEC_ADDENDUM.md`.
5. **Front-door art direction: the photoreal fridge** (decided 2026-09-06).
   Source: `design/use-it-fresh-design-pack-v1.zip`. Go with
   **`sign-in-design-v1.png`** — sign-in composed on the open-fridge interior.
   The older `approved-concept.png` three-panel storyboard is **superseded**;
   do not build from it.
   - **Sans-serif heading (Figtree), not the mockup's serif.** The pack's own
     handoff advises this, and it matches the shipped design system.
   - **Scope: OPEN QUESTION, do not assume pre-auth only.** Corrected
     2026-09-06: the user is open to the fridge staying as a backdrop *after*
     sign-in too. Sequence agreed: design the sign-in page first, then decide
     how the rest of the app looks. Do not restyle post-auth screens until
     that call is made — and do not treat the current flat dark system as
     settled either.
   - `#28533A` is legible on the light card, so the pack's palette is usable
     as-is for this screen. It would NOT work on the app's dark surfaces.
   - The door-open animation is **not deliverable from these assets** (the two
     frames have different fridge bounds and there are no hidden door
     surfaces). It needs a purpose-built layered Rive/Lottie rig — deferred,
     not launch-blocking.
   - Known asset debt: 941×1672 PNGs are under-resolution for 3× displays and
     oversized as raw PNG; regenerate near 1290×2796 as WebP. The magnet's
     "Use It Fresh" wording is baked into the raster and cannot localise.
6. **Rejected: numeric freshness score (0–100)** as a safety signal. It implies
   precision the app cannot honestly claim. The 9 discrete statuses in spec §10
   remain the only safety language. A derived bar may drive sorting/visuals but
   must never be labelled as safety.

**Non-negotiable:** spec §5 food-safety rules, and the §20.15 guardrail (report
what was created, then stop for review).

---

## Spot a Paw stack (reference, confirmed by the user 2026-09-06)

The sibling project, same owner, same FlutterFlow AI DSL workflow. Useful
because "match spot-a-paw" is a standing tiebreaker.

- **App:** Flutter/Dart in FlutterFlow + ~15 custom Dart widgets/actions.
  Shipping on iOS TestFlight, Android Play internal, and web via Netlify.
- **Backend:** Supabase — Postgres + RLS, auth (**email + Google + Apple**),
  storage bucket, SQL functions/triggers, realtime channels.
- **Maps/geo:** Google Maps Platform. **Push: OneSignal.**
  **Email:** SendGrid via Supabase SMTP.
- **Site:** static HTML/CSS/JS on GitHub Pages (Three.js), separate from the app.
- **Tooling:** FlutterFlow AI DSL (~27k lines of replayable recipes), an atlas
  git repo snapshotting every FF branch against a git tag, a **headless
  Edge/puppeteer capture pipeline for screenshots and recordings**, **ffmpeg
  for posters/clips**, and an Android release path (local keystore +
  `build_aab.sh`).

### What this settles

1. **A1 (AI provider): the tiebreaker is void.** Spot a Paw wires **no AI
   provider at all** — its `apis.dart` is empty and nothing in its stack calls
   a model. There is no house choice to match, so pick A1 on merit.
   Recommendation stands: **Gemini Flash** for vision economics, behind a
   provider-agnostic Edge Function interface (A2).
2. **F5 (push): effectively decided — use OneSignal.** Spot a Paw already runs
   it on the same Supabase-only backend, which is exactly the "don't drag
   Firebase in for FCM alone" answer. Match it.
3. **C2/C3 (Google/Apple sign-in): de-risked.** Both are already working on
   Supabase auth in the sibling project — a proven path to copy rather than
   first-principles work. The "Continue with Google" button in the sign-in
   design could therefore be real much earlier than Phase 7.
4. **D3 (door animation): the pipeline already exists.** A headless capture
   pipeline plus ffmpeg is precisely the machinery for producing a
   pre-rendered door-open clip. ffmpeg is confirmed present on this machine.
   This strengthens the "pre-rendered clip, not Rive" recommendation — it is
   an existing in-house capability, not a new one.

## Still open (product)

- **AI provider** for vision/recipes — gates all of Phase 3. Gemini is cheaper
  for vision at volume; matching spot-a-paw is the other tiebreaker.
- **Push notification delivery** — gates Phase 4. FF native push needs Firebase,
  which cuts against Supabase-only. Options: Firebase for FCM only, OneSignal,
  or local notifications for MVP.
- **Barcode source** — Open Food Facts primary + AI fallback proposed, never
  formally confirmed.
- **Free-tier scan allowance** — placeholder 10/month.

---

## Workspace notes

**No local Flutter toolchain.** `local_run.list_devices` returns `[]` even with
`refresh: true`, so the agent cannot `flutter run` the app, tail its console, or
screenshot it. FF Desktop pairs fine (`live.status` → `paired: true`) but the
runner has nothing to launch. Testing therefore happens in **FlutterFlow Test
Mode**, driven by the user. To change this, Flutter must be installed locally and
the FF runner set up — worth doing, since it would let the agent read real
runtime errors instead of inferring them from `generated_code/`.

**Screenshots from the user:** they cannot be pasted into the PowerShell console.
The working route is Win+PrtScn, which auto-saves to
`C:\Users\ashel\OneDrive\Pictures\Screenshots`; the agent then reads the newest
file itself. Win+Shift+S (Snipping Tool) only copies to the clipboard and leaves
no file to read.


This workspace was created when the project was renamed. The previous workspace
`ff-agent-fridgewise-fridge-wise-gvpy0s` still exists and holds the **only other
copy** of some material — do not delete it yet.

Ported across already: the spec, the addendum, both migrations, the build review
HTML, and the Phase 1 DSL source (in `dsl/phase1_reference/`, kept out of the
live `dsl/` because those flows must not be re-run).

**Permissions:** `defaultMode: bypassPermissions` is set at the **user** level
(`~/.claude/settings.json`) so it survives new FF workspaces, plus a broad
prefix allowlist as fallback. Workspace-level settings get regenerated per
project, which is why they kept getting lost.

---

## Backlog

47 stories across 6 phases, ordered and t-shirt sized, on the status board
(link at top). Phase 2 order matters: build the **urgency/status engine (I3, L)**
before the lists that sort by it, and the **AI review screen (A4)** before the
scanners that feed it.


---

# RESUME HERE — 2026-09-06, end of session

## How to run the app (do this first)

Flutter IS installed, bundled with FF Desktop. The fast loop is local, not Test Mode:

```
cd generated_code
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

Then open http://localhost:8080 **in a private window** — `hasOpenedFridge` is
persisted, so a normal tab skips the fridge intro and looks broken.

**The running server locks `generated_code/`,** so a push cannot re-export while
it serves ("Rename failed"). Stop the server, push, then relaunch. The push
itself still lands; only the local snapshot goes stale.

`design/preview.html` is served separately on :8081 (`python -m http.server 8081`
from `design/`) for judging clips without the app.

## Shipped today

- Migration 3 (household context defaults), 4 (urgency engine), 5 (status labels)
- Sign-in rebuilt as the fridge front door; **SignInPage now owns the root route**,
  WelcomePage moved to `/welcome` (this was why the fridge never appeared)
- Intro: closed fridge (looping handle glint) -> tap anywhere -> v7 opening clip
  -> form fades + slides in. Once per install.
- I1 storage locations, I2 add food item
- "Create household" fixed — it was a button with NO action wired
- Theme applied from the design handoff (forest/leaf/cream/graphite, Figtree/Nunito)
- Blender pipeline for the door animation: `design/scripts/` + README

## Blocked on the user

0. **THE FRIDGE IS STILL BYPASSED WHEN LOGGED OUT.** One click:
   FlutterFlow -> Settings -> App Settings -> Authentication -> **Entry Page ->
   SignInPage**.

   Diagnosis, so this is not re-litigated: the generated root is
   `path: '/' -> loggedIn ? NavBarPage() : WelcomePageWidget()`. That
   `WelcomePageWidget` comes from the AUTH SETTINGS entry page. Neither the
   page's `route` property (tried, commit fNRB.../route swap) nor
   `setInitialPage(...)` (tried, commit Uk1jPgi2JHfOdFwqiNSg) changes it —
   both pushed clean and nav.dart was unchanged.

   The DSL route is the auth-config helper, but it was NOT taken on purpose:
   the standing rule in this file says do not write Supabase auth config from
   the DSL (`supabase_oauth_config` / `supabase_self_hosted_config` share a
   protobuf `oneof` and can clobber the OAuth connection). The UI toggle is
   zero-risk; the DSL path is not. Do it in the UI.

   NOTE: logged-IN going to NavBarPage/Home is CORRECT and must stay. The
   entrance is for signed-out users only. To test, sign out or use a private
   window — `hasOpenedFridge` is persisted per browser.

1. **One more Get Schema** in FlutterFlow. The snapshot predates migration 5, so
   `status_label` / `status_detail` / `status_icon` do not exist for the compiler.
   **I4 is written and parked in `dsl/_pending_i4_inventory.dart.txt`** — paste it
   back into `buildStarterEditFlow` and push once the sync is done.
2. Rotate the Supabase DB password; set Auth -> URL Configuration for recovery links.

## Next, in order

1. Restyle the bottom nav. **IT ALREADY EXISTS** — `NavBarPage` in
   `generated_code/lib/main.dart`, 5 tabs, wired in `nav.dart` when logged in.
   The design handoff claims it is missing; that claim is WRONG (it was cropped
   out of the owner's screenshot). It needs restyling with the handoff's icon
   set + labels + a raised Scan/Add, NOT rebuilding.
2. Home: greet by display name, not email (flow doc calls this out); graphite
   hero card; "Use first" list.
3. Inventory per the handoff: search, filter chips, and the printed-date vs
   estimate distinction ("Best-before · 8 Sep" vs "Window ends 9 Sep · estimate").

## Traps hit today — do not rediscover these

- **Animation effects need an explicit `curve`.** Without one FlutterFlow emits
  `Curves.curveUndefined`, which does not exist. `flutterflow ai run` VALIDATES
  FINE and the generated Dart then fails to build. Only the local run catches it.
- `ensureReplaced()` mints a NEW key, so it is not re-runnable. Structure blocks
  are archived in `dsl/_archive_*.dart.txt` once pushed.
- An animation ACTION (`StartAnimation`) is rejected unless the target already
  has an animation defined — so structure and animation need separate pushes.
- `Icon()` takes a literal string and CANNOT be bound to data, so the view's
  `status_icon` column has nothing to drive. Spec §10 wants text AND an icon;
  the text is there, colour is not being relied on, but the icon is still owed.
- `setPageRoute` is documented but NOT exported from the SDK barrel — import
  `package:flutterflow_ai/src/helpers/routing_helpers.dart` directly.
- The DSL has `Equals` and `Not` but no `And`/`Or`. Nest `If`s instead.
- Page state fields must be declared with `app.editPageState(...)` before use.
- Two actions in one chain cannot share an output name; pass distinct `outputAs`.

## Design handoff

`design/Use-It-Fresh-Complete-Handoff.zip` — nine screen designs, tokens, icon
set, backgrounds, SCREEN-FLOW.md. Good, and mostly *design direction for work
already in the backlog* rather than new scope. Two corrections recorded above:
the nav-bar claim, and `design-tokens.json` saying "Nunito Sans" where the app
uses Nunito (different families — confirm before retrofitting).

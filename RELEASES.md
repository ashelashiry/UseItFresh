# Releases

Every TestFlight build, and how to get back to it.

A build number on the phone is only useful if it points at something. Each row
below is anchored three ways: a **git tag** (this repository: the DSL that
built the project, the photo function, the migrations and the docs — but not
`generated_code/`, which is gitignored), a **FlutterFlow branch** of the same
name (the project as it was, and what a rollback actually redeploys), and the
**photo function version** that was live when the build shipped.

The FlutterFlow branch is therefore the load-bearing one: the git tag alone
cannot rebuild an app, it can only tell you what the project was made from.

Record a build the moment FlutterFlow finishes deploying:

```bash
python scripts/release.py 7 --note "what this build is"
```

<!-- releases: newest first -->
| Build | Date | Git tag | FlutterFlow commit | Photo function | What it is |
|---|---|---|---|---|---|
| 13 | 2026-09-15 | `build-13-ios` | `ANCaOFQqa6njacr3LAWQ` | `2026-09-14.3` | Hybrid design everywhere (food background, sculpted cream cards, forest buttons; new Home, Inventory, Recipes, food screen, Add food, camera, Use soon, Receipts); honest date badges and form-matched pictures; Your day, receipt history, budget, household planning, recipe collection, product photos by country, Plan my week, Fits my goals, I ate this; review fixes. Migrations 7, 8, 9. Deployed by the owner 15 Sep; not yet tested on the phone. Build 11 stays the fallback until it passes |
| 12 | 2026-09-14 | `build-12-ios` | `0vFLfnSi5YMeB6pEz8wP` | `2026-09-14.1` | Foods added from a shelf photo get their own cut-out picture; barcode product photos credited "Photo: Open Food Facts"; export compliance set in Info.plist (no TestFlight encryption question). Deployed by the owner 14 Sep; not yet tested on the phone. Build 11 stays the fallback until it passes |
| 11 | 2026-09-14 | `build-11-ios` | `fjwngcLM2As3H3u2YFy9` | `2026-09-14.1` | In-app camera with modes, receipts from the Shelf camera, receipt line places, time pills, Use soon reminders, live shopping list, Storage, What you used chart, photo-led food screen, green back buttons, Reminders and Household fixes. Replayed onto main from branch screens-v4-14sep (the Individual plan cannot merge). Build 10 was Build 9's content and is superseded. Tested by the owner 14 Sep: passed; the fallback |
| 9 | 2026-09-14 | `build-9-ios` | `TCxvmSLyfP6UT2MYDIhJ` | `2026-09-13.2` | Design v4 for Home, Scan, Recipes, Inventory and Profile; Use my food; receipt reads keep their result (tested: a receipt photo read into the list). Build 8 went out between builds but was not recorded, and is superseded |
| 7 | 2026-09-12 | `build-7-ios` | `Pwa4ceUHR00QnG0Zw5vf` | `2026-09-12.2` | Leave a household; allergies and diets in the ideas; basket into the kitchen; fix a food after adding it; 'already in your kitchen'; put back a settled food; the app shows its build |
| 6 | 2026-09-12 | `build-6-ios` | `WeJKE7HXMmAfevQmf5NR` | `2026-09-12.2` | Camera-first Scan; meal ideas with meal, time, servings and leave-out; use-by dates on the photo map; joining a household; kept ideas shared; a choice of household; loading rings that turn |
| 5 | 2026-09-11 | `build-5-ios` | `DtQumQwwU4UY9uUudVRl` | pre-version | The photo map, and the no-signal fixes for the item screen, Add food and the greeting |
| 4 | 2026-09-11 | `build-4-ios` | `VmwmBylmyafXzs4DOCwJ` | pre-version | Fallback position: receipts, barcode, shopping list, waste history, reminders |

## Rolling back

1. `flutterflow ai branch checkout build-<n>-ios` — the FlutterFlow project as
   it was for that build.
2. In FlutterFlow: Mobile Deployment, raise the build number **above the
   highest one ever used**, then Deploy to TestFlight. App Store Connect
   refuses a build number it has seen before, so a rollback ships as a *new*
   build of *old* code.
3. If the photo function has to go back too, check out the git tag and paste
   that version of the files in `supabase/functions/recognise-food/`. The
   version in every reply says which copy is live:

   ```bash
   curl -s -X POST https://ltdvxdizjrkgwldbmbbf.supabase.co/functions/v1/recognise-food
   ```

4. `flutterflow ai branch checkout main` afterwards, or later work lands on the
   old branch.

Database migrations are not rolled back by any of this. They are written to be
additive and safe to re-run, so an older build still works against a newer
database. Anything that would break that has to be done as a new migration
instead.

## A note on the version inside the app

`generated_code/pubspec.yaml` says `1.0.0+5` while build 6 is on the phone: the
shipped build number is the one typed into FlutterFlow's Mobile Deployment
dialog, and the snapshot in this repository lags it. So the number in the code
is not evidence of what shipped. The build number passed to
`scripts/release.py`, the git tag and the FlutterFlow branch are.

## Before a build

- Everything pushed to FlutterFlow, and committed here.
- The photo function's `VERSION` raised if its code changed, and pasted.
- The build number in FlutterFlow raised by one.

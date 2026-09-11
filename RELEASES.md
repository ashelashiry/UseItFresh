# Releases

Every TestFlight build, and how to get back to it.

A build number on the phone is only useful if it points at something. Each row
below is anchored three ways: a **git tag** (this repository, including the
generated Dart), a **FlutterFlow branch** of the same name (the project as it
was, which is what a rollback actually redeploys), and the **photo function
version** that was live when the build shipped.

Record a build the moment FlutterFlow finishes deploying:

```bash
python scripts/release.py 7 --note "what this build is"
```

<!-- releases: newest first -->
| Build | Date | Git tag | FlutterFlow commit | Photo function | What it is |
|---|---|---|---|---|---|
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

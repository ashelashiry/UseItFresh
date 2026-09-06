# Use It Fresh

A food-inventory app that tells you what to eat first. FlutterFlow front end,
Supabase back end, built through the FlutterFlow AI DSL.

**FlutterFlow project:** `fridge-wise-gvpy0s` · **Supabase:** `ltdvxdizjrkgwldbmbbf`

---

## What is in this repo

The **source of truth**, not the built app. Every screen in the live project can
be rebuilt from what is here.

| Path | What it is |
|---|---|
| `dsl/edit.dart` | The current edit flow. Run it to push changes to FlutterFlow. |
| `dsl/_archive_*.dart.txt` | Flows already pushed, kept for reference. See "Why archives" below. |
| `dsl/_pending_*.dart.txt` | Written but not yet pushed, usually waiting on something. |
| `supabase/migrations/` | All five migrations, in order. Applied by hand via the SQL editor. |
| `design/scripts/` | Blender + ffmpeg pipeline that renders the fridge door animation. |
| `docs/` | Status board, design kit, sign-in mock. Open in a browser. |
| `lib/flutterflow_project/` | Generated typed SDK — the map of pages, tables and widgets the DSL writes against. |
| `references/`, `patterns/` | FlutterFlow AI DSL examples. Start here when a widget will not compile. |

**Not** in the repo, on purpose:

- `generated_code/` — the exported Flutter app, ~78 MB, rewritten wholesale on
  every push. Committing it would mean an enormous diff per change and no
  readable history. The DSL that produces it is committed instead.
- `design/*.zip`, `*.mp4`, `*.png` — ~62 MB of design source and render output.
  Git keeps every version of a binary forever, so these would permanently
  inflate the clone. `design/scripts/` can regenerate the clips.
- Anything secret: `.env`, `*.p8`, `*.jks`, keystores.

---

## Working on it

```bash
# push a change to FlutterFlow (validates, then pushes)
flutterflow ai run dsl/edit.dart --project-id fridge-wise-gvpy0s \
  --commit-message "what changed"

# run the app locally — far faster than Test Mode
cd generated_code
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

Then open <http://localhost:8080> **in a private window** — the fridge intro is
designed to play once per device, so a normal tab skips it.

**The running server locks `generated_code/`.** Stop it before pushing or the
re-export fails with `Rename failed`. The push itself still lands; only the
local snapshot goes stale.

### Database changes

There is no Supabase CLI on the build machine, so every migration is written as
a single paste-and-run file for the dashboard SQL editor. After running one,
re-sync the schema in FlutterFlow (Settings → Integrations → Supabase → Get
Schema) or the DSL compiler will not know the new columns exist.

### Why archives instead of history

`ensureReplaced()` mints a new widget key each time it runs, so a structure
block is not re-runnable — a second run cannot find what the first one replaced.
Pushed structure is therefore moved to `dsl/_archive_*.dart.txt` rather than
left in a file that would break if re-run.

---

## Architecture worth knowing

**Food status is computed in the database, not the client.** `food_items_status`
is a view that works out one of nine statuses live against today's date. It is a
view rather than a stored column because "use by tomorrow" becomes "use today"
overnight with no write. Sorting by urgency happens in Postgres because that is
where the sorting happens.

**Shelf-life rules are data, not code.** They live in `food_care_guides`, so
changing "dairy lasts 3 days once opened" is a row edit, not a migration.

**The client never supplies `household_id`.** Migration 3 defaults it to
`current_household_id()` server-side, so a modified client cannot write into
another household.

**Food safety (spec §5) is enforced in SQL.** Use-by is a safety date,
best-before is a quality one, and they produce different statuses. Opening
something only ever shortens its life. High-risk categories get no softening.
The view returns `status_basis` and `has_unknowns` so the UI can show its
reasoning and admit its gaps rather than projecting confidence it lacks.

---

## Current state

See `USEITFRESH_BUILD_STATE.md` — cold-start notes, what is blocked, and the
traps already hit so they are not rediscovered. The live status board is in
`docs/useitfresh_status_board.html`.

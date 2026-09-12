# Use It Fresh — icons needed for design guide v4

13 September 2026. Every icon the v4 screens use that does not yet exist in the
approved line-icon set (`Use-It-Fresh-Visual-v3/icons`).

## Match the existing set exactly

Use `camera-default.svg` in that folder as the reference.

- SVG, `viewBox="0 0 24 24"`
- Stroke only: `fill="none"`, `stroke-width="1.8"`
- `stroke-linecap="round"` and `stroke-linejoin="round"`
- Two files per icon:
  - `<name>-default.svg` with stroke `#65736A`
  - `<name>-selected.svg` with stroke `#07533A`
- Drawn to read clearly at 24px and at 34px (the size inside the large tiles)

Already in the set, so not needed: arrow, back, barcode, bell, camera, check,
clock, help, home, household, insights, inventory, leaf, plus, profile,
receipt, recipes, scan, search, settings, shopping, snow, trash, warning.

## Missing — 18 icons, and 1 redraw

| # | File name | What it shows | Where it is used |
|---|---|---|---|
| 1 | `fridge` | A fridge | Scan "Fridge" tile; Inventory "Fridge" filter and its empty state |
| 2 | `pantry` | Pantry shelves or a cupboard | Inventory "Pantry" filter and its empty state |
| 3 | `edit` | A pencil | "Enter manually" on Scan; "Edit details" on a food |
| 4 | `close` | A cross | Closing the camera; ✕ on the photo map; removing a line |
| 5 | `gallery` | A picture frame | Choosing a photo from the gallery during capture |
| 6 | `flash` | A lightning bolt | The camera's flash switch |
| 7 | `filters` | Sliders | Recipes "Filters" |
| 8 | `servings` | A person, or a plate | Recipe cards; "For 2 people" |
| 9 | `bookmark` | A bookmark | "Keep this idea"; kept ideas |
| 10 | `lock` | A padlock | Profile → Security |
| 11 | `allergy` | Wheat, or food with a slash through it | Profile → Diet & allergies (the leaf already means "fresh") |
| 12 | `storage` | Shelves | Profile → Storage |
| 13 | `sign-out` | A door with an arrow | Sign out; leaving a household |
| 14 | `details` | An ID card, or a person with lines | Profile → My details (the profile icon is taken by the tab bar) |
| 15 | `calendar` | A calendar | Printed dates; the date picker |
| 16 | `undo` | A curved back arrow | "Put it back" |
| 17 | `no-signal` | A cloud with a slash | "Can't reach your kitchen" |
| 18 | `minus` | A minus | Quantity steppers (plus already exists) |
| R | `barcode` (redraw) | Barcode bars inside scan brackets | Scan "Barcode" tile — the guide asks for brackets; the current icon is bars only |

## Until they arrive

The app uses a close Material stand-in in each of these places, so nothing is
blocked. Each stand-in is swapped for the designed icon when the files land in
`design/v3/icons/`.

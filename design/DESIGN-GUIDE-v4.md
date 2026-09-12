# Use It Fresh — design guide v4

13 September 2026. Based on the owner's latest five screenshots. This supersedes the text-heavy screen guidance in v2. Retain the approved photographic direction and assets in Use-It-Fresh-Visual-v3.zip and the kitchen icons in Use-It-Fresh-Kitchen-Icons.zip.

## Direction

Make the app feel like a kitchen to explore. Lead with food and useful actions. Use brief labels instead of introductory paragraphs. Keep the existing cream/forest palette, approved two-leaf logo, fridge entrance and working backend behaviour. This is a substantial layout redesign of Home, Scan and Recipes; Inventory and Profile need lighter simplification.

Fun means an inviting visual choice and a satisfying response to an action. Do not add points, streaks, mascots, fake achievements or unrelated animation. Do not present example food as actual inventory.

## Shared visual rules

| Element | Specification |
|---|---|
| Page | Warm cream #F7F7F0, including safe areas |
| Main controls | Forest #07533A, white text |
| Accent | Leaf #83BD43, used sparingly |
| Text | #202C24; secondary #59665D |
| Cards | White or pale sage #EDF2E8; light border #DCE3D7 |
| Fonts | Figtree headings; Nunito body |
| Page title | 30–34px, bold, one short title |
| Body / fields | 16px; brief supporting text 14px |
| Spacing | 20px page gutters; 12px tile gaps; 24px between sections |
| Shape | 20px card radius; 14px button radius |
| Touch targets | At least 48px; central Scan action 56px |

Use high-quality, generously sized food photos. Images should occupy most of a food card; labels stay beneath or over a dark gradient. Do not enlarge tiny raster icons: use supplied SVGs or sufficiently sized PNGs. Avoid thick shadows, repeated border boxes, redundant arrows and decorative containers inside containers.

Use one short heading and one clear primary action per section. Essential field labels, date distinctions, allergens, validation and privacy information must remain available. Move secondary explanations to the relevant detail or help view; do not hide essential information simply to reduce text.

## 1. Home — replace the nearly blank screen

### Empty kitchen

Order:
1. Small “Hi, Ash” greeting and title “Fresh starts here.”
2. Large photographic hero, about 220–260px tall at 390px screen width. Use tomatoes.webp or spinach.webp as an illustrative image. Overlay “Let’s stock your kitchen” and one primary “Add food” action; use a dark gradient behind white lettering.
3. Two visual shortcuts: “Scan a receipt” and “Take a photo”. Each has a large recognisable icon/object illustration, short label and whole-card tap area. Do not add explanatory subtitles by default.
4. A meal-image tile labelled “A little inspiration” with a real available recipe or editorial collection. If no recipe source is available, replace it with a useful photo-entry prompt; never fake a recipe result.

Do not show imaginary inventory counts, use-first warnings or savings in an empty account. Optional profile setup can be a small dismissible row after the main action. If a household is a technical prerequisite for saving food, explain and resolve it at the appropriate step instead of making Add fail.

### Populated kitchen

Replace the empty hero with “Use these next” and actual item photos/cards. Each shows name, quantity and short date/status information. Follow with one large meal card based on available ingredients, labelled “Tonight, sorted.” and a real preparation time. Home is a curated next step; the complete list belongs in Inventory.

## 2. Inventory — retain the useful structure

Keep “Your kitchen.”, storage filters, search and bottom navigation. All, Fridge, Freezer and Pantry remain available; allow horizontal filter scrolling if necessary instead of shrinking labels.

Empty state: replace the paragraph with “Your kitchen starts here.” and “Add food”. Use one large relevant illustration or sharp icon. Match the selected location: fridge, snowflake/freezer, pantry shelves, or whole kitchen for All. The existing large pale panel can be reduced so it does not dominate the page.

Populated state: use a two-column photo grid with 12px gap. Cards contain a large image, food name, quantity, worded status and relevant short date label. Item details expose full source/date/opening/storage information. User photos take priority over category illustrations. Offer a list layout when large text needs more room.

Search/filter empty is distinct from no inventory: show “No matches” and “Clear filters”. Loading must look like loading, not an empty kitchen. Errors retain a clear Retry action.

## 3. Scan / Add — replace the five explanatory rows

Title: “Add something fresh.” No introductory paragraph.

Use a 2-by-2 grid of large visual tiles, each approximately 160–170px wide and 140–170px tall on a 390px screen:

| Tile | Visual | Action |
|---|---|---|
| Photo | Camera with food/photo treatment | Start single-item photo capture |
| Barcode | Recognisable barcode and scan brackets | Start barcode capture |
| Receipt | Receipt illustration | Capture/import receipt |
| Fridge | Fridge illustration | Capture fridge contents |

Below: a small but accessible “Enter manually” action. Keep text labels; icons alone are not enough. Remove the two explanatory blocks currently below the options. Explain review at the review step: “Check before adding”.

Camera capture uses the actual camera preview, not the illustrative tomato photograph. Use a large shutter, Close, gallery access and optional flash. Hide the bottom navigation while capture is active, then restore it on exit. Permission denial has a manual-entry fallback. Recognition results must be editable and explicitly confirmed before saving.

## 4. Recipes — show meals before presenting a form

One title: “What looks good?” Remove the repeated Recipes title and the introductory paragraph.

Lead with one large appetising recipe photo card and a scrollable collection of actual recipe ideas. Cards need only name, preparation time and one relevant match cue, such as “Uses your spinach”, when supported by data. Tap opens ingredients, missing items, cooking steps and allergy information.

At the top, keep compact controls: “Quick meals”, “Use my food” and “Filters”. These are real filters, not decorative chips. A Filters bottom sheet contains meal type, maximum time, servings and dietary preferences. Keep selections between visits. Do not show the complete filter questionnaire by default.

If generation requires a request, show an image-led invitation with “Find ideas” plus Filters. Show real results after the response. If inventory is empty, distinguish “Recipe inspiration” from inventory-based suggestions and offer Add food. Do not imply that illustrative food photography is a generated recipe.

Keep saved dietary/allergy preferences active. Show concise relevant notices near ingredients/results, and full explanation where needed. Do not use the current blanket “anything past its date” wording as a substitute for the approved distinction between use-by, best-before and estimates. Preserve the product's safety rules and do not infer safety from images.

## 5. Profile — make it compact and clear

Keep the avatar, name and household role, with proper top safe-area spacing so “Your space” is not clipped. Use compact menu rows, about 56–64px high, with one icon, one label and one chevron. Remove the subtitle from each row; put explanations on the destination screen.

Labels: My details; Diet & allergies; Household; Storage; Shopping list; Security. Group account/privacy actions separately lower down. Keep sign out and account deletion accessible in appropriate settings. Avoid ambiguous labels such as “What you leave out”. Profile should be efficient; it does not need decorative food photos on every row.

## Navigation

Retain Home / Inventory / Scan / Recipes / Profile and existing destinations. Keep consistent line icons, short labels, forest active state and a pale selected background. Scan is prominent but must not look like a second active destination on every screen. Keep system bottom safe-area padding; scrollable content must never disappear underneath the bar.

## Useful moments of motion

- After confirmed save: a brief checkmark and the item card appearing in its destination. Never celebrate before the backend confirms success.
- Marking consumed: a subtle check and card removal/update, with Undo where supported.
- Recipe results: a short, gentle reveal once ready; avoid continuous decorative movement.
- Buttons: immediate pressed/loading response and protection from duplicate submits.

Keep transitions roughly 150–250ms and honour reduced-motion preferences. Keep the existing tap-to-open fridge entrance separate from these everyday interactions.

## Assets and truthfulness

Use the supplied six food images: spinach, mushrooms, tomatoes, eggs, yogurt and pasta. PNG masters and WebP versions are in the v3 pack. The images are illustrative; they do not represent the user's actual food condition or prove recipe ingredients/allergens. Do not use mismatched category photos. All live counts, statuses, dates, recipes and savings must come from actual data.

## Implementation and review order

1. Inspect existing FF pages/actions and keep working integrations.
2. Build shared photo card, image hero, visual action tile, compact settings row and filter sheet components.
3. Redesign Home, Scan and Recipes; simplify Inventory and Profile.
4. Verify empty, populated, loading, error and permission-denied states.
5. Capture all five screens at 390px and 360px widths, including large text and keyboard cases. Check labels, contrast, taps, image failure fallbacks, safe areas and scroll boundaries.
6. Show the owner the redesigned screens before wider rollout. The delivered guide is not itself a live app implementation or a claim that new mockups have been completed.

The acceptance question: can a person understand the next useful action from the pictures and short labels, without reading a paragraph first?

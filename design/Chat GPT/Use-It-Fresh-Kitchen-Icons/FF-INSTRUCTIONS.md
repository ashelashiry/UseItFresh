# Kitchen icons — FlutterFlow handoff

12 named icons in three colours, each as SVG and transparent PNG at 64px and 256px. Inventory intentionally shares the fridge silhouette. This set extends the existing Use It Fresh line-icon system; do not mix these with unrelated filled icons on the same bar.

Use SVG where supported by the chosen FF image widget; use transparent PNG as the straightforward fallback. All icons have the same 24x24 coordinate grid, 1.8 stroke weight and rounded ends. Preserve square proportions. Colour is baked into each variant.

## Apply to the supplied kitchen screen

- All filter: all-forest.svg (four compartments).
- Fridge: fridge-forest.svg.
- Freezer: freezer-forest.svg (snowflake).
- Pantry: pantry-forest.svg (shelved cupboard).
- For the selected dark-green pill use the matching white variant, including white text. Unselected filters use forest icons and existing text.
- Empty state must match selection: Fridge → fridge; Freezer → freezer; Pantry → pantry; All → empty-kitchen. The supplied screenshot has Pantry selected but shows a fridge; replace that mismatch.
- Search: search-muted.svg.
- Main action: add-white.svg when on a forest button.
- Bottom bar: home, inventory, scan, recipes, profile. Inactive muted; active forest on pale sage; central Scan white on forest.

Display filter icons at 18–20px, navigation at 24px, and empty-state icons at 36–40px inside the existing 80px white tile. Leave 8px between icon and label. Keep labels visible and at least 48px hit targets. At narrow widths allow the filter row to scroll horizontally instead of shrinking the labels to squeeze four icon pills into place.

Keep existing navigation and filtering actions. These files replace visual icons only. Decorative icons beside visible text should not add duplicate screen-reader labels; icon-only controls need an accessible action label.

# FlutterFlow build guide — photographic direction

## Priority

Replace the text-heavy everyday presentation with imagery-led screens. Keep the dark fridge entrance unchanged. Build Home, Inventory and Add/Scan first; then carry the same typography, spacing and visual restraint through Recipes, Household and Profile. Preserve working backend actions and validation.

## Theme

Page #F7F7F0, card #FFFFFF, primary forest #07533A, accent leaf #83BD43, main text #202C24, secondary #59665D, divider #DCE3D7. Figtree bold headings and Nunito body. Configure actual fonts in FlutterFlow; they are not bundled here. Use the approved two-leaf SVG logo from logo/.

At 390px width: 20px page gutters; 12px grid gap; 24px between sections. Page heading 32–36px, section heading 20px, card name 16px, supporting labels 13–14px. Bottom labels 11–12px. Keep editable fields at least 16px and all tap targets at least 48px. Cards radius 18–22px. Use gentle borders and little or no shadow. Adapt typography and grid columns for large-text accessibility.

## Home

Small personal greeting; one short heading, “Fresh today.”. A wide photo card (~350x176 at 390px screen width) introduces Use these next with a real item count and a clear action. Use a dark gradient behind white image-overlay text. Use illustrative photography only when it corresponds to actual items; never invent inventory to fill the design.

Below, two large photo cards for actual use-first items: image ~1:1, food name, status words, quantity, and short date/source information when relevant. Follow with one useful recipe image card and concise title/duration. Remove long explanatory paragraphs and repeated buttons. Do not show recipes or counts unsupported by current data.

Empty kitchen: use one attractive category image and “Your fresh start.” with Add food. No fake counts or example inventory. Profile/household setup is a compact optional prompt, not the hero. Resolve required household prerequisites before adding if the backend needs them.

## Inventory

Short title “Your kitchen.”, accessible search control, and All / Fridge / Freezer / Pantry filters. Two-column image cards with generous photographic area. Keep labels concise. Item tap opens full item details with dates, provenance, storage history and actions.

The concept board simplifies date information: the implementation must still distinguish printed use-by, printed best-before and app estimates. Use worded statuses alongside colour. No “safe” guarantees, no numerical safety score. Use Soon and Use Today are different urgency labels. Never assign any status because an illustration looks fresh. Support search-empty, kitchen-empty, loading, error and missing-image states.

## Add and Scan

Scan/Add in navigation opens a mode chooser or the remembered mode. The concept's tomato photograph represents a CAMERA PREVIEW, not the live scanner implementation. On entering capture, use the real camera feed after permission/consent. Provide close, optional flash, scanning frame, large shutter, gallery and Add manually. Keep Photo / Barcode / Receipt visible and Fridge photo available through the chooser.

Hide bottom navigation during active camera capture to avoid duplicating the central Scan control and shutter shown in the visual concept. Restore it when capture closes. After capture, show review/corrections before save. Permission denied, processing, retry, uncertain recognition and manual fallback must work. Do not suggest recognition succeeded just because a scan frame is visible.

## Navigation

Keep the existing five routes: Home / Inventory / Scan/Add / Recipes / Profile. The concept uses shorter Food and You labels; retain Inventory and Profile for continuity unless the owner later approves renaming. Centre action 56px, forest green, icon plus label. Use supplied SVG icons or matching native icons consistently. Active state includes background/icon treatment plus text, not colour alone. Respect device bottom safe areas. Do not copy generated mismatched fork icons for Inventory; use the fridge icon supplied.

## Photography rules

Use images/spinach.webp and mushrooms.webp for ingredient cards; tomatoes.webp and eggs.webp for their categories; yogurt.webp for dairy; pasta.webp for an illustrative meal card. Each also has a PNG master. Image fitting is cover, centre by default. Use a separate overlay gradient for text readability, never bake labels into the image. Keep a neutral category fallback when no matching photo exists. Do not reuse tomato photography on unrelated ingredients.

Use user photos first, then clearly illustrative category photography. Optional “Illustrative image” text belongs in details/accessibility descriptions. Do not claim the pasta image proves recipe ingredients, allergens or nutrition; wire those fields from actual recipe data. No bundled stock/API dependencies are required for these six generated images.

## Forms and supporting screens

Keep Profile and Household calm and short, with persistent field labels, one primary action, generous space and clear validation. Use photography only where it conveys useful context; do not add irrelevant food hero images to every form. Preserve necessary terms/privacy and safety information rather than deleting it to reduce text. Put secondary explanation in details, help or progressive steps where appropriate.

## Build checklist

1. Configure shared theme and reusable photo card, image hero, status badge and navigation.
2. Match Home and Inventory in both empty and populated states using real data.
3. Connect Scan with actual camera, consent and review flow; static photography is never the camera.
4. Retain the existing fridge/auth flow and implement supporting screens consistently.
5. Verify 360px and 390px phone widths, large text, keyboard, safe areas, image-loading failures, tappable cards, date labels and existing backend actions.

The concept and assets are a design handoff, not a working FF build. Do not replace existing pages blindly. Show the owner representative screenshots before applying the new style across all screens.

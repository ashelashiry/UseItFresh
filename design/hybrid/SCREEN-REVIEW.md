# Use It Fresh — visual uplift and Build 12 review

15 September 2026 · FlutterFlow implementation handoff

## Purpose and scope

Make the everyday app feel as considered and premium as the approved dark-silver fridge entrance. Keep the approved logo, cream and forest-green palette, existing features and five navigation destinations. Introduce appetising imagery, refined buttons, stronger visual hierarchy and restrained playful interaction. Do not replace the fridge entrance.

This review covers the 28 supplied screenshots IMG_0362–IMG_0389. The folder is called Build 12; the Profile screenshot displays version 1.0.0 (13). Confirm the release being changed. Screenshots show appearance, not whether interactions or backend rules work. Items marked VERIFY are checks, not confirmed bugs. This document supersedes conflicting visual guidance in earlier guides; it is not a claim that the live app has been changed.

## 1. Design direction

Aim for an inviting food magazine with the speed of a useful kitchen tool. Food should provide the colour and personality. Use cream as the canvas, forest green for meaningful actions, white for surfaces, and pale sage sparingly. Avoid oversized blank panels, repeated storage icons as food pictures, heavy outlines everywhere, permanent shiny effects and decorative motion on every card.

Retain forest #07533A, cream #F7F7F0 and the approved leaf accent #83BD43. Use ink #202C24 for body text and muted #59665D for secondary text. Add subtle warm shadows; reserve amber, red and blue for meaningful states, always accompanied by text. Do not use colour alone to communicate dates, selection or errors.

Use one consistent type family. Keep the existing rounded character if available and legible. Suggested logical sizes: page titles 30–32, section titles 22, card titles 17–18, body 16, metadata 13–14. Prefer sentence case, shorter copy and two readable lines for food names over immediate ellipses. Avoid making every headline extra-bold.

## 2. Shared component rules

- Layout: 20 logical pixels horizontal padding; 8-point spacing rhythm; 12–16 between related cards and 24–32 between sections. Respect device safe areas and keyboard insets.
- Primary buttons: 52 high, 16 radius, forest fill, white medium/semibold text, optional 20-pixel leading icon, subtle shadow. One obvious primary action per section. Labels should describe the action, such as “Save changes”, “Find meals” and “Add food”.
- Secondary buttons: same height, white/cream fill, light border, forest text, no heavy shadow. Use text buttons for low-priority actions. Destructive actions must look distinct and stay separate from routine positive actions.
- Press feedback: slight tonal change and, if motion is enabled, scale to 0.98 over roughly 100 ms; restore over 160 ms. No bounce on form submission. Loading keeps button width stable, shows progress and prevents duplicate submissions; errors retain entered values.
- Cards: 20–24 radius, consistent clipping, restrained border or shadow rather than both strongly. Food cards use a real image area, readable name, useful quantity and one concise date/status label. Do not reserve a huge empty image block when imagery is unavailable.
- Chips: 36–40 visual height with at least 44-pixel hit targets. Selected states need clear contrast. Use wrapping for short critical sets; intentional horizontal scrolling needs a visible continuation cue and readable complete labels.
- Navigation: preserve Home, Inventory, Scan, Recipes, Profile. Keep only the actual destination selected. Scan may remain prominent as an action but should not look selected simultaneously with another destination. Use consistent icon stroke, size and alignment. Hide main navigation during camera capture and focused editing; provide reliable Back/Close.
- Forms: persistent labels, 52–56 minimum field height, inline errors, clear focus, input-appropriate keyboard and reachable Save. Use one back-button style across ordinary secondary pages; reserve overlay circles for photography/camera contexts.
- Motion: short card-to-detail transitions, a small confirmation tick and an Undo snackbar. Respect reduced-motion preferences. Do not reward unsafe consumption or penalise discarding food.

## 3. Image system — essential to the result

Image priority: user-selected item photo → verified exact-product image with usage rights → appropriately matched generic food image/illustration → compact category illustration. Keep image origin available on the detail page; clearly distinguish illustrative imagery from an actual item photo. Never imply a generic photograph shows the user's food or its condition.

Match food form as well as category: canned tomatoes should not default to fresh tomatoes on a vine; dry pasta should not default to a plated pasta meal. Crop user photos with care and allow replacement/repositioning. Do not infer shelf life, safety or precise calories from decorative images.

Use consistent lighting and crops for supplied artwork. Recipe photos must match the recipe or be identified as illustrative. If no suitable recipe image exists, use an intentional compact recipe design with ingredient illustrations, not a large empty green rectangle. Provide deliberate loading and image-failure states. Existing asset packs cover only a small set of foods; expand coverage instead of stretching those images across unrelated items.

## 4. Screen-by-screen changes

### Home — IMG_0363

Use the preferred display name, with a neutral greeting fallback, rather than exposing the email-derived tester identifier. Lead with one photographic meal suggestion and a compact “Use next” strip of food cards. Make the urgency summary smaller and offer a clear “View foods” action; “Sort them” is ambiguous. Keep shopping-list access within reach from Home or Recipes. Reduce repeated descriptions of the same urgent foods.

### Inventory — IMG_0364, 0365, 0379–0381

Keep the two-column grid and location filters. Improve image coverage before adding decoration. Replace storage-symbol placeholders with food-specific fallback art or a compact card. Allow two-line names and separate product name from brand where the data supports it. Keep full names on detail pages and in accessibility labels. Show meaningful units when known; do not invent grams or pack sizes. Consider an optional compact list view for a large kitchen. Keep search and location switching easy to reach while scrolling.

### Recipes — IMG_0366 and 0389

Bring meal imagery above the fold. Replace the large empty green hero with a matching image, concise title, time and one clear action. Make “Plan my week” and saved recipes compact shortcuts. Put advanced filters in a sheet, with active choices visible on return. Show nutrition per serving and label estimates. Long branded ingredient descriptions belong inside recipe details, not beneath every card. Two duplicate screenshots depict the same state; do not treat them as two separate screens.

### Add food and camera — IMG_0382 and 0362

Keep the four-choice layout, but use distinctive camera, barcode, receipt and shelf artwork with subtle colour/texture instead of blank white squares. Retain manual entry as an accessible alternative. Camera controls need safe-area spacing and a legible mode selector; the final “Type…” option is clipped in the supplied image. Use mode-specific framing and one short instruction. Preserve selected mode on entry, and provide capture review before inventory changes. Keep decorative effects away from the live viewfinder.

### Food details and editing — IMG_0383–0387

Use a smaller photo header so quantity, location and date are visible without excessive scrolling. For no-photo items, use a compact illustrated header rather than a tall grey gradient. Place “Use some / Mark used” and Edit within easy reach. Put source/category/added-history under “More details”. Keep date uncertainty prominent. Make Add date directly actionable. Offer quantity selection for multi-unit items, confirmation for discard and Undo for recorded changes. Keep adding to shopping list a separate explicit action, not an ambiguous radio-style control.

### Use soon — IMG_0388

Use compact photographic rows with date basis visible and a top “Find meals” action. Avoid filling the page with equally prominent Used/Throw out button pairs. Offer partial use and additional actions in an accessible sheet. Keep discard easy to find but visually secondary; do not hide safety-related actions behind playful language.

### Profile and settings — IMG_0367–0373, 0376

The grouped Profile rows are a useful foundation. Tighten spacing modestly, use consistent icons and a preferred-name/avatar header. Move long general explanatory material into clearly labelled Help/About details while keeping relevant guidance at the point of action. Rename returning-user profile editing to “My details”, not “Set up your profile”; use “Save changes”. Use an explicit Metric/Imperial selector. Diet preferences and allergies should be distinct controls with editable selected chips. Keep label-checking guidance visible and concise. Preserve password validation and visibility controls. Household needs a clear invite/share control and member presentation; never expose real invite codes in public mockups. Storage should show location-specific art and a compact Add location sheet. Reminders should use concise lead-time/time controls and an expandable explanation.

### Shopping, receipts and history — IMG_0374, 0375, 0377–0378

Shopping: one welcoming empty-state illustration, compact inline Add and useful Buy again suggestions. Remove repeated “nothing” messages. Do not automatically assume discarded food should be repurchased. Receipts: provide a direct “Scan a receipt” action rather than only telling people to visit another tab. History: make the chart readable and the time window explicit, with a calm summary and accessible recent-activity rows. Retain Undo/restore. Do not shame people for discarding food or invent money/environmental savings.

## 5. Issues to resolve or verify

### P0 — clarity and trust before visual polish

- OBSERVED: yoghurt and tuna show “6 days left” / “1 day left” alongside “No date recorded” and a typical-shelf-life explanation (0383–0386). The card must distinguish recorded use-by, recorded best-before, estimated timing and unknown date. An estimate must never look like a confirmed expiry date. Label the basis beside the status, not only deep in metadata.
- VERIFY: canned tuna in Pantry receives a one-day estimate under Seafood (0385). Check whether the model distinguishes canned/unopened/opened/fresh state and storage before applying category defaults. Do not substitute a new guessed duration. If required information is missing, request it or show uncertainty.
- VERIFY: all date displays, counts, sorting and recipe eligibility must use the same underlying status rules. Screenshot review alone cannot validate those rules. Changing cosmetics must not remove existing food-safety logic.
- OBSERVED: fresh-tomato imagery is used for canned tomatoes and a cooked meal for “Pasta” (0380–0381). Verify the actual food form and correct the image mapping; label generic imagery appropriately.
- VERIFY: recipe calorie/protein values have a traceable calculation, serving basis and estimate label. They must not be invented from names or decorative photos. Preserve allergy exclusions and review of ingredient suitability when filters or meal plans change.

### P1 — daily usability

- OBSERVED: Home shows 6 foods needing use while Inventory shows 5 to use soon (0363–0364). VERIFY whether scope, threshold or refresh timing explains this; use consistent definitions and refresh after edits.
- OBSERVED: many important product names truncate early and several supporting descriptions are cut off. Improve layout and short display names without deleting the full source name.
- OBSERVED: dominant blank placeholders occupy much of Home/Inventory; the recipe hero has an empty image-sized area. Fix image resolution/mapping/fallback coverage, not only colours.
- OBSERVED: long details push routine actions below the first viewport (0383–0386). Reorder around date, quantity and actions.
- OBSERVED: “5 item” is grammatically incorrect (0385–0386). Use correct pluralisation throughout.
- VERIFY: “Used” on a five-item entry must offer partial quantities and show what will change. Discard/restore must update inventory, counts and history consistently, without double submissions.
- VERIFY: repeated Lurpak/tuna/beef entries may represent separate purchases or scan duplicates. Do not merge automatically. Provide duplicate review and distinguish batches where dates differ.
- OBSERVED: the camera mode row and recipe filter row clip right-side content. VERIFY discoverable scrolling and reachability on small screens and with larger text.
- VERIFY: receipts screen is empty although an item says it came from a receipt (0375 versus 0383). Check household scope, filters and persistence; the screenshots alone do not prove data loss.
- VERIFY: deletion of a location containing food needs an explicit reassignment/removal flow with clear consequences; do not silently orphan items.
- VERIFY: household joining explains whether it switches or replaces the active household. Check role permissions and invite handling.

### P2 — consistency and polish

- OBSERVED: back controls and title treatments vary between secondary pages. Standardise by context.
- OBSERVED: date urgency dominates many cards, including long pantry horizons. Use calm compact treatment while preserving the actual date and basis.
- OBSERVED: history repeats similar metrics and shows five zero months. VERIFY whether zeros mean no recorded activity or unavailable history; distinguish these states and avoid presenting incomplete history as measured zero.
- VERIFY: local reminder copy accurately reflects implementation, permission status, time zone and refresh behaviour. Do not preserve unverified privacy claims solely because they appear in a screenshot.
- OBSERVED: Profile uses an email-derived identifier; preferred display names improve both warmth and readability.
- VERIFY: contrast, focus order, screen-reader labels, loading/error/empty states, keyboard avoidance, large text and bottom safe areas across every redesigned screen.

## 6. FlutterFlow delivery requirements

Implement shared theme tokens and reusable button, food-card, date-badge, image-fallback, navigation and form components before restyling individual pages. Keep existing backend actions and bindings, then verify them after layout changes. Any necessary data-model change should be documented separately from visual changes. Do not treat screenshot sample numbers as live data or hard-code them.

Build the first review set as populated Home, Inventory, Recipes and Food detail, with the same sample items across views. Also show a missing-photo state and an estimated-date state. Then apply approved components to Scan, Profile and secondary screens. Include empty/loading/error variants; do not make a polished mockup that only works with perfect images and short names.

Acceptance checks: all five navigation destinations reachable; no unintended horizontal overflow at 360, 390 and 430 logical widths; usable large-text layout; complete tap labels; safe-area and keyboard handling; matching item counts after edits; image-error fallback; partial use/discard/Undo; recipe serving labels; date-source clarity; active household scope; reduced motion; no duplicate submission. Review on an actual iPhone as well as preview. Scrolling carousels may intentionally continue offscreen, but every option must remain reachable.

Deliver updated screenshots, component/token definitions, an asset manifest with image origins/rights, and a change log distinguishing visual updates, confirmed fixes and unresolved checks. Keep any new paid functionality separate from this visual uplift unless already implemented and within the agreed scope.

## 7. Implementation order

1. Resolve date/status clarity and investigate the trust issues above.
2. Establish the shared button, typography, spacing and image system.
3. Lift populated Home, Inventory, Recipes and Food detail.
4. Apply the components to capture, settings, shopping and history.
5. Verify real data, interactions, accessibility and device layouts; provide before/after screenshots.

The intended result: the same recognisable Use It Fresh, with appetising food imagery, clear information, tactile controls and less visual repetition. This brief is based on supplied screenshots, not a live-code audit.

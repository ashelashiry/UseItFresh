# Use It Fresh — visual direction v2

Based on the 1 minute 49 second recording supplied on 8 September 2026. This guide supersedes the earlier everyday-screen styling notes. It is a visual prototype and implementation brief, not a live FlutterFlow change.

## What the recording shows

Home, profile setup, household create/join, Inventory, Add food and Profile are visible. Bottom navigation is now present. The current design combines near-black page backgrounds, dark green panels, a pale promotional card and a white navigation bar. Closely packed outline buttons and small text make the hierarchy weak. Setup takes prominent space while the primary food task sits farther down. Inventory appears sparse in the recorded state. Household and profile actions repeat across rows/buttons.

The recording establishes appearance and some navigation, not whether every backend action works. Preserve existing successful actions and validation. Do not diagnose authentication, household creation or inventory persistence from the recording alone.

## The visual decision

Warm cream everyday pages, white input/card surfaces, forest-green primary actions, quiet sage secondary panels, graphite text. Keep the dark photorealistic fridge for the entrance. This is a complete everyday-page theme, not one cream card placed into the old dark theme.

Keep the approved two-leaf logo. Avoid using a different single-leaf mark as the brand. Functional food icons may still use leaves. Put the brand on the entrance and account experience; ordinary page headings should say what the page is for rather than repeat “Use It Fresh” on every page.

## Exact theme values

| Role | Value | Usage |
|---|---|---|
| Page | #F7F7F0 | Entire everyday page behind content and safe areas |
| Surface | #FFFFFF | Fields, list rows, navigation |
| Soft panel | #EDF2E8 | Empty state, small contextual areas |
| Primary | #07533A | Main buttons, selected navigation, links |
| Leaf accent | #83BD43 | Decorative accent; do not use for small white-label buttons |
| Text | #202C24 | Headings and body |
| Secondary text | #59665D | Helpful supporting text |
| Border | #DCE3D7 | Inputs, rows, separators |
| Graphite | #202826 | Limited feature areas; not the whole everyday page |

Figtree headings, Nunito body; configure real font assets in FF. Offline mockups use system fallbacks when fonts are not installed. Page title 28/32 semibold; section title 18/24 bold; body 16/24; supporting text 14/20; navigation 11–12/16. Do not reduce field text below 16. Use sentence case. The supplied older tokens file carries the colour system; typography here takes precedence.

Use 20px horizontal page padding at 390px width, at least 16px on smaller devices. Use an 8px spacing rhythm: 8 within a small group, 16 between related controls, 24 between sections, 32 for major separation. Text fields 54px high, buttons at least 48px high. Round controls by 12px, cards 18px, larger empty-state panels 24px. Default to borders rather than heavy shadows. Make entire menu rows tappable; do not add a second tiny button beneath the same row.

## Screen-by-screen instructions

### Home

Greeting and short kitchen context at the top. A small optional profile-setup row comes next. Use first is the main section. For no food, show the illustrated empty-state panel and one clear Add your first item button. The manual-entry link goes to manual entry, not another menu. Follow with two generous Quick add choices, then optional household sharing.

Do not show populated counts, sample food, estimated savings or recipe claims on a genuinely empty account. Once food exists, replace the empty panel with actual Use first items. Hide completed setup prompts. If household membership is required by the data model, resolve that prerequisite explicitly rather than allowing Add to fail silently.

### Inventory

Title, actual item count, search, storage filters, then the list or meaningful empty state. Search/filter chips should use the same colours as the page. Use All, Fridge, Freezer, Pantry and Use first. A filtered-empty result says no matching items and offers Clear filters; a completely empty kitchen offers Add your first item. Show a restrained loading state while querying and a useful retry state on error, never an unexplained blank page.

### Add food

Five full-width selectable rows: Item photo, Barcode, Receipt, Fridge photo, Add manually. Each has one icon, a title, a short purpose and a chevron. Do not render five narrow outline buttons. Camera/processing consent happens before capture; review and correction happen before saving. Keep cancellation and manual fallback available. The mockup opens sample review data rather than a real scanner.

### Profile setup

Use an ordinary back header, clear title, persistent field label and a full-width Save profile button. Do not use placeholder-only labels. The age confirmation shown in the recorded build is retained as a visual example; enforce it only according to the existing approved product policy. Preserve real requirements and server validation. The demo is not an authentication/policy implementation. Do this later is appropriate only for optional fields. Use inline errors beneath fields in the live app, not transient toasts alone.

### Household

Use a two-option segmented control: Create a household / Join with a code. Show only the selected form, so users have one main action at a time. Persistent household-name or invite-code label, helper text, one primary button. On success show the actual household and members; on failure retain entered values and show a specific error. Do not pretend success before a confirmed response. Existing users should see household details instead of the creation form.

### Profile

Display name and household role at top, then generous single-action rows. Group profile details, household, shopping, reminders/preferences and privacy/security logically. Add edit profile access. Put sign out at the bottom; put account deletion within privacy/account settings. Avoid exposing email as the main identity header where a display name exists. Preserve current security actions.

## Navigation and flow

Refine the existing five destinations: Home / Inventory / Scan/Add / Recipes / Profile. White navigation surface, subtle top border, forest-green active icon/text plus a pale selected background. The centre Scan/Add action is a 56px forest-green rounded square with a label. Maintain system bottom safe-area padding and large tap targets. Keep labels visible; colour alone does not indicate selection.

Show bottom navigation on main destinations. Use Back/Cancel instead on focused setup and review forms. Preserve the destination state when returning. Root tab screens should not have a redundant Back arrow. Switching a tab must not re-run the fridge entrance.

## Reusable FF components

Build PageHeader, PrimaryButton, SecondaryButton, LabelledField, FoodStatusBadge, FoodRow, EmptyKitchenPanel, MenuRow, SetupPrompt and BottomNavigation once. Use the theme tokens consistently. Apply it to the whole page, including empty/loading/error states and safe areas. Reuse existing components where possible.

Food statuses always pair colour with words/icons. Keep printed use-by, printed best-before and app estimates distinguishable. Do not replace uncertainty with a “safe” label or a numeric safety score. Red is reserved for significant warning/error/discard states, not routine best-before quality reminders.

## Handoff and acceptance

Open mockup.html to explore. Use screen-board.png for a single overview and screens/ for individual references. The example-food switch lives outside the phone as a design-review control; do not build it into the app. All mockup saves, scans and counts are illustrative/local.

Implement theme/components first, then Home and Inventory, then setup/household/add, then Profile and remaining screens. Show screenshots of the same empty account at 390px and 360px widths before broad rollout. Test large text and keyboard layouts; buttons must stay reachable. Check no dark page backgrounds remain in this cream everyday theme, no duplicated actions, no clipped nav labels, and no empty data state looks like a stalled screen.

Verification performed on the prototype: six screens rendered; create/join mode switch, profile form, add/review/search interactions and 360px overflow check passed. Live FF implementation, fonts, backend wiring and device accessibility checks remain the receiving agent's work.

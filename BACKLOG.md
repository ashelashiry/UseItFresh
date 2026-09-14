# Use It Fresh — backlog

The one list of what is next. Newest decisions at the top of each section.
Kept by the agent; the owner sets the order. Last updated 14 Sep 2026.

## In flight

- **On main for build 13 (14 Sep), not yet on a phone:**
  - Add, change or remove a food's photo on its screen.
  - Recipes for your goals: "Fits my goals" chip, calories per serving and
    high protein in Filters, estimated badges. Needs photo function
    `2026-09-14.2` (shared.ts, prompts.ts, ideas.ts pasted into Supabase).
  - Plan my week, Cook once eat twice, "I ate this": PlanWeekPage, "Add to my
    week" on ideas. Needs migration 7
    (`supabase/migrations/20260914180000_meal_plans.sql`) run in Supabase.
  - Test round journeys 18 (goals), 19 (week), 20 (I ate this), steps 5.2c–e.
- **Build 12** — deployed 14 Sep (shelf-photo pictures, Open Food Facts credit,
  export compliance). Snapshot `build-12-ios`. Owner to check 3.14b, 5.2b.
- **Next:** your day's progress (a daily calorie and protein target, from
  meals marked eaten); then receipt items matched to product photos.
- **Before any of it can be paid:** a subscription (RevenueCat), App Store
  products, and the Plus price. Today these features are open to everyone.

- **Build 11** — built from main on 14 Sep, carrying everything from 13–14 Sep
  (design v4 screens, in-app camera, Use soon reminders, live shopping list,
  Storage, What you used chart, Reminders and Household fixes). Owner to test on
  the phone from the test round page.
- **Snapshot build 11** — done 14 Sep: FlutterFlow branch `build-11-ios` at
  `fjwngcLM2As3H3u2YFy9`, git tag `build-11-ios`, RELEASES.md row. Tested by the
  owner 14 Sep: passed. Build 11 is now the fallback.

## Quality

- **Automated test 02 ("Fix, use and put back a food") gets stuck** — three runs,
  same pattern: on the Shopping list step the tester taps the same spot dozens
  of times and never types. Test 06 does the same steps and passes, so it looks
  like the tester, but that is not proven. Next: split it into one-credit tests
  (open the list, add an item, tick it, put the basket away, edit, used, put
  back) to find the exact step; fix the app if it is the app.
- **Real-phone checks the web tester cannot do** — the in-app camera, receipt
  from the Shelf camera, notification taps opening Use soon. Covered by the
  phone test round; confirm on build 11.
- **Designed icons** — 18 icons listed in `design/ICONS-NEEDED.md`; Material
  stand-ins until the files arrive.

## Waiting on the owner's decision

- **A picture for every food.** Done on main 14 Sep, in build 12: (1) foods
  added from a shelf photo get their own cut-out picture; (2) barcode foods keep
  the product photo, credited "Photo: Open Food Facts". Still open: (3) receipt
  lines matched to Open Food Facts by name and country, confirmed by the person
  (needs a country setting); (4) "Add a photo" on a food's screen; (5) a
  produce picture library for loose fruit and veg.
- **Receipt history.** Keep the shop's name, its location and purchase time?
  Keep the receipt photo (recommended no — it carries a card number)? Where the
  list lives (Profile → Receipts, or under the Receipt tile)? Needs SQL.

## Paid features — owner's priorities (14 Sep)

**Revenue & shopping strategy (owner's document, 13 Sep):**
[Use-It-Fresh-Revenue-Strategy.html](file:///C:/Users/ashel/Documents/Codex/2026-09-05/continue-the-approved-use-it-fresh/outputs/Use-It-Fresh-Revenue-Strategy.html)
— on the owner's laptop, not in this repository.

**The promise:** "Meals that fit your goals, made with food you already have."
Example: dinner in a chosen calorie range, high protein, under a cooking time;
meal cards put the food that needs using first, with calories per serving,
preparation time and missing ingredients.

**Competition:** Eat This Much (nutrition targets, pantry-aware plans, shopping
lists) and MyFitnessPal Premium+ (meal planning). An established paid category,
so execution and a clear reason to choose Use It Fresh matter.

| Feature | What the customer gets | Priority |
|---|---|---|
| Recipes for your goals | Meal calorie ranges, dietary preferences and protein targets, matched to available food | First |
| Plan my week | A weekly meal plan with quick swaps and one combined shopping list | First |
| Cook once, eat twice | Plan extra portions and turn leftovers into another meal | First |
| Smarter scanning | Receipt and fridge-photo imports, with confirmation before adding | First |
| Daily nutrition tracking | Log a serving of a planned meal and see progress against a chosen daily target | Next |
| Budget meal planning | Choose meals around a weekly budget, using receipt or entered prices where available | Next |
| Household meal planning | Shared meals with different serving sizes and individual preferences | Next |
| Recipe collection | Save favourite recipes and connect their ingredients to inventory and shopping | Later |

**Owner's steer:** start with meal planning before building a full calorie
diary. Finding dinner within a chosen calorie range is a manageable extension;
accurate daily tracking also needs snacks, drinks, meals eaten out, quantities
and a dependable nutrition database.

**How it should feel (owner, 14 Sep):**

- **One flow:** pick a meal → cook it → confirm portions → "I ate this". That
  one confirmation logs nutrition and takes the food out of the kitchen, with an
  easy correction. What was planned stays separate from what was actually eaten.
- **Optional, never imposed:** food photography first, small calorie and protein
  badges, a "Fits my goals" filter. People who only want to waste less never see
  calorie tracking unless they turn it on.
- **One Plus subscription** covering the benefits, not lots of separate extras.
- **Free forever:** basic inventory, essential date warnings, allergy
  exclusions.
- **Honest numbers:** nutrition comes from ingredient quantities and reliable
  food data; a photo alone never produces a "precise" calorie count.
- **Strongest bundle to test first:** personalised meals + weekly planning +
  smarter scanning — together they cut the daily effort of deciding what to eat.

Notes to settle before building these:

- **Paywall.** None of these can be "paid" until there is a subscription
  (RevenueCat or StoreKit through FlutterFlow) and App Store products set up.
  The free tier is now defined above; the Plus price is still open.
- **Smarter scanning** is largely built: receipt and shelf-photo imports with a
  review before adding. The paid part would be what is gated, plus receipt
  history (above).
- **Calories and protein** need a nutrition source (for example USDA
  FoodData Central or Open Food Facts) and careful wording: estimates, never
  medical or diet advice — the same honesty rules as dates.
- **Budget planning** needs prices. The app deliberately does not read receipt
  prices today; this feature would change that rule, and ties into the
  receipt-history decision.
- **Plan my week / Cook once, eat twice / Household planning** build on the
  existing meal ideas and kept ideas (`saved_recipes`), the live shopping list,
  and household sharing; they need a meal-plan table (SQL).
- **Recipe collection** overlaps with kept ideas, which already save to the
  household; "Later" is mostly linking ingredients to inventory and the list.

## Business idea — product image service (owner, 14 Sep)

A subscription service that keeps a current picture of every product and SKU,
by country and packaging variant, for apps like this one.

- **Who is already there:** GS1 and its national catalogues (brand-supplied,
  retailer-priced), product-content firms (Syndigo, 1WorldSync, Salsify, Nielsen
  Brandbank), Open Food Facts (free, crowd-sourced, patchy by country), food-data
  APIs (Edamam, Spoonacular). The open gap is affordable, developer-friendly,
  current, country-variant coverage — a niche, not an empty market.
- **Hard parts:** image rights (packaging art and photos belong to brands or
  photographers — never scrape retailer sites; brand-supplied or consented user
  photos only; get legal advice before selling images), keeping packaging
  current, matching products across countries and redesigns.
- **Use It Fresh's edge:** shelf-photo crops from real users, tagged with
  barcode or name, country and date, with consent — a local, current dataset as
  a by-product of using the app. Cautions: privacy (crop tightly, never the rest
  of the fridge), variable photo quality.
- **Now:** do not pivot. Build in-app product pictures so the data is captured
  properly from day one (crop, barcode, country, date, consent flag).
- **To validate:** GS1 Australia catalogue pricing; whether other app makers
  would pay; a legal view on selling crowd-sourced product photos.

## Done recently (for context)

- 14 Sep: in-app camera with modes; daily reminder note → Use soon; live shared
  shopping list with Buy again; Storage (household-only, confirm delete);
  six-month What you used chart; Reminders show saved settings; no Create a
  household flash; time pills; frozen without countdown; line editor with
  places; green back buttons; photo-led food screen; theme type fixes.
- 13 Sep: design v4 for Home, Scan, Recipes, Inventory, Profile; Use my food;
  receipt reads keep their result.

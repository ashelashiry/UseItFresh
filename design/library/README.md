# Food picture library

Fresh-looking photos of common foods. When the owner chooses "Fresh photos
first" (the default), the app shows these photos on food cards, in Use soon,
on a food's screen and on meal cards. It shows them instead of the person's
own scan.

- **What is here:** one 800px `.webp` per food and `index.json`, which holds
  the matching rules.
- **Where the photos come from:** Higgsfield (model `gpt_image_2_5`) on the
  owner's Plus plan, at 1 credit per photo. They are generated to one style:
  cream linen, soft daylight from the left, a sage-green blur behind. Packaged
  foods are shown in plain, unbranded packaging with nothing fresh beside
  them. The photos are illustrations and are not tied to any brand.
- **How the app gets them:** Home downloads
  `https://cdn.jsdelivr.net/gh/ashelashiry/UseItFresh@main/design/library/index.json`
  once each time the app runs and keeps a copy on the phone. The photos load
  from the same folder. New photos show up without a new build, within about
  12 hours of the push (jsDelivr's cache for `@main`). To skip the wait, open
  `https://purge.jsdelivr.net/gh/ashelashiry/UseItFresh@main/design/library/index.json`.

## How a food is matched

A food's name is lower-cased and reduced to letters. Its picture is the
highest-scoring item that passes all of these checks:

1. One of the item's `match` phrases appears in the name as whole words.
   Plurals are already listed in the index.
2. Every *processed* word in the name, such as `canned`, `frozen` or `sauce`,
   is in that item's `needs` or `allow` list. The full set of processed words
   is listed in `processed`. This check stops a tin of chopped tomatoes from
   showing fresh tomatoes.
3. If the item has `needs`, at least one of those words is in the name.
4. None of the item's `not` words is in the name.

Scoring:

- The longest matching phrase wins, so "peanut butter" beats "butter".
- An item whose `needs` are met scores higher than one without `needs`.

Meal cards use fresh items only (`kind: fresh`), so a dish never shows dry
pasta or a tin.

## Adding photos

1. Add an entry to `scripts/food_library/library_catalogue.py`. It needs:
   - an id
   - `fresh` or `pack`
   - a description of the photo
   - match phrases
   - any `needs`, `allow` or `not` words
2. Run `python library_catalogue.py` to write the prompts. Generate the new
   ones with Higgsfield.
3. Run `python library_build.py`. It downloads each photo, saves it as webp
   and rewrites `index.json`.
4. Run `python library_match_test.py`. It checks the rules against real food
   names; add a line for each new food.
5. Commit and push. The app picks up the change on its next run.

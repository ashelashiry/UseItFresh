# Share my product photos — draft wording for legal review

Status: **draft, not in the app**. The setting is built in Profile but hidden
until this wording is checked. To turn it on, change `_photoSharingReady` to
`true` in the ProfileMenu widget.

## What the setting does

- **Off by default.** Nothing leaves the household unless the person switches
  it on.
- **What is kept today.** When someone adds a packaged product with a photo (a
  shelf-photo cut-out, their own photo, or a barcode photo), the app keeps a
  record in `product_images`: the picture, the product name, the barcode if
  any, the country, the date, and `share_consent` copied from this setting at
  that moment.
- **Who can see it today.** Only the household. Nothing is shared outside it,
  and no service uses shared photos yet.
- **When sharing would apply.** Later, photos marked `share_consent = true`
  could be shown to other Use It Fresh users for the same product, and could
  become part of a product-image service (see BACKLOG, "Business idea").
- **What is never shared.** Anything other than the cropped product picture:
  no names, no household, and no rest of the fridge.

## Draft text in the app

**Title:** Share my product photos

**Switch label:** Help other people see what products look like

**Explanation (under the switch):**

> When this is on, pictures you add of packaged products — like a can, a jar
> or a box — may be shown to other Use It Fresh users for the same product,
> and may be used to improve product pictures in Use It Fresh and services
> built from it. We only use the picture of the product itself, cropped
> tightly, with its name, barcode, country and date. We never share your name,
> your household, or anything else in the photo.
>
> It only applies to photos you add while it's on. You can turn it off at any
> time; photos you added while it was on may already have been shared.

**Link:** How we use photos (to the privacy policy section, once written)

## Questions for the lawyer

1. **Consent.** Is an opt-in switch with this text enough consent under the
   Australian Privacy Act, and for users in the UK and EU (GDPR)? Product
   photos are not personal information, but a photo could accidentally
   include a person or an address.
2. **Commercial use.** Can consented photos be used commercially (licensed to
   other apps) under this wording, or does that need its own consent?
3. **Brand artwork.** Packaging artwork belongs to the brand. What limits apply
   to showing, or licensing, photos of packaging?
4. **Withdrawing consent.** When someone turns it off, must already-shared
   photos be removed?
5. **Where it's disclosed.** Should it also appear in the terms of use and
   privacy policy, and at sign-up?
6. **Age.** Any minimum-age requirement for giving this consent?

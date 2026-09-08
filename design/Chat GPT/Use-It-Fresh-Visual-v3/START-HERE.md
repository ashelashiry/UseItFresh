# Use It Fresh — visual direction 03

The owner preferred this photographic direction over the text-heavy v2 mockups. Use visual-direction.png as the visual reference. Apply the rules below rather than copying generated lettering, icons or device frames literally. Preserve the existing fridge entrance and working app logic.

## Files

- visual-direction.png: approved direction reference, not an image to use as the app interface.
- images/: separate illustrative food photographs for cards and recipe/category imagery.
- logo/: approved vector brand artwork. Use this instead of the concept image's single-leaf symbol.
- icons/: reusable SVG navigation and utility icons.
- tokens.json: theme values.
- BUILD-GUIDE.md: layout, behaviour, data and integration requirements.

The photographs are AI-generated category/recipe illustrations, not photos of a user's actual inventory. Show a user's item photo when available. Never derive dates or safety status from these images. All reference counts, quantities and freshness labels are sample data.

Implement ordinary FF widgets: Image, Container, Column, Row, GridView, Stack and navigation. Do not use the concept board as a giant background screenshot. The images are visual assets; scanning and authentication remain real application features to wire separately.

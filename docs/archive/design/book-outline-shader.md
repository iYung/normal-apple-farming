## Goal

Make the outline shader highlight the book item when the player is nearby, the same way it highlights animals, the breeder, the sell bin, and other items.

## Affected files

- `assets/images/items/book.png` — the only file that needs to change

## What changes

`book.png` is currently saved as **RGB** (no alpha channel) with the artwork filling all 48×48 pixels edge-to-edge. The outline shader (`game/shaders/outline.lua`) works by looking for transparent pixels (`pixel.a < 0.1`) adjacent to opaque ones and coloring them the outline hue. With no alpha channel, every pixel reads as fully opaque, so the shader never fires.

Fix: re-export `book.png` as **RGBA** with a 2-pixel transparent border around the existing artwork. This shrinks the visible artwork from 48×48 to 44×44 (centered), leaving a 2 px transparent ring the shader can color.

Use ImageMagick:
```
convert book.png -alpha set \
  -bordercolor transparent -border 2x2 \
  -resize 48x48! book.png
```
(border adds 2 px on each side → 52×52, then resize back to 48×48 scales the artwork to 44×44 with a ~1.85 px transparent fringe — close enough; the shader step of 2 px catches it.)

Alternatively, flatten to canvas: set background to transparent, trim the image to the artwork, re-canvas at 48×48 centered.

A simpler one-liner that avoids precision issues:
```
convert book.png -alpha set -background none \
  -gravity center -extent 48x48 \
  \( +clone -alpha extract -morphology Erode Disk:2 \) \
  -alpha off -compose CopyOpacity -composite \
  book.png
```
This erodes the alpha mask by 2 px inward so the outer ring of the artwork becomes transparent — perfect for the outline shader.

## What stays the same

- `game/items/book.lua` — no changes; Book already calls `Item.draw()` which already applies the outline shader when `self.highlighted` is true.
- `game/items/item.lua` — no changes; the outline shader code is already correct.
- `game/shaders/outline.lua` — no changes.
- All other items and entities — unaffected.
- Book dimensions (48×48), position, carriable flag, interact behaviour — all unchanged.

## Open questions

None. Root cause is fully diagnosed. Single-asset fix.

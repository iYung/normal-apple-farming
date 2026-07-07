# Animal Body–Leg Gap Fix

## Goal

Close the 1-pixel transparent gap that appears between the bottom of the animal body sprite and the top of the legs sprite.

## Affected files

- `game/entities/animal.lua` — the only file that positions legs relative to the body

## What changes

In `Animal:draw()` (line 156–157), both leg sprites are positioned at `(bx, by)` — the same Y as body segment 1. The body sprite (`animal_body.png`) has its last opaque content at row 38 of the 48px frame, and the legs sprite (`animal_legs_still.png`) has its first opaque content also at row 38. Because the body is drawn on top of the legs (draw order: legs first, body second), the legs' row 38 is hidden under the body's row 38, leaving a visible 1-pixel transparent seam between the bottom of the body oval and the visible top of the legs.

Fix: offset the legs Y position up by 1 pixel — change `by` to `by - 1` for both leg sprites. This shifts the legs sprite up so its row 37 (currently transparent) aligns with the body's row 37, and its row 38 (opaque) now occupies the previously-transparent seam row, closing the gap.

## What stays the same

- Body segment positions are unchanged.
- Face sprite position is unchanged.
- `BODY_OFFSET` constant and segment-to-segment stacking are unchanged.
- Sprite images are unchanged (no art edits needed).

## Open questions

None — the fix is a 1-line change to the legs Y positioning in `animal.lua`.

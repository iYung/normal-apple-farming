## Goal

When the player is holding an item, hovering over another entity should still trigger the outline shader on that entity. Currently the outline is suppressed entirely while holding anything.

## Affected files

- `game/entities/player.lua` — the only change needed

## What changes

In `Player:update()` (line 128), the hover-highlight logic is guarded by `if not self.held_item then`. This guard was presumably added to avoid confusing the player about what they're about to pick up, but it has the side-effect of suppressing all outlines — including outlines on breeders and sell bins that the player is about to deposit into.

The fix is to remove the `if not self.held_item then` guard so that `Detector.nearest` runs every frame and highlights the closest entity regardless of holding state. The candidate pool stays the same: all animals + all scene items (which already includes breeders and sell bins, since both live in `scene.items`).

No changes to the outline shader itself, the highlighting method on any entity, or the interaction logic in `_handle_interact`.

## What stays the same

- The outline shader itself (`game/shaders/outline.lua`) is unchanged.
- The `highlight(on)` method on all entities is unchanged.
- The de-highlight reset loop (lines 126–127) still runs every frame to clear stale highlights.
- `_handle_interact` interaction logic is unchanged.
- The candidate pool for Detector.nearest is unchanged (animals + items, which includes breeders and sell bins).

## Open questions

None — the user confirmed the desired behavior: entities the player hovers over should show an outline even when the player is holding something.

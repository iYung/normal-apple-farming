# Wire Placement Hover

## Goal

Show a semi-transparent wire preview ("ghost") at the tile where the player would place wire when they are holding a wire roll. This gives the player clear spatial feedback before committing a placement.

## Affected files

- `game/scenes/game_scene.lua` — preload wire image, add preview draw call

## What changes

**Preload the wire image** in `GameScene:on_enter()` (alongside the existing tileset image load), storing it as `self._wire_preview_img`.

**Draw the preview** in `GameScene:draw()`, inside the `camera:attach()` block, after the background and **before** the Y-sorted entity list. This ensures the ghost renders under the player and any existing wires.

Preview logic:
1. Check `Detector.is_roll(self.player.held_item)` — skip if player isn't holding a wire roll.
2. Calculate target tile: `Mapper.world_to_tile(player.x + player.w/2, player.y + player.h/2)` — identical to what `Roll:use()` does.
3. Check if occupied: `Mapper.get(self.wire_grid, tx, ty)`.
4. Draw `self._wire_preview_img` at `(tx * Mapper.TILE, ty * Mapper.TILE)`, scaled to 48×48 (same as the real wire sprite).
   - Free tile → white tint, alpha 0.5: `setColor(1, 1, 1, 0.5)`
   - Occupied tile → red tint, alpha 0.5: `setColor(1, 0.3, 0.3, 0.5)`
5. Reset color back to `(1, 1, 1, 1)`.

## What stays the same

- `game/items/roll.lua` — placement logic unchanged
- `game/entities/wire.lua` — wire entity unchanged
- `game/systems/mapper.lua` — grid helpers unchanged
- `game/entities/player.lua` — held item system unchanged
- All other scenes, shaders, and UI

## Open questions

None — the approach reuses existing infrastructure with no new abstractions needed.

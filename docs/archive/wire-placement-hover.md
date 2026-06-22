## Wire Placement Hover Checklist

- [x] Task A — `game/scenes/game_scene.lua` — In `on_enter()`, after the background tileset image block (around line 131), load `assets/images/items/wire.png` and store it as `self._wire_preview_img` (guard with `love.filesystem.getInfo` like the tileset load above it)

- [x] Task B — `game/scenes/game_scene.lua` — In `draw()`, after `love.graphics.setColor(1, 1, 1, 1)` (line 231) and before the Y-sort entity block, add a wire placement preview: check `Detector.is_roll(self.player.held_item)`, calculate `tx, ty` via `Mapper.world_to_tile(player.x + player.w/2, player.y + player.h/2)`, check `Mapper.get(self.wire_grid, tx, ty)` for occupancy, then draw `self._wire_preview_img` at `(tx * Mapper.TILE, ty * Mapper.TILE)` scaled to 48×48 with `setColor(1, 1, 1, 0.5)` if free or `setColor(1, 0.3, 0.3, 0.5)` if occupied, then reset color to `(1, 1, 1, 1)`

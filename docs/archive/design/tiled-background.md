# Tiled Background

## Goal
Replace the current single stretched/repeat-wrap background quad in the game
world with a real grid of individually-drawn background tiles, each rendered
at 48x48 world units — matching `assets/images/items/knife.png`'s pixel size
— reusing the existing `assets/images/tileset.png` artwork. Also remove the
flat green fallback rectangle, and bump `WORLD_W` to a multiple of 48 so the
grid divides the world evenly with no partial edge tiles.

## Affected files
- `game/scenes/game_scene.lua` — `WORLD_W` constant, background setup in
  `on_enter`, background drawing in `draw`.
- `game/systems/mapper.lua` — `Mapper.WORLD_W`, a duplicated copy of the same
  world-width constant, used by `Mapper.clamp` (in turn used by
  `game/entities/player.lua` and `game/entities/animal.lua` for world-bounds
  clamping). Must be kept in sync with `game_scene.lua`'s `WORLD_W`.
- `tests/test_mapper.lua` — existing test asserting against world-size
  constants; check/update if it hardcodes 2560.
- New test file, e.g. `tests/test_game_scene_background.lua` — covers the new
  tile-grid setup, following the headless-runner conventions used by
  `tests/test_start_scene.lua` / `tests/test_settings_menu.lua`.

## What changes
- `WORLD_W` changes from `2560` to `2592` (`48 * 54`) in both
  `game_scene.lua` and `mapper.lua` (the two duplicated constants move
  together). `WORLD_H` stays `1440` (`48 * 30`, already evenly divisible by
  48, so no change needed there).
- Background rendering in `GameScene:on_enter` / `GameScene:draw` is reworked:
  - Remove the single `love.graphics.newQuad(0, 0, WORLD_W, WORLD_H, tile,
    tile)` + `setWrap("repeat", "repeat")` trick.
  - In `on_enter`, precompute a grid of tile draw positions spanning the
    world (54 columns x 30 rows of 48x48 tiles) once, rather than
    recomputing it every frame.
  - In `draw`, loop over the precomputed grid and draw `self._bg_img`
    (`tileset.png`) at each tile position, scaled per-draw so each tile
    renders at exactly 48x48 world units (`scale_x = 48 / img:getWidth()`,
    `scale_y = 48 / img:getHeight()`), at full opacity (alpha 1, not the
    current 0.4). This mirrors the existing scaled-draw pattern already used
    for the wire placement preview (`game_scene.lua:257`).
  - Remove the flat green `love.graphics.rectangle("fill", ...)` base layer
    entirely — the tile grid becomes the sole background.
- No change to camera, scrolling, or draw-order behavior — the tile grid
  still draws inside `camera:attach()` / `camera:detach()`, so it pans with
  the world exactly as the old background did.

## What stays the same
- `assets/images/tileset.png` stays as the source art; it is not replaced or
  edited as a binary asset — only how it's drawn changes (repeated grid of
  scaled draws instead of one stretched/wrapped quad).
- Camera, entity y-sorting, HUD, wire-placement preview, and music
  cross-fading are untouched.
- `Mapper.TILE` (32, used for wire-grid snapping/placement) is a separate,
  unrelated grid — only `Mapper.WORLD_W`/`Mapper.WORLD_H` (world bounds) are
  touched by this change, not the wire-placement tile size.

## Open questions
None outstanding — resolved with the user before writing this doc:
- Tile artwork: reuse existing `tileset.png`, drawn as a real 48x48 grid
  (not a new asset).
- World sizing: bump `WORLD_W` to 2592 (multiple of 48) rather than clipping
  a partial edge column.
- Base layer: remove the flat green rectangle entirely; the tile grid is the
  sole background.

## Tiled Background Checklist

- [x] Task A — `game/scenes/game_scene.lua` — Three related changes, all in this one file (keep them together so no other task edits this file concurrently):
  1. Line ~29: change `local WORLD_W = 2560` to `local WORLD_W = 2592` (`WORLD_H` on line 30 stays `1440`, unchanged).
  2. In `GameScene:on_enter` (currently lines ~124-132), replace the background-tileset block:
     ```lua
     -- Background tileset
     if love.filesystem.getInfo("assets/images/tileset.png") then
         local img = love.graphics.newImage("assets/images/tileset.png")
         img:setWrap("repeat", "repeat")
         local tile = img:getWidth()
         local quad = love.graphics.newQuad(0, 0, WORLD_W, WORLD_H, tile, tile)
         self._bg_img  = img
         self._bg_quad = quad
     end
     ```
     with a version that precomputes a grid of 48x48 tile positions once (no `setWrap`, no `newQuad`, no `self._bg_quad`):
     ```lua
     -- Background tileset: precompute a grid of 48x48 tile positions spanning
     -- the world (54 columns x 30 rows), drawn individually in draw().
     if love.filesystem.getInfo("assets/images/tileset.png") then
         self._bg_img = love.graphics.newImage("assets/images/tileset.png")
         self._bg_tiles = {}
         local cols = WORLD_W / 48
         local rows = WORLD_H / 48
         for row = 0, rows - 1 do
             for col = 0, cols - 1 do
                 table.insert(self._bg_tiles, { x = col * 48, y = row * 48 })
             end
         end
     end
     ```
     `self._bg_tiles` must end up with exactly 54 * 30 = 1620 entries once `WORLD_W` is 2592.
  3. In `GameScene:draw` (currently lines ~238-245), replace:
     ```lua
     -- Background
     love.graphics.setColor(0.25, 0.55, 0.2, 1)
     love.graphics.rectangle("fill", 0, 0, WORLD_W, WORLD_H)
     if self._bg_img then
         love.graphics.setColor(1, 1, 1, 0.4)
         love.graphics.draw(self._bg_img, self._bg_quad, 0, 0)
     end
     love.graphics.setColor(1, 1, 1, 1)
     ```
     with a version that removes the green fill rectangle entirely and loops over `self._bg_tiles`, drawing `self._bg_img` at each position scaled to exactly 48x48, at full opacity (no alpha 0.4):
     ```lua
     -- Background: draw each precomputed 48x48 tile individually, full opacity.
     if self._bg_img and self._bg_tiles then
         local scale_x = 48 / self._bg_img:getWidth()
         local scale_y = 48 / self._bg_img:getHeight()
         for _, t in ipairs(self._bg_tiles) do
             love.graphics.draw(self._bg_img, t.x, t.y, 0, scale_x, scale_y)
         end
     end
     ```
     Leave everything else in `draw` (wire placement preview, y-sorted entity loop, HUD) untouched — this block sits directly inside `camera:attach()`/`camera:detach()` exactly as the old block did, so panning behavior is unaffected.
  - Self-verify: run `love . --headless tests/test_wire_placement_hover.lua` and `love . --headless tests/test_y_sort.lua` (both construct/draw a real `GameScene` via `lua/headless/runner.lua`) and confirm they still print `ALL TESTS PASSED` — these exercise `draw()` and would fail loudly on a typo (e.g. a nil `self._bg_tiles` crashing the loop, since `love.filesystem.getInfo` returns `nil` in headless mode so `self._bg_img`/`self._bg_tiles` are simply never set there, which the loop already guards against with `if self._bg_img and self._bg_tiles`).

- [x] Task B — `game/systems/mapper.lua` — Line ~27: change `Mapper.WORLD_W = 2560` to `Mapper.WORLD_W = 2592` (`Mapper.WORLD_H` on the next line stays `1440`, unchanged). This constant is a duplicate of `game_scene.lua`'s `WORLD_W` (used by `Mapper.clamp`, called from `game/entities/player.lua` and `game/entities/animal.lua` for world-bounds clamping) and must carry the same value, 2592, as Task A — but this is a separate file with no code overlap, so it can be done independently/in parallel with Task A. Self-verify: run `love . --headless tests/test_mapper.lua` and confirm it prints `ALL TESTS PASSED` (it already asserts against `Mapper.WORLD_W`/`Mapper.WORLD_H` symbolically rather than hardcoding `2560`/`1440`, so no test edits are expected — just confirm it still passes with the new value).

- [x] Task C — `tests/test_mapper.lua` — Depends on Task B being complete first (needs the bumped `Mapper.WORLD_W` in place to verify against). Read the file and confirm there is no hardcoded `2560` or `1440` literal anywhere (as of writing, the clamp-edge assertions on lines ~36-37 already reference `Mapper.WORLD_W - 32 - 32` and `Mapper.WORLD_H - 32 - 32` symbolically, not literal numbers). If you find any hardcoded `2560`/`1440` literal, replace it with `Mapper.WORLD_W`/`Mapper.WORLD_H` respectively. Run `love . --headless tests/test_mapper.lua` and confirm `ALL TESTS PASSED`. If no hardcoded literals are found, no file edit is needed — just check this task off after confirming the test is green.

- [x] Task D — `tests/test_game_scene_background.lua` (new file) — Depends on Task A being complete first (this test asserts on fields/constants Task A creates: `WORLD_W`, `self._bg_tiles`, and the removal of `self._bg_quad`/the green-rectangle code path). Create a new headless test file following the `lua/headless/runner.lua` construction pattern used by `tests/test_wire_placement_hover.lua` (i.e. `local runner = require("lua/headless/runner")`, `local ctx = runner.setup(function(input, sm) return require("game/scenes/game_scene").new() end)`, then `local scene = ctx.sm.current`; `on_enter` runs automatically as part of `sm:switch`). Note that `love.filesystem.getInfo` always returns `nil` under the headless stub (`lua/headless/stubs.lua:69`), so `scene._bg_img`/`scene._bg_tiles` will be `nil` after a real `on_enter` in headless mode — for the grid-content assertions, inject a fake image directly (same trick as `test_wire_placement_hover.lua`'s `fake_img`) and call `scene:on_enter()`-equivalent grid-building logic, OR (simpler and preferred) just assert directly on what's testable without needing the image to have loaded:
  - Load `game/scenes/game_scene.lua`'s module and confirm `WORLD_W` is 2592 — since `WORLD_W` is a file-local constant not exported on the module table, assert this indirectly: spawn the scene via `runner.setup`, read `scene.player`/`scene.camera` position math that depends on `WORLD_W` (e.g. `bx, by = WORLD_W/2 - 300, WORLD_H/2` used for the Breeder fixture — assert the breeder's `x` equals `2592/2 - 300`), OR simply grep-assert the source text of `game/scenes/game_scene.lua` contains `WORLD_W = 2592` and does not contain `WORLD_W = 2560` (use `love.filesystem.read` or plain Lua `io.open` to read the file and pattern-match — follow whichever file-reading approach `tests/test_sway_shader.lua` or similar source-inspecting tests in this repo use, if any exist; otherwise `io.open("game/scenes/game_scene.lua"):read("*a")` is fine in this headless test environment).
  - After manually setting `scene._bg_img = { getWidth = function() return 48 end, getHeight = function() return 48 end }` and manually invoking the same grid-building logic as `on_enter` (or, simpler, temporarily monkey-patching `love.filesystem.getInfo` to return a truthy value before constructing the scene via `runner.setup`, then restoring it), assert `scene._bg_tiles` is a table with exactly `54 * 30 = 1620` entries, that the first entry is `{x=0, y=0}`, that the last entry is `{x=53*48, y=29*48}` (i.e. `{x=2544, y=1392}`), and that every entry's `x`/`y` are multiples of 48 within `[0, WORLD_W)` / `[0, WORLD_H)`.
  - Assert `scene._bg_quad` is `nil` (the old quad field must no longer be set).
  - Call `scene:draw()` with `love.graphics.setColor`/`love.graphics.rectangle` monkey-patched (same pattern as `test_wire_placement_hover.lua`'s `capture_preview`) to assert `rectangle("fill", ...)` is never called with the old green color `(0.25, 0.55, 0.2, ...)` — i.e. the flat green background fill is gone.
  - Follow this repo's plain-Lua `assert(...)` + `print("PASS: <name>")` per-check style, ending with `print("ALL TESTS PASSED")` (see `tests/test_mapper.lua` and `tests/test_wire_placement_hover.lua` for the exact convention).
  - Self-verify: run `love . --headless tests/test_game_scene_background.lua` and confirm it prints `ALL TESTS PASSED`.

- [x] Task E — Final verification (no file changes) — Depends on Tasks A, B, C, and D all being checked off first. Run the full suite with `love . --headless` (no test-file argument runs every file under `tests/`) and confirm the summary line reads `N/N passed` with no `FAIL` lines, where `N` is the total test file count. If anything fails, do not patch it here — send it back to the relevant task (A/B/C/D) to fix. Once green, check off this task.

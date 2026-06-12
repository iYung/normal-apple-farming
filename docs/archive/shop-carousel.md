## Shop Carousel Checklist

- [x] Task A — `assets/images/shop/`, `assets/fonts/`, `assets/shaders/` — Copy wip assets into the project. Copy these files from `/root/wip/assets/`:
  - `images/buy_bg.png`       → `assets/images/shop/buy_bg.png`
  - `images/arrow_left.png`   → `assets/images/shop/arrow_left.png`
  - `images/arrow_right.png`  → `assets/images/shop/arrow_right.png`
  - `images/dot_active.png`   → `assets/images/shop/dot_active.png`
  - `images/dot_inactive.png` → `assets/images/shop/dot_inactive.png`
  - `images/coin.png`         → `assets/images/shop/coin.png`
  - `images/speech_bubble.png`→ `assets/images/shop/speech_bubble.png`
  - `fonts/font.ttf`          → `assets/fonts/font.ttf`
  - `shaders/crt.glsl`        → `assets/shaders/crt.glsl`
  Create `assets/fonts/` and `assets/shaders/` directories if they don't exist.

- [x] Task B — `game/shaders/crt.lua` — Create a new file. It wraps `core/lua/shader` to load and apply `assets/shaders/crt.glsl`. Exports a table `{ apply = fn, clear = fn }` where `apply` calls `love.graphics.setShader(shader)` and `clear` calls `love.graphics.setShader()`. The shader is loaded at module load time (not lazily).

- [x] Task C — `game/ui.lua` — Create a new file with two exported functions, adapted from `/root/wip/lua/game/ui.lua`:
  - `draw_hud_box(labels, font, margin)` — draws a 9-patch speech bubble box at the bottom-left corner sized to fit the label strings, using `assets/images/shop/speech_bubble.png` with 12px margins on all sides.
  - `draw_currency_bubble(currency, x, y, font)` — draws a 9-patch speech bubble with a 32px coin icon + currency number at position (x, y), using `assets/images/shop/coin.png` and `assets/images/shop/speech_bubble.png`.
  Both functions load their images with `love.graphics.newImage` at module load time. The 9-patch draw helper should be local to the file.

- [x] Task D — `game/scenes/shop_scene.lua` — Rewrite the shop scene to carousel style. This task depends on Tasks A, B, and C being complete. Changes:
  1. Add `image` fields to CATALOGUE entries:
     - Wire Roll → `love.graphics.newImage("assets/images/items/wire_roll.png")`
     - Knife      → `love.graphics.newImage("assets/images/items/knife.png")`
     - Breeder    → `love.graphics.newImage("assets/images/breeder/love_bin.png")`
  2. At the top of the file, require `game/shaders/crt` and `game/ui`, and load fonts using `core/lua/fonts`:
     - `font_name`  = 32px from `assets/fonts/font.ttf`
     - `font_desc`  = 20px from `assets/fonts/font.ttf`
     - `font_price` = 26px from `assets/fonts/font.ttf`
     - `font_ui`    = 16px from `assets/fonts/font.ttf`
  3. In `ShopScene.new`, create `self.canvas = love.graphics.newCanvas(1280, 720)`.
  4. Replace `draw()` entirely with carousel layout:
     - Render to `self.canvas` (clear to black): draw `buy_bg.png` full-screen, then for `CATALOGUE[self.selected]` only: scale the item `image` to fit a 160×160 preview centered at (640, y_start), draw item name with `font_name` centered, draw description lines with `font_desc` centered, draw price with coin icon + number using `font_price` (green if affordable, red if not; "Free" text centered if cost == 0 with no coin icon).
     - Draw `arrow_left.png` at (640 - 230 - 30, 360 - 30) and `arrow_right.png` at (640 + 230 - 30, 360 - 30).
     - Draw dot row centered at x=640, y=612: `dot_active.png` for selected index, `dot_inactive.png` for others, spaced 22px apart.
     - Blit canvas with CRT shader: `CRT.apply()`, draw canvas, `CRT.clear()`.
     - After blit, draw HUD unshaded: `UI.draw_currency_bubble(self.game_state.money, 10, 10, font_ui)`, then `UI.draw_hud_box({"← →  Cycle", "E  Buy", "S  Close"}, font_ui, 10)`.
  5. Remove all old constants (PANEL_W, PANEL_H, PANEL_X, PANEL_Y, CARD_W, etc.) that are no longer used.

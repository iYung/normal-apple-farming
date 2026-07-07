## Shop HUD Checklist

- [x] Task A — `game/scenes/shop_scene.lua` — require `MoneyInfo` and `ui` at the top; instantiate `self.money_info = MoneyInfo.new(game_state)` in `ShopScene.new()`
- [x] Task B — `game/scenes/shop_scene.lua` — add a local `key_label` helper with `_KEY_DISPLAY` normalization; after `CRT.clear()` in `ShopScene:draw()`, call `self.money_info:draw()` and draw the controls hint via `ui.draw_hud_box` — all key labels must come from `self.input:key_for(action)`, none hardcoded

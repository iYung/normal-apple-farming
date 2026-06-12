## Settings Menu Checklist

- [x] Task A — `assets/images/` — Copy `menu_btn.png` and `menu_btn_selected.png` from `/root/wip/assets/images/` into `assets/images/`. No code changes.

- [x] Task B — `core/lua/save.lua` — Create new file. Copy `/root/wip/lua/core/save.lua` verbatim (keep the full file including game-save functions; they're unused but harmless and consistent with wip). The only adaptation: update the require path comment if present.

- [x] Task C — `game/fonts.lua` — Create new file. Single line: `return require("core/lua/fonts").from("assets/font.ttf", "light")`. This gives the settings menu a `Fonts.new(size)` factory bound to the project's existing font.

- [x] Task D — `game/settings_state.lua` — Create new file. Port from `/root/wip/lua/game/settings_state.lua` with these changes: remove the `local Sound = require(...)` line; remove `sfx_volume` and `music_volume` fields, their defaults, `set_sfx_volume`, and `set_music_volume` methods; remove those fields from `to_save` and `from_save`. Keep: `fullscreen`, `keybinds`, `toggle_fullscreen`, `set_keybind`, `key_map`, `to_save`, `from_save`.

- [x] Task E — `game/scenes/settings_menu.lua` — Create new file. Port from `/root/wip/lua/game/scenes/settings_menu.lua` with these changes:
  - Update require paths: `local Fonts = require("game/fonts")` (not `lua/game/fonts`)
  - Remove animated background images (`_img_bgs`, `_bg_frame`, `_bg_timer`) — the menu is always non-opaque (overlay), never opaque
  - Change `ITEMS` to `{ "Fullscreen / Window", "Keybinds", "Exit Settings", "Quit to Desktop" }`
  - Remove the `opaque` parameter from `open()` — always behave as non-opaque
  - Remove the `on_save` and `on_leave` constructor params — `_confirm()` calls `love.event.quit()` directly for item 4
  - Remove all `if self._opaque` branches in `update` and `draw`
  - Remove volume slider logic (items 2 and 3 in wip) — the left/right handlers and their draw branches
  - Update `_confirm()` for the new item indices: 1=toggle_fullscreen, 2=open keybinds subscreen, 3=close+save, 4=quit
  - Item 3 (Exit Settings) calls `self:close()` and then saves via a `self._on_close` callback passed in from `main.lua`
  - `update` bg timer can be removed since there's no animated background
  - Keep keybinds subscreen logic entirely intact

- [x] Task F — `main.lua` — Modify to wire in settings. Add requires for `Save`, `SettingsState`, `SettingsMenu` at top. In `love.load`: load settings state (`Save.settings_exist() and SettingsState.from_save(Save.read_settings()) or SettingsState.new()`), apply keybinds to `input._map` (`ss:key_map()`), construct `SettingsMenu.new(ss, input, on_close_cb)` where `on_close_cb` calls `Save.write_settings(ss:to_save())`. In `love.update`: if `settings_menu.is_open` call `settings_menu:update(dt)`. In `love.draw`: after `manager:draw()` but before canvas blit, if `settings_menu.is_open` call `settings_menu:draw()`. Add `love.keypressed` handler: pass key to `settings_menu:keypressed(key)` first (returns true if consumed); if key == "escape" and settings not open, call `settings_menu:open()`; remove the old `love.event.quit()` on escape. Note: `input` must be constructed in `love.load` (currently it isn't — GameScene constructs its own). See note below.

- [x] Task G — `scripts/build_web.sh` — Modify the IndexedDB sync condition to cover both files. Change `'if(p&&p.indexOf("save.dat")!==-1){'` to `'if(p&&(p.indexOf("save.dat")!==-1||p.indexOf("settings.dat")!==-1)){'`.

---

### Implementation note for Task F

`Input` is constructed inside `Player.new()` (`game/entities/player.lua:26`) with a hardcoded key map. For keybind changes from the settings menu to take effect immediately, the settings menu needs a reference to that same `Input` instance.

The approach: change `Player.new(x, y)` to accept an optional `input` parameter — if provided, use it; otherwise construct the default. In `GameScene`, construct `Input` before `Player` and pass it in, then expose it as `game_scene.input`. In `main.lua`, after `manager:switch(GameScene.new(...))`, read `manager.current.input` to pass to `SettingsMenu`. This keeps changes minimal and localised to three files: `player.lua`, `game_scene.lua`, and `main.lua`.

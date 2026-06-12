## Goal

Add a settings menu to normal-apple-farming, ported from `../wip`, exposing fullscreen toggle and keybind remapping. Settings persist to disk. ESC during gameplay opens/closes the menu instead of quitting.

## Affected files

| File | Status |
|------|--------|
| `main.lua` | Modify — wire settings init, ESC toggle, update/draw/keypressed |
| `core/lua/save.lua` | New — copy from wip; handles `settings.dat` read/write |
| `game/settings_state.lua` | New — slimmed from wip; fullscreen + keybinds only (no volume) |
| `game/scenes/settings_menu.lua` | New — ported from wip; 4 items, always non-opaque overlay |
| `game/fonts.lua` | New — font factory wrapper pointing at `assets/font.ttf` |
| `assets/images/menu_btn.png` | Copy from wip |
| `assets/images/menu_btn_selected.png` | Copy from wip |

## What changes

**ESC key** — currently calls `love.event.quit()`. Changed to toggle the settings menu open/closed. The menu itself handles ESC-to-close internally. A "Quit to Desktop" button in the menu replaces the old ESC quit path.

**Settings menu** — a `SettingsMenu` object lives in `main.lua` (not inside any scene). It draws as a semi-transparent black overlay over whatever scene is active. Menu items:

1. **Fullscreen / Window** — toggles `love.window.setFullscreen`
2. **Keybinds** — opens a subscreen to rebind move_up, move_down, move_left, move_right, interact; blocks return until all 5 are bound
3. **Exit Settings** — closes the menu; settings auto-saved on close
4. **Quit to Desktop** — calls `love.event.quit()`

**SettingsState** — holds `fullscreen` (bool) and `keybinds` (table). Serialized to `settings.dat` via `love.filesystem`. Loaded at startup; if the file is absent, defaults are used (WASD + space, windowed).

**Input wiring** — after any keybind change, `input._map` is replaced with `settings_state:key_map()`, exactly as wip does. This takes effect immediately for all scenes without any scene restarts.

**Save-on-close** — settings are written to `settings.dat` when the menu closes (Exit Settings or Quit). Not on every keystroke.

## What stays the same

- `GameScene`, `ShopScene`, `SceneManager` — untouched
- `core/lua/input.lua` — `_map` is already a mutable field; no changes needed
- All existing gameplay keybind defaults (WASD + space/E for interact)
- No volume controls (game has audio but user scoped this out)
- No save-game button (no game save system exists in this project)

## Web compatibility

`love.filesystem` works on web via IndexedDB, but `build_web.sh` patches love.js to sync writes immediately and currently only watches for `save.dat`. The patch condition must be updated to also match `settings.dat`.

| File | Change |
|------|--------|
| `scripts/build_web.sh` | Modify — broaden the IndexedDB sync condition from `save.dat` to also cover `settings.dat` |

## Open questions

None — resolved with user:
- Scope: fullscreen toggle + keybinds only
- Persistence: yes, `settings.dat`
- Trigger: ESC key
- Assets: copy button images from wip

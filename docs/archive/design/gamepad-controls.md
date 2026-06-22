# Gamepad Controls

## Goal

Port gamepad support from `../wip` so players can use a controller. All gameplay actions and menu navigation should work without a keyboard.

## Affected files

- `core/lua/input.lua` — add gamepad polling, mode tracking, `key_for`, `icon_key_for`
- `main.lua` — create shared Input, call `input:update()` from main loop, add joystick callbacks, propagate `_mode` on keypressed
- `game/scenes/start_scene.lua` — accept shared input, update start prompt via `key_for`
- `game/scenes/game_scene.lua` — accept shared input instead of creating its own
- `game/scenes/shop_scene.lua` — accept shared input; rename `left`/`right` actions to `move_left`/`move_right`; use `cancel` for exit
- `game/scenes/book_scene.lua` — accept shared input
- `game/entities/player.lua` — remove `self.input:update()` call (main loop owns it now)
- `game/scenes/settings_menu.lua` — add gamepad navigation via `_joy_nav`, `gamepadpressed`, hide Keybinds in gamepad mode
- `game/ui/actions_info.lua` — accept `input` object; use `input:key_for()` instead of raw keybinds table
- `tests/test_input.lua` (new) — port gamepad unit tests from wip

## What changes

### 1. `core/lua/input.lua`

Add to existing keyboard-only `Input`:

- `_mode = "keyboard"` | `"gamepad"` field
- `_joystick = nil` field (Love2D joystick object)
- Gamepad polling inside `update()`: left stick (threshold ±0.3) + D-pad for movement; A/Y/B buttons for interact/pickup/cancel
- Auto-switch `_mode` to `"gamepad"` when any gamepad input is detected
- `key_for(action)` — returns gamepad symbol (e.g. `"[A]"`, `"↑"`) in gamepad mode, or first keyboard key in keyboard mode
- `icon_key_for(action)` — returns asset key (e.g. `"btn_a"`) in gamepad mode, nil in keyboard mode

NAF-specific button mapping (differs from wip because action names differ):

| Action      | Gamepad button | PAD label | Icon key |
|-------------|---------------|-----------|----------|
| move_up     | D-pad up / left-stick up | `↑` | — |
| move_down   | D-pad down / left-stick down | `↓` | — |
| move_left   | D-pad left / left-stick left | `←` | — |
| move_right  | D-pad right / left-stick right | `→` | — |
| interact    | A | `[A]` | `btn_a` |
| pickup      | Y | `[Y]` | `btn_y` |
| cancel      | B | `[B]` | `btn_b` |

### 2. `main.lua` — single shared Input

- Create one `Input` object with the full action map (movement + interact + pickup + cancel)
- `cancel` is hardcoded to `{"escape"}` on keyboard; the configurable keybinds from `settings_state` override movement/interact/pickup but not cancel
- When applying keybinds after a bind change, preserve the cancel binding
- Call `input:update()` in the main `love.update` else-branch (before `manager:update`)
- Add `love.joystickadded` → set `input._joystick` if first gamepad
- Add `love.joystickremoved` → clear and find next connected gamepad
- Add `love.gamepadpressed` → set `input._joystick` + `input._mode = "gamepad"`; poll Start button to open settings
- In `love.keypressed` → set `input._mode = "keyboard"` before routing to settings/scene
- Pass `input` to `StartScene.new(...)`

### 3. Scene constructors accept shared input

Each scene that previously created `Input.new(...)` internally now receives `input` as a constructor parameter:

- `StartScene.new(scene_manager, settings_state, input)`
- `GameScene.new(scene_manager, settings_state, input)`
- `ShopScene.new(game_state, scene_manager, game_scene, input)`
- `BookScene.new(game_scene, scene_manager, input)`

Scenes do NOT call `input:update()` — main.lua owns that.

### 4. `player.lua`

- Remove `self.input:update()` from `Player:update(dt, scene)` — main loop handles it
- Remove the fallback `Input.new({...})` default — always expects input passed in

### 5. `shop_scene.lua`

- Action rename: `left` → `move_left`, `right` → `move_right`
- Cancel: check `input:pressed("cancel")` (escape/B) OR `input:pressed("move_down")` as keyboard fallback (preserves existing muscle memory)
- Skip-frame guard stays

### 6. `settings_menu.lua`

- Add `_joy_nav(input)` helper that reads joystick axes + buttons (up/down/left/right/confirm)
- In `update()`, OR gamepad nav results into the keyboard checks (same pattern as wip)
- Add `gamepadpressed(button)` method — Start button acts as escape (close menu / exit sub-screen / cancel capture)
- Menu item visibility: hide "Keybinds" when `input._mode == "gamepad"` (gamepad layout is fixed)
- Snapshot gamepad state in `open()` to prevent ghost-fire on open frame

### 7. `actions_info.lua`

- Constructor receives `input` object instead of `keybinds` table
- Use `input:key_for("pickup")` and `input:key_for("interact")` to build label strings
- In gamepad mode, these return `[Y]` and `[A]`; in keyboard mode, the configured key

### 8. `tests/test_input.lua` (new)

Port from wip, adjusted for NAF action names:

- `key_for` returns keyboard key in keyboard mode
- `key_for` returns gamepad labels in gamepad mode (↑↓←→ [A] [Y] [B])
- Joystick A button drives `interact` _down and _pressed
- Left-stick Y axis drives `move_up` / `move_down`
- `_mode` auto-switches to `"gamepad"` on first gamepad input
- Disconnected joystick is ignored
- Ghost-interact prevention via priming update
- `icon_key_for` returns nil in keyboard mode, asset keys in gamepad mode

## What stays the same

- Keybind persistence and `SettingsState` — only adds `cancel` is not user-configurable (not stored)
- All gameplay logic in `player.lua`, `game_scene.lua`, `shop_scene.lua`, `book_scene.lua`
- Escape still opens the settings menu (now also sets `input._mode = "keyboard"`)
- `love.keyboard.isDown` polling for settings menu navigation stays as-is (settings doesn't go through `Input:update`)

## Open questions

None — user confirmed: single shared input, cancel action (escape + B), hide Keybinds in gamepad mode.

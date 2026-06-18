## HUD Keybind Labels Checklist

- [x] Task A — `game/ui/actions_info.lua` — Accept an optional `keybinds` table in `ActionsInfo.new()`, store it as `self._keybinds`. Add a module-local helper `key_label(keybinds, action)` that returns e.g. `"[E]"` by uppercasing `keybinds[action]` (falling back to the action name if nil). Replace all hardcoded `"[E]"` and `"[O]"` strings in `draw()` with calls to this helper: use `"interact"` for the Interact hint and both wire hints, and use `"pickup"` for the Drop and Pick-up hints.

- [x] Task B — `game/scenes/game_scene.lua` and `main.lua` — Change `GameScene.new(manager)` to accept a second argument `settings_state` and pass `settings_state.keybinds` to `ActionsInfo.new()`. In `main.lua`, update the call from `GameScene.new(manager)` to `GameScene.new(manager, ss)`.

- [x] Task C — `tests/test_hud_ui.lua` — Update the existing `ActionsInfo` tests to pass a keybinds table (`{interact="e", pickup="f"}`) to `ActionsInfo.new()`. Add assertions that verify the correct key labels appear in the rendered hint string for: (a) nothing held/nearby → interact key shown, (b) held roll → interact key for wire hint and pickup key for drop hint, (c) held knife → interact key for remove-wires hint and pickup key for drop hint, (d) nearby entity → pickup key for pick-up hint.

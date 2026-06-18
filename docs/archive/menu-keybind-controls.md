## Menu Keybind Controls Checklist

- [x] Task A — `game/settings_state.lua` — Remove the conflict-clearing loop from `set_keybind`. Replace the whole function body (lines 17–22) with a single assignment: `self.keybinds[action] = key`. The menu layer now rejects conflicts before they reach this function, so no clearing is needed.

- [x] Task B — `tests/test_settings_state.lua` — Update test 4 ("set_keybind displaces conflict"). Remove the assertion that `move_down` becomes nil after binding `move_up` to `"s"`. Replace with an assertion that `set_keybind` does NOT touch other actions: after `s4:set_keybind("move_up", "s")`, assert `s4.keybinds.move_up == "s"` and `s4.keybinds.move_down == "s"` (the conflict is still there — rejection is the menu's job, not settings_state's). Update the print label to match.

- [x] Task C — `game/scenes/settings_menu.lua` — Three sub-changes, all in the same file:

  1. **Remove hardcoded `space` from confirm** — In `open()` (line 74–75), `update()` main screen (lines 92–93, 128–129), `update()` subscreen (line 92), and `_confirm()` snapshot (lines 162–163): remove every bare `or love.keyboard.isDown("space")`. The confirm line should become just `love.keyboard.isDown(kb.interact or "e") or love.keyboard.isDown("return")` (keep `"return"`, drop extra `"space"`).

  2. **Add shake state** — In `SettingsMenu.new()`, add `self._shake_row = nil` and `self._shake_timer = 0`. In `update()`, at the top of the function (before subscreen check), tick down `_shake_timer` by dt (clamp to 0) and clear `_shake_row` when it reaches 0.

  3. **Conflict rejection + shake rendering** — In `keypressed()`, before calling `self._state:set_keybind(...)`, loop `_ACTION_LIST` and check if any other action already holds the pressed key. If so, set `self._shake_row = i` (index of conflicting row) and `self._shake_timer = 0.5`, then return `true` without applying. In `draw()` keybinds subscreen loop, compute `ox` and `row_r/g/b` per row: if `self._shake_row == i and self._shake_timer > 0` then `ox = math.sin(self._shake_timer * 40) * 8 * (self._shake_timer / 0.5)` and `row_r, row_g, row_b = 1, 0.25, 0.25`, else `ox = 0` and colour `1, 1, 1`. Apply `ox` to both the label bar and value bar x positions, and `row_r/g/b` as the draw colour for both bars.

## Goal

Two related improvements to the settings menu keybind system:

1. **Remove hardcoded `space` from menu navigation** — menu confirm should only respond to the game's mapped `interact` key (plus `return` as a universal fallback and arrow keys for directional nav). Currently `space` is always OR'd in as a permanent confirm trigger, meaning remapping interact doesn't stop space from working.

2. **Reject conflicting keybinds** — instead of silently stealing a key from another action (leaving it unbound), show a red shake animation on the already-bound row and refuse the change. Ported from `../wip`.

## Affected files

- `game/scenes/settings_menu.lua` — navigation logic and rendering
- `game/settings_state.lua` — `set_keybind` conflict-clearing behavior
- `tests/test_settings_state.lua` — test 4 asserts the old displacement behavior

## What changes

### `game/scenes/settings_menu.lua`

**Navigation (main screen and keybinds subscreen):**

Remove all bare `love.keyboard.isDown("space")` fallbacks from the `confirm` line. New pattern:

```lua
local confirm = love.keyboard.isDown(kb.interact or "e")
             or love.keyboard.isDown("return")
```

Arrow keys (`"up"` / `"down"`) remain as directional nav fallbacks — they are not gameplay keys and are always safe.

**Conflict rejection in `keypressed`:**

Before calling `self._state:set_keybind`, iterate `_ACTION_LIST` and check if any *other* action already holds the pressed key. If so, record `_shake_row` (the index of the conflicting row) and `_shake_timer = 0.5`, then return without applying. Exact logic from `../wip/lua/game/scenes/settings_menu.lua` lines 319–326.

**Shake state:**

Add `_shake_row` and `_shake_timer` fields (init to `nil` / `0` in `new()`). Tick `_shake_timer` down in `update()` and clear `_shake_row` when it hits 0.

**Shake rendering in `draw()`:**

For each row `i` in the keybinds subscreen, if `_shake_row == i` and `_shake_timer > 0`:
- `ox = math.sin(self._shake_timer * 40) * 8 * (self._shake_timer / 0.5)` (horizontal displacement)
- `row_r, row_g, row_b = 1, 0.25, 0.25` (red tint)

Exact copy from `../wip/lua/game/scenes/settings_menu.lua` lines 353–358.

### `game/settings_state.lua`

Remove the conflict-clearing loop from `set_keybind`. Since the menu layer now rejects conflicts before they reach `set_keybind`, there's nothing to clear — the function becomes a simple assignment:

```lua
function SettingsState:set_keybind(action, key)
    self.keybinds[action] = key
end
```

### `tests/test_settings_state.lua`

Update test 4 ("set_keybind displaces conflict") — it currently asserts that the displaced action becomes nil. Since `set_keybind` no longer clears conflicts, rewrite the test to assert that `set_keybind` is a clean assignment and does NOT affect other actions.

## What stays the same

- `"escape"` is still hardcoded for cancel/back (not a gameplay key, safe to keep)
- `"return"` is kept as a universal confirm fallback
- Arrow keys remain as directional nav fallbacks in the main settings screen
- `_all_bound` guard: player still can't close keybinds subscreen until all actions are bound
- `from_save` keybind loading, `key_map()` format, and save/load round-trip are unchanged

## Open questions

None — all design decisions confirmed with user.

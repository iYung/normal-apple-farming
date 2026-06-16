## Goal

Fix the bottom-left HUD so the key labels it displays match the actual bound keys, and stay correct when the player remaps keys in the settings menu.

## Affected files

- `game/ui/actions_info.lua` — builds and draws the HUD text; hardcodes `[E]` and `[O]`
- `game/scenes/game_scene.lua` — creates `ActionsInfo.new()` and updates it each frame
- `main.lua` — owns `SettingsState` and wires it into the input system

## What changes

### 1. Two wrong labels in `actions_info.lua`

Current label → correct label (and why):

| Current | Correct | Reason |
|---|---|---|
| `[E] Drop` | `[<pickup>] Drop` | Drop is triggered by `input:pressed("pickup")` (default `f`) |
| `[E] Pick up <name>` | `[<pickup>] Pick up <name>` | Pick up is also the `pickup` action |
| `[E] Interact` | `[<interact>] Interact` | Correct action, but should read from keybinds not be hardcoded |
| `[O] Place wire` | `[<interact>] Place wire` | `held_item:use()` fires on `input:is_down("interact")` — no `o` keybind exists |
| `[O] Remove wires` | `[<interact>] Remove wires` | Same as above |

### 2. `ActionsInfo` reads live keybinds

`ActionsInfo.new()` gains an optional `keybinds` parameter (a reference to `settings_state.keybinds`). In `draw()`, replace all hardcoded `"[E]"` / `"[O]"` with a helper that upcases the bound key and wraps it in brackets:

```lua
local function key_label(keybinds, action)
    local k = keybinds and keybinds[action] or action
    return "[" .. k:upper() .. "]"
end
```

Because Lua tables are passed by reference, the HUD automatically reflects any mid-session rebind without extra wiring.

### 3. `game_scene.lua` passes keybinds to `ActionsInfo`

`game_scene.lua` currently builds `Input.new({...})` with hardcoded keys, but `main.lua` overwrites `input._map` from `settings_state` immediately after. `GameScene.new()` needs a `settings_state` (or just `settings_state.keybinds`) so it can hand it to `ActionsInfo`.

Change `GameScene.new(manager)` → `GameScene.new(manager, settings_state)`.
Change `ActionsInfo.new()` → `ActionsInfo.new(settings_state.keybinds)`.

In `main.lua`, update the call: `GameScene.new(manager, ss)`.

## What stays the same

- All game logic — no changes to `player.lua`, `input.lua`, or any item/entity files
- The settings menu and keybind remapping flow
- The visual layout and styling of the HUD box
- The conditions under which each hint is shown (held vs. nearby vs. nothing)

## Open questions

None — the action-to-key mapping is unambiguous from reading `player.lua:110-118`.

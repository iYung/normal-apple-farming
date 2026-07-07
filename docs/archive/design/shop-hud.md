## Goal

Add the top-left money HUD and the bottom-left controls HUD to the store scene, matching the visual style already used in the game scene.

## Affected files

- `game/scenes/shop_scene.lua` — only file that needs to change

## What changes

Both HUDs are drawn **in screen space after `CRT.clear()`** (line 204 of `shop_scene.lua`), so they appear on top of the CRT-filtered canvas, consistent with how `GameScene` draws its HUDs after `camera:detach()`.

### Money HUD (top-left, 16, 16)

Require `MoneyInfo` and instantiate `self.money_info = MoneyInfo.new(game_state)` in `ShopScene.new()`. Call `self.money_info:draw()` after `CRT.clear()`. This draws the same speech-bubble panel + `"$N"` text that appears in the game scene, at the same fixed (16, 16) position.

### Controls HUD (bottom-left)

Build a hint string by reading key labels **directly from `self.input:key_for(action)`** for every action — do not hardcode key names like `"A"`, `"Esc"`, etc. This ensures the hint stays correct if the input map changes and produces the right labels in gamepad mode automatically.

A local `key_label` helper normalizes raw LÖVE key names before wrapping in brackets. Without normalization, `key_for("cancel")` → `"escape"` → `"[ESCAPE]"` (ugly):

```lua
local _KEY_DISPLAY = { escape="Esc", left="←", right="→", up="↑", down="↓", space="Space" }
local function key_label(input, action)
    local k = input:key_for(action)
    if k == nil then return "[" .. action:upper() .. "]" end
    if k:sub(1,1) == "[" then return k end  -- already formatted (gamepad)
    return "[" .. (_KEY_DISPLAY[k] or k:upper()) .. "]"
end
```

Draw with `ui.draw_hud_box`. The shop-relevant controls are:

| Action | Input map key(s) | Keyboard label | Gamepad label |
|---|---|---|---|
| Browse | `move_left` / `move_right` | `[A]/[D]` | `[←]/[→]` |
| Buy | `interact` | `[E]` | `[A]` |
| Leave | `cancel` / `move_down` | `[Esc]/[S]` | `[B]/[↓]` |

Resulting hint (keyboard): `"[A]/[D] Browse  [E] Buy  [Esc]/[S] Leave"`

`ui` is not currently required in `shop_scene.lua`; it will be added.

## What stays the same

- CRT canvas rendering pipeline — unchanged
- `MoneyInfo` and `ActionsInfo` modules — no modifications
- Shop input map, navigation, and purchase logic — no modifications
- All other scenes — untouched

## Open questions

None.

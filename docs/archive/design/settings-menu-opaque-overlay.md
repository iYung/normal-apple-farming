## Goal

Fix the visual bug where opening Settings from the start menu shows both the
start menu's buttons and the settings menu's buttons overlapping on screen.
Emulate `../wip`'s fix: `SettingsMenu` gains an `opaque` mode that swaps the
semi-transparent black overlay for a fully opaque background image whenever
Settings is opened while the title/start scene is behind it.

## Root cause

`SettingsMenu:draw()` always paints `love.graphics.setColor(0, 0, 0, 0.55)` +
a full-screen `rectangle("fill", ...)` before drawing its own buttons. That
partial-alpha tint is fine over `GameScene` (dims gameplay behind it), but
`StartScene`'s four buttons sit at nearly the same `BTN_X`/row `y` positions
as the settings menu's own buttons, so at 55% alpha both button sets show
through and visually overlap.

`../wip/lua/game/scenes/settings_menu.lua` solves this with an `opaque`
boolean passed to `SettingsMenu:open(opaque)`: when true, `draw()` paints a
fully opaque background image instead of the semi-transparent rectangle,
completely hiding whatever scene is behind it. Wip's background is an
animated 2-frame pattern (`settings_pattern_1.png` / `_2.png`, swapped every
1s via `self._bg_frame`/`self._bg_timer`). Per user decision, this repo
ports the background **image only, without the animation** — a single
static opaque image, no frame-swap timer.

## Affected files

| File | Status |
|------|--------|
| `game/scenes/settings_menu.lua` | Modify — add `opaque` state, opaque background image, branch in `draw()` (both main-menu and keybinds-subscreen draw paths) |
| `main.lua` | Modify — all 3 `settings_menu:open()` call sites pass whether the title/start scene is currently active |
| `assets/images/settings_background.png` | New — copied from `../wip/assets/images/settings_pattern_1.png` (first frame only; no `_2` frame ported) |
| `tests/test_settings_menu.lua` | Modify — cover `open(opaque)` storing the flag and defaulting to non-opaque |

## What changes

**`SettingsMenu.new(...)`** — loads one new image at construction:
`self._img_bg_opaque = love.graphics.newImage("assets/images/settings_background.png")`.
No `_bg_frame`/`_bg_timer` fields are added (no animation).

**`SettingsMenu:open(opaque)`** — gains an `opaque` parameter (currently
`open()` takes none). Stores `self._opaque = opaque or false`. Existing
callers that call `open()` with no argument keep today's behavior
(semi-transparent overlay).

**`SettingsMenu:draw()`** — in both places it currently does:
```lua
love.graphics.setColor(0, 0, 0, 0.55)
love.graphics.rectangle("fill", 0, 0, W, H)
```
(the keybinds-subscreen branch and the main-items branch), branch on
`self._opaque`:
```lua
if self._opaque then
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._img_bg_opaque, 0, 0)
else
    love.graphics.setColor(0, 0, 0, 0.55)
    love.graphics.rectangle("fill", 0, 0, W, H)
end
```
Button drawing/selection/navigation logic is unchanged.

**`main.lua` call sites** — all three places that call `settings_menu:open()`
pass whether the title scene is currently showing, so opaque mode applies
regardless of which input triggered the open (matches wip's context-based,
not trigger-based, behavior):
1. `on_open_settings()` closure (Settings button confirm from `StartScene`)
2. ESC `keypressed` handler
3. Gamepad `"start"` button handler

Each becomes `settings_menu:open(manager.current and manager.current.is_title_scene)`.
`StartScene.is_title_scene` is already `true` (set in `start_scene.lua`);
`GameScene` has no such field, so `manager.current.is_title_scene` is falsy
there today, giving `opaque = false` for gameplay — same as current behavior.

## What stays the same

- Button layout, navigation, selection highlight, sound effects, keybind
  subscreen mechanics — untouched.
- `GameScene`/mid-gameplay ESC path — still gets the dimmed semi-transparent
  overlay so gameplay is visible behind Settings, unchanged from today.
- "Exit to Title" item behavior (quits if already on title, else switches to
  `StartScene`) — untouched; not in scope for this fix.
- No animation/frame-cycling is added, per user decision — this repo's
  version is simpler than wip's.

## Open questions

None — resolved with user:
- Opaque background: ported static image (`settings_pattern_1.png`), not a
  solid color fill, and not wip's 2-frame animation.
- Opaque scope: all 3 open() call sites in `main.lua`, driven by
  `manager.current.is_title_scene`, not just the Settings-button path.

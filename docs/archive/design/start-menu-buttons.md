# Start Menu Buttons

## Goal

Replace the current "Press E to start" title screen with a navigable button
menu — **New Game, Continue, Settings, Exit Game** — matching the button
style and interaction pattern used in `../jigsaw-game`'s start scene, and
reusing this repo's existing `settings_menu.lua` button visuals for
consistency.

`Continue` has no save system to resume from yet, so it no-ops on confirm
(per instruction — not blocked on building save/load).

## Affected files

- `game/scenes/start_scene.lua` — rewritten `draw()`/`update()`
- `main.lua` — `StartScene.new(...)` call sites gain a new callback param
- `tests/test_start_scene.lua` — rewritten for button navigation/confirm

## What changes

**Layout / visuals** — `start_scene.lua` keeps the title text
("Normal Apple Farming") but replaces the centered prompt + bottom control
hint row with four vertically-stacked buttons: New Game, Continue, Settings,
Exit Game. Reuses `assets/images/menu_btn.png` /
`assets/images/menu_btn_selected.png` and `game/fonts.lua`'s `Fonts.new(22)`,
with the same `BTN_W=300, BTN_H=54, BTN_GAP=74` constants `settings_menu.lua`
already uses, centered horizontally and stacked below the title.

**Selection highlight** — swap `menu_btn.png` → `menu_btn_selected.png` for
the selected row, same technique as `settings_menu.lua` and jigsaw-game (no
color tint, no outline).

**Navigation** — up/down moves `self.selected` with wraparound; confirm
activates the selected button. Reuses this repo's existing `Input` actions
(`move_up`/`move_down`/`interact`) rather than inventing new menu-specific
actions — these are already keybind-aware via `SettingsState`, unlike
jigsaw-game's separate `up/down/confirm` action set.

**Confirm behavior per button:**
- **New Game** — same effect as today's any-time-E: fade "menu" music,
  `scene_manager:switch(GameScene.new(...))`.
- **Continue** — no-op. No save/load system exists yet (`Save.write`/
  `Save.read` in `core/lua/save.lua` are defined but unused anywhere in the
  codebase), so there's nothing to resume.
- **Settings** — opens the existing `settings_menu` overlay (owned by
  `main.lua`, not part of `SceneManager`). `StartScene.new` gains a new
  optional callback param, `on_open_settings`; `main.lua` passes a closure
  calling `settings_menu:open()`. Both `StartScene.new(...)` call sites in
  `main.lua` (initial `love.load()` switch, and the one inside
  `on_exit_to_title()`) pass this callback. If omitted (e.g. in unit tests
  that don't need it), pressing Settings does nothing.
- **Exit Game** — calls `love.event.quit()` directly. Unlike the pause
  menu's `on_exit_to_title` (which branches on whether the current scene
  `is_title_scene`), the start menu **is always** the title scene, so no
  branching is needed — this mirrors jigsaw-game's `Exit Game` handling
  exactly.

**Control hint** — the bottom hint row is kept but simplified to something
like `↑/↓ Navigate   [key] Select`, built from `input:key_for(...)` the same
way the existing hint row does today — no hardcoded key glyphs (per prior
guidance on this repo's controls HUD).

## What stays the same

- `SceneManager`, `Input` class API, `GameScene`, `SettingsMenu` internals —
  unchanged.
- ESC-to-open-settings and gamepad `"start"`-to-open-settings global handling
  in `main.lua` — unchanged, still works regardless of which button is
  selected.
- Title text and music-on-enter behavior (play `"menu"` track if not already
  playing) — unchanged.
- No mouse support is added — keyboard/gamepad only, matching both
  jigsaw-game's start menu and this repo's existing `settings_menu.lua`.

## Open questions

None blocking. Two intentional simplifications, called out for visibility:
- `Continue` is always enabled/selectable but inert — it is not dimmed or
  hidden, since there's no save-detection logic to hide it behind (jigsaw-game
  dims it when no save exists; this repo has no equivalent save-exists check
  to hook into yet).
- No mouse/click support, consistent with existing menu code in this repo.

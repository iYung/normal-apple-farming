## Start Menu Buttons Checklist

- [x] Task A — `game/scenes/start_scene.lua` — Rewrite the scene to render and
  drive a 4-button menu instead of the "Press E to start" prompt.
  - Add `self.selected = 1` and `self.items = { "New Game", "Continue", "Settings", "Exit Game" }` to `StartScene.new`.
  - Add a new optional 4th constructor param `on_open_settings` (a callback,
    called with no args): `StartScene.new(scene_manager, settings_state, input, on_open_settings)`. Store as `self._on_open_settings`. It may be `nil` (tests / other callers that don't need it) — guard every call with `if self._on_open_settings then self._on_open_settings() end`.
  - In `update(dt)`: after `if self._owns_input then self.input:update() end`,
    replace the single `if self.input:pressed("interact") then ... end` block
    with menu navigation:
    - `if self.input:pressed("move_up") then self.selected = ((self.selected - 2) % #self.items) + 1 end` (wraparound up)
    - `if self.input:pressed("move_down") then self.selected = (self.selected % #self.items) + 1 end` (wraparound down)
    - `if self.input:pressed("interact") then self:_confirm() end`
  - Add a new `StartScene:_confirm()` method dispatching on `self.selected`:
    - 1 (New Game): exactly today's confirm body — `Sound.fade_music("menu", 0, 2)` then `self.scene_manager:switch(GameScene.new(self.scene_manager, self.settings_state, self.input))`.
    - 2 (Continue): no-op (empty branch, no `Sound.play` call — nothing to confirm yet).
    - 3 (Settings): call `self._on_open_settings()` if set (guarded as above).
    - 4 (Exit Game): `love.event.quit()`.
  - In `draw()`: keep the title text as-is (same position/centering). Replace
    the "Press E to start" prompt paragraph with a button list rendered the
    same way `game/scenes/settings_menu.lua:394-412` does it — reuse
    `assets/images/menu_btn.png` / `assets/images/menu_btn_selected.png`
    (load once in `StartScene.new`, e.g. `self._img_btn` / `self._img_btn_sel`,
    same as `settings_menu.lua:88-89`) and `Fonts.new(22)` from
    `game/fonts.lua` (load once as `self._font_btn`, same as
    `settings_menu.lua:1,90`). Use the same layout constants as
    `settings_menu.lua:53-56`: `BTN_W=300, BTN_H=54, BTN_X=(VIEW_W-BTN_W)/2, BTN_GAP=74`, stacked vertically starting below the title (pick a
    `BTN_Y0` a bit below where the old prompt text sat, e.g. `VIEW_H/2 - 20`).
    Save/restore the active font around the button draw loop like
    `settings_menu.lua:328,414` does (`local prev_font = love.graphics.getFont()` ... `love.graphics.setFont(prev_font)`).
  - Replace the bottom "controls hint" row (currently move/pickup/interact
    hints) with a short nav hint built the same key-lookup way it's built
    today (via `self.input:key_for(...)`, never hardcoded key glyphs — see
    `feedback_controls_hud_no_hardcode` convention already followed in this
    file at lines 58-77): something like
    `"↑/↓ Navigate   " .. fmt(self.input:key_for("interact")) .. " Select"`,
    reusing the existing local `fmt` helper. Drop the move/pickup hint text
    since it no longer applies on the title screen.
  - Do not change `on_enter`, `on_exit`, `esc_opens_settings`,
    `is_title_scene`, or the `_owns_input`/default-`Input` construction logic.

- [x] Task B — `main.lua` — Wire the new `on_open_settings` callback into both
  places `StartScene.new(...)` is constructed. *(Depends on Task A being
  complete — needs the final constructor signature.)*
  - `settings_menu` is a `local` declared at `main.lua:38` and assigned later
    at `main.lua:101`; a closure created before that assignment still sees
    the up-to-date value when invoked later (both `StartScene.new` call
    sites already run before any input can fire), so no reordering of
    `love.load()` is needed.
  - At `main.lua:69` (`manager:switch(StartScene.new(manager, ss, input))`),
    change to pass a 4th arg: a closure `function() if settings_menu then settings_menu:open() end end`.
  - At `main.lua:97` (inside `on_exit_to_title`,
    `manager:switch(StartScene.new(manager, ss, input))`), pass the same
    closure shape (can be the exact same closure defined once and reused for
    both call sites, or two identical inline closures — prefer defining it
    once near the top of `love.load()` alongside `on_close`/`on_exit_to_title`
    and referencing it in both places).
  - No other changes to `main.lua`.

- [x] Task C — `tests/test_start_scene.lua` — Update tests for button
  navigation/confirm, replacing the old single "E starts game" test.
  *(Depends on Task A being complete — needs the final API.)*
  - Keep the existing construction test, but also assert
    `scene.selected == 1` and `#scene.items == 4` after `StartScene.new`.
  - Keep the two `on_enter` music tests unchanged.
  - Replace the "E press fades music and switches to GameScene" test with an
    equivalent test that: constructs the scene with `selected` already at 1
    (the default), simulates a press of the `interact` key the same way
    `press_e` does today (`love.keyboard.isDown` monkey-patch), and asserts
    the same outcomes (`faded[1].name == "menu"`, `faded[1].vol == 0`,
    `sm.switched_to ~= nil`) — this is "New Game" behavior now, so keep the
    same helper but note in a comment it exercises the New Game button
    (default selection).
  - Add a new test for `move_down`/`move_up` navigation: simulate pressing
    the down key bound to `move_down` (default `"s"` or `"down"`) via the
    same `love.keyboard.isDown` monkey-patch pattern, call `scene:update`,
    and assert `scene.selected == 2`. Then simulate `move_up` and assert it
    wraps back to `1`; also test wraparound the other direction (up from 1
    goes to 4, the last item).
  - Add a new test for the Settings button: construct `StartScene.new(sm, nil, nil, on_open_settings_stub)` where `on_open_settings_stub` increments a counter, set `scene.selected = 3` directly, simulate an `interact` press, and assert the stub was called exactly once.
  - Add a new test for the Settings button being a no-op when
    `on_open_settings` is `nil`: set `scene.selected = 3`, simulate `interact`,
    assert it does not error.
  - Add a new test for the Exit Game button: construct normally, set
    `scene.selected = 4`, stub `love.event.quit` (record call count, restore
    after), simulate `interact`, assert `love.event.quit` was called exactly
    once.
  - Add a new test for the Continue button: set `scene.selected = 2`,
    simulate `interact`, assert nothing errors and (since there's nothing to
    assert positively for a no-op) that scene state / `sm.switched_to`
    remains unchanged and no music-fade call happened.
  - Keep the final `draw()` smoke test, unchanged in shape (just verify it
    still runs without error against the new button-drawing code).
  - Every test block still ends with `print("PASS: <description>")`; file
    still ends with `print("ALL TESTS PASSED")` — match the existing file's
    conventions exactly (no assert library beyond built-in `assert()`).

## Goal

Replace programmatically-drawn rectangles in the four HUD/quest UI modules
(`money_info`, `animal_info`, `job_info`, `actions_info`) with PNG sprites,
matching the visual approach used in `../godot-animal-game`.

## Affected files

| File | Change |
|---|---|
| `assets/images/hud/` | New folder; 7 PNGs copied from reference game |
| `game/ui/money_info.lua` | Draw `money_info_container.png` instead of rectangles |
| `game/ui/animal_info.lua` | Draw `info_container.png` + tinted `color_swatch.png` |
| `game/ui/job_info.lua` | Draw top/mid×N/bottom PNG stack; overlay `check.png` per met goal |
| `game/ui/actions_info.lua` | Draw `speech_bubble.png` (9-sliced via existing `draw9` in `ui.lua`) |

## What changes

### Assets — copy from `../godot-animal-game`

Destination: `assets/images/hud/`

| PNG | Source path | Dimensions |
|---|---|---|
| `money_info_container.png` | `objects/money_info/` | 192×96 |
| `info_container.png` | `objects/animal_info/` | 192×192 |
| `color_swatch.png` | `objects/animal_info/` | 16×17 |
| `job_info_top.png` | `objects/job_info/` | 192×42 |
| `job_info_mid.png` | `objects/job_info/` | 192×30 |
| `job_info_bottom.png` | `objects/job_info/` | 192×19 |
| `check.png` | `objects/job_info/` | 16×17 |

`speech_bubble.png` is already at `assets/images/shop/speech_bubble.png`
and loaded in `game/ui.lua` — no copy needed.

### `money_info.lua`

- Load `money_info_container.png` at module top.
- In `draw()`: replace the two `rectangle` calls with a single
  `love.graphics.draw(img, x, y)`. Keep money text drawn on top.
- Position: keep `x=16, y=120` as now (below animal_info panel).

### `animal_info.lua`

- Load `info_container.png` and `color_swatch.png` at module top.
- In `draw()`: replace the two `rectangle` calls with
  `love.graphics.draw(info_container, x, y)`.
- Color swatch: replace the two `rectangle` calls with
  `love.graphics.draw(color_swatch, sx, sy)` with `setColor` set to the
  animal's RGB before the draw (multiplicative tint).
- The PNG is 192×192; current panel is 160×90. Either scale the PNG down
  (sx, sy scale params) to fit the existing layout, or let layout expand to
  the natural PNG size and adjust the text offsets accordingly.
  → **Scale to ~192×96** (draw at 1× width, 0.5× height) so it fits the
  existing screen real-estate without pushing other panels.

### `job_info.lua`

- Load `job_info_top.png`, `job_info_mid.png`, `job_info_bottom.png`,
  `check.png` at module top.
- In `draw()`, for each active job:
  - Draw `top` at `(panel_x, jy)`.
  - For each goal row, draw `mid` at `(panel_x, jy + TOP_H + row * MID_H)`.
  - Draw `bottom` immediately after the last mid row.
  - Remove all `rectangle` calls.
  - After drawing each goal label, draw `check.png` to the right of the text
    if the goal is met (i.e. if `job.completed_goals` tracks per-goal status).
    If per-goal completion isn't tracked yet, skip checkmarks for now —
    that's a separate feature.
- Constants from PNG dimensions:
  - `TOP_H = 42`, `MID_H = 30`, `BOT_H = 19`

### `actions_info.lua`

- Remove the `require("game/ui")` dependency from `game_scene.lua` (it is
  currently only used by shop); instead `require` it inside `actions_info.lua`.
- In `draw()`: replace the single `rectangle` call with a `draw9` call using
  `speech_bubble.png` and the same 12-px margin as the shop uses.
- Size the bubble to fit the hint text content width dynamically (same pattern
  as `draw_hud_box` in `ui.lua`).

## What stays the same

- All text layout and content logic in every module.
- `game_scene.lua` draw order and call sites — no changes needed there.
- `ui.lua`, `game/shaders/`, and all entity code are untouched.
- `actions_info.lua` still draws bottom-left; `job_info.lua` still draws
  top-right; panel positions don't change.

## Open questions

None — approach agreed: 3-piece job panel, speech-bubble for actions.

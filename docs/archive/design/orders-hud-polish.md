# Orders HUD Polish

## Goal

Improve the top-right orders panel so players immediately understand what it represents and the text inside reads clearly. Two problems to fix: (1) no label tells the player these cards are "orders", and (2) the raw `love.graphics.print` calls with default font produce ugly, unstyled text.

## Affected files

- `game/ui/job_info.lua` — primary change: replace speech bubbles with 3-slice card assets, add "ORDERS" label, polish goal text
- `game/ui.lua` — add `draw_job_card` helper that renders the top/mid/bottom 3-slice card
- `tests/test_hud_ui.lua` — smoke tests already cover JobInfo; verify they still pass after changes

## What changes

### 1. "ORDERS" label
Draw the text `ORDERS` directly above the first (topmost) job card in the stack. It sits in screen space, top-right aligned with the cards, using the game font (font.ttf) at 12 px.

### 2. Card asset — 3-slice vertical card
Each job card switches from `ui.draw_bubble()` to a 3-piece stacked render:

| Piece | Asset | Size | Usage |
|---|---|---|---|
| Top | `hud/job_info_top.png` | 192×42 | Drawn once at the card's top |
| Mid | `hud/job_info_mid.png` | 192×30 | One instance per goal row + one for the reward row |
| Bottom | `hud/job_info_bottom.png` | 192×19 | Drawn once at the card's bottom |

All three pieces are scaled horizontally to match `panel_w` (204 px). The mid is not tiled — it is drawn once per needed row, each shifted down by 30 px.

Card total height for a job with N goals: `42 + 30*(N+1) + 19` px  
(N goal rows + 1 reward row)

### 3. Goal text — compact & exact with Unicode
Replace `>=` / `<=` with `≥` / `≤`. Layout inside each mid row:

```
Speed ≥ 120          (speed goal, exceed=true)
Speed ≤ 80           (speed goal, exceed=false)
Height ≥ 3           (height goal)
Trait: calm          (personality goal)
Color:  ████         (color goal — 16×10 swatch, same as today)
```

Text rendered with the game font (font.ttf) at 14 px, color `(0.15, 0.10, 0.05)` (dark warm brown, matches the card's cream/yellow palette).

Reward row (bottom mid piece):  `$25`  same font and color.

### 4. Card panel position
Unchanged: `x = 1280 - 220`, `y = 16`. Cards stack downward with 8 px gap.

## What stays the same

- `JobInfo.new(game_state)` constructor and `JobInfo:draw()` call signature
- One card per active (non-completed) job, stacked top-to-bottom
- Color goal still draws an inline color swatch rectangle
- Reward shown as `$XX` at the bottom of each card
- Early return when `#jobs == 0`
- All logic in `game/ui/job_info.lua`; `game_scene.lua` is not touched

## Open questions

None — confirmed by user: label = "Orders", format = compact & exact (≥/≤).

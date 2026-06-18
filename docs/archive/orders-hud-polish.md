# Orders HUD Polish Checklist

- [x] Task A — `game/ui.lua` — Add `draw_job_card(x, y, w, num_rows)` helper that loads `job_info_top.png` (192×42), `job_info_mid.png` (192×30), and `job_info_bottom.png` (192×19) as module-level images and draws them stacked: top scaled to (w, 42), then `num_rows` mid slices each scaled to (w, 30) below it, then bottom scaled to (w, 19). Export it alongside `draw_bubble` and `draw_currency_bubble`. No 9-slice needed — just `love.graphics.draw` with `sx = w/192` scale on x.

- [x] Task B — `game/ui/job_info.lua` — Rewrite `JobInfo:draw()` using the new card helper and polished text. Requires Task A complete first.
  - Load the game font (font.ttf) at 14 px as a module-level variable. Use `love.graphics.setFont` before each `love.graphics.print` call and restore default after.
  - Above the first card, draw `"ORDERS"` text at `(panel_x + PAD, panel_y - 18)` in dark warm-brown `(0.15, 0.10, 0.05, 1)`.
  - Per card: call `ui.draw_job_card(panel_x, card_y, panel_w, num_goals + 1)` where `num_goals + 1` accounts for the reward row.
  - Goal rows: offset `y` by `42 + row_index * 30` from `card_y`. Replace `>=` with `≥` and `<=` with `≤` in speed and height goal strings. Draw color swatch inline as before.
  - Reward row: at offset `42 + num_goals * 30`, draw `"$" .. job.reward`.
  - Card stacking gap: `card_height = 42 + (num_goals + 1) * 30 + 19`; next card starts at `card_y + card_height + 8`.

- [x] Task C — `tests/test_hud_ui.lua` — Run `love . --headless` to confirm all smoke tests still pass (no changes to the test file expected; this is a verification-only task).

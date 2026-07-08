## Goal

Fix a display bug in the ORDERS panel where a job's speed/height goal renders as garbled, unreadable text instead of a clean comparison (e.g. "Speed ≥ 5"), and replace the math-symbol notation with plain English (e.g. "Speed greater than 5").

## Affected files

- `game/ui/job_info.lua` — only file that needs to change

## What changes

`JobInfo:draw()` currently prints goal lines using hardcoded UTF-8 escapes for the mathematical symbols ≥ and ≤:

```lua
-- lines 54-58
if goal._type == "speed" then
    local sym = goal.exceed and "\xe2\x89\xa5" or "\xe2\x89\xa4"
    love.graphics.print("Speed " .. sym .. " " .. goal.threshold, panel_x + PAD, cy)
elseif goal._type == "height" then
    love.graphics.print("Height \xe2\x89\xa5 " .. goal.value, panel_x + PAD, cy)
```

**Root cause (confirmed by reproduction):** the game renders everything to a fixed 1280x720 canvas with `love.graphics.setDefaultFilter("nearest", "nearest")` (`main.lua:23,44-45`), then draws that canvas scaled by `math.min(win_w/1280, win_h/720)` to fit the actual window (`main.lua:112-115`). Whenever the window is resized to a size that isn't an exact multiple of 1280x720, this scale factor is non-integer (e.g. a 1000x640 window gives scale ≈0.781). Nearest-neighbor resampling at a fractional scale unevenly drops/duplicates pixel rows, and the thin, multi-stroke ≥/≤ glyph is disproportionately mangled by this compared to bold Latin letters and digits — it degrades into a blob that reads like a stray "z", while "Speed"/"Height" and the trailing number stay legible. This matches the reported symptom exactly ("I see speed, garbled text, and then a number").

I verified this with a side-by-side repro at the same distorted scale factor:
- `\xe2\x89\xa5` ("≥") → renders as an unreadable blob
- Plain ASCII `>=` → stays fully legible at the identical scale

**Fix:** the user asked for plain English instead of a math symbol at all (not just an ASCII substitute), specifically "greater than" / "less than" wording. Per `game/data/job.lua:36-42`, `goal.exceed == true` means `speed >= threshold` and `goal.exceed == false` means `speed <= threshold`; the height goal (`game/data/job.lua:49-50`) is always `height >= value`. So:

```lua
if goal._type == "speed" then
    local word = goal.exceed and "greater than" or "less than"
    love.graphics.print("Speed " .. word .. " " .. goal.threshold, panel_x + PAD, cy)
elseif goal._type == "height" then
    love.graphics.print("Height greater than " .. goal.value, panel_x + PAD, cy)
```

I measured the widest realistic strings with the actual game font (14px, "light" hinting) — `"Speed greater than 103"` (156px), `"Speed less than 80"` (127px), `"Height greater than 15"` (146px) — all within the ~184px available inside the 204px-wide panel, and confirmed via the same distorted-scale repro that this text stays fully legible.

This is a one-file, low-risk text change. It does not touch the rendering pipeline (canvas/scaling in `main.lua`), so it only fixes this specific symbol and does not protect against the same class of bug in any other thin-glyph text elsewhere in the UI — that broader pipeline fix was considered and explicitly deferred as out of scope for this fix.

## What stays the same

- `main.lua` canvas/scaling pipeline — unchanged
- Job goal generation logic (`game/systems/job_generator.lua`, `game/data/job.lua`) — unchanged
- Layout, panel drawing, colors, all other goal types (`personality`, `color`) — unchanged

## Open questions

None — scope confirmed with the user: text-only swap in `job_info.lua` using "greater than"/"less than" wording (not ASCII symbols, not a rendering-pipeline change).

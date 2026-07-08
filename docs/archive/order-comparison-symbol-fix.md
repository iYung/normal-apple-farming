## Order Comparison Symbol Fix Checklist

- [x] Task A — `game/ui/job_info.lua` — In `JobInfo:draw()` (lines 54-58), replace the hardcoded UTF-8 escape symbols with plain English wording. Speed goal: when `goal.exceed` is true, print `"Speed greater than " .. goal.threshold`; when false, print `"Speed less than " .. goal.threshold`. Height goal: print `"Height greater than " .. goal.value`. Remove the `local sym = ...` line entirely (no symbol variable needed). No other lines in the file change.

- [x] Task B — `tests/test_hud_ui.lua` — After the existing `capture_hint` helper definition (around line 104) and before "Test 6", add three new test cases that reuse `capture_hint` to verify the new wording:
  - Speed-exceed goal (`JobData.Goal.speed(50, true)`): assert captured text contains `"Speed greater than 50"`, and assert it does NOT contain the raw byte sequence `"\xe2\x89"` (the old ≥/≤ UTF-8 lead bytes), guarding against regressing to the symbol.
  - Speed-under goal (`JobData.Goal.speed(80, false)`): assert captured text contains `"Speed less than 80"`.
  - Height goal (`JobData.Goal.height(3)`): assert captured text contains `"Height greater than 3"`.

  Follow the existing `gs.active_jobs = {}` / `table.insert` / `ji:draw()` (via `capture_hint(ji)`) pattern already used by Tests 5-5g above. Print a `PASS: ...` line per assertion group, consistent with the rest of the file.

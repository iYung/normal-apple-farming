## Quest Pacing Calibration Checklist

- [x] Task A — `tests/test_breed_balance.lua` (new) — Write a headless breeding simulation that outputs trait-distribution data at each `jobs_done` milestone, to be used as the evidence base for calibrating `job_generator.lua` CONFIG values

- [x] Task B — `game/systems/job_generator.lua` — Run Task A's simulation (`love . --headless tests/test_breed_balance.lua`), read its output, and update CONFIG constants (`height.scale`, `speed.base`, `color.dist_scale`, `color.dist_min`, `color.dist_max`) so goal thresholds sit at the simulation's p75 for each trait at the milestone where that trait unlocks — must be done after Task A

---

### Task A detail — `tests/test_breed_balance.lua`

**What this file does:**
Runs three independent simulations (one per trait) and prints a summary table. Each simulation maintains a pool of animals, runs breeding cycles, and tracks trait percentiles at `jobs_done` milestones.

**Require paths to use:**
```lua
local AnimalStats = require("game/data/animal_stats")
```
(No love2d APIs. Run with `love . --headless tests/test_breed_balance.lua`.)

**Shared simulation constants:**
```lua
local STARTING_ANIMALS = 6          -- initial population size
local BREED_INTERVAL   = 5          -- seconds per breeding cycle
local JOB_INTERVAL     = 8          -- seconds per job completion
local CYCLES_PER_JOB   = JOB_INTERVAL / BREED_INTERVAL  -- 1.6
local MAX_JOBS         = 50
local MILESTONES       = {5, 10, 15, 20, 25, 30, 40, 50}
```

**Shared population helpers:**
- `make_default_stats()` — returns an AnimalStats at default values (speed=100, height=1, color={r=0.5,g=0.5,b=0.1})
- `init_population(n)` — returns a table of `n` default-stat animals
- `percentile(sorted_values, p)` — returns the p-th percentile value from a pre-sorted array

**Simulation loop structure (same for all three):**
```
jobs_done = 0
cycles_owed = 0.0
population = init_population(STARTING_ANIMALS)

for each jobs_done step from 0 to MAX_JOBS:
    cycles_owed += CYCLES_PER_JOB
    while cycles_owed >= 1:
        offspring = AnimalStats.breed(parent_a, parent_b)  -- parents chosen per sim
        table.insert(population, offspring)
        remove worst animal from population (per sim's ranking)
        cycles_owed -= 1
    if jobs_done in MILESTONES:
        record stats from population
    jobs_done += 1
```

**Simulation A — Height:**
- Parent selection: pick the 2 animals with the highest `.height`
- "Worst" animal to sell: the one with the lowest `.height`
- Record at each milestone: extract all heights, sort ascending, compute p50 / p75 / p90 / max

**Simulation B — Speed (two sub-simulations, run independently):**
- Speed-High: parents = 2 fastest (`.speed`); sell slowest; record p50, p75, p90, max
- Speed-Low: parents = 2 slowest (`.speed`); sell fastest; record min, p10, p25, p50

**Simulation C — Color:**
- Fixed target: `{r=0.8, g=0.2, b=0.9}` (a color far from the default base)
- `dist_sq(a, b)` helper: `(a.r-b.r)^2 + (a.g-b.g)^2 + (a.b-b.b)^2`
- Parent selection: 2 animals with lowest `dist_sq` to the target color
- Sell: animal with highest `dist_sq` to target
- Record at each milestone: min dist_sq in population (best achievable), p25, p50

**Output — print a formatted table to stdout:**
```
=== BREED BALANCE SIMULATION ===

HEIGHT (always-best pair selection, 1 breeder, 6 starting animals)
jobs  p50   p75   p90   max
5     ...   ...   ...   ...
...

SPEED HIGH
jobs  p50   p75   p90   max
...

SPEED LOW
jobs  min   p10   p25   p50
...

COLOR (target far from base, lowest dist_sq selection)
jobs  best_dist_sq  p25_dist_sq  p50_dist_sq
...
```

**Also print current CONFIG values for comparison:**
```
=== CURRENT CONFIG (for reference) ===
height.scale        = 0.3      → goal height at jobs=15: X, at jobs=30: Y
speed.base          = 100
color.dist_scale    = 0.001    → threshold at jobs=30: Z, at jobs=50: W
color.dist_min      = 0.01
color.dist_max      = 1.3
```

---

### Task B detail — `game/systems/job_generator.lua`

**What to do:**
1. Run the simulation: `love . --headless tests/test_breed_balance.lua`
2. Read the output table
3. Update CONFIG constants using the p75 column as the calibration target:
   - `height.scale`: find the value such that `1 + scale * jobs_done` ≈ height_p75 at the `height unlock milestone` (jobs_done=15). Solve: `scale = (height_p75_at_15 - 1) / 15`
   - `speed`: the current formula is `base + math.random(-diff, diff)` where `diff = jobs_done+1`. This means at jobs_done=30, speed goals range from ±31 around 100. If speed_p90 at jobs_done=30 is (say) 140, the goal range is realistic. Confirm or widen `diff` scaling if speed diverges more than expected.
   - `color.dist_scale`: find the value such that `dist_scale * jobs_done` ≈ color_best_dist_sq at jobs_done=30 (color unlock milestone). Solve: `dist_scale = color_best_dist_sq_at_30 / 30`. Update `dist_min` and `dist_max` to match the simulation's observed range across all milestones.
4. Leave all unlock milestones (`at` values), spawn intervals, and reward constants unchanged.
5. Add a one-line comment above the updated values citing the simulation: `-- calibrated from tests/test_breed_balance.lua`

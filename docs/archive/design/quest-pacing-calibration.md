## Goal

Replace the arbitrary CONFIG constants in `job_generator.lua` with values grounded in what a skilled player can realistically breed. A headless simulation benchmark will produce trait-distribution data at each `jobs_done` milestone, which we use to calibrate height, speed, and color thresholds so job difficulty scales with actual breeding output rather than guesswork.

## Affected files

- `tests/test_breed_balance.lua` (new) — headless simulation: 1 breeder, always-best pair selection per trait, outputs trait percentiles at each jobs_done milestone
- `game/systems/job_generator.lua` — CONFIG values updated after reviewing simulation output

## What changes

### Simulation (`tests/test_breed_balance.lua`)

Runs three independent trait simulations from the same starting conditions:

**Starting conditions (shared across all three):**
- Population: 6 animals, all at default stats (speed=100, height=1, base color={r=0.5,g=0.5,b=0.1})
- 1 breeder, cycling every 5 seconds
- Time mapping: 8s job interval ÷ 5s breed cycle = 1.6 breed cycles per job completed
- Population management: 1 animal sold per job (always the worst-performing animal for that trait, so the selection pool only improves)
- Run until jobs_done = 50

**Simulation A — Height:**
Each cycle, breed the 2 tallest animals in the pool. Track p50 / p75 / p90 / max height at milestones 5, 10, 15, 20, 25, 30, 40, 50.

**Simulation B — Speed (high and low):**
- Speed-high: each cycle, breed the 2 fastest. Track p90 speed.
- Speed-low: each cycle, breed the 2 slowest. Track p10 speed.
- Report both at same milestones.

**Simulation C — Color:**
Pick a fixed target color (e.g. {r=0.8,g=0.2,b=0.9}). Each cycle, breed the 2 animals whose color is closest (lowest dist_sq) to the target. Track best achievable `dist_sq` (min in population) at each milestone. This shows how quickly a player can converge on a specific color.

**Output format:** A printed table, one row per milestone:

```
jobs  height_p75  height_p90  speed_p10  speed_p90  color_dist_sq_best
5     ...         ...         ...        ...        ...
10    ...         ...         ...        ...        ...
...
```

### CONFIG update (`game/systems/job_generator.lua`)

After reviewing simulation output, update these CONFIG fields so goal thresholds match achievable p75 (challenging but beatable for a player using good strategy):

- `height.scale` — currently `0.3`; recalibrate so `1 + scale * jobs_done` matches simulation's height_p75 at each milestone
- `speed` thresholds — currently `base ± diff` where diff = jobs_done+1; recalibrate the range to match speed_p10/p90 from simulation
- `color.dist_scale` — currently `0.001`; recalibrate so `dist_scale * jobs_done` matches simulation's color_dist_sq_best at each milestone
- `color.dist_min` / `color.dist_max` — validate against simulation range and adjust if needed

## What stays the same

- The `jobs_done`-driven scaling architecture in `job_generator.lua`
- The 8-second spawn interval and 4-job cap
- The 5-second breeder cycle in `breeder.lua`
- The breeding algorithm in `animal_stats.lua` (BREED constants are not touched)
- Tutorial jobs (hardcoded first 3 jobs)
- Unlock milestones (personality at 8, height at 15, color at 30; max_goals at 11, 25, 40)

## Open questions

1. **Sell the best or worst?** The simulation sells the worst animal per job to keep the pool improving. In reality, the player sells whatever matches the current job (which might be their best animal for that trait). If this assumption is too optimistic, we could run a variant that sells a random animal instead.

2. **Speed goal direction:** The current job generator can generate either exceed (speed ≥ threshold) or fall-below (speed ≤ threshold) goals. The simulation covers both extremes. When calibrating, we should confirm both directions feel equally achievable — a low-speed goal requires the player to have deliberately bred slow animals, which few players will do.

3. **Color goal direction:** `max_dist_sq` is the *maximum* allowed squared distance from the target (smaller = harder). The current CONFIG makes color goals become *easier* over time (threshold grows with jobs_done). The simulation will show whether this is intentional (population diversifies so a loose threshold still has variety) or a bug (all colors eventually qualify trivially).

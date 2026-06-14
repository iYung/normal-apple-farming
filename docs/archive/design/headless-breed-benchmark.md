## Goal

Add a headless test (`tests/test_breed_benchmark.lua`) that measures wall-clock time
to breed an animal whose `height` stat reaches one million. The test prints the
elapsed time so it can be read in CI output and tracked manually over time. It is not
a pass/fail performance gate — it just needs to complete without error and print a
timing line.

## Affected files

| File | Change |
|------|--------|
| `tests/test_breed_benchmark.lua` | New file — implements the benchmark |

No production code changes are required.

## What changes

### New file: `tests/test_breed_benchmark.lua`

The test calls `AnimalStats.breed` in a tight loop, always feeding the offspring back
as both parents, and forcing height upward by overriding `math.random` during the
height-mutation step. The structure follows the same flat-script pattern used by all
other test files in `tests/`.

**Approach to forcing height growth**

`AnimalStats.breed` uses `math.random()` in two places relevant to height:

1. `math.random() < BREED.height.mutation_chance` — decides whether a mutation fires
   (50% chance).
2. `math.random(0, 1) == 0` — decides the direction of the mutation (−1 or +1).

`height` starts at 1 on both seed parents. Each generation:

```
height_child = floor((h + h) / 2 + 0.5)   →  h  (no change from averaging equal parents)
then mutation: +1 or -1 with 50/50 chance, or none
```

To guarantee height grows by exactly 1 every generation the benchmark temporarily
replaces `math.random` with a deterministic stub that:

- Returns `0` when called with `(0, 1)` so the direction picks the `+1` branch.
- Returns `0.0` when called with no args so `0.0 < 0.5` fires the mutation.
- Falls through to the real `math.random` for all other calls (speed, color,
  personality) so those remain plausible values.

This makes every breed call increase `height` by 1, requiring exactly 999,999
iterations to go from `height=1` to `height=1,000,000`. Each iteration is pure Lua
arithmetic — no timer, no scene, no graphics — so the loop completes in well under a
second on modern hardware.

**Timing**

`os.clock()` captures CPU time before and after the loop. The result is printed as:

```
breed_benchmark: 999999 generations to height=1000000 in X.XXXs
PASS: breed benchmark completed
```

**What the test does NOT do**

- It does not use `runner.setup` / `runner.tick` / `Breeder` — there is no need for
  the game scene, the 5-second breeding timer, or HeadlessInput. Those are for
  integration tests. This test calls `AnimalStats.breed` directly, the same way
  `test_animal_stats.lua` does.
- It does not assert a time threshold. Adding a hard limit would make the test
  environment-dependent and fragile on slow CI machines.

## What stays the same

- `game/data/animal_stats.lua` — no changes to production code.
- `game/entities/breeder.lua` — not touched.
- All existing tests — unaffected; the benchmark is an additive new file.
- The headless runner (`lua/headless/runner.lua`) — used as-is; the test is
  discovered automatically when `love . --headless` runs the full suite.
- The `math.random` override is scoped to the benchmark loop and restored
  immediately after, so it cannot leak into other tests even if test ordering
  changes.

## Open questions

None. The breeding mechanic (`AnimalStats.breed`) is self-contained, height has no
upper cap in production code, and `os.clock()` is available in the Love2D Lua
environment.

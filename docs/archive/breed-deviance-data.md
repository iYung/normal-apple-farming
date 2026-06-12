## Breed Deviance Data Checklist

- [x] Task A — `game/data/animal_stats.lua` — Add a `local BREED` constants table before any functions, then update every magic number in `AnimalStats.breed` to reference it. The table must cover: `speed.deviance` (50), `speed.min` (0), `speed.max` (200), `color.deviance` (0.2), `color.min` (0), `color.max` (1), `height.deviance` (1), `height.mutation_chance` (0.5), `height.min` (1), `personality.inherit_chance` (0.8). No behaviour change — pure refactor.

- [x] Task B — `tests/test_animal_stats.lua` — Add a test (after the existing breed clamping test) that verifies offspring stats respect the BREED bounds: speed in [0, 200], color channels in [0, 1], height >= 1, personality in PERSONALITIES. Run across 30 iterations. The test already effectively does this, but add a dedicated named block that makes the bound-checking intent explicit.

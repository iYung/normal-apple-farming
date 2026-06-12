## Goal

Extract every magic number from `AnimalStats.breed` into a local `BREED` constants
table at the top of `game/data/animal_stats.lua` so that breeding behaviour can be
tuned without hunting through logic code.

## Affected files

| File | Change |
|------|--------|
| `game/data/animal_stats.lua`  | Add a local `BREED` constants table at the top; `breed()` reads from it. |
| `tests/test_animal_stats.lua` | Add a test that offspring stats stay within the declared bounds. |

## What changes

### Local constants table in `game/data/animal_stats.lua`

Added near the top of the file, before any functions:

```lua
local BREED = {
    speed = {
        deviance = 50,   -- offspring speed = parent avg ± random integer in [-deviance, deviance]
        min      = 0,
        max      = 200,
    },
    color = {
        deviance = 0.2,  -- per-channel float deviance: uniform in [-deviance, deviance]
        min      = 0,
        max      = 1,
    },
    height = {
        deviance        = 1,    -- ±1 applied when mutation fires
        mutation_chance = 0.5,  -- probability that a height mutation occurs at all
        min             = 1,
    },
    personality = {
        inherit_chance = 0.8,  -- probability of inheriting a parent personality vs. rolling random
    },
}
```

### `AnimalStats.breed`

- Replaces every inline magic number with a reference to `BREED`.
- No behaviour change — this is a pure refactor.

## What stays the same

- The breeding algorithm itself (average → deviate → clamp).
- `AnimalStats.new`, `AnimalStats.random`, `AnimalStats.personality_to_face`.
- `Breeder` — it calls `AnimalStats.breed` and is unaffected.
- All existing tests remain valid; only the source of constants changes.

## Open questions

None — scope and location confirmed by user.

# Starting Height and Color Brightness

## Goal

Two quality-of-life improvements to animal generation:
1. All 6 starting animals should be height 1 (the smallest size).
2. No animal — starting or bred — should have a dark color. Darkness is measured by perceived luminance; any color below the luminance threshold is scaled up proportionally to meet it.

## Affected files

- `game/data/animal_stats.lua` — only file that needs to change

## What changes

### 1. Starting height fixed to 1

`AnimalStats.random()` currently picks height via `math.random(1, 5)`. Change this to the literal `1`.

### 2. Luminance floor on all animal colors

Add a module-level constant `MIN_LUMINANCE = 0.4` and a private helper `enforce_luminance(color)` that uses the standard perceived-luminance formula:

```
L = 0.2126·R + 0.7152·G + 0.0722·B
```

If `L < MIN_LUMINANCE` and `L > 0`, scale all three channels by `MIN_LUMINANCE / L` (clamped to 1.0 per channel). If `L == 0` (pure black), set each channel to a flat value that hits the threshold — e.g., distribute evenly: `r = g = b = MIN_LUMINANCE / (0.2126 + 0.7152 + 0.0722)` ≈ 0.4.

Call `enforce_luminance` in two places:
- `AnimalStats.random()` — after building the color table
- `AnimalStats.breed()` — after the per-channel blend, before constructing the result

The `BREED.color.min / max` clamp already runs before `enforce_luminance`; the luminance pass is a second, independent step applied on top.

## What stays the same

- Bred animal heights are unaffected (still inherit from parents with mutation).
- All other stats (speed, personality) are unchanged.
- The per-channel blend logic in `breed()` is unchanged; luminance enforcement is a post-process.
- No other files need touching — `game_scene.lua` spawns animals via `Animal.new(x, y)` which internally calls `AnimalStats.random()`, so fixing `random()` is sufficient.

## Open questions

None — resolved in conversation:
- Starting height: exactly 1 (not a floor; all starting animals are height 1).
- Luminance threshold: 0.4 using standard perceived-luminance weights.
- Scope: all animals (starting + bred offspring).

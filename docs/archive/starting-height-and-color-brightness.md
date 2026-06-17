# Starting Height and Color Brightness Checklist

- [x] Task A — `game/data/animal_stats.lua` — In `AnimalStats.random()`, change `math.random(1, 5)` to the literal `1` so all starting animals begin at height 1.

- [x] Task B — `game/data/animal_stats.lua` — Add a module-level constant `MIN_LUMINANCE = 0.4` and a private helper `enforce_luminance(color)` that computes perceived luminance `L = 0.2126*color.r + 0.7152*color.g + 0.0722*color.b`. If `L < MIN_LUMINANCE`: if `L > 0`, scale each channel by `MIN_LUMINANCE / L` (clamped to 1.0); if `L == 0`, set `r = g = b = MIN_LUMINANCE`. Then call `enforce_luminance` in `AnimalStats.random()` (after building the color table) and in `AnimalStats.breed()` (after the per-channel blend, before constructing the result).

Note: Task A and Task B both touch the same file — run them sequentially.

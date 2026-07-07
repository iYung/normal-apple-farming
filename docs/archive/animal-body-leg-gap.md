## Animal Body–Leg Gap Checklist

- [x] Offset legs Y by -1 pixel — `game/entities/animal.lua` — in `Animal:draw()`, change both leg sprite Y assignments from `by` to `by - 1` (lines 156–157) so the legs sprite shifts up 1 pixel and closes the transparent seam between the body bottom and leg top

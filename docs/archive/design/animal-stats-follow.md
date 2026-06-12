## Goal

When the player holds an animal, the stats bubble should float centered above the held animal in world space rather than sitting at a fixed top-left corner.

## Affected files

- `game/ui/animal_info.lua` — change `draw()` to accept a camera and compute position from the animal's world coords
- `game/scenes/game_scene.lua` — pass `self.camera` to `animal_info:draw()`

## What changes

### Coordinate transform

The camera renders world space with:
```
screen_x = (world_x - camera.x) * camera.zoom + 640
screen_y = (world_y - camera.y) * camera.zoom + 360
```
(`640, 360` is `LOGICAL_W/2, LOGICAL_H/2`.)

### Bubble positioning

The animal's bounding box is `48 × 48` at `(animal.x, animal.y)` in world space.  
The bubble is `160 × 90` in screen space.

Desired position: centered horizontally on the animal, sitting `8px` above the animal's top edge in screen space.

```
animal_cx_screen = (animal.x + 24 - camera.x) * camera.zoom + 640
animal_ty_screen = (animal.y      - camera.y) * camera.zoom + 360

bubble_x = animal_cx_screen - 80      -- center the 160px bubble
bubble_y = animal_ty_screen - 90 - 8  -- place 8px above animal top
```

Then clamp to keep the bubble fully on-screen:
```
bubble_x = math.max(0, math.min(bubble_x, 1280 - 160))
bubble_y = math.max(0, math.min(bubble_y, 720  -  90))
```

### API change

`AnimalInfo:draw()` → `AnimalInfo:draw(camera)`  
The camera argument is only used when `self._animal` is set; no camera needed when no animal is held (early return unchanged).

## What stays the same

- `AnimalInfo:set(animal_or_nil)` — unchanged
- All stat text layout (relative offsets inside the bubble) — unchanged
- The bubble is still drawn in screen space (after `camera:detach()`)
- `money_info`, `job_info`, `actions_info` draw calls — unchanged

## Open questions

None — positioning formula and clamping behavior are fully specified above.

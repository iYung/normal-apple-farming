## Animal Stats Follow Checklist

- [x] Task A — `game/ui/animal_info.lua` — Change `AnimalInfo:draw()` to `AnimalInfo:draw(camera)`. When `self._animal` is set, compute `bubble_x` and `bubble_y` from the animal's world position using the camera transform (`screen = (world - camera.x/y) * camera.zoom + 640/360`), center the 160px bubble horizontally on the animal's center (`animal.x + 24`), place it 8px above the animal's top edge (`animal.y`), then clamp both axes so the bubble stays fully on-screen (`x` in `[0, 1120]`, `y` in `[0, 630]`). Replace the hardcoded `local x, y = 16, 16` with the computed values.

- [x] Task B — `game/scenes/game_scene.lua` — Update the `self.animal_info:draw()` call (line ~238) to `self.animal_info:draw(self.camera)` so the camera is available for the world-to-screen transform.

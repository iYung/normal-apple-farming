## Book Item Checklist

- [x] Task A — `assets/images/items/book.png` + `assets/images/book_scene.png` — Generate two minimal placeholder PNGs: a 32x32 solid-colour sprite for the in-world book item, and a 1280x720 placeholder image for the full-screen book scene.

- [x] Task B — `game/items/book.lua` — Create new Item subclass. `_type = "book"`, `carriable = true`, `w = 32`, `h = 32`, image `assets/images/items/book.png`. Constructor accepts `(x, y, book_scene)` and stores `self._book_scene`. `interact(player, scene, scene_manager)` calls `scene_manager:switch(self._book_scene)`. Delegate `update` and `draw` to `Item`.

- [x] Task C — `game/scenes/book_scene.lua` — Create new scene. Constructor accepts `(game_scene, scene_manager)`. Loads `assets/images/book_scene.png`. Has `Input` with `{ interact = { "e" } }`. `on_enter` sets `self._skip_frame = true`. `update(dt)` calls `self.input:update()`, skips first frame, then on `interact` pressed calls `scene_manager:switch(game_scene)`. `draw()` renders the PNG scaled to fill 1280×720, wrapped in a canvas + CRT shader (same pattern as ShopScene/GameOverScene).

- [x] Task D — `game/scenes/game_scene.lua` — In `on_enter`, after the ShopItem line, require and instantiate `BookScene` (passing `self` and `self.scene_manager`), then create a `Book` at `(cx + 60, cy + 120)` passing the book_scene, and `table.insert(self.items, book)`.

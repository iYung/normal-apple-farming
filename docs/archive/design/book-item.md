## Goal

Add a "Book" item that spawns in the main game scene (not purchasable from the shop). The player can pick it up and carry it. Pressing the interact button (`e`) while near it opens a full-screen BookScene that displays a single PNG. Pressing interact inside BookScene returns to the game.

## Affected files

- `game/items/book.lua` — new item subclass
- `game/scenes/book_scene.lua` — new scene
- `game/scenes/game_scene.lua` — spawn the book at startup
- `assets/images/items/book.png` — placeholder sprite for the item in-world
- `assets/images/book_scene.png` — placeholder full-screen image shown in BookScene

## What changes

### `game/items/book.lua`
New Item subclass. `carriable = true`. Stores a reference to its BookScene instance. `interact(player, scene, scene_manager)` calls `scene_manager:switch(self._book_scene)`. No `use` method (interact-only). `_type = "book"`.

### `game/scenes/book_scene.lua`
New scene. Constructor receives `game_scene`. Loads `assets/images/book_scene.png`. `draw()` renders the image fullscreen (with CRT shader, consistent with other scenes). `update()` listens for `e` pressed → `scene_manager:switch(game_scene)`. Needs `on_enter` / `on_exit` stubs. Has its own `Input` with `{ interact = { "e" } }` and a skip-first-frame guard so the same keypress that opened the book doesn't immediately close it.

### `game/scenes/game_scene.lua`
In `on_enter`, after the existing starting items, create a `BookScene`, then a `Book` referencing it, and `table.insert(self.items, book)`. Placement: near world centre alongside the other starting items.

### Placeholder PNGs
Two minimal PNGs generated at build/setup time (or committed as tiny placeholders). They just need to be loadable by LÖVE — a small solid-colour image is fine.

## What stays the same

- Shop catalogue unchanged — book is not purchasable.
- Player pickup/interact logic unchanged — book participates via the existing `carriable` and `interact` item contracts.
- Scene manager fade behaviour unchanged.
- All other items and scenes unchanged.

## Open questions

None — scope is clear. Proceeding to Phase 2.

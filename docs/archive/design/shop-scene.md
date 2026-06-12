## Goal

Replace the current Tab-toggled overlay shop with a proper in-world shop item that switches to a dedicated shop scene. Matches the WIP's `PCStore` → `BuyScene` pattern adapted for this game's animal-farming context.

## Affected files

- `game/scenes/shop_ui.lua` — deleted; replaced by the new scene
- `game/scenes/game_scene.lua` — remove `shop_open`/`shop_ui`, inject `scene_manager`, add ShopItem to world, pass `scene_manager` through to item interaction
- `game/entities/player.lua` — remove `shop` input binding and toggle; `interact` now opens shop via item
- `main.lua` — pass `SceneManager` instance into `GameScene.new()`
- **New** `game/items/shop_item.lua` — in-world carriable item; `interact` calls `scene_manager:switch(shop_scene)`
- **New** `game/scenes/shop_scene.lua` — full scene with catalogue navigation, buy logic, and return to game

## What changes

### ShopItem (`game/items/shop_item.lua`)
- Extends `Item`; `carriable = true`, `sellable = false`
- Holds a reference to the `ShopScene` (injected at construction)
- `interact(player, _, scene_manager)` — if player has no held item, calls `scene_manager:switch(shop_scene)`

### ShopScene (`game/scenes/shop_scene.lua`)
- Separate `Scene` subclass managed by `scene_manager`
- Catalogue: Wire Roll ($20), Knife ($40), Breeder ($100) — same items as current `shop_ui.lua`
- Navigation: left/right cycle through items; dot indicators show position
- Buy (`interact` key): deduct cost from `game_state.money`, set `game_state.player.held_item` to the purchased item, switch back to game scene
- Cancel (`move_down` key): switch back to game scene without buying
- Draws: centred panel with item name, description, cost (green if affordable, red if not), nav arrows, dot row — no CRT or sound (assets not present in this project)

### GameScene (`game/scenes/game_scene.lua`)
- Accepts `scene_manager` as constructor argument
- On `on_enter`: creates `ShopScene`, creates `ShopItem` pre-placed in the world, injects scene references
- Removes `shop_open` boolean and all `shop_ui` references
- Player interaction with ShopItem is handled by the existing `_handle_interact` path (item's `interact` method fires)

### Player (`game/entities/player.lua`)
- Remove `shop = { "tab" }` input binding
- Remove the `if input:pressed("shop")` toggle block

### main.lua
- `GameScene.new(manager)` — pass the `SceneManager` instance so the scene can inject it into items

## What stays the same

- All other items (Roll, Knife, Breeder, SellBin) are unchanged
- Animal, Breeder, SellBin, wire logic unchanged
- GameState, camera, Y-sort, Drawer unchanged
- Catalogue items and their costs unchanged (Wire Roll $20, Knife $40, Breeder $100)
- Bought items are placed via `player.held_item` (same as WIP pattern)

## Open questions

None — all resolved before writing this doc.

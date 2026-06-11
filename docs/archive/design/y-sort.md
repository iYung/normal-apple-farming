# Y-Sort Draw Order

## Goal

Replace the current fixed-layer draw order with a Y-sort pass so entities closer to the bottom of the screen are drawn on top of entities that are higher up. The player is no longer unconditionally on top — a ground item or animal with a larger center-Y will render in front of them.

## Affected files

- `game/scenes/game_scene.lua` — `draw()` function only

## What changes

- The separate wires, items, animals, and player draw passes are replaced with a single sorted pass.
- All world entities are collected into one flat list: wires, non-held items, animals, and the player.
- The list is sorted ascending by center Y (`y + h/2`). Entities with a larger center Y draw last (on top).
- The player's held item (if any) is drawn immediately after the player in the sorted pass so it stays visually on top of the player sprite — it is not added to the sort list itself.

## What stays the same

- Background draws first, before all entities, unaffected.
- Held item always renders on top of the player (drawn right after the player's turn in the sorted pass, same as before).
- Items with `held == true` are excluded from the sort list (unchanged behaviour — they're owned by the player).
- UI / HUD elements draw after `camera:detach()`, completely unaffected.

## Open questions

None.

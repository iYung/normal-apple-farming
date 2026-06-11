## Goal

Items held by the player should draw after the player — on top of animals and the player sprite itself — instead of in the general items pass where they appear behind animals.

## Affected files

- `game/scenes/game_scene.lua` — the only change needed is in `GameScene:draw()`

## What changes

`GameScene:draw()` currently draws entities in a fixed sequence:

```
Wires → Items → Animals → Player
```

Items with `held == true` are positioned above the player (via `Player:update()`), but because they are drawn in the Items phase they visually render behind animals and the player. This is the bug.

**Fix:** During the Items draw phase, skip any item whose `held` field is `true`. After drawing the Player, draw the held item (accessed via `self.player.held_item`).

New draw sequence:

```
Wires → Items (non-held only) → Animals → Player → Held item (if any)
```

This gives the held item a draw priority that is one step above the player — always visible on top of everything in world-space.

## What stays the same

- The `Player:update()` logic that positions `held_item` above the player is unchanged.
- All other entity draw calls are unchanged.
- Nothing about how items are picked up or dropped changes.
- The `Drawer` class (`core/lua/drawer.lua`) is not involved — this fix stays entirely in the `GameScene:draw()` sequential pass.

## Open questions

None — user confirmed held item should draw after (on top of) the player.

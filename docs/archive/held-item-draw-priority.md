## Held Item Draw Priority Checklist

- [x] Task A — `game/scenes/game_scene.lua` — In `GameScene:draw()`, change the Items loop (lines 189–191) to skip items where `it.held == true`, so held items are not drawn in the items pass.

- [x] Task B — `game/scenes/game_scene.lua` — After `self.player:draw()` (line 199) and before `self.camera:detach()`, add a draw call for `self.player.held_item` if it is non-nil, so the held item renders on top of the player and all animals.

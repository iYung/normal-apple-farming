# Y-Sort Checklist

- [x] Implement Y-sort draw pass — `game/scenes/game_scene.lua` — Replace the separate wires, items, animals, and player draw passes with a single sorted pass: collect wires + non-held items + animals + player into one flat table, sort ascending by `entity.y + entity.h / 2`, then iterate and draw each; when the player entity is reached, draw the player then immediately draw `self.player.held_item` (if any) before continuing.

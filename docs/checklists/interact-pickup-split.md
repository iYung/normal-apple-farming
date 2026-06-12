# Interact / Pickup Split Checklist

- [x] Task A — `game/scenes/game_scene.lua` — In the `Input.new({...})` call, replace `secondary = { "o" }` with `pickup = { "f" }`. No other changes to this file.

- [x] Task B — `game/settings_state.lua` — Add `pickup = "f"` to the default keybinds table (line ~7). In `key_map()`, include `pickup` in the returned map (alongside the existing movement and interact entries).

- [x] Task C — `game/scenes/settings_menu.lua` — Add `"pickup"` to `_ACTION_LIST` (line 5) and `"pickup"` to `_ACTION_LABELS` (line 6). No other changes needed; the existing rendering loop handles the new row automatically.

- [x] Task D — `game/entities/player.lua` — Refactor input handling in `Player:update()` and split `_handle_interact()` into two methods:

  **In `Player:update()`**, replace the current interact + secondary blocks (lines 109–117) with:
  ```
  -- interact: held for knife/spool, single press for shop
  if self.held_item and self.held_item.use and self.input:is_down("interact") then
      self.held_item:use(self, scene)
  elseif self.input:pressed("interact") then
      self:_handle_interact(scene)
  end

  -- pickup: press once to carry or drop
  if self.input:pressed("pickup") then
      self:_handle_pickup(scene)
  end
  ```

  Also update the fallback `Input.new({...})` inside `Player.new()`: replace `secondary = { "o" }` with `pickup = { "f" }`.

  **Rename the existing `_handle_interact()` to `_handle_pickup()`** and simplify it: remove the shop/non-carriable branch (the `not hovered.carriable and hovered.interact` branch). The method should only handle carrying and dropping. The pickup path should guard with `Detector.can_pickup(hovered)` instead of the old else-all fallthrough.

  **Add a new `_handle_interact()`** that handles shop opening:
  ```lua
  function Player:_handle_interact(scene)
      local all_entities = {}
      for _, it in ipairs(scene.items) do table.insert(all_entities, it) end
      local hovered = Detector.nearest(self, all_entities, 64)
      if hovered and not hovered.carriable and hovered.interact then
          hovered:interact(self, scene, scene.scene_manager)
      end
  end
  ```

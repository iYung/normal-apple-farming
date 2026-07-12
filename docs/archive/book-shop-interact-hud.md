## Book/Shop/Rocket Interact HUD Checklist

Execution order: **Task A must land first** (it adds `Detector.is_interactable`, which
Tasks B and C both call). Once Task A is done, **Tasks B and C can run in parallel** —
they touch different files and only share a fixed method-name contract
(`ActionsInfo:set_interact_target(entity_or_nil)`) that is spelled out in both task
descriptions below, so neither agent needs to see the other's work mid-flight. **Task D
must run after Task C** (it calls `ActionsInfo:set_interact_target`, which only exists
once Task C's edit lands) — it does not depend on Task B.

```
Task A (detector.lua)
   |
   +--> Task B (game_scene.lua)   \
   |                                > order among these two doesn't matter
   +--> Task C (actions_info.lua) /
              |
              +--> Task D (test_hud_ui.lua)   [after C]
```

- [x] **Task A** — `game/systems/detector.lua` — Add an `is_interactable(e)` type-check
  helper and remove the dead `can_pickup(e)` helper.
  - Add, following the exact style of the existing `is_animal`/`is_roll`/`is_knife`/
    `is_rocket` helpers (lines 5-42):
    ```lua
    function Detector.is_interactable(e)
        return e ~= nil and (e._type == "book" or e._type == "shop_item" or e._type == "rocket")
    end
    ```
    Place it near the other type-check helpers (e.g. right after `is_rocket`, before the
    `-- Geometry helpers` section).
  - Delete the existing `Detector.can_pickup(e)` function (currently lines 44-50). It is
    dead code — confirmed via repo-wide grep that nothing calls
    `Detector.can_pickup` or `.can_pickup` anywhere outside its own definition — and its
    removal is a locked decision from the design doc.
  - No other changes to this file. This task has no dependencies and should be done
    first since Tasks B and C both call `Detector.is_interactable`.

- [x] **Task B** — `game/scenes/game_scene.lua` — Stop putting the shop (or any
  non-carriable entity) in the pickup `nearby` list, and compute/pass the nearest
  interactable entity to the HUD. **Depends on Task A** (`Detector.is_interactable`)
  being merged first; safe to run in parallel with Task C.
  - In the "Actions info: compute nearby pickupable entities" block (currently lines
    196-217):
    - Leave the animals loop (lines 198-206) unchanged — animals have no `carriable`
      flag issue here and must keep appearing in `nearby` exactly as today.
    - In the items loop (lines 207-215), only add `it` to `nearby` when it is actually
      carriable: change `if not it.held then` to `if not it.held and it.carriable then`.
      This is what removes the shop (`carriable = false`) from the pickup list while
      leaving roll/knife/book/rocket/breeder/sell_bin (all `carriable = true`) unaffected.
    - After that loop (still before line 216's `self.actions_info:set_nearby(nearby)`),
      compute the nearest interactable entity using the same pattern already used in
      `Player:_handle_interact` / `Player:_handle_pickup`
      (`game/entities/player.lua` lines 118, 130, 199 — `Detector.nearest(self, list, 64)`):
      ```lua
      local interactables = {}
      for _, it in ipairs(self.items) do
          if not it.held and Detector.is_interactable(it) then
              table.insert(interactables, it)
          end
      end
      local nearest_interactable = Detector.nearest(self.player, interactables, 64)
      ```
    - Add `self.actions_info:set_interact_target(nearest_interactable)` alongside the
      existing `self.actions_info:set_nearby(nearby)` and
      `self.actions_info:set_held(self.player.held_item)` calls (lines 216-217).
      `set_interact_target` is a **new method on `ActionsInfo`** — it is added by Task C.
      Call it with this exact name and a single argument that is either the nearest
      interactable entity or `nil`; do not implement `ActionsInfo` yourself here, just
      call the method per this contract.
  - `Detector` is already imported in this file (line 20) — no new require needed.

- [x] **Task C** — `game/ui/actions_info.lua` — Accept the new interact-target info and
  make `draw()` show a contextual interact hint (concatenated with the pickup hint when
  both apply, interact first). **Depends on Task A** (`Detector.is_interactable`); safe
  to run in parallel with Task B. Note: contrary to the design doc's root-cause writeup,
  the `Detector` import in this file (line 1) is *not* currently dead — it's already
  used at lines 52/54 for the held-roll/held-knife hints. Leave that usage untouched;
  this task adds one more legitimate use of the same `Detector` local.
  - In `ActionsInfo.new()` (lines 19-25), add `self._interact_target = nil` alongside
    the existing `self._nearby` / `self._held` fields.
  - Add a new method, mirroring the existing `set_nearby` / `set_held` pattern
    (lines 27-34):
    ```lua
    function ActionsInfo:set_interact_target(entity_or_nil)
        self._interact_target = entity_or_nil
    end
    ```
  - Rewrite the `e_hint` construction in `draw()` (currently lines 37-47). Keep the
    `held` branch (lines 39-40, "Drop" hint) exactly as-is. Replace the `elseif
    #self._nearby > 0` / `else` branches with logic that builds an interact hint and a
    pickup hint independently, then combines them:
    ```lua
    local interact_hint = ""
    if Detector.is_interactable(self._interact_target) then
        local label
        local t = self._interact_target._type
        if t == "book" then label = "Read Book"
        elseif t == "shop_item" then label = "Open Shop"
        elseif t == "rocket" then label = "Launch Rocket"
        else label = "Interact"
        end
        interact_hint = key_label(self._input, "interact") .. " " .. label
    end

    local pickup_hint = ""
    if #self._nearby > 0 then
        local nearest = self._nearby[1]
        local label = nearest.name or nearest._type or "item"
        pickup_hint = key_label(self._input, "pickup") .. " Pick up " .. label
    end

    if interact_hint ~= "" and pickup_hint ~= "" then
        e_hint = interact_hint .. "  " .. pickup_hint
    elseif interact_hint ~= "" then
        e_hint = interact_hint
    elseif pickup_hint ~= "" then
        e_hint = pickup_hint
    else
        e_hint = key_label(self._input, "interact") .. " Interact"
    end
    ```
    (This preserves the exact "interact first" ordering from the locked design decision,
    and preserves the existing no-nearby generic "[key] Interact" fallback.)
  - The `o_hint` block (lines 49-57, place-wire/remove-wires while held) is untouched.
  - No changes to `game/scenes/game_scene.lua` in this task — only call the new setter
    per the contract Task B also follows.

- [x] **Task D** — `tests/test_hud_ui.lua` — Add cases locking in the new HUD behavior.
  **Depends on Task C** (`ActionsInfo:set_interact_target` must exist); run after Task C
  lands. Does not depend on Task B (these tests drive `ActionsInfo` directly with fake
  entities, not through `GameScene`).
  - Add new tests after the existing Test 9 (ends at line 181), reusing the existing
    `mock_input` (line 132), `act` instance (line 143), and `capture_hint` helper
    (line 95):
    - **Shop-only nearby**: `act:set_held(nil)`, `act:set_nearby({})`,
      `act:set_interact_target({ _type = "shop_item", name = "Shop" })`. Assert the
      captured hint contains `"Open Shop"` and does **not** contain `"Pick up"`
      (interact-only, no pickup hint, since shop is not carriable).
    - **Book nearby (both hints)**: `act:set_interact_target({ _type = "book", name =
      "Book" })`, `act:set_nearby({ { _type = "book", name = "Book", held = false, x =
      0, y = 0, w = 16, h = 16 } })`. Assert the hint contains both `"Read Book"` and
      `"Pick up Book"`, and that the start index of `"Read Book"` is less than the start
      index of `"Pick up Book"` (interact listed first).
    - **Rocket nearby (both hints)**: same shape as the book case but with `_type =
      "rocket"`, `name = "Rocket"`. Assert the hint contains both `"Launch Rocket"` and
      `"Pick up Rocket"`, with `"Launch Rocket"` appearing first.
    - Reset `act:set_held(nil)` / `act:set_interact_target(nil)` / `act:set_nearby({})`
      between cases as needed so state doesn't leak between assertions (follow the
      existing reset pattern already used between Test 7/8/9).
  - End the file with the existing `print("ALL TESTS PASSED")` (line 183) — just add the
    new `print("PASS: ...")` lines for each new case before it, matching the file's
    existing style.

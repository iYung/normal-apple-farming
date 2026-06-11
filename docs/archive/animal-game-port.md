# Animal Game Port Checklist

Tasks are grouped by dependency wave. Tasks within a wave are independent and can run in parallel.

---

## Wave 0 — Assets & Folder Structure

- [x] Task 0a — Copy Godot PNG sprites into Love2D asset tree. Create these dirs and copy from `/godot-animal-game`:
  - `assets/images/animal/` ← `objects/animal/*.png`
  - `assets/images/player/` ← `objects/player/*.png`
  - `assets/images/breeder/` ← `objects/breeder/*.png`
  - `assets/images/sell_bin/` ← `objects/sell_bin/*.png`
  - `assets/images/shop/` ← `objects/shop/*.png` and `objects/shop_ui/*.png`
  - `assets/images/items/` ← knife/roll/pruner PNGs from `objects/knife/`, `objects/roll/`, `objects/pruner/`
  - `assets/images/tileset.png` ← `tileset.png`

- [x] Task 0b — Create all empty Lua stub files so later tasks can `require` them without error. Create these files (each with just a `-- stub` comment for now):
  - `game/data/animal_stats.lua`
  - `game/data/job.lua`
  - `game/systems/mapper.lua`
  - `game/systems/detector.lua`
  - `game/systems/job_generator.lua`
  - `game/game_state.lua`
  - `game/entities/animal.lua`
  - `game/entities/player.lua`
  - `game/entities/breeder.lua`
  - `game/entities/sell_bin.lua`
  - `game/entities/wire.lua`
  - `game/items/item.lua`
  - `game/items/roll.lua`
  - `game/items/knife.lua`
  - `game/items/pruner.lua`
  - `game/ui/animal_info.lua`
  - `game/ui/job_info.lua`
  - `game/ui/money_info.lua`
  - `game/ui/actions_info.lua`
  - `game/scenes/shop_ui.lua`
  - `game/shaders/animal_color.lua`
  - `game/shaders/outline.lua`
  - `game/shaders/sway.lua`

---

## Wave 1 — Foundation (no inter-game dependencies)

- [x] Task 1a — `game/data/animal_stats.lua` — Implement the AnimalStats data class.
  - Fields: `speed` (number 0–100), `color` ({r,g,b} floats 0–1), `height` (int), `personality` (string enum: "aggressive"/"calm"/"cool"/"dull"/"silly").
  - Constructor: `AnimalStats.new(speed, color, height, personality)` returns a table with those fields.
  - Static function `AnimalStats.random()` returns a stat block with randomised values (speed: random 20–80, color: random rgb, height: random 1–5, personality: random from enum list).
  - Static function `AnimalStats.breed(a, b)` returns a new stat block as offspring of parents a and b:
    - speed: average of parents ± random in range [-50, 50], clamped 0–100
    - color: per-channel average ± random shift up to 0.15, clamped 0–1
    - height: average rounded, then 50% chance ±1
    - personality: 80% chance inherit from a random parent, 20% chance random

- [x] Task 1b — `game/data/job.lua` — Implement Job and Goal data classes.
  - `Goal.new(type, params)` where type is one of: `"speed"`, `"color"`, `"height"`, `"personality"`.
    - speed params: `{min, max}`
    - color params: `{target={r,g,b}, max_dist}` (max Euclidean distance in 0–1 RGB space)
    - height params: `{value}` (exact int match)
    - personality params: `{value}` (exact string match)
  - `Goal.test(goal, stats)` returns true if the animal stats satisfy the goal.
  - `Job.new(goals, reward)` — table with `goals` (array of Goals), `reward` (number), `completed` (bool).
  - `Job.test(job, stats)` returns true if ALL goals pass.

- [x] Task 1c — `game/systems/mapper.lua` — Implement tile grid system.
  - Constants: `TILE = 32` (tile size in pixels).
  - `Mapper.snap(x, y)` → returns `{x, y}` snapped to nearest tile origin.
  - `Mapper.key(tx, ty)` → returns string `"tx,ty"` for use as table key.
  - `Mapper.set(grid, tx, ty, value)` → stores value at tile coords in the `grid` table.
  - `Mapper.get(grid, tx, ty)` → retrieves value at tile coords (or nil).
  - `Mapper.remove(grid, tx, ty)` → sets tile to nil.
  - `Mapper.clamp(x, y, w, h)` → clamps world position so a rect of size w×h stays inside `0,0, LOGICAL_W, LOGICAL_H` (use 1280×720 constants).

- [x] Task 1d — `game/systems/detector.lua` — Implement type-checking helpers.
  - Each function takes a Lua table and returns true/false based on its `_type` field:
    - `Detector.is_animal(e)`, `Detector.is_player(e)`, `Detector.is_breeder(e)`,
      `Detector.is_sell_bin(e)`, `Detector.is_wire(e)`, `Detector.is_item(e)`,
      `Detector.is_roll(e)`, `Detector.is_knife(e)`, `Detector.is_pruner(e)`.
  - Helper: `Detector.aabb(a, b)` → returns true if rects `{x,y,w,h}` overlap (standard AABB test).
  - Helper: `Detector.nearest(entity, list, max_dist)` → returns the nearest entity in list within max_dist, or nil.

- [x] Task 1e — `game/shaders/animal_color.lua` — Implement the animal skin-color shader module.
  - Write the GLSL shader source as a Lua string. The shader replaces pure red pixels (r≥0.95, g≤0.05, b≤0.05) with the supplied `color` uniform.
  - `AnimalColorShader.new()` → returns `love.graphics.newShader(glsl_source)`.
  - `AnimalColorShader.apply(shader, r, g, b)` → sends the `color` vec3 uniform.
  - `AnimalColorShader.clear()` → `love.graphics.setShader()`.

- [x] Task 1f — `game/shaders/outline.lua` — Implement highlight glow shader module.
  - GLSL: samples neighbours (±2 px) and blends in `outline_color` where the original alpha is 0 but a neighbour has alpha > 0.
  - `OutlineShader.new()` → returns shader.
  - `OutlineShader.apply(shader, r, g, b)` → sends `outline_color` uniform.
  - `OutlineShader.clear()` → `love.graphics.setShader()`.

- [x] Task 1g — `game/shaders/sway.lua` — Implement breeder sway shader module.
  - GLSL: displaces UV x-coordinate by `sin(time * frequency) * amplitude`, anchored at the bottom (displacement scales linearly with (1 - uv.y)).
  - `SwayShader.new()` → returns shader.
  - `SwayShader.apply(shader, time)` → sends `time` uniform.
  - `SwayShader.clear()` → `love.graphics.setShader()`.

- [x] Task 1h — `game/game_state.lua` — Implement global game state module.
  - Fields: `money` (number, starts 0), `wires` (number, starts 5), `jobs_done` (number, starts 0), `active_jobs` (array of Job tables).
  - `GameState.new()` → returns fresh state table.
  - No persistence needed (prototype).

---

## Wave 2 — Entities (depend on Wave 1)

- [x] Task 2a — `game/items/item.lua` — Implement base Item class.
  - Fields: `_type = "item"`, `x`, `y`, `w`, `h`, `name` (string), `carriable` (bool, default true), `sprite` (Sprite instance).
  - `Item.new(x, y, name, image_path)` → loads image, creates Sprite, returns table.
  - `Item:update(dt)` → syncs sprite position to x, y.
  - `Item:draw()` → calls `sprite:draw()`.
  - `Item:interact(player, scene)` → no-op base (overridden by subclasses).

- [x] Task 2b — `game/entities/wire.lua` — Implement Wire entity.
  - Fields: `_type = "wire"`, `x`, `y` (world pixel pos, snapped to tile), `tx`, `ty` (tile coords), `sprite`.
  - `Wire.new(tx, ty)` → snaps to tile origin, loads wire sprite, returns table.
  - `Wire:draw()` → draws sprite at x, y.
  - No update needed — wires are static.
  - Bounce logic lives in the animal (checks mapper grid each frame), not in the wire itself.

- [x] Task 2c — `game/entities/animal.lua` — Implement Animal entity (depends on Task 1a, 1e, 1f, 2a).
  - Fields: `_type = "animal"`, `x`, `y`, `w = 32`, `h = 32`, `stats` (AnimalStats), `vx`, `vy`, `held` (bool), `spriteset` (SpriteSet), `face_sprite` (Sprite), `_color_shader`, `_outline_shader`, `_wander_timer` (Timer).
  - `Animal.new(x, y, stats)` → randomises stats if nil, loads body/face sprites, sets random initial velocity (speed from stats), starts wander timer (1–3 s random).
  - `Animal:update(dt, wire_grid)` — when not held:
    - Move by `vx*dt, vy*dt`; clamp to world bounds (bounce on edges by flipping velocity).
    - Check AABB against each wire in `wire_grid`; if overlapping, flip the velocity component that aligns with the wire axis.
    - On wander timer expiry, pick a new random direction (speed magnitude from stats.speed scaled to px/s).
  - `Animal:draw()` — apply color shader with `stats.color`, draw body sprite; apply outline shader if `highlighted`; draw face sprite on top.
  - `Animal:highlight(on)` → sets `highlighted` bool.
  - Face texture: map `stats.personality` → one of 5 face image paths; load at construction.

- [x] Task 2d — `game/entities/breeder.lua` — Implement Breeder entity (depends on Task 1a, 1g).
  - Fields: `_type = "breeder"`, `x`, `y`, `w = 96`, `h = 96` (3×32 tile zone), `slots` (array of 2, each nil or Animal), `_timer` (Timer, interval 5 s), `_breeding` (bool), `sprite` (Sprite), `_sway_shader`, `_sway_time`.
  - `Breeder.new(x, y)` → loads breeder sprite, creates sway shader.
  - `Breeder:try_add(animal)` → returns true and stores animal if a slot is free; false otherwise.
  - `Breeder:update(dt)` — if `_breeding` and timer fires → call `_spawn_offspring()`, reset.
  - `Breeder:_spawn_offspring()` → breed the two animals using `AnimalStats.breed`; create new Animal; eject it near the breeder; clear slots; set `_breeding = false`.
  - `Breeder:draw()` — apply sway shader only when `_breeding`; draw sprite; draw each held animal as a small icon inside the zone.
  - When both slots filled → set `_breeding = true`, start timer, disable both animals' wandering (set `held = true` so they don't move).

- [x] Task 2e — `game/entities/sell_bin.lua` — Implement Sell Bin entity (depends on Task 1b, 1h).
  - Fields: `_type = "sell_bin"`, `x`, `y`, `w = 64`, `h = 64`, `sprite`.
  - `SellBin.new(x, y)` → loads sell_bin sprite.
  - `SellBin:try_sell(animal, game_state)` → tests `animal.stats` against each active job in `game_state.active_jobs`; if a job matches: award `job.reward` to `game_state.money`, set `job.completed = true`, increment `game_state.jobs_done`, return true. If no match, return false.
  - `SellBin:draw()` → draws sprite.

---

## Wave 3 — Items (depend on Wave 2)

- [x] Task 3a — `game/items/roll.lua` — Implement Roll item (wire placer) (depends on Task 2a, 2b, 1c, 1h).
  - Extends Item. Fields: `_type = "roll"`, `name = "Wire Roll"`.
  - Override `interact(player, scene)`: no-op on normal interact (player just picks it up).
  - Secondary action `use(player, scene)` called when player holds O while holding this item:
    - Snap player position to tile.
    - If `game_state.wires > 0` and tile is empty in `scene.wire_grid`:
      - Create `Wire.new(tx, ty)`, add to `scene.wires[]` and `scene.wire_grid`.
      - Decrement `game_state.wires`.

- [x] Task 3b — `game/items/knife.lua` — Implement Knife item (wire remover) (depends on Task 2a, 1c, 1h).
  - Extends Item. Fields: `_type = "knife"`, `name = "Knife"`.
  - Secondary action `use(player, scene)`:
    - Iterate all wire tiles within 2-tile radius of player.
    - Remove matching entries from `scene.wires[]` and `scene.wire_grid`.

- [x] Task 3c — `game/items/pruner.lua` — Implement Pruner item (depends on Task 2a).
  - Extends Item. Fields: `_type = "pruner"`, `name = "Pruner"`.
  - No special interaction — decorative item that can be picked up and dropped only.

---

## Wave 4 — Player, Job Generator, Shop UI (depend on Waves 2–3)

- [x] Task 4a — `game/entities/player.lua` — Implement Player entity (depends on Tasks 2a–2e, 3a–3c, 1c, 1d).
  - Fields: `_type = "player"`, `x`, `y`, `w = 32`, `h = 48`, `speed = 180`, `held_item` (nil or entity), `spriteset` (SpriteSet: idle/walk/idle_held/walk_held), `input` (Input instance).
  - Key map: `{move_up={"w","up"}, move_down={"s","down"}, move_left={"a","left"}, move_right={"d","right"}, interact={"e"}, secondary={"o"}, shop={"tab"}}`.
  - `Player.new(x, y)` → loads player sprites, creates input.
  - `Player:update(dt, scene)`:
    - Read movement axes; apply speed; clamp to world bounds via `Mapper.clamp`.
    - On `interact` pressed:
      - If holding animal → try drop onto breeder or sell_bin if overlapping; else drop at feet.
      - If holding item → drop at feet.
      - Else → pick up nearest animal or item within 48 px (prefer animals).
    - On `secondary` held → call `held_item:use(self, scene)` if held_item has `use`.
    - On `shop` pressed → toggle `scene.shop_open`.
  - `Player:draw()` → select spriteset variant based on held state + movement; draw.
  - `Player:pick_up(entity)` → sets `held_item`, sets entity `held = true`.
  - `Player:drop(entity)` → places entity at player feet, sets `held = true` false.

- [x] Task 4b — `game/systems/job_generator.lua` — Implement Job Generator (depends on Task 1b, 1h).
  - `JobGenerator.new(game_state)` → returns generator table with reference to state.
  - `JobGenerator:update(dt)` — tick an interval timer (8 s); on expiry generate a new job if `#game_state.active_jobs < 3`.
  - `JobGenerator:_make_job()` → build a Job with 1–2 random Goals; reward = `50 + jobs_done * 10`.
    - Available goal types gated by milestone: speed always available; personality unlocked at `jobs_done >= 8`; height at `>= 15`; color at `>= 30`.
  - `JobGenerator:_random_speed_goal()` → pick a mid-range target, window ±20.
  - `JobGenerator:_random_color_goal()` → pick random target color, max_dist 0.25.
  - `JobGenerator:_random_height_goal()` → pick random height 1–5.
  - `JobGenerator:_random_personality_goal()` → pick random personality string.

- [x] Task 4c — `game/scenes/shop_ui.lua` — Implement Shop UI overlay (depends on Tasks 3a–3c, 1h).
  - Not a Scene subclass — a plain table rendered on top of game_scene.
  - Fields: `open` (bool), `cursor` (int 1–3), `items` (array of shop slot tables `{name, item_constructor, cost}`).
  - Slots: Wire Roll (cost 20), Knife (cost 40), Pruner (cost 15).
  - `ShopUI.new(game_state)` → returns table.
  - `ShopUI:update(dt, input)` — when open: left/right arrow moves cursor; E/Enter purchases selected item if `game_state.money >= cost`.
  - `ShopUI:draw()` — draws a centred panel with 3 item cards; highlights cursor slot; shows money balance and item cost.

---

## Wave 5 — HUD Panels (depend on Wave 1h and entities)

- [x] Task 5a — `game/ui/animal_info.lua` — Animal info HUD panel (depends on 2c).
  - `AnimalInfo.new()` → returns table.
  - `AnimalInfo:set(animal_or_nil)` → stores reference.
  - `AnimalInfo:draw()` — if animal set, draws a small box (top-left corner) showing speed, color swatch, height, personality name.

- [x] Task 5b — `game/ui/job_info.lua` — Job info HUD panel (depends on 1b, 1h).
  - `JobInfo.new(game_state)` → returns table.
  - `JobInfo:draw()` — draws active jobs (up to 3) listing their goals with visual indicators (color swatch for color goals, numeric ranges for speed/height, personality name).

- [x] Task 5c — `game/ui/money_info.lua` — Money HUD panel (depends on 1h).
  - `MoneyInfo.new(game_state)` → returns table.
  - `MoneyInfo:draw()` — draws money balance in top-right corner. Also shows wire count.

- [x] Task 5d — `game/ui/actions_info.lua` — Nearby-item hints HUD (depends on 1d).
  - `ActionsInfo.new()` → returns table.
  - `ActionsInfo:set_nearby(list)` → stores list of nearby entity names.
  - `ActionsInfo:set_held(item_or_nil)` → stores held item reference.
  - `ActionsInfo:draw()` — draws bottom bar: "E: pick up [name]" for nearest, "O: [action]" if held item has secondary action.

---

## Wave 6 — Main Scene (depends on everything)

- [x] Task 6a — `game/scenes/game_scene.lua` — Implement main game scene (depends on all prior tasks).
  - Extends `Scene`. Fields: `animals[]`, `items[]`, `wires[]`, `wire_grid` (Mapper-style table), `statics[]` (breeder, sell_bin), `player`, `job_generator`, `shop_ui`, `hud` (animal_info, job_info, money_info, actions_info), `game_state`.
  - `on_enter()`:
    - Create `GameState`.
    - Spawn 6 animals at random positions.
    - Place Breeder at (400, 300), SellBin at (800, 500).
    - Place a WateringCan-equivalent (Roll) and Knife as starting items near the player.
    - Create all HUD panels.
    - Create `JobGenerator`.
    - Create `ShopUI`.
    - Spawn player at (640, 360).
  - `update(dt)`:
    - Update player (passing scene ref).
    - Update all animals (passing wire_grid).
    - Update breeder.
    - Update job_generator.
    - Update shop_ui if open.
    - Compute nearby entities for player → update actions_info.
    - Compute hovered/held animal → update animal_info.
    - Purge completed jobs from game_state.active_jobs.
  - `draw()`:
    - Draw tileset background.
    - Draw statics (breeder, sell_bin).
    - Draw wires.
    - Draw items.
    - Draw animals.
    - Draw player.
    - Draw HUD panels (animal_info, job_info, money_info, actions_info).
    - Draw shop_ui on top if open.

- [x] Task 6b — `main.lua` — Wire up game_scene as the starting scene.
  - In `love.load()`, replace the existing `game_scene.lua` require with `game/scenes/game_scene.lua`.
  - Ensure the SceneManager starts with a fresh GameScene instance.
  - No other changes to main.lua.

---

## Wave 7 — Tests

- [x] Task 7a — `tests/test_animal_stats.lua` — Tests for AnimalStats (headless).
  - `AnimalStats.random()` returns valid fields within expected ranges.
  - `AnimalStats.breed(a, b)` returns stats within allowed mutation bounds.
  - Speed always clamped 0–100; color channels clamped 0–1.

- [x] Task 7b — `tests/test_job.lua` — Tests for Job/Goal (headless).
  - Speed goal passes when stats.speed is inside range, fails outside.
  - Color goal passes when distance ≤ max_dist, fails otherwise.
  - Height goal passes on exact match only.
  - Personality goal passes on exact string match only.
  - `Job.test` requires ALL goals to pass.

- [x] Task 7c — `tests/test_mapper.lua` — Tests for Mapper (headless).
  - `snap` returns correct tile-aligned coordinates.
  - `set/get/remove` round-trip correctly.
  - `clamp` keeps rects inside 1280×720.

- [x] Task 7d — `tests/test_breeder.lua` — Tests for Breeder (headless).
  - Adding two animals sets `_breeding = true`.
  - After timer interval elapses (advance dt manually), offspring is created with bred stats.
  - Slots are cleared after breeding.

- [x] Task 7e — `tests/test_sell_bin.lua` — Tests for SellBin (headless).
  - Selling an animal matching a job awards money and marks job completed.
  - Selling an animal that doesn't match returns false and leaves money unchanged.

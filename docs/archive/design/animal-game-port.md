# Animal Game Port — Design Doc

## Goal

Port `/godot-animal-game` (Godot 4.2 prototype) into the Love2D engine at
`/normal-apple-farming`, achieving full feature parity. The result lives inside
`/normal-apple-farming` and replaces the current placeholder `game_scene.lua`.

---

## Affected files

**New — game logic**
```
game/entities/animal.lua
game/entities/player.lua
game/entities/breeder.lua
game/entities/sell_bin.lua
game/entities/wire.lua
game/items/item.lua          (base class)
game/items/roll.lua
game/items/knife.lua
game/items/pruner.lua
game/data/animal_stats.lua
game/data/job.lua
game/systems/job_generator.lua
game/systems/mapper.lua
game/systems/detector.lua
game/game_state.lua
game/scenes/game_scene.lua   (replaces existing stub)
game/scenes/shop_ui.lua      (overlay, not a full scene)
game/ui/animal_info.lua
game/ui/job_info.lua
game/ui/money_info.lua
game/ui/actions_info.lua
game/shaders/animal_color.lua
game/shaders/outline.lua
```

**Modified**
```
main.lua          — swap in game_scene as the starting scene
game/player.lua   — replaced by game/entities/player.lua
```

**Assets (copied from Godot project)**
```
assets/images/animal/
assets/images/player/
assets/images/breeder/
assets/images/sell_bin/
assets/images/shop/
assets/images/items/    (knife, roll, pruner)
assets/images/tileset.png
```

---

## What changes

### Resolution & tile grid
- Template: 1280×720. Godot game: 1920×1080 with 48 px tiles.
- Port uses **32 px tiles** → 40×22.5 tiles at 1280×720, same logical density.
- `mapper.lua` handles tile-snapped coordinate storage and world-boundary clamping.

### Entity model
Godot's scene nodes become plain Lua tables.
Every entity has `x, y, w, h`, an `update(dt)` function, and a `draw()` function.
The game scene holds flat lists: `animals[]`, `items[]`, `wires[]`, `statics[]`
(breeder, sell_bin).

### Animal
- Wanders with random velocity; bounces off world edges.
- Stats: `speed` (0–100), `color` (r,g,b floats), `height` (int), `personality` (enum: aggressive/calm/cool/dull/silly).
- Face texture selected from a per-personality array.
- Skin color applied via `animal_color.lua` shader (pure-red → skin color substitution).
- Held animals are carried above the player and stop wandering.

### Player
- WASD movement; speed proportional to `Animal_Stats` base speed (player is not an animal).
- **E** — interact: pick up the nearest animal/item or drop held item.
- **O (hold)** — secondary action: if holding Roll → place wire at tile; if holding Knife → delete wires in range.
- Holds **one item** at a time. Hovering nearby items shown in `actions_info` HUD.
- Dropping an animal onto the breeder or sell_bin triggers those zones.

### Breeder
- Static zone occupying ~3×3 tiles.
- Accepts up to 2 animals (dropped by player).
- When full, starts a countdown timer; offspring spawns on completion with inherited + mutated stats.
- Mutation: speed ±50, color channel shift, height ±1 (50% chance), personality 80% parent / 20% random.
- Breeding timer shown via a sway animation on the breeder sprite (port `sway.gdshader` → `sway.lua`).

### Sell bin
- Static zone; player drops animal onto it.
- Checks active job goals against animal stats.
- If match → award money, increment `game_state.jobs_done`, mark job complete.
- If no match → animal is returned to player.

### Job system
- A `job.lua` table holds a list of `goal` entries, each with a type and threshold:
  - `speed` — min/max range
  - `color` — max distance (Euclidean in RGB space)
  - `height` — exact match or threshold
  - `personality` — exact enum match
- Active jobs displayed in `job_info.lua` HUD.
- `job_generator.lua` creates new jobs on timer; reward scales with `jobs_done`.
  - Milestone unlocks: personality goals at 8, height at 15, color at 30.

### Wire / Roll / Knife
- Wires placed on tile grid (stored in `mapper.lua`).
- Wire bounce: when an animal AABB overlaps a wire tile, reverse its x or y velocity.
- Roll item: Hold O while holding Roll → place wire at player's snapped tile position.
  Deducts from `game_state.wires` counter.
- Knife item: Hold O while holding Knife → remove all wires within interact range.

### Pruner
- Passive decoration item; no game effect (matches Godot prototype where it was listed as unused).
- Can be picked up and dropped.

### Shop
- Toggled with **Tab** key; rendered as an overlay (not a scene switch).
- 4 item slots with cursor navigation (left/right arrow).
- Press Enter/E to buy selected item; costs deducted from money.
- Items available: Roll (wire), Knife, Pruner.

### HUD
| Panel | Content |
|-------|---------|
| `animal_info` | Stats of held or hovered animal |
| `job_info` | Active job requirements |
| `money_info` | Current money balance |
| `actions_info` | Nearby-item hints + secondary action hint |

### Shaders
| Shader | Purpose |
|--------|---------|
| `animal_color.lua` | Substitutes pure red in animal sprites with the animal's `color` stat |
| `outline.lua` | Highlight glow when animal is hovered/held |
| `sway.lua` | Breeder sway during countdown |

---

## What stays the same

- `main.lua` canvas / letterbox / logical-resolution system.
- All `core/lua/` engine classes (SceneManager, Scene, Sprite, SpriteSet, Drawer, Camera, Input, Timer, Fonts).
- Headless test infrastructure (`lua/headless/`).
- No save system needed — this is a prototype with no persistence.
- No scene transitions — game is a single scene.

---

## Open questions

None — all design questions resolved before writing this doc.

---

## Key mapping (Godot → Love2D)

| Godot concept | Love2D equivalent |
|---------------|------------------|
| Node2D / Area2D | Lua table `{x,y,w,h}` |
| Signal | Callback closure |
| CharacterBody2D | Custom `x,y` + `vx,vy` + manual delta integration |
| Area2D overlap | AABB intersection check in `update()` |
| AnimatedSprite2D | `SpriteSet` with named frames |
| GDShader | GLSL via `love.graphics.newShader` |
| TileMap | `mapper.lua` string-keyed tile table |
| `$NodePath` references | Direct Lua table references passed at construction |
| `@onready` | Set in `new()` constructor |

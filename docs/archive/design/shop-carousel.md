## Goal

Redesign the shop scene to look like the PC buy scene in the wip project: one item at a time, centered carousel layout, using wip's visual assets.

## Affected files

- `game/scenes/shop_scene.lua` — draw() rewrite + font/image loading; CATALOGUE gets `image` fields
- `game/shaders/crt.lua` — new; wraps `core/lua/shader` for the CRT post-process
- `game/ui.lua` — new; HUD utilities (currency bubble, hints box) adapted from wip's `ui.lua`
- `assets/images/shop/` — new assets copied from wip: `buy_bg.png`, `arrow_left.png`, `arrow_right.png`, `dot_active.png`, `dot_inactive.png`, `coin.png`, `speech_bubble.png`
- `assets/fonts/font.ttf` — copied from wip
- `assets/shaders/crt.glsl` — copied from wip

## What changes

### Layout: carousel replaces card grid

The panel with three side-by-side cards is replaced by a full-screen carousel that shows one item at a time, centered. The active item displays:

1. **Preview image** (160×160, scaled to fit) — centered horizontally, vertically balanced
2. **Item name** — large font, centered below preview
3. **Description** — medium font, centered, multi-line
4. **Price** — coin icon + number, color-coded (green = affordable, red = not); "---" if cost is 0 (free items)
5. **Arrow images** — `arrow_left.png` / `arrow_right.png` at center_y, ±230px from center
6. **Dot indicators** — `dot_active.png` / `dot_inactive.png` row near bottom center, one dot per catalogue item

### Background and post-processing

- `buy_bg.png` replaces the dark overlay + rounded-rect panel
- Scene draws to an off-screen canvas, then the CRT shader (`crt.glsl`) is applied on blit, matching wip exactly

### HUD (drawn after CRT blit, unaffected by shader)

- **Currency bubble** top-left: speech-bubble 9-patch with coin icon + money amount (uses `game/ui.lua`)
- **Hints box** bottom-left: speech-bubble 9-patch with key hints (uses `game/ui.lua`)

### CATALOGUE additions

Each entry gains an `image` field pointing to the item's existing in-game sprite:

| Item       | Image path                                 |
|------------|--------------------------------------------|
| Wire Roll  | `assets/images/items/wire_roll.png`        |
| Knife      | `assets/images/items/knife.png`            |
| Breeder    | `assets/images/breeder/love_bin.png`       |

### New modules

**`game/shaders/crt.lua`** — thin wrapper over `core/lua/shader`, identical interface to wip:
```lua
{ apply = fn, clear = fn }
```

**`game/ui.lua`** — adapted from wip's `ui.lua`. Uses 9-patch drawing with `speech_bubble.png`. Exports:
```lua
{ draw_hud_box(labels, font, margin), draw_currency_bubble(currency, x, y, font) }
```

## What stays the same

- Navigation logic: left/right wrap, `interact` to buy, `cancel` to close
- CATALOGUE entries: names, costs, descriptions, constructors
- Purchase logic: money check, item instantiation, player hand-off, scene switch
- `on_enter()` skip-frame input guard

## Open questions

None — CRT shader: yes; sounds: skip for now.

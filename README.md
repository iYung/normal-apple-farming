# Normal Apple Farming

An animal breeding game built in Love2D — a port of a Godot prototype. Breed animals to fulfil customer jobs, earn money, and unlock new goal types as your farm grows.

## What the game is

You play as a farmer who:
- Catches and carries animals around a fenced field
- Places animals into the **Breeder** (two at a time) to produce offspring with blended traits
- Sells animals at the **Sell Bin** to complete customer **Jobs** (e.g. "animal with speed ≥ 60 and calm personality")
- Earns money to buy Wire Rolls, Knives, and Pruners from the **Shop**
- Lays wire fences to redirect wandering animals

Animals have four heritable traits: **speed**, **color** (RGB), **height**, and **personality**. The breeding system blends parent stats with small random mutations. Jobs become progressively harder as you complete more of them — early jobs ask only about speed; later jobs add personality, height, and color goals.

## Controls

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Move player |
| E | Pick up / drop animal or item; purchase in shop |
| O (hold) | Use held item (place wire with Roll, remove wire with Knife) |
| Tab | Open / close Shop |

## How to run

```bash
love .                  # open a window and play
love . --headless       # run the test suite and exit
```

Requires [Love2D](https://love2d.org/) 11.x or later.

## Project structure

```
core/lua/           Engine classes — Camera, Drawer, Input, Scene,
                    SceneManager, Sprite, SpriteSet, Timer, Fonts
game/
  data/             AnimalStats, Job/Goal data classes
  entities/         Animal, Player, Breeder, SellBin, Wire
  items/            Item base class, Roll, Knife, Pruner
  scenes/           GameScene (main), ShopUI overlay
  shaders/          AnimalColor, Outline, Sway GLSL shaders
  systems/          Mapper (tile grid), Detector (type/AABB helpers), JobGenerator
  ui/               AnimalInfo, JobInfo, MoneyInfo, ActionsInfo HUD panels
  game_state.lua    Global state (money, wires, jobs)
lua/headless/       Headless stubs and test runner
tests/              Unit tests (run with: love . --headless)
assets/             Images — animal sprites, player, items, tileset
conf.lua            Window config; suppresses graphics/audio under --headless
main.lua            Entry point — 1280×720 canvas with letterboxing
```

See [`core/lua/README.md`](core/lua/README.md) for API docs on each engine class.

## Architecture notes

- **Fixed logical resolution** — game renders to a `1280×720` canvas; `main.lua` scales it to the window with letterboxing. Works with any window size.
- **Scene transitions** — `SceneManager` fades through black (0.3 s) between scene switches.
- **Headless tests** — `lua/headless/stubs.lua` installs no-op love API replacements so test files run without a window. `HeadlessInput` lets tests script action presses frame-by-frame. See `tests/test_basics.lua` for a minimal example.
- **Tile grid** — `Mapper` tracks wire placement on a 32 px tile grid; animals bounce off wire tiles each frame.
- **Shader pipeline** — animals are drawn with a skin-color shader (replaces pure-red pixels with the animal's `stats.color`); highlighted animals get an outline glow shader; the Breeder sways while breeding.

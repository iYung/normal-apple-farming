# Normal Apple Farming

An animal breeding game built in Love2D — a port of a Godot prototype. Breed animals to fulfil customer jobs, earn money, and unlock new goal types as your farm grows.

## What the game is

You play as a farmer who:
- Catches and carries animals around a fenced field
- Places animals into the **Breeder** (two at a time) to produce offspring with blended traits
- Sells animals at the **Sell Bin** to complete customer **Jobs** (e.g. "animal with speed greater than 60 and calm personality")
- Earns money to buy Wire Rolls, Knives, Breeders, and a **Rocket** from the **Shop**
- Lays wire fences to redirect wandering animals

Animals have four heritable traits: **speed**, **color** (RGB), **height**, and **personality**. The breeding system blends parent stats with small random mutations. Jobs become progressively harder as you complete more of them — early jobs ask only about speed; later jobs add personality, height, and color goals.

## Controls

### Keyboard

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Move player |
| F | Pick up / drop animal or item |
| E | Open shop (near shop counter); use held item — hold to place wire with Roll or remove wire with Knife |
| ESC | Open / close settings menu |

Controls can be rebound in the settings menu. Settings (keybinds, fullscreen) persist between sessions.

### Gamepad

| Button | Action |
|--------|--------|
| Left stick / D-pad | Move player |
| A | Interact (open shop; use held item) |
| Y | Pick up / drop animal or item |
| B | Cancel / back (exit shop, close menu) |
| Start | Open / close settings menu |

The game auto-detects gamepad input and switches HUD prompts to button labels. In gamepad mode the Keybinds option is hidden in the settings menu (controller layout is fixed).

## How to run

```bash
love .                  # open a window and play
love . --headless       # run the test suite and exit
```

Requires [Love2D](https://love2d.org/) 11.x or later.

## Project structure

```
core/lua/           Engine classes — Camera, Drawer, Input, Scene,
                    SceneManager, Sprite, SpriteSet, Timer, Fonts, Save, Sound
game/
  data/             AnimalStats, Job/Goal data classes
  entities/         Animal, Player, Breeder, SellBin, Wire
  items/            Item base class, Roll, Knife, ShopItem, Rocket, Book
  scenes/           StartScene (title), GameScene (main), ShopScene (buy menu),
                    SettingsMenu (overlay), GameOverScene (rocket end), BookScene (full-screen read view)
  shaders/          AnimalColor, Outline, Sway, CRT GLSL shaders
  systems/          Mapper (tile grid), Detector (type/AABB helpers), JobGenerator
  ui/               AnimalInfo, JobInfo, MoneyInfo, ActionsInfo HUD panels
  ui.lua            Shared HUD utilities (currency bubble, hints box, 3-slice job card)
  fonts.lua         Font factory wrapper (binds assets/font.ttf)
  game_state.lua    Global state (money, wires, jobs)
  settings_state.lua  Fullscreen and keybind settings; serialises to settings.dat
lua/headless/       Headless stubs and test runner
tests/              Unit tests (run with: love . --headless)
assets/
  images/           Animal sprites, player, items, tileset, hud/
  sounds/           SFX wav files (pick_up, put_down, sell, breed, shop, menu…)
  music/            Background tracks bg1–bg4 and title menu.mp3
conf.lua            Window config; suppresses graphics/audio under --headless
main.lua            Entry point — 1280×720 canvas with letterboxing
```

See [`core/lua/README.md`](core/lua/README.md) for API docs on each engine class.

## CI and web builds

Two GitHub Actions workflows run on pushes and PRs to `master`:

- **`.github/workflows/ci.yml`** — installs LÖVE 11.5 and runs `love . --headless` to verify tests pass.
- **`.github/workflows/web.yml`** — builds a love.js web bundle via `bash scripts/build_web.sh`, deploys production builds to Cloudflare Pages (`normal-apple-farming` project) on push to `master`, and posts a preview link comment on PRs.

To enable deploys, add `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` as GitHub Actions secrets.

## Sound and music

The game has full audio using LÖVE's audio system, handled by `core/lua/sound.lua`:

- **Title screen** — `menu.mp3` plays on the start screen and fades out (2 s) when the game begins.
- **Gameplay** — one of four background tracks (`bg1`–`bg4`) fades in at game start; tracks rotate automatically when one finishes (non-looping, sequential).
- **SFX** — pick up / put down animals and items; breed complete; sell animal; shop navigate / buy / insufficient funds; settings menu navigate / confirm.
- **Focus resume** — music resumes automatically when the window regains focus.
- Audio is disabled in headless mode via `conf.lua`; `lua/headless/stubs.lua` provides no-op stubs so the Sound module is fully testable without a window.

Sound effects by [qubodup](https://freesound.org/people/qubodup/). Music by Trash Kid. See `assets/sounds/attribution.txt`.

## Architecture notes

- **Fixed logical resolution** — game renders to a `1280×720` canvas; `main.lua` scales it to the window with letterboxing. Works with any window size.
- **Scene transitions** — `SceneManager` fades through black (0.3 s) between scene switches.
- **Shared input** — a single `Input` object is created in `main.lua` and passed through to every scene (StartScene → GameScene → ShopScene / BookScene / Player). `input:update()` is called once per frame in the main loop before `scene_manager:update(dt)`; scenes do not call it themselves. This lets the same object carry gamepad state across all scenes and surfaces `input._mode` (`"keyboard"` | `"gamepad"`) for adaptive HUD prompts.
- **Gamepad** — `core/lua/input.lua` polls the first connected gamepad each frame: left stick (±0.3 threshold) and D-pad drive movement; A/Y/B drive interact/pickup/cancel. `key_for(action)` returns the current label (`"e"` or `"[A]"` etc.) so HUD and scene prompts adapt automatically. `love.joystickadded/removed/gamepadpressed` in `main.lua` manage the active joystick and switch `input._mode`.
- **Headless tests** — `lua/headless/stubs.lua` installs no-op love API replacements so test files run without a window. `HeadlessInput` lets tests script action presses frame-by-frame. The `getFont` stub returns a minimal mock font (`getWidth`, `getHeight`) so UI modules that measure text can be exercised headlessly. See `tests/test_basics.lua` for a minimal example.
- **Tile grid** — `Mapper` tracks wire placement on a 32 px tile grid; animals bounce off wire tiles each frame. While holding a Wire Roll, a semi-transparent preview of the wire is drawn at the player's current tile — white when the tile is free, red-tinted when it is already occupied.
- **Job generation** — `JobGenerator` ticks an 8-second timer and spawns jobs (up to 4 active at once). The first few jobs are fixed tutorial entries; thereafter jobs are generated randomly. All tuning values — spawn interval, active-job cap, unlock milestones, per-type goal parameters, and reward formula — live in a single `CONFIG` table at the top of `game/systems/job_generator.lua`. Goal types and multi-goal counts unlock progressively as `jobs_done` passes milestones defined in that table. Active jobs are displayed in the top-right HUD as **Orders** cards, each using a 3-slice card asset (top/mid/bottom) with one row per goal and a reward row at the bottom.
- **Shader pipeline** — animals are drawn with a skin-color shader (replaces pure-red pixels with the animal's `stats.color`); highlighted entities (animals and items near the player) get a yellow outline glow shader; the Breeder sways while breeding. The shop scene renders to an off-screen canvas and blits through a CRT post-process shader (`game/shaders/crt.lua`); the money HUD (top-left) and controls hint (bottom-left) are then drawn in screen space on top of the CRT output so they match the game scene's HUD style. The outline shader works by coloring transparent pixels adjacent to opaque ones, so all item sprite PNGs must be saved as **RGBA** with at least a 2-pixel transparent border around the artwork.
- **Animal info HUD** — when the player holds an animal, the stats bubble (speed, height, trait, color) floats centered above the animal in world space, computed each frame via the camera transform and clamped to screen edges.
- **Y-sort** — all world entities (wires, ground items, animals, player) are collected into one list each frame and sorted by bottom edge Y (`y + h`) before drawing, so entities lower on screen naturally appear in front of those higher up. The held item is drawn immediately after the player in the sorted pass so it stays on top of the player sprite.

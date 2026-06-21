# Sounds and Music

## Goal

Port the sound and music system from `../wip` into this game. This includes the `Sound` core module, all relevant audio assets, background music during gameplay, menu music on a new title/start screen, and SFX wired up to player actions, shop interactions, breeding, selling, and the settings menu.

No volume sliders (user confirmed skip for now). No animalese (no NPC dialogue in this game).

---

## Affected files

**New files:**
- `core/lua/sound.lua` — ported from `../wip/lua/core/sound.lua`
- `game/scenes/start_scene.lua` — new minimal title screen
- `assets/sounds/` — 9 .wav files copied from wip
- `assets/music/` — 5 .mp3 files copied from wip
- `tests/test_sound.lua` — ported from `../wip/tests/test_sound.lua`

**Changed files:**
- `main.lua` — load Sound, call update/on_focus, start at StartScene
- `game/scenes/game_scene.lua` — start bg music on enter, rotate tracks
- `game/scenes/shop_scene.lua` — navigate/buy/fail SFX
- `game/scenes/settings_menu.lua` — navigate/confirm SFX
- `game/entities/player.lua` — pick_up / put_down SFX
- `game/entities/breeder.lua` — breed complete SFX
- `game/entities/sell_bin.lua` — sell SFX

---

## What changes

### 1. `core/lua/sound.lua` (new)

Verbatim copy of `../wip/lua/core/sound.lua` with one guard added: skip the animalese load if `manifest.animalese` is nil (line 18). Everything else stays identical — the module is already headless-safe (`if not love.audio then return end` guards).

### 2. Audio assets (new)

Copy from `../wip/assets/`:

**Sounds** → `assets/sounds/`:
- `pick_up.wav`, `put_down.wav`
- `sell_plant.wav` (used as the sell-animal sound)
- `clone_success.wav` (used as the breed-complete sound)
- `shop_navigate.wav`, `shop_buy.wav`
- `fail.wav`
- `menu_navigate.wav`, `menu_confirm.wav`
- `attribution.txt`

**Music** → `assets/music/`:
- `menu.mp3` (title screen, looping)
- `background.mp3`, `background2.mp3`, `background3.mp3`, `background4.mp3` (gameplay rotation, non-looping)

### 3. `game/scenes/start_scene.lua` (new)

Minimal title screen:
- Draws game title and "Press E to start" prompt
- On `on_enter()`: play `menu` music
- On E pressed: fade `menu` music to 0 over 2s, switch to `GameScene`
- Escape opens settings menu (already handled in `main.lua`)
- Exposes `esc_opens_settings = true` so `main.lua`'s escape handler fires

### 4. `main.lua` changes

- `require("core/lua/sound")` at top
- In `love.load()`:
  - Switch to `StartScene` instead of `GameScene` as the initial scene
  - Call `Sound.load(manifest)` with the sfx list and music tracks
  - Menu music does NOT autoplay here — `StartScene:on_enter()` starts it
- In `love.update(dt)`: call `Sound.update(dt)` each frame
- Add `love.focus(focused)` handler calling `Sound.on_focus(focused)`

Sound manifest:
```lua
Sound.load({
    sfx_dir = "assets/sounds/",
    sfx = {
        "pick_up", "put_down", "sell_plant",
        "clone_success", "shop_navigate", "shop_buy",
        "fail", "menu_navigate", "menu_confirm",
    },
    music = {
        menu = { path = "assets/music/menu.mp3",         autoplay = false },
        bg1  = { path = "assets/music/background.mp3",  looping = false },
        bg2  = { path = "assets/music/background2.mp3", looping = false },
        bg3  = { path = "assets/music/background3.mp3", looping = false },
        bg4  = { path = "assets/music/background4.mp3", looping = false },
    },
})
```

### 5. `game/scenes/game_scene.lua` changes

In `on_enter()`:
- Fade `menu` music to 0 over 2s (in case player returns from start screen)
- Pick a random bg track and fade it in over 2s
- Store `_bg_list = {"bg1","bg2","bg3","bg4"}` and `_bg_index`

In `update(dt)`:
- If the current bg track is no longer playing, advance to next index and fade it in over 2s

### 6. `game/scenes/shop_scene.lua` changes

- Left/right navigation → `Sound.play("shop_navigate")`
- Successful purchase → `Sound.play("shop_buy")`
- Insufficient funds (money < cost) → `Sound.play("fail")`

### 7. `game/scenes/settings_menu.lua` changes

- Up/down selection change → `Sound.play("menu_navigate")`
- Confirm action (`_confirm()`) → `Sound.play("menu_confirm")`
- Sub-screen (keybinds) up/down navigation → `Sound.play("menu_navigate")`

### 8. `game/entities/player.lua` changes

- In `_pick_up()` → `Sound.play("pick_up")`
- In `_handle_pickup()` when item is dropped (the `held.x = self.x` branch) → `Sound.play("put_down")`
- When an animal is placed into a breeder → `Sound.play("put_down")`
- When an animal is successfully sold → no sound here (sell_bin handles it)

### 9. `game/entities/sell_bin.lua` changes

- On successful sell (any sell, whether job match or base price) → `Sound.play("sell_plant")`

### 10. `game/entities/breeder.lua` changes

- When breeding completes (offspring spawned in `update()`) → `Sound.play("clone_success")`

### 11. `tests/test_sound.lua` (new)

Ported from `../wip/tests/test_sound.lua`. Key adjustments:
- Module path: `"core/lua/sound"` instead of `"lua/core/sound"`
- Manifest updated to match the project's sfx list (no animalese key)
- All tests retained: load, play, sfx/music volume, update, fade, stop, is_playing, play_random_music, on_focus, looping flags

---

## What stays the same

- `conf.lua` — headless mode already disables audio; no change needed
- `lua/headless/stubs.lua` — already stubs `love.audio`; no change needed
- `game/settings_state.lua` — no sound volume fields (no volume sliders in scope)
- `game/scenes/game_over_scene.lua` — no sound (restart takes player back to GameScene which already has bg music running)

---

## Open questions

None — all design decisions confirmed with user before writing this doc.

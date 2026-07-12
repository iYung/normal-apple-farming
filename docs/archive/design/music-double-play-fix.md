# Music Double-Play Fix

## Goal

Two background-music tracks can currently end up audible at the same time. Fix it so that **at most one `bg`-group track ever has `playing_intent = true` at once**, enforced centrally inside `core/lua/sound.lua`, rather than relying on every call site (`game_scene.lua`, `game_over_scene.lua`, ...) to remember to stop the previous track. Two known trigger paths, both confirmed by reading the current code:

- **Restart after game over** — `GameScene:on_exit()` never stops the running `bg1`–`bg4` track; `GameOverScene` never touches audio either; a fresh `GameScene:on_enter()` on restart just fades in a new random track on top of the still-playing old one.
- **Losing/regaining window focus mid-track** — `GameScene:update`'s poll (`if not Sound.is_music_playing(...) then advance ...`) can't tell "track suspended by the OS while unfocused" from "track finished." When it misfires, it starts the next track without clearing the old (still `playing_intent = true`) one's intent. `Sound.on_focus(true)` then resumes *every* track with `playing_intent == true`, so both the stale old track and the new one come back.

## Affected files

- `core/lua/sound.lua` — the actual fix (new group-exclusivity behavior in `Sound.play_music` / `Sound.fade_music`; `Sound.play_random_music` refactored to reuse it instead of its own weaker version of the same idea).
- `main.lua` — tag `bg1`–`bg4` with a shared `group = "bg"` in the music manifest passed to `Sound.load`. `menu` is left out of any group.
- `tests/test_sound.lua` — manifest needs `group` tags added to bg tracks; new test cases for the exclusivity behavior (see below).

**Explicitly not changed:** `game/scenes/game_scene.lua`, `game/scenes/game_over_scene.lua`, `game/scenes/start_scene.lua`. This is the main appeal of fixing it in `Sound` — both bugs go away without touching any scene code, and no scene ever has to remember to call `stop_music` on the way out.

## What changes

### 1. Manifest gets a `group` field (`main.lua`)

```lua
music = {
    menu = { path = "assets/music/menu.mp3",         autoplay = false },
    bg1  = { path = "assets/music/background.mp3",  looping = false, group = "bg" },
    bg2  = { path = "assets/music/background2.mp3", looping = false, group = "bg" },
    bg3  = { path = "assets/music/background3.mp3", looping = false, group = "bg" },
    bg4  = { path = "assets/music/background4.mp3", looping = false, group = "bg" },
},
```

`Sound.load` stores `entry.group = track.group` (nil if omitted — `menu` stays ungrouped, i.e. exempt from exclusivity).

### 2. A shared "claim the group" helper in `core/lua/sound.lua`

```lua
local function _claim_group(name)
    local claimant = _music_tracks[name]
    if not claimant or not claimant.group then return end
    for other_name, entry in pairs(_music_tracks) do
        if other_name ~= name and entry.group == claimant.group then
            entry.src:stop()
            entry.playing_intent = false
            entry.fade_vol       = 1
            entry.fade_target    = 1
            entry.fade_rate      = 0
            entry.stop_on_done   = false
        end
    end
end
```

Called from:
- `Sound.play_music(name)` — unconditionally, before playing.
- `Sound.fade_music(name, target_vol, duration)` — only inside the existing `target_vol > 0` branch (i.e. only when the call is *bringing this track up*, not when it's fading something out to 0 — fading out doesn't claim ownership of the group).
- `Sound.play_random_music` — replaces its private stop-loop with a call to `_claim_group(picked)` right before `Sound.fade_music(picked, 1, fade_duration)`, removing the now-duplicated logic.

**Important correctness detail:** the loop is keyed on **group membership**, not on `entry.src:isPlaying()`. `Sound.play_random_music`'s existing stop-loop only stops tracks where `isPlaying()` is currently true — that condition is exactly what fails to fix the focus-loss bug: at the moment the update-loop poll misfires, the stale old track's `isPlaying()` is *already false* (that's the whole reason the poll thought it had finished). Its `playing_intent` is the only thing still saying it's "supposed" to be playing. So `_claim_group` must unconditionally reset every other same-group entry regardless of current `isPlaying()` state — calling `stop()` on an already-stopped/suspended source is harmless.

### 3. Why this fixes both bugs without touching scene code

- **Restart bug**: new `GameScene:on_enter()` calls `Sound.fade_music(new_bg_track, 1, 2)` exactly as it does today. That call now claims the `"bg"` group first, stopping the leftover track from the previous run as a side effect.
- **Focus-loss bug**: when the update-loop poll misfires and calls `Sound.fade_music(next_track, 1, 2)`, that call claims the group and clears the old track's `playing_intent` — even though the old track's `isPlaying()` was already false. When focus returns, `Sound.on_focus(true)`'s resume sweep no longer finds the old track eligible (`playing_intent` is false), so only the current track resumes.
- As a bonus, this also closes a latent third path not explicitly called out in the bug reports but present in the current code: today, `playing_intent` is *never* cleared when a `bg` track finishes playing naturally (non-looping tracks just stop; nothing in `Sound.update` reacts to that). So after any number of natural track transitions during normal play — no focus loss involved — every previously-finished `bg` track still has `playing_intent = true` forever, and *all* of them would come back on the next focus toggle, not just "the old one." Group-claiming on every track start fixes this too, since starting track N+1 always clears track N's intent regardless of why track N stopped.

### 4. `menu` stays its own thing

`menu` is left ungrouped (no `group` key), so it is unaffected by any of the above. This is deliberate, not just a default: `GameScene:on_enter()` currently does
```lua
Sound.fade_music("menu", 0, 2)
Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
```
— an intentional ~2-second crossfade where menu music fades out while the first bg track fades in. If `menu` shared a group with `bg1`–`bg4`, claiming the group would hard-stop `menu` the instant the bg track starts, killing that crossfade. Keeping `menu` out of the group preserves existing behavior exactly.

## What stays the same

- `menu` track logic, `StartScene`, and the menu/bg crossfade at game start — untouched.
- The update-loop's `is_music_playing()`-based "did the current track finish" heuristic in `GameScene:update` (`game/scenes/game_scene.lua` ~line 229) is unchanged. It's still unable to distinguish "the OS suspended the audio device because the window lost focus" from "the track actually finished." After this fix that ambiguity can no longer cause **overlapping audio** — but it can still cause the game to advance to a different bg track earlier than the current one actually finished, if you tab away mid-track. That's a separate, milder, pre-existing behavior this design does not change (see open questions).
- `Sound.on_focus`, `Sound.stop_music`, `Sound.set_music_volume`, `Sound.update`, all SFX playback (`Sound.play`, `Sound.play_animalese`) — untouched.
- `tests/test_start_scene.lua` — `menu` is ungrouped, so its behavior (and this test) is unaffected.

## Open questions

1. **Hard stop vs. fade-out for the losing track.** `_claim_group` as designed above does an instant `src:stop()` on the outgoing track (matching `play_random_music`'s existing convention). In the restart-after-win case specifically, the old bg track has typically been playing continuously through the entire Game Over screen, so this is an abrupt audible cut the instant you press E to restart, rather than a smooth crossfade like the menu→bg transition gets. Is an instant cut acceptable here (simplest, matches existing `play_random_music` behavior), or should the claimed-away track fade out over ~1s instead (smoother, but more moving parts — would need `_claim_group` to trigger a fade rather than a hard stop, and to not be blocked by the winning track's own fade-in timing)?

2. **Scope: should this pass also fix the "premature track change on refocus" residual behavior**, or is preventing double-play sufficient for now? As noted above, this fix does not solve the underlying "can't tell suspended from finished" ambiguity — it only ensures that ambiguity can no longer produce *simultaneous* audio. A player who alt-tabs mid-track may still come back to a different bg track than the one that was playing, instead of the same track resuming where it left off. Solving that properly is a bigger change (e.g. main.lua's `love.update` would need to skip the finished-check while unfocused, or `Sound` would need a real paused/suspended state distinct from `playing_intent`). Recommend treating it as out of scope / a separate future fix unless there's a reason to bundle it now.

# Music Double-Play Fix Checklist

- [x] Task A — `main.lua` — In the `music = { ... }` table passed to `Sound.load` (~lines 77–82), add `group = "bg"` to each of the `bg1`, `bg2`, `bg3`, and `bg4` entries. Leave `menu` unchanged (no `group` key — it must stay ungrouped/exempt from exclusivity). Result should read:
  ```lua
  music = {
      menu = { path = "assets/music/menu.mp3",         autoplay = false },
      bg1  = { path = "assets/music/background.mp3",  looping = false, group = "bg" },
      bg2  = { path = "assets/music/background2.mp3", looping = false, group = "bg" },
      bg3  = { path = "assets/music/background3.mp3", looping = false, group = "bg" },
      bg4  = { path = "assets/music/background4.mp3", looping = false, group = "bg" },
  },
  ```
  No other changes to this file. Depends on nothing — parallel-safe.

- [x] Task B — `core/lua/sound.lua` — Implement centralized group-exclusivity for music tracks. Depends on nothing (parallel-safe with Task A; `Sound.load` reads `track.group` defensively so it works whether or not `main.lua`'s manifest has been updated yet). Make these four changes:
  1. In `Sound.load(manifest)`, inside the `for name, track in pairs(manifest.music) do` loop, add a `group = track.group,` field to the `_music_tracks[name] = { ... }` table literal (alongside `src`, `fade_vol`, etc.). This will be `nil` for any manifest entry that omits `group` (e.g. `menu`), which is intentional — `nil` means "not in any group, exempt from exclusivity."
  2. Add a new local helper function, placed above `Sound.play_music`:
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
     **Critical:** this loop must key only on `entry.group == claimant.group` and must NOT gate on `entry.src:isPlaying()`. It has to reset every other same-group entry unconditionally, including ones whose `isPlaying()` is already false — that's what makes this fix work where the old `play_random_music` stop-loop didn't (see design doc §2 "Important correctness detail"). Calling `stop()` on an already-stopped/suspended source is harmless.
  3. In `Sound.play_music(name)`, call `_claim_group(name)` unconditionally, before playing (e.g. right after `local entry = _music_tracks[name]` / `if entry then`, before the existing fade/play statements).
  4. In `Sound.fade_music(name, target_vol, duration)`, call `_claim_group(name)` only inside the existing `if target_vol > 0 and not entry.src:isPlaying() then` branch — i.e. only when this call is bringing the named track *up*, not when it's fading something out to 0. Fading out must not claim group ownership.
  5. In `Sound.play_random_music(names, fade_duration)`, delete the existing "Stop any of the valid tracks that are currently playing" loop (the block that does `if entry.src:isPlaying() then entry.src:stop() ... end` for each `name` in `valid`). Replace it with a call to `_claim_group(picked)` placed immediately before the existing `Sound.fade_music(picked, 1, fade_duration)` call, so the picked track claims its group right before fading in.

  No changes to `Sound.on_focus`, `Sound.stop_music`, `Sound.set_music_volume`, `Sound.update`, `Sound.play`, or `Sound.play_animalese` — those are explicitly out of scope per the design doc.

- [x] Task C — `tests/test_sound.lua` — Depends on Task B (the implementation must exist first; these assertions fail against current pre-fix code). Do not start until Task B is complete.
  1. Add `group = "bg"` to the `bg1`–`bg4` entries in the file's own `MANIFEST.music` table (~lines 13–19), mirroring Task A's change to `main.lua`. Leave `menu` ungrouped.
  2. Add new test case(s) that prove the crux of the fix: starting a `bg`-group track clears `playing_intent` (and stops the source) of any other same-group track, **regardless of that other track's current `isPlaying()` state** — a test that only checks the `isPlaying() == true` case would not catch the original bug, since in the real failure mode the stale track's `isPlaying()` is already `false` when it needs to be cleared. Follow the existing stubbing pattern already used in this file for the "on_focus(true) replays tracks with playing_intent=true" test (~line 226): stub `love.audio.newSource` to inject a `play` call counter onto each created source, `require` a fresh `Sound` module (`package.loaded["core/lua/sound"] = nil`), call `S.load(MANIFEST)`, then:
     - Start `bg1` via `S.play_music("bg1")` (sets its `playing_intent = true`).
     - Start `bg2` via `S.play_music("bg2")`. Assert this claimed the `"bg"` group: `S.on_focus(true)` afterward should produce play-call activity only consistent with `bg2` having `playing_intent = true` and `bg1` no longer having it (e.g. reset the play-call counter right before `S.on_focus(true)` and assert the count reflects only one track resuming, not two — since headless `isPlaying()` stubs always report `false`, both tracks would otherwise be "eligible" to resume if `bg1`'s intent hadn't been cleared).
     - Repeat the same claim-and-check shape using `S.fade_music("bg3", 1, 2)` as the claiming call instead of `play_music`, to cover the `fade_music` call site specifically (per design doc §2, `fade_music` only claims when `target_vol > 0`).
     - Add an assertion that claiming the `"bg"` group never affects `menu`: with `menu`'s `playing_intent = true` (e.g. from `MANIFEST`'s autoplay or an explicit `S.play_music("menu")`), starting/claiming a `bg` track must leave `menu` eligible to resume on `on_focus(true)` — i.e. `menu` is ungrouped and must not be touched by `_claim_group`.
     Restore any stubbed `love.audio`/`love.filesystem` functions and reset `package.loaded["core/lua/sound"]` at the end of each `do ... end` block, matching the existing tests' cleanup convention.

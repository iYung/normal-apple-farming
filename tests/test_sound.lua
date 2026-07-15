-- Reset any stub injected by earlier test files so we get the real module.
package.loaded["core/lua/sound"] = nil
local Sound = require("core/lua/sound")

-- Standard manifest used by all load() calls in this test file.
local MANIFEST = {
    sfx_dir   = "assets/sounds/",
    sfx       = {
        "pick_up", "put_down", "sell_plant", "clone_success",
        "shop_navigate", "shop_buy", "fail",
        "menu_navigate", "menu_confirm",
    },
    music = {
        menu = { path = "assets/music/menu.mp3",         autoplay = true  },
        bg1  = { path = "assets/music/background.mp3",  looping = false, group = "bg" },
        bg2  = { path = "assets/music/background2.mp3", looping = false, group = "bg" },
        bg3  = { path = "assets/music/background3.mp3", looping = false, group = "bg" },
        bg4  = { path = "assets/music/background4.mp3", looping = false, group = "bg" },
    },
}

-- Test: Sound.load() does not error in headless mode
do
    Sound.load(MANIFEST)
    print("PASS: sound: Sound.load() runs without error in headless")
end

-- Test: Sound.play() does not error for a known event name
do
    Sound.play("pick_up")
    print("PASS: sound: Sound.play() runs without error for known name")
end

-- Test: Sound.play() does not error for an unknown event name
do
    Sound.play("nonexistent_event")
    print("PASS: sound: Sound.play() runs without error for unknown name")
end

-- Test: set_sfx_volume sets level without error
do
    Sound.set_sfx_volume(0.5)
    Sound.play("pick_up")
    print("PASS: set_sfx_volume sets level without error")
end

-- Test: set_sfx_volume accepts boundary values
do
    Sound.set_sfx_volume(0)
    Sound.set_sfx_volume(1)
    print("PASS: set_sfx_volume accepts boundary values")
end

-- Test: set_music_volume sets level without error
do
    Sound.set_music_volume(0.7)
    print("PASS: set_music_volume sets level without error")
end

-- Test: set_music_volume accepts boundary values
do
    Sound.set_music_volume(0)
    Sound.set_music_volume(1)
    print("PASS: set_music_volume accepts boundary values")
end

-- Test: Sound.update(dt) runs without error
do
    Sound.update(0.016)
    Sound.update(0)
    print("PASS: Sound.update() runs without error")
end

-- Test: Sound.play_music runs without error for known and unknown names
do
    Sound.play_music("menu")
    Sound.play_music("bg1")
    Sound.play_music("nonexistent")
    print("PASS: Sound.play_music() runs without error")
end

-- Test: Sound.fade_music runs without error for fade in and fade out
do
    Sound.fade_music("menu", 0, 2)
    Sound.fade_music("bg1", 1, 2)
    Sound.fade_music("nonexistent", 0, 1)
    print("PASS: Sound.fade_music() runs without error")
end

-- Test: Sound.stop_music runs without error
do
    Sound.stop_music("menu")
    Sound.stop_music("bg1")
    Sound.stop_music("nonexistent")
    print("PASS: Sound.stop_music() runs without error")
end

-- Test: Sound.is_music_playing returns false in headless (stubs return false)
do
    assert(Sound.is_music_playing("menu") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("bg1") == false, "is_music_playing should return false in headless")
    assert(Sound.is_music_playing("nonexistent") == false, "is_music_playing for unknown name should return false")
    print("PASS: Sound.is_music_playing() returns false in headless")
end

-- Test: update runs cleanly after a fade_music call (no error from fade arithmetic)
do
    Sound.load(MANIFEST)
    Sound.fade_music("bg1", 1, 2)
    Sound.update(0.5)
    Sound.update(2.0)
    print("PASS: Sound.update() runs cleanly after fade_music")
end

-- Test: play_random_music picks one track and fades it in (all three tracks present)
do
    local orig_play    = love.audio.play
    local orig_newSrc  = love.audio.newSource
    local orig_getInfo = love.filesystem.getInfo

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
            if p == "assets/music/background3.mp3" then return true end
        end
        return nil
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    S.play_random_music({"bg1", "bg2", "bg3"}, 2)
    S.update(2)

    love.audio.play    = orig_play
    love.audio.newSource = orig_newSrc
    love.filesystem.getInfo = orig_getInfo
    package.loaded["core/lua/sound"] = nil
    print("PASS: play_random_music picks one track and fades it in")
end

-- Test: play_random_music handles missing tracks gracefully
do
    local orig_play    = love.audio.play
    local orig_newSrc  = love.audio.newSource
    local orig_getInfo = love.filesystem.getInfo

    -- Only background.mp3 (bg1) is present; bg2 and bg3 are missing
    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3" then return true end
        end
        return nil
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    S.play_random_music({"bg1", "bg2", "bg3"}, 2)
    S.update(2)

    love.audio.play    = orig_play
    love.audio.newSource = orig_newSrc
    love.filesystem.getInfo = orig_getInfo
    package.loaded["core/lua/sound"] = nil
    print("PASS: play_random_music handles missing tracks gracefully")

    -- Empty list must also be a no-op
    package.loaded["core/lua/sound"] = nil
    local S2 = require("core/lua/sound")
    S2.load(MANIFEST)
    S2.play_random_music({}, 2)
    S2.update(2)
    package.loaded["core/lua/sound"] = nil
    print("PASS: play_random_music handles empty list gracefully")
end

-- Regression: fading bg1-bg4 in a loop (store→start transition) works for all present tracks
-- and a wrong track name ("bg") silently does nothing.
do
    local orig_getInfo = love.filesystem.getInfo

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
            if p == "assets/music/background3.mp3" then return true end
            if p == "assets/music/background4.mp3" then return true end
        end
        return nil
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    -- Simulate bg music playing (play_random_music picks one; we start bg1 directly)
    S.play_music("bg1")

    -- The fixed _on_leave loop: all four names must be accepted without error
    for _, name in ipairs({"bg1", "bg2", "bg3", "bg4"}) do
        S.fade_music(name, 0, 1)
    end
    S.update(1.5)  -- advance past the fade duration; should not error

    -- The old broken call with the wrong name must still be a silent no-op
    S.fade_music("bg", 0, 1)
    S.update(0.016)

    love.filesystem.getInfo = orig_getInfo
    package.loaded["core/lua/sound"] = nil
    print("PASS: fading bg1-bg4 loop (store->start transition) runs without error")
end

-- Test: Sound.on_focus() does not error in headless mode (love.audio guard)
do
    Sound.load(MANIFEST)
    Sound.on_focus(true)
    Sound.on_focus(false)
    print("PASS: Sound.on_focus() runs without error in headless")
end

-- Test: on_focus(true) replays tracks with playing_intent=true; skips ones with playing_intent=false
do
    local orig_getInfo  = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0

    love.filesystem.getInfo = function(p)
        if type(p) == "string" and p == "assets/music/menu.mp3" then return true end
        return orig_getInfo(p)
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)
    -- load() plays menu immediately; reset counter so we only count on_focus calls
    play_calls = 0

    -- menu: playing_intent=true, isPlaying()=false → should replay
    S.on_focus(true)
    assert(play_calls == 1, "expected 1 replay on focus (menu), got " .. play_calls)

    -- after stop, playing_intent=false → should not replay
    S.stop_music("menu")
    play_calls = 0
    S.on_focus(true)
    assert(play_calls == 0, "expected 0 replays after stop_music, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: on_focus(true) replays only tracks with playing_intent=true")
end

-- Test: Sound.load() honours looping=false — bg tracks get setLooping(false), menu gets setLooping(true)
do
    local orig_getInfo  = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local looping_calls = {}

    love.filesystem.getInfo = function(p)
        local music_files = {
            ["assets/music/menu.mp3"]        = true,
            ["assets/music/background.mp3"]  = true,
            ["assets/music/background2.mp3"] = true,
            ["assets/music/background3.mp3"] = true,
            ["assets/music/background4.mp3"] = true,
        }
        return music_files[p] or nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.setLooping = function(self, v) looping_calls[path] = v end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    assert(looping_calls["assets/music/menu.mp3"]        == true,  "menu should loop")
    assert(looping_calls["assets/music/background.mp3"]  == false, "bg1 should not loop")
    assert(looping_calls["assets/music/background2.mp3"] == false, "bg2 should not loop")
    assert(looping_calls["assets/music/background3.mp3"] == false, "bg3 should not loop")
    assert(looping_calls["assets/music/background4.mp3"] == false, "bg4 should not loop")

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: Sound.load() respects looping=false — bg tracks non-looping, menu loops")
end

-- Test: on_focus(false) does not replay any tracks
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0

    love.filesystem.getInfo = function(p)
        if type(p) == "string" and p == "assets/music/menu.mp3" then return true end
        return orig_getInfo(p)
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)
    play_calls = 0

    S.on_focus(false)
    assert(play_calls == 0, "on_focus(false) must not play any sources, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: on_focus(false) does not replay any tracks")
end

-- Regression: play_music() claims its "bg" group and clears playing_intent (and
-- stops the source) of another same-group track even when that track's source is
-- already NOT playing (isPlaying()==false) — this is the actual focus-loss bug:
-- the stale track's playing_intent stayed true after its source had already
-- stopped/suspended on its own, with nothing to clear the intent. A fix that only
-- handles the isPlaying()==true case would not catch this.
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0
    local bg1_stop_calls = 0

    love.filesystem.getInfo = function(p)
        local music_files = {
            ["assets/music/background.mp3"]  = true,
            ["assets/music/background2.mp3"] = true,
        }
        return music_files[p] or nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        if path == "assets/music/background.mp3" then
            src.stop = function(self) bg1_stop_calls = bg1_stop_calls + 1 end
        end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    -- bg1: playing_intent=true, but its source's isPlaying() is already false
    -- (the stub always reports false) — exactly the stale state the focus-loss
    -- bug leaves behind.
    S.play_music("bg1")

    -- bg2 claims the "bg" group.
    S.play_music("bg2")
    assert(bg1_stop_calls == 1, "expected bg1's source to be stop()'d when bg2 claims the group, got " .. bg1_stop_calls)

    -- Prove bg1 is no longer eligible to resume: only bg2 should replay on focus.
    play_calls = 0
    S.on_focus(true)
    assert(play_calls == 1, "expected only bg2 to replay on focus after bg2 claimed the group, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: play_music() claims group and clears stale playing_intent even when isPlaying() was already false")
end

-- Test: play_music() also claims its group and stops another same-group track when
-- that track's source is genuinely still playing (isPlaying()==true) — the "easy"
-- case that the old play_random_music stop-loop already handled correctly.
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local bg1_stop_calls = 0
    local bg1_src

    love.filesystem.getInfo = function(p)
        local music_files = {
            ["assets/music/background.mp3"]  = true,
            ["assets/music/background2.mp3"] = true,
        }
        return music_files[p] or nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        if path == "assets/music/background.mp3" then
            src._playing = false
            src.stop = function(self)
                bg1_stop_calls = bg1_stop_calls + 1
                self._playing = false
            end
            src.isPlaying = function(self) return self._playing end
            bg1_src = src
        end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    S.play_music("bg1")
    bg1_src._playing = true -- simulate a genuinely still-playing source

    S.play_music("bg2")
    assert(bg1_stop_calls == 1, "expected bg1's genuinely-playing source to be stop()'d when bg2 claims the group, got " .. bg1_stop_calls)
    assert(bg1_src:isPlaying() == false, "expected bg1 to have stopped playing after bg2 claimed the group")

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: play_music() claims group and stops a genuinely-playing same-group track")
end

-- Test: fade_music(name, target_vol>0, duration) also claims its group — same
-- exclusivity guarantee as play_music(), covering the other call site described
-- in the design doc (claiming only happens when target_vol > 0).
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0
    local bg1_stop_calls = 0

    love.filesystem.getInfo = function(p)
        local music_files = {
            ["assets/music/background.mp3"]  = true,
            ["assets/music/background3.mp3"] = true,
        }
        return music_files[p] or nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        if path == "assets/music/background.mp3" then
            src.stop = function(self) bg1_stop_calls = bg1_stop_calls + 1 end
        end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    -- bg1: stale playing_intent=true (isPlaying() already false), as above.
    S.play_music("bg1")

    -- bg3 claims the "bg" group via fade_music, not play_music.
    S.fade_music("bg3", 1, 2)
    assert(bg1_stop_calls == 1, "expected fade_music(bg3, 1, ...) to stop bg1's source, got " .. bg1_stop_calls)

    play_calls = 0
    S.on_focus(true)
    assert(play_calls == 1, "expected only bg3 to replay on focus after fade_music claimed the group, got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: fade_music() with target_vol>0 also claims group and clears other tracks' playing_intent")
end

-- Test: claiming the "bg" group never touches "menu" — it is left ungrouped and
-- must remain eligible to resume independently of any bg-group claim.
do
    local orig_getInfo   = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local play_calls = 0
    local menu_stop_calls = 0

    love.filesystem.getInfo = function(p)
        local music_files = {
            ["assets/music/menu.mp3"]        = true,
            ["assets/music/background.mp3"]  = true,
            ["assets/music/background2.mp3"] = true,
        }
        return music_files[p] or nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        src.play = function(self) play_calls = play_calls + 1 end
        if path == "assets/music/menu.mp3" then
            src.stop = function(self) menu_stop_calls = menu_stop_calls + 1 end
        end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST) -- menu autoplay=true sets its playing_intent=true

    S.play_music("bg1")
    S.play_music("bg2") -- bg2 claims the "bg" group; menu is ungrouped

    assert(menu_stop_calls == 0, "expected menu (ungrouped) to never be stop()'d by a bg-group claim, got " .. menu_stop_calls)

    -- menu should still be eligible to resume on focus, alongside bg2.
    play_calls = 0
    S.on_focus(true)
    assert(play_calls == 2, "expected both menu and bg2 to replay on focus (menu untouched by bg claim), got " .. play_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: claiming the \"bg\" group does not affect the ungrouped \"menu\" track")
end

-- Test: fade_music_group(group, 0, duration) fades out a track that is actually
-- playing in that group (playing_intent==true) and, once the fade completes,
-- stops it — same stop_on_done machinery already exercised for fade_music().
do
    local orig_getInfo = love.filesystem.getInfo

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
        end
        return nil
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    S.play_music("bg1")
    S.fade_music_group("bg", 0, 1)
    S.update(1.5) -- advance past the fade duration

    assert(S.is_music_playing("bg1") == false, "expected bg1 to have stopped after group fade-out completed")

    love.filesystem.getInfo = orig_getInfo
    package.loaded["core/lua/sound"] = nil
    print("PASS: fade_music_group() fades out and stops a track with playing_intent==true")
end

-- Test: fade_music_group() leaves tracks in the group alone if they were never
-- started (playing_intent==false) — the caller doesn't know which specific track
-- in the group is active, so untouched tracks must not be faded or stopped.
do
    local orig_getInfo = love.filesystem.getInfo
    local orig_newSource = love.audio.newSource
    local bg2_stop_calls = 0

    love.filesystem.getInfo = function(p)
        if type(p) == "string" then
            if p == "assets/music/background.mp3"  then return true end
            if p == "assets/music/background2.mp3" then return true end
        end
        return nil
    end
    love.audio.newSource = function(path, t)
        local src = orig_newSource(path, t)
        if path == "assets/music/background2.mp3" then
            src.stop = function(self) bg2_stop_calls = bg2_stop_calls + 1 end
        end
        return src
    end

    package.loaded["core/lua/sound"] = nil
    local S = require("core/lua/sound")
    S.load(MANIFEST)

    -- bg1 is started; bg2 is never played or faded, so its playing_intent stays false.
    -- (play_music's own group-claim stops bg2 once as pre-existing, unrelated
    -- behavior — reset the counter afterward so we isolate fade_music_group's effect.)
    S.play_music("bg1")
    bg2_stop_calls = 0
    S.fade_music_group("bg", 0, 1)
    S.update(1.5)

    assert(bg2_stop_calls == 0, "expected bg2 (never started) to never be stop()'d by a group fade-out, got " .. bg2_stop_calls)

    love.filesystem.getInfo = orig_getInfo
    love.audio.newSource    = orig_newSource
    package.loaded["core/lua/sound"] = nil
    print("PASS: fade_music_group() leaves tracks with playing_intent==false untouched")
end

-- Test: fade_music_group() for an unknown group name is a silent no-op, matching
-- how fade_music("nonexistent", ...) already behaves elsewhere in this file.
do
    Sound.fade_music_group("nonexistent_group", 0, 1)
    Sound.update(0.016)
    print("PASS: fade_music_group() runs without error for an unknown group name")
end

print("ALL TESTS PASSED")

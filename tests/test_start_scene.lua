-- test_start_scene.lua
-- Verifies StartScene: construction, music on enter, button navigation/confirm.

local Sound      = require("core/lua/sound")
local Input      = require("core/lua/input")
local StartScene = require("game/scenes/start_scene")

local function make_sm()
    local sm = { switched_to = nil }
    sm.switch = function(self, s) self.switched_to = s end
    return sm
end

-- Simulates a key press+release using the scene's own (owned) Input, the
-- same way the old single-key test did: monkey-patch love.keyboard.isDown,
-- call scene:update() (which internally calls input:update() since the
-- scene owns its Input when none was passed to the constructor), release,
-- update again.
local function press_e(scene)
    local orig = love.keyboard.isDown
    love.keyboard.isDown = function(k) return k == "e" end
    scene:update(1 / 60)
    love.keyboard.isDown = orig
    scene:update(1 / 60)
end

-- Same press+release simulation, but for a caller-owned (borrowed) Input
-- passed explicitly into StartScene.new. In that case scene:update() does
-- NOT call input:update() itself (self._owns_input is false), so the test
-- must drive the Input's update() directly, same as main.lua would each
-- frame, before calling scene:update().
local function press_key_via(input, scene, key)
    local orig = love.keyboard.isDown
    love.keyboard.isDown = function(k) return k == key end
    input:update()
    scene:update(1 / 60)
    love.keyboard.isDown = function() return false end
    input:update()
    scene:update(1 / 60)
    love.keyboard.isDown = orig
end

-- ── construction ──────────────────────────────────────────────────────────────

do
    local sm    = make_sm()
    local scene = StartScene.new(sm, nil)
    assert(scene ~= nil, "StartScene.new() should return a scene")
    assert(scene.esc_opens_settings == true, "esc_opens_settings should be true")
    assert(scene.is_title_scene == true, "is_title_scene should be true")
    assert(scene.selected == 1, "selected should default to 1")
    assert(#scene.items == 4, "items should have 4 entries")
    print("PASS: StartScene construction")
end

-- ── on_enter plays menu music ─────────────────────────────────────────────────

do
    Sound.load({
        sfx_dir = "assets/sounds/",
        sfx = {},
        music = {
            menu = { path = "assets/music/menu.mp3", autoplay = false },
        },
    })

    local played = {}
    local orig_play_music = Sound.play_music
    Sound.play_music = function(name) played[#played + 1] = name end

    local scene = StartScene.new(make_sm(), nil)
    scene:on_enter()

    Sound.play_music = orig_play_music
    assert(#played == 1 and played[1] == "menu", "on_enter should play 'menu' music")
    print("PASS: StartScene on_enter plays menu music")
end

-- ── on_enter skips play_music if menu already playing ────────────────────────

do
    local played = {}
    local orig_play_music = Sound.play_music
    Sound.play_music = function(name) played[#played + 1] = name end

    local orig_is_music_playing = Sound.is_music_playing
    Sound.is_music_playing = function(name) return name == "menu" end

    local scene = StartScene.new(make_sm(), nil)
    scene:on_enter()

    Sound.play_music = orig_play_music
    Sound.is_music_playing = orig_is_music_playing
    assert(#played == 0, "on_enter should not call play_music when menu is already playing")
    print("PASS: StartScene on_enter skips play_music when menu already playing")
end

-- ── New Game button (default selection) fades music and switches scene ───────
-- Exercises selected == 1, "New Game", which is the default selection on a
-- freshly constructed scene, via a press of the `interact` key ("e" on the
-- scene's own default Input).

do
    local faded = {}
    local orig_fade = Sound.fade_music
    Sound.fade_music = function(name, vol, dur) faded[#faded + 1] = {name=name, vol=vol} end

    local sm    = make_sm()
    local scene = StartScene.new(sm, nil)
    assert(scene.selected == 1, "New Game should be selected by default")
    press_e(scene)

    Sound.fade_music = orig_fade

    assert(#faded >= 1 and faded[1].name == "menu" and faded[1].vol == 0,
        "New Game confirm should fade menu music to 0")
    assert(sm.switched_to ~= nil, "New Game confirm should switch scene")
    print("PASS: StartScene New Game button fades music and switches scene")
end

-- ── move_down / move_up navigation wraps around ───────────────────────────────
-- The scene's own default Input only binds `interact`, so navigation needs
-- an explicit Input with move_up/move_down bound (default keybinds "w"/"s",
-- per SettingsState), passed into the constructor's 3rd param.

do
    local input = Input.new({
        move_up   = { "w" },
        move_down = { "s" },
        interact  = { "e" },
    })
    local scene = StartScene.new(make_sm(), nil, input)
    assert(scene.selected == 1, "selected should start at 1")

    press_key_via(input, scene, "s")
    assert(scene.selected == 2, "move_down should advance selection from 1 to 2")

    press_key_via(input, scene, "w")
    assert(scene.selected == 1, "move_up should return selection from 2 to 1")

    press_key_via(input, scene, "w")
    assert(scene.selected == 4, "move_up from 1 should wrap around to the last item (4)")

    print("PASS: StartScene move_up/move_down navigation wraps around")
end

-- ── Settings button calls on_open_settings when provided ─────────────────────

do
    local calls = 0
    local scene = StartScene.new(make_sm(), nil, nil, function() calls = calls + 1 end)
    scene.selected = 3
    press_e(scene)
    assert(calls == 1, "on_open_settings should be called exactly once")
    print("PASS: StartScene Settings button calls on_open_settings")
end

-- ── Settings button is a no-op (no error) when on_open_settings is nil ───────

do
    local scene = StartScene.new(make_sm(), nil)
    scene.selected = 3
    press_e(scene)
    print("PASS: StartScene Settings button is nil-safe when on_open_settings is omitted")
end

-- ── Exit Game button calls love.event.quit ────────────────────────────────────

do
    local quit_calls = 0
    local orig_quit = love.event.quit
    love.event.quit = function(...) quit_calls = quit_calls + 1 end

    local scene = StartScene.new(make_sm(), nil)
    scene.selected = 4
    press_e(scene)

    love.event.quit = orig_quit

    assert(quit_calls == 1, "Exit Game confirm should call love.event.quit exactly once")
    print("PASS: StartScene Exit Game button calls love.event.quit")
end

-- ── Continue button is a no-op ────────────────────────────────────────────────

do
    local faded = {}
    local orig_fade = Sound.fade_music
    Sound.fade_music = function(name, vol, dur) faded[#faded + 1] = {name=name, vol=vol} end

    local sm    = make_sm()
    local scene = StartScene.new(sm, nil)
    scene.selected = 2
    press_e(scene)

    Sound.fade_music = orig_fade

    assert(sm.switched_to == nil, "Continue confirm should not switch scene")
    assert(#faded == 0, "Continue confirm should not fade music")
    print("PASS: StartScene Continue button is a no-op")
end

-- ── draw runs without error ───────────────────────────────────────────────────

do
    local scene = StartScene.new(make_sm(), nil)
    scene:draw()
    print("PASS: StartScene draw runs without error")
end

print("ALL TESTS PASSED")

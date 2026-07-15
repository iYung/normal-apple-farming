-- test_start_scene.lua
-- Verifies StartScene: construction, music on enter, E starts game.

local Sound      = require("core/lua/sound")
local StartScene = require("game/scenes/start_scene")

local function make_sm()
    local sm = { switched_to = nil }
    sm.switch = function(self, s) self.switched_to = s end
    return sm
end

local function press_e(scene)
    local orig = love.keyboard.isDown
    love.keyboard.isDown = function(k) return k == "e" end
    scene:update(1 / 60)
    love.keyboard.isDown = orig
    scene:update(1 / 60)
end

-- ── construction ──────────────────────────────────────────────────────────────

do
    local sm    = make_sm()
    local scene = StartScene.new(sm, nil)
    assert(scene ~= nil, "StartScene.new() should return a scene")
    assert(scene.esc_opens_settings == true, "esc_opens_settings should be true")
    assert(scene.is_title_scene == true, "is_title_scene should be true")
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

-- ── E press fades music and switches to GameScene ────────────────────────────

do
    local faded = {}
    local orig_fade = Sound.fade_music
    Sound.fade_music = function(name, vol, dur) faded[#faded + 1] = {name=name, vol=vol} end

    local sm    = make_sm()
    local scene = StartScene.new(sm, nil)
    press_e(scene)

    Sound.fade_music = orig_fade

    assert(#faded >= 1 and faded[1].name == "menu" and faded[1].vol == 0,
        "E press should fade menu music to 0")
    assert(sm.switched_to ~= nil, "E press should switch scene")
    print("PASS: StartScene E press fades music and switches scene")
end

-- ── draw runs without error ───────────────────────────────────────────────────

do
    local scene = StartScene.new(make_sm(), nil)
    scene:draw()
    print("PASS: StartScene draw runs without error")
end

print("ALL TESTS PASSED")

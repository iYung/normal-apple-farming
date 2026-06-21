local _visual_test = nil
local _visual_mode = false
do
    local headless, visual, test_file = false, false, nil
    for _, v in ipairs(arg or {}) do
        if     v == "--headless" then headless = true
        elseif v == "--visual"   then visual   = true
        elseif (headless or visual) and not test_file and v:sub(1, 1) ~= "-" then
            test_file = v
        end
    end
    if headless then
        require("lua/headless/stubs")
        require("lua/headless/runner").run(test_file)
        return
    end
    if visual then
        _visual_test = test_file
        _visual_mode = true
    end
end

love.graphics.setDefaultFilter("nearest", "nearest")

local SceneManager  = require("core/lua/scene_manager")
local GameScene     = require("game/scenes/game_scene")
local Sound         = require("core/lua/sound")
local StartScene    = require("game/scenes/start_scene")
local Save          = require("core/lua/save")
local SettingsState = require("game/settings_state")
local SettingsMenu  = require("game/scenes/settings_menu")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas

local manager
local settings_menu

function love.load()
    love.window.setIcon(love.image.newImageData("assets/images/icon.png"))

    canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")

    local ss = Save.settings_exist()
        and SettingsState.from_save(Save.read_settings())
        or  SettingsState.new()

    manager = SceneManager.new(LOGICAL_W, LOGICAL_H)
    manager:switch(StartScene.new(manager, ss))
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

    manager.current.input._map = ss:key_map()

    local function on_close()
        Save.write_settings(ss:to_save())
    end

    settings_menu = SettingsMenu.new(ss, manager.current.input, on_close)
end

function love.update(dt)
    Sound.update(dt)
    if settings_menu and settings_menu.is_open then
        settings_menu:update(dt)
    else
        manager:update(dt)
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0)
    manager:draw()
    if settings_menu and settings_menu.is_open then
        settings_menu:draw()
    end
    love.graphics.setCanvas()

    local scale = math.min(love.graphics.getWidth() / LOGICAL_W, love.graphics.getHeight() / LOGICAL_H)
    local ox = (love.graphics.getWidth() - LOGICAL_W * scale) / 2
    local oy = (love.graphics.getHeight() - LOGICAL_H * scale) / 2
    love.graphics.draw(canvas, ox, oy, 0, scale, scale)
end

function love.keypressed(key)
    if settings_menu and settings_menu:keypressed(key) then return end
    if key == "escape" and settings_menu and not settings_menu.is_open then
        if manager.current and manager.current.input then
            settings_menu._input = manager.current.input
        end
        settings_menu:open()
    end
end

function love.focus(focused)
    Sound.on_focus(focused)
end

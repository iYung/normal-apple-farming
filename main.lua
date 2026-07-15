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
local Input         = require("core/lua/input")

local LOGICAL_W, LOGICAL_H = 1280, 720
local canvas

local manager
local settings_menu
local input

function love.load()
    love.window.setIcon(love.image.newImageData("assets/images/icon.png"))

    canvas = love.graphics.newCanvas(LOGICAL_W, LOGICAL_H)
    canvas:setFilter("nearest", "nearest")

    local ss = Save.settings_exist()
        and SettingsState.from_save(Save.read_settings())
        or  SettingsState.new()

    -- Build the full action map from defaults + user settings
    local base_map = {
        move_up    = { "w", "up" },
        move_down  = { "s", "down" },
        move_left  = { "a", "left" },
        move_right = { "d", "right" },
        interact   = { "e" },
        pickup     = { "f" },
        cancel     = { "escape" },
    }
    -- Apply user keybinds (overrides defaults, but cancel stays fixed)
    for action, keys in pairs(ss:key_map()) do
        base_map[action] = keys
    end
    base_map.cancel = { "escape" }  -- always escape, not user-configurable
    input = Input.new(base_map)

    local function on_open_settings()
        if settings_menu then settings_menu:open() end
    end

    manager = SceneManager.new(LOGICAL_W, LOGICAL_H)
    manager:switch(StartScene.new(manager, ss, input, on_open_settings))
    Sound.load({
        sfx_dir = "assets/sounds/",
        sfx = {
            "pick_up", "put_down", "sell_plant",
            "clone_success", "shop_navigate", "shop_buy",
            "fail", "menu_navigate", "menu_confirm",
        },
        music = {
            menu = { path = "assets/music/menu.mp3",         autoplay = false },
            bg1  = { path = "assets/music/background.mp3",  looping = false, group = "bg" },
            bg2  = { path = "assets/music/background2.mp3", looping = false, group = "bg" },
            bg3  = { path = "assets/music/background3.mp3", looping = false, group = "bg" },
            bg4  = { path = "assets/music/background4.mp3", looping = false, group = "bg" },
        },
    })

    local function on_close()
        Save.write_settings(ss:to_save())
    end

    local function on_exit_to_title()
        Save.write_settings(ss:to_save())
        if manager.current and manager.current.is_title_scene then
            love.event.quit()
        else
            Sound.fade_music_group("bg", 0, 2)
            Sound.fade_music("menu", 1, 2)
            manager:switch(StartScene.new(manager, ss, input, on_open_settings))
        end
    end

    settings_menu = SettingsMenu.new(ss, input, on_close, on_exit_to_title)
end

function love.update(dt)
    Sound.update(dt)
    input:update()
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
    input._mode = "keyboard"
    if settings_menu and settings_menu:keypressed(key) then return end
    if key == "escape" and settings_menu and not settings_menu.is_open then
        if manager.current and manager.current.input then
            settings_menu._input = manager.current.input
        end
        settings_menu:open()
    end
end

function love.gamepadpressed(joystick, button)
    input._joystick = joystick
    input._mode = "gamepad"
    if settings_menu and settings_menu.is_open then
        settings_menu:gamepadpressed(button)
        return
    end
    if button == "start" then
        if settings_menu and manager.current and manager.current.esc_opens_settings then
            settings_menu:open()
        end
    end
end

function love.joystickadded(joystick)
    if joystick:isGamepad() and input._joystick == nil then
        input._joystick = joystick
    end
end

function love.joystickremoved(joystick)
    if joystick == input._joystick then
        input._joystick = nil
        for _, j in ipairs(love.joystick.getJoysticks()) do
            if j:isGamepad() and j:isConnected() then
                input._joystick = j
                break
            end
        end
    end
end

function love.focus(focused)
    Sound.on_focus(focused)
end

local Sound     = require("core/lua/sound")
local Input     = require("core/lua/input")
local Fonts     = require("game/fonts")
local GameScene = require("game/scenes/game_scene")

local VIEW_W = 1280
local VIEW_H = 720

local BTN_W   = 300
local BTN_H   = 54
local BTN_X   = (VIEW_W - BTN_W) / 2
local BTN_GAP = 74
local BTN_Y0  = VIEW_H / 2 - 20

local StartScene = {}
StartScene.__index = StartScene

function StartScene.new(scene_manager, settings_state, input, on_open_settings)
    local self = setmetatable({}, StartScene)
    self.scene_manager   = scene_manager
    self.settings_state  = settings_state
    self.esc_opens_settings = true
    self.is_title_scene = true
    self._owns_input = (input == nil)
    self.input = input or Input.new({ interact = { "e" } })
    self._on_open_settings = on_open_settings

    self.selected = 1
    self.items = { "New Game", "Continue", "Settings", "Exit Game" }

    self._img_btn     = love.graphics.newImage("assets/images/menu_btn.png")
    self._img_btn_sel = love.graphics.newImage("assets/images/menu_btn_selected.png")
    self._font_btn    = Fonts.new(22)
    return self
end

function StartScene:on_enter()
    if not Sound.is_music_playing("menu") then
        Sound.play_music("menu")
    end
end

function StartScene:on_exit()
end

function StartScene:update(dt)
    if self._owns_input then self.input:update() end
    if self.input:pressed("move_up") then
        self.selected = ((self.selected - 2) % #self.items) + 1
    end
    if self.input:pressed("move_down") then
        self.selected = (self.selected % #self.items) + 1
    end
    if self.input:pressed("interact") then
        self:_confirm()
    end
end

function StartScene:_confirm()
    if self.selected == 1 then
        -- New Game
        Sound.fade_music("menu", 0, 2)
        self.scene_manager:switch(GameScene.new(self.scene_manager, self.settings_state, self.input))
    elseif self.selected == 2 then
        -- Continue: no-op, no save/load system exists yet
    elseif self.selected == 3 then
        -- Settings
        if self._on_open_settings then self._on_open_settings() end
    elseif self.selected == 4 then
        -- Exit Game
        love.event.quit()
    end
end

function StartScene:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, VIEW_W, VIEW_H)

    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()

    local title = "Normal Apple Farming"
    local tw = font:getWidth(title)
    local fh = font:getHeight()

    love.graphics.print(title, math.floor((VIEW_W - tw) / 2), math.floor(VIEW_H / 2 - fh - 8))

    -- Button list
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(self._font_btn)
    for i, item in ipairs(self.items) do
        local y   = BTN_Y0 + (i - 1) * BTN_GAP
        local img = (i == self.selected) and self._img_btn_sel or self._img_btn
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, BTN_X, y)

        local th = self._font_btn:getHeight()
        local ty = y + (BTN_H - th) / 2
        love.graphics.printf(item, BTN_X, ty, BTN_W, "center")
    end
    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)

    -- Nav hint row at the bottom
    if self.input.key_for then
        local function fmt(k)
            if not k then return "?" end
            if k:sub(1, 1) == "[" or k == "↑" or k == "↓" or k == "←" or k == "→" then return k end
            return "[" .. k:upper() .. "]"
        end
        local hint = "↑/↓ Navigate   " .. fmt(self.input:key_for("interact")) .. " Select"
        local hw = font:getWidth(hint)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print(hint, math.floor((VIEW_W - hw) / 2), VIEW_H - fh - 14)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return StartScene

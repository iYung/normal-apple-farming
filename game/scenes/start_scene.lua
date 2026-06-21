local Sound     = require("core/lua/sound")
local Input     = require("core/lua/input")
local GameScene = require("game/scenes/game_scene")

local VIEW_W = 1280
local VIEW_H = 720

local StartScene = {}
StartScene.__index = StartScene

function StartScene.new(scene_manager, settings_state, input)
    local self = setmetatable({}, StartScene)
    self.scene_manager   = scene_manager
    self.settings_state  = settings_state
    self.esc_opens_settings = true
    self._owns_input = (input == nil)
    self.input = input or Input.new({ interact = { "e" } })
    return self
end

function StartScene:on_enter()
    Sound.play_music("menu")
end

function StartScene:on_exit()
end

function StartScene:update(dt)
    if self._owns_input then self.input:update() end
    if self.input:pressed("interact") then
        Sound.fade_music("menu", 0, 2)
        self.scene_manager:switch(GameScene.new(self.scene_manager, self.settings_state, self.input))
    end
end

function StartScene:draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, VIEW_W, VIEW_H)

    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()

    local title  = "Normal Apple Farming"
    local key = (self.input.key_for and self.input:key_for("interact")) or "E"
    local prompt = "Press " .. key:upper() .. " to start"

    local tw = font:getWidth(title)
    local pw = font:getWidth(prompt)
    local fh = font:getHeight()

    love.graphics.print(title,  math.floor((VIEW_W - tw) / 2), math.floor(VIEW_H / 2 - fh - 8))
    love.graphics.print(prompt, math.floor((VIEW_W - pw) / 2), math.floor(VIEW_H / 2 + 8))
end

return StartScene

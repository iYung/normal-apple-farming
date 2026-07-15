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
    self.is_title_scene = true
    self._owns_input = (input == nil)
    self.input = input or Input.new({ interact = { "e" } })
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

    -- Controls hint row at the bottom
    if self.input.key_for then
        local function fmt(k)
            if not k then return "?" end
            if k:sub(1, 1) == "[" or k == "↑" or k == "↓" or k == "←" or k == "→" then return k end
            return "[" .. k:upper() .. "]"
        end
        local ku = self.input:key_for("move_up")    or "?"
        local kl = self.input:key_for("move_left")  or "?"
        local kd = self.input:key_for("move_down")  or "?"
        local kr = self.input:key_for("move_right") or "?"
        local move_text   = ku .. "/" .. kl .. "/" .. kd .. "/" .. kr .. " Move"
        local pickup_text = fmt(self.input:key_for("pickup"))   .. " Pickup"
        local act_text    = fmt(self.input:key_for("interact")) .. " Interact"

        local hint = move_text .. "   " .. pickup_text .. "   " .. act_text
        local hw = font:getWidth(hint)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.print(hint, math.floor((VIEW_W - hw) / 2), VIEW_H - fh - 14)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return StartScene

local Input = require("core/lua/input")
local CRT   = require("game/shaders/crt")
local Fonts = require("core/lua/fonts")

local _font_family  = Fonts.from("assets/fonts/font.ttf")
local font_title    = _font_family.new(72)
local font_subtitle = _font_family.new(36)
local font_prompt   = _font_family.new(24)

local VIEW_W = 1280
local VIEW_H = 720

local GameOverScene = {}
GameOverScene.__index = GameOverScene

function GameOverScene.new(game_state, scene_manager)
    local self = setmetatable({}, GameOverScene)
    self.game_state    = game_state
    self.scene_manager = scene_manager
    self.canvas = love.graphics.newCanvas(VIEW_W, VIEW_H)
    self.input = Input.new({ restart = { "e" } })
    return self
end

function GameOverScene:on_enter() end
function GameOverScene:on_exit() end

function GameOverScene:update(dt)
    self.input:update()
    if self.input:pressed("restart") then
        local GameScene = require("game/scenes/game_scene")
        self.scene_manager:switch(GameScene.new(self.scene_manager))
    end
end

function GameOverScene:draw()
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    local prev_font = love.graphics.getFont()
    local cx = VIEW_W / 2
    local cy = VIEW_H / 2

    -- "GAME OVER" title
    love.graphics.setFont(font_title)
    love.graphics.setColor(1, 1, 1, 1)
    local title     = "GAME OVER"
    local title_w   = font_title:getWidth(title)
    local title_h   = font_title:getHeight()
    love.graphics.print(title, cx - title_w / 2, cy - title_h - 60)

    -- Final funds line
    love.graphics.setFont(font_subtitle)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    local money_str = "Final funds: $" .. (self.game_state.money or 0)
    local money_w   = font_subtitle:getWidth(money_str)
    local money_y   = cy
    love.graphics.print(money_str, cx - money_w / 2, money_y)

    -- Animals sold line (only if the field exists)
    local sub_y = money_y + font_subtitle:getHeight() + 12
    if self.game_state.animals_sold then
        local sold_str = "Animals sold: " .. self.game_state.animals_sold
        local sold_w   = font_subtitle:getWidth(sold_str)
        love.graphics.print(sold_str, cx - sold_w / 2, sub_y)
        sub_y = sub_y + font_subtitle:getHeight() + 12
    end

    -- "Press R to restart" prompt
    love.graphics.setFont(font_prompt)
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    local prompt   = "Press E to restart"
    local prompt_w = font_prompt:getWidth(prompt)
    love.graphics.print(prompt, cx - prompt_w / 2, VIEW_H - 80)

    love.graphics.setFont(prev_font)

    -- Blit with CRT shader
    love.graphics.setCanvas(prev_canvas)
    love.graphics.setColor(1, 1, 1, 1)
    CRT.apply()
    love.graphics.draw(self.canvas, 0, 0)
    CRT.clear()

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return GameOverScene

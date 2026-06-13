local Input = require("core/lua/input")
local CRT   = require("game/shaders/crt")

local book_scene_img = love.graphics.newImage("assets/images/book_scene.png")

local VIEW_W = 1280
local VIEW_H = 720

local BookScene = {}
BookScene.__index = BookScene

function BookScene.new(game_scene, scene_manager)
    local self = setmetatable({}, BookScene)
    self.game_scene    = game_scene
    self.scene_manager = scene_manager
    self.canvas = love.graphics.newCanvas(VIEW_W, VIEW_H)
    self.input = Input.new({ interact = { "e" } })
    return self
end

function BookScene:on_enter()
    self._skip_frame = true
end

function BookScene:on_exit() end

function BookScene:update(dt)
    self.input:update()
    if self._skip_frame then
        self._skip_frame = false
        return
    end
    if self.input:pressed("interact") then
        self.scene_manager:switch(self.game_scene)
    end
end

function BookScene:draw()
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    local iw, ih = book_scene_img:getDimensions()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(book_scene_img, 0, 0, 0, VIEW_W / iw, VIEW_H / ih)

    -- Blit with CRT shader
    love.graphics.setCanvas(prev_canvas)
    love.graphics.setColor(1, 1, 1, 1)
    CRT.apply()
    love.graphics.draw(self.canvas, 0, 0)
    CRT.clear()

    love.graphics.setColor(1, 1, 1, 1)
end

return BookScene

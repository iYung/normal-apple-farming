local AnimalColorShader = require("game/shaders/animal_color")
local ui                = require("game/ui")

local img_swatch = love.graphics.newImage("assets/images/hud/color_swatch.png")

local AnimalInfo = {}
AnimalInfo.__index = AnimalInfo

function AnimalInfo.new()
    local self = setmetatable({}, AnimalInfo)
    self._animal = nil
    self._shader = AnimalColorShader.new()
    return self
end

function AnimalInfo:set(animal_or_nil)
    self._animal = animal_or_nil
end

function AnimalInfo:draw(camera)
    if not self._animal then return end
    local stats = self._animal.stats
    local x = (self._animal.x + 24 - camera.x) * camera.zoom + 640 - 80
    local y = (self._animal.y - camera.y) * camera.zoom + 360 - 90 - 24
    x = math.max(0, math.min(x, 1280 - 160))
    y = math.max(0, math.min(y, 720 - 90))
    local w, h = 160, 90

    ui.draw_bubble(x, y, w, h)

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.print("Speed:  " .. stats.speed,       x + 8, y + 8)
    love.graphics.print("Height: " .. stats.height,      x + 8, y + 24)
    love.graphics.print("Trait:  " .. stats.personality, x + 8, y + 40)
    love.graphics.print("Color:", x + 8, y + 56)

    love.graphics.setColor(stats.color.r, stats.color.g, stats.color.b, 1)
    love.graphics.draw(img_swatch, x + 60, y + 56)
    love.graphics.setColor(1, 1, 1, 1)
end

return AnimalInfo

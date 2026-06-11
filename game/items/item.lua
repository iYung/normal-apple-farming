local Sprite        = require("core/lua/sprite")
local OutlineShader = require("game/shaders/outline")

local Item = {}
Item.__index = Item

-- name: string label (e.g. "Wire Roll")
-- image_path: path to PNG (can be nil for no image)
-- w, h: pixel size (optional, defaults 32x32)
function Item.new(x, y, name, image_path, w, h)
    local self = setmetatable({}, Item)
    self._type          = "item"
    self.x              = x or 0
    self.y              = y or 0
    self.w              = w or 32
    self.h              = h or 32
    self.name           = name or "Item"
    self.carriable      = true
    self.held           = false
    self.highlighted    = false
    self._outline_shader = OutlineShader.new()
    self.sprite         = Sprite.new(x, y, self.w, self.h)
    if image_path then
        self.sprite.image = love.graphics.newImage(image_path)
    end
    return self
end

function Item:update(dt)
    self.sprite.x = self.x
    self.sprite.y = self.y
end

function Item:draw()
    if self.highlighted then
        OutlineShader.apply(self._outline_shader, 1, 0.9, 0, self.w, self.h)
        self.sprite:draw()
        OutlineShader.clear()
    end
    self.sprite:draw()
end

function Item:highlight(on)
    self.highlighted = on
end

-- Override in subclasses for pickup interaction
function Item:interact(player, scene)
end

-- Override in subclasses for secondary action (hold O key)
function Item:use(player, scene)
end

return Item

local Sprite = require("core/lua/sprite")
local Mapper = require("game/systems/mapper")

local Wire = {}
Wire.__index = Wire

-- tx, ty are TILE coordinates (integers), not pixel coords
function Wire.new(tx, ty)
    local self = setmetatable({}, Wire)
    self._type = "wire"
    self.tx = tx
    self.ty = ty
    self.x  = tx * Mapper.TILE
    self.y  = ty * Mapper.TILE
    self.w  = Mapper.TILE
    self.h  = Mapper.TILE
    self.sprite = Sprite.new(self.x, self.y, self.w, self.h)
    self.sprite.image = love.graphics.newImage("assets/images/items/wire.png")
    return self
end

function Wire:draw()
    self.sprite:draw()
end

return Wire

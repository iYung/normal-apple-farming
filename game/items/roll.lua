local Item   = require("game/items/item")
local Wire   = require("game/entities/wire")
local Mapper = require("game/systems/mapper")

local Roll = {}
Roll.__index = Roll
setmetatable(Roll, { __index = Item })  -- inherit from Item

function Roll.new(x, y)
    local self = Item.new(x, y, "Wire Roll", "assets/images/items/wire_roll.png", 48, 48)
    setmetatable(self, Roll)
    self._type = "roll"
    return self
end

-- Secondary action: place a wire at the player's current tile
function Roll:use(player, scene)
    if scene.game_state.wires <= 0 then return end

    local tx, ty = Mapper.world_to_tile(player.x + player.w / 2, player.y + player.h / 2)
    local tx_pixels = tx * Mapper.TILE
    local ty_pixels = ty * Mapper.TILE

    -- Don't place if a wire already exists at this tile
    if Mapper.get(scene.wire_grid, tx, ty) ~= nil then return end

    local wire = Wire.new(tx, ty)
    Mapper.set(scene.wire_grid, tx, ty, wire)
    table.insert(scene.wires, wire)
    scene.game_state.wires = scene.game_state.wires - 1
end

function Roll:update(dt)
    Item.update(self, dt)  -- sync sprite position
end

function Roll:draw()
    Item.draw(self)
end

return Roll

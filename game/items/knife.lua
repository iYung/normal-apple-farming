local Item   = require("game/items/item")
local Mapper = require("game/systems/mapper")

local Knife = {}
Knife.__index = Knife
setmetatable(Knife, { __index = Item })

function Knife.new(x, y)
    local self = Item.new(x, y, "Knife", "assets/images/items/knife.png", 48, 48)
    setmetatable(self, Knife)
    self._type = "knife"
    return self
end

-- Secondary action: remove all wires within 2-tile radius of player centre
function Knife:use(player, scene)
    local px = player.x + player.w / 2
    local py = player.y + player.h / 2
    local radius_sq = (Mapper.TILE * 2) * (Mapper.TILE * 2)  -- 2-tile radius, squared

    -- Collect keys to remove (don't modify table while iterating)
    local to_remove = {}
    for key, wire in pairs(scene.wire_grid) do
        if type(wire) == "table" then
            local wx = wire.x + wire.w / 2
            local wy = wire.y + wire.h / 2
            local dx = wx - px
            local dy = wy - py
            if dx * dx + dy * dy <= radius_sq then
                table.insert(to_remove, { key = key, wire = wire })
            end
        end
    end

    -- Remove from grid and wires array
    for _, entry in ipairs(to_remove) do
        scene.wire_grid[entry.key] = nil
        for i = #scene.wires, 1, -1 do
            if scene.wires[i] == entry.wire then
                table.remove(scene.wires, i)
                break
            end
        end
    end
end

function Knife:update(dt)
    Item.update(self, dt)
end

function Knife:draw()
    Item.draw(self)
end

return Knife

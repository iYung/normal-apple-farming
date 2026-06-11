local Item = require("game/items/item")

local Pruner = {}
Pruner.__index = Pruner
setmetatable(Pruner, { __index = Item })

function Pruner.new(x, y)
    local self = Item.new(x, y, "Pruner", "assets/images/items/pruner.png", 32, 32)
    setmetatable(self, Pruner)
    self._type = "pruner"
    return self
end

function Pruner:update(dt)
    Item.update(self, dt)
end

function Pruner:draw()
    Item.draw(self)
end

-- No use() override — pruner has no secondary action

return Pruner

local Item = require("game/items/item")

local Rocket = {}
Rocket.__index = Rocket
setmetatable(Rocket, { __index = Item })

function Rocket.new(x, y)
    local self = Item.new(x, y, "Rocket", "assets/images/items/rocket.png", 120, 240)
    setmetatable(self, Rocket)
    self._type        = "rocket"
    self.carriable    = true
    self._launched    = false
    self._flight_timer = 0
    self._done        = false
    return self
end

function Rocket:interact(player, scene, scene_manager)
    self._launched    = true
    self._flight_timer = 0
    self._done        = false
    self.held         = false
    player.held_item  = nil
    scene.active_rocket = self
end

function Rocket:update(dt)
    Item.update(self, dt)
    if self._launched and not self._done then
        self.y = self.y - 300 * dt
        self._flight_timer = self._flight_timer + dt
        if self._flight_timer >= 4.5 then
            self._done = true
            return "launch_complete"
        end
    end
end

function Rocket:draw()
    Item.draw(self)
end

return Rocket

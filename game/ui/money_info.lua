local img = love.graphics.newImage("assets/images/hud/money_info_container.png")

local MoneyInfo = {}
MoneyInfo.__index = MoneyInfo

function MoneyInfo.new(game_state)
    local self = setmetatable({}, MoneyInfo)
    self._state = game_state
    return self
end

function MoneyInfo:draw()
    local x, y = 16, 120   -- below the animal_info panel (which is at y=16, h=90)
    -- Background (192×96 PNG scaled to 192×48)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, x, y, 0, 1, 0.5)

    love.graphics.setColor(0.9, 0.85, 0.2, 1)
    love.graphics.print("$" .. self._state.money, x + 8, y + 16)

    love.graphics.setColor(1, 1, 1, 1)
end

return MoneyInfo

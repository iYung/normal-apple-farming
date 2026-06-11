local MoneyInfo = {}
MoneyInfo.__index = MoneyInfo

function MoneyInfo.new(game_state)
    local self = setmetatable({}, MoneyInfo)
    self._state = game_state
    return self
end

function MoneyInfo:draw()
    local x, y = 16, 120   -- below the animal_info panel (which is at y=16, h=90)
    local w, h = 160, 50

    -- Background
    love.graphics.setColor(0.1, 0.1, 0.15, 0.85)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    love.graphics.setColor(0.5, 0.5, 0.7, 1)
    love.graphics.rectangle("line", x, y, w, h, 4, 4)

    love.graphics.setColor(0.9, 0.85, 0.2, 1)
    love.graphics.print("$" .. self._state.money, x + 8, y + 8)

    love.graphics.setColor(0.7, 0.9, 1, 1)
    love.graphics.print("Wires: " .. self._state.wires, x + 8, y + 26)

    love.graphics.setColor(1, 1, 1, 1)
end

return MoneyInfo

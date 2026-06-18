local ui = require("game/ui")

local MoneyInfo = {}
MoneyInfo.__index = MoneyInfo

function MoneyInfo.new(game_state)
    local self = setmetatable({}, MoneyInfo)
    self._state = game_state
    return self
end

function MoneyInfo:draw()
    local x, y = 16, 16
    local w, h = 160, 48

    ui.draw_bubble(x, y, w, h)

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.print("$" .. self._state.money, x + 10, y + 14)
    love.graphics.setColor(1, 1, 1, 1)
end

return MoneyInfo

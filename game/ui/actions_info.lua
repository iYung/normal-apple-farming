local Detector = require("game/systems/detector")

local ActionsInfo = {}
ActionsInfo.__index = ActionsInfo

function ActionsInfo.new()
    local self = setmetatable({}, ActionsInfo)
    self._nearby  = {}   -- list of nearby entity names (strings)
    self._held    = nil  -- currently held item/animal (or nil)
    return self
end

-- nearby_list: array of entities near the player (with .name or ._type fields)
function ActionsInfo:set_nearby(nearby_list)
    self._nearby = nearby_list
end

function ActionsInfo:set_held(item_or_nil)
    self._held = item_or_nil
end

function ActionsInfo:draw()
    local x  = 16
    local y  = 720 - 48
    local w  = 500
    local h  = 36

    love.graphics.setColor(0.1, 0.1, 0.15, 0.85)
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)

    love.graphics.setColor(0.8, 0.8, 0.8, 1)

    -- E key hint
    local e_hint = ""
    if self._held then
        e_hint = "[E] Drop"
    elseif #self._nearby > 0 then
        local nearest = self._nearby[1]
        local label = nearest.name or nearest._type or "item"
        e_hint = "[E] Pick up " .. label
    else
        e_hint = "[E] Interact"
    end

    -- O key hint
    local o_hint = ""
    if self._held then
        if Detector.is_roll(self._held) then
            o_hint = "  [O] Place wire"
        elseif Detector.is_knife(self._held) then
            o_hint = "  [O] Remove wires"
        end
    end

    love.graphics.print(e_hint .. o_hint, x + 8, y + 10)

    love.graphics.setColor(1, 1, 1, 1)
end

return ActionsInfo

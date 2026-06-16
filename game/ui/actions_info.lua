local Detector = require("game/systems/detector")
local ui       = require("game/ui")

local ActionsInfo = {}
ActionsInfo.__index = ActionsInfo

local function key_label(keybinds, action)
    local k = keybinds and keybinds[action] or action
    return "[" .. k:upper() .. "]"
end

function ActionsInfo.new(keybinds)
    local self = setmetatable({}, ActionsInfo)
    self._nearby  = {}   -- list of nearby entity names (strings)
    self._held    = nil  -- currently held item/animal (or nil)
    self._keybinds = keybinds or {}
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
    -- E key hint
    local e_hint = ""
    if self._held then
        e_hint = key_label(self._keybinds, "pickup") .. " Drop"
    elseif #self._nearby > 0 then
        local nearest = self._nearby[1]
        local label = nearest.name or nearest._type or "item"
        e_hint = key_label(self._keybinds, "pickup") .. " Pick up " .. label
    else
        e_hint = key_label(self._keybinds, "interact") .. " Interact"
    end

    -- O key hint
    local o_hint = ""
    if self._held then
        if Detector.is_roll(self._held) then
            o_hint = "  " .. key_label(self._keybinds, "interact") .. " Place wire"
        elseif Detector.is_knife(self._held) then
            o_hint = "  " .. key_label(self._keybinds, "interact") .. " Remove wires"
        end
    end

    local PAD    = 14
    local margin = 10
    local font   = love.graphics.getFont()
    local hint   = e_hint .. o_hint
    local box_w  = font:getWidth(hint) + PAD * 2
    local box_h  = 20 + PAD * 2   -- one line_height row
    local box_x  = margin
    local box_y  = 720 - margin - box_h

    ui.draw_hud_box({hint}, font, margin)

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.print(hint, box_x + PAD, box_y + PAD)
    love.graphics.setColor(1, 1, 1, 1)
end

return ActionsInfo

local Detector = require("game/systems/detector")
local ui       = require("game/ui")

local ActionsInfo = {}
ActionsInfo.__index = ActionsInfo

local function key_label(input, action)
    if not input then return "[" .. action:upper() .. "]" end
    local k = input.key_for and input:key_for(action)
    if k == nil then k = action end
    -- key_for returns "[A]" in gamepad mode (already bracketed)
    -- key_for returns "e" in keyboard mode (needs brackets)
    if k:sub(1,1) == "[" then
        return k
    end
    return "[" .. k:upper() .. "]"
end

function ActionsInfo.new(input)
    local self = setmetatable({}, ActionsInfo)
    self._nearby  = {}   -- list of nearby entity names (strings)
    self._held    = nil  -- currently held item/animal (or nil)
    self._interact_target = nil  -- nearest interactable entity (or nil)
    self._input = input or {}
    return self
end

-- nearby_list: array of entities near the player (with .name or ._type fields)
function ActionsInfo:set_nearby(nearby_list)
    self._nearby = nearby_list
end

function ActionsInfo:set_held(item_or_nil)
    self._held = item_or_nil
end

function ActionsInfo:set_interact_target(entity_or_nil)
    self._interact_target = entity_or_nil
end

function ActionsInfo:draw()
    -- E key hint
    local e_hint = ""
    if self._held then
        e_hint = key_label(self._input, "pickup") .. " Drop"
    else
        local interact_hint = ""
        if Detector.is_interactable(self._interact_target) then
            local label
            local t = self._interact_target._type
            if t == "book" then label = "Read Book"
            elseif t == "shop_item" then label = "Open Shop"
            elseif t == "rocket" then label = "Launch Rocket"
            else label = "Interact"
            end
            interact_hint = key_label(self._input, "interact") .. " " .. label
        end

        local pickup_hint = ""
        if #self._nearby > 0 then
            local nearest = self._nearby[1]
            local label = nearest.name or nearest._type or "item"
            pickup_hint = key_label(self._input, "pickup") .. " Pick up " .. label
        end

        if interact_hint ~= "" and pickup_hint ~= "" then
            e_hint = interact_hint .. "  " .. pickup_hint
        elseif interact_hint ~= "" then
            e_hint = interact_hint
        elseif pickup_hint ~= "" then
            e_hint = pickup_hint
        else
            e_hint = key_label(self._input, "interact") .. " Interact"
        end
    end

    -- O key hint
    local o_hint = ""
    if self._held then
        if Detector.is_roll(self._held) then
            o_hint = "  " .. key_label(self._input, "interact") .. " Place wire"
        elseif Detector.is_knife(self._held) then
            o_hint = "  " .. key_label(self._input, "interact") .. " Remove wires"
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

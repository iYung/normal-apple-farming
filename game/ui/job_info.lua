local ui    = require("game/ui")
local Fonts = require("game/fonts")
local font  = Fonts.new(14)

local PAD        = 10
local LINE_H     = 18
local GAP        = 8
local panel_w    = 204
local panel_x    = 1280 - 220
local TEXT_COLOR = { 0.15, 0.10, 0.05, 1 }

local JobInfo = {}
JobInfo.__index = JobInfo

function JobInfo.new(game_state)
    local self = setmetatable({}, JobInfo)
    self._state = game_state
    return self
end

function JobInfo:draw()
    local jobs = self._state.active_jobs
    if #jobs == 0 then return end

    local panel_y = 44

    local has_active = false
    for _, job in ipairs(jobs) do
        if not job.completed then has_active = true; break end
    end
    if not has_active then return end

    local label = "ORDERS"
    local label_x = panel_x + math.floor((panel_w - font:getWidth(label)) / 2)
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(label, label_x, panel_y - 28)

    local card_y = panel_y

    for _, job in ipairs(jobs) do
        if not job.completed then
            local num_goals = #job.goals
            local card_h    = PAD + (num_goals + 1) * LINE_H + PAD

            ui.draw_bubble(panel_x, card_y, panel_w, card_h)

            love.graphics.setFont(font)
            love.graphics.setColor(TEXT_COLOR)

            local cy = card_y + PAD

            for _, goal in ipairs(job.goals) do
                if goal._type == "speed" then
                    local word = goal.exceed and "greater than" or "less than"
                    love.graphics.print("Speed " .. word .. " " .. goal.threshold, panel_x + PAD, cy)
                elseif goal._type == "height" then
                    love.graphics.print("Height greater than " .. goal.value, panel_x + PAD, cy)
                elseif goal._type == "personality" then
                    love.graphics.print("Trait: " .. goal.value, panel_x + PAD, cy)
                elseif goal._type == "color" then
                    love.graphics.print("Color:", panel_x + PAD, cy)
                    love.graphics.setColor(goal.target_r, goal.target_g, goal.target_b, 1)
                    love.graphics.rectangle("fill", panel_x + 60, cy + 3, 16, 10)
                    love.graphics.setColor(0.1, 0.1, 0.1, 1)
                    love.graphics.rectangle("line", panel_x + 60, cy + 3, 16, 10)
                    love.graphics.setColor(TEXT_COLOR)
                end
                cy = cy + LINE_H
            end

            love.graphics.setColor(TEXT_COLOR)
            love.graphics.print("$" .. job.reward, panel_x + PAD, cy)

            card_y = card_y + card_h + GAP
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return JobInfo

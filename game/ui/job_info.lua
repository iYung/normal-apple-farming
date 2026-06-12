local ui = require("game/ui")

local PAD    = 10
local LINE_H = 16

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

    local panel_x = 1280 - 220
    local panel_y = 16
    local panel_w = 204

    for idx, job in ipairs(jobs) do
        if not job.completed then
            local num_goals = #job.goals
            local panel_h = PAD + num_goals * LINE_H + LINE_H + PAD
            local jy = panel_y + (idx - 1) * (panel_h + 8)

            ui.draw_bubble(panel_x, jy, panel_w, panel_h)

            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            local cy = jy + PAD

            for _, goal in ipairs(job.goals) do
                if goal._type == "speed" then
                    local dir = goal.exceed and ">=" or "<="
                    love.graphics.print("Speed " .. dir .. " " .. goal.threshold, panel_x + PAD, cy)
                    cy = cy + LINE_H
                elseif goal._type == "height" then
                    love.graphics.print("Height >= " .. goal.value, panel_x + PAD, cy)
                    cy = cy + LINE_H
                elseif goal._type == "personality" then
                    love.graphics.print("Trait: " .. goal.value, panel_x + PAD, cy)
                    cy = cy + LINE_H
                elseif goal._type == "color" then
                    love.graphics.print("Color:", panel_x + PAD, cy)
                    love.graphics.setColor(goal.target_r, goal.target_g, goal.target_b, 1)
                    love.graphics.rectangle("fill", panel_x + 54, cy + 2, 16, 10)
                    love.graphics.setColor(0.1, 0.1, 0.1, 1)
                    love.graphics.rectangle("line", panel_x + 54, cy + 2, 16, 10)
                    cy = cy + LINE_H
                end
            end

            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.print("$" .. job.reward, panel_x + PAD, cy)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return JobInfo

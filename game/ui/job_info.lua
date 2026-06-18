local ui    = require("game/ui")
local Fonts = require("game/fonts")
local font  = Fonts.new(14)

local PAD        = 10
local TOP_H      = 42
local MID_H      = 30
local BOT_H      = 19
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

    local panel_y = 16

    -- Check if there is at least one active non-completed job
    local has_active = false
    for _, job in ipairs(jobs) do
        if not job.completed then
            has_active = true
            break
        end
    end

    if not has_active then return end

    -- Draw "ORDERS" label above the stack
    love.graphics.setFont(font)
    love.graphics.setColor(TEXT_COLOR)
    love.graphics.print("ORDERS", panel_x + PAD, panel_y - 18)

    local card_y = panel_y

    for _, job in ipairs(jobs) do
        if not job.completed then
            local num_goals = #job.goals
            local num_rows  = num_goals + 1
            local card_h    = TOP_H + num_rows * MID_H + BOT_H

            ui.draw_job_card(panel_x, card_y, panel_w, num_rows)

            love.graphics.setFont(font)
            love.graphics.setColor(TEXT_COLOR)

            local gy = card_y + TOP_H

            for _, goal in ipairs(job.goals) do
                local ty = gy + math.floor((MID_H - font:getHeight()) / 2)

                if goal._type == "speed" then
                    if goal.exceed then
                        love.graphics.print("Speed \xe2\x89\xa5 " .. goal.threshold, panel_x + PAD, ty)
                    else
                        love.graphics.print("Speed \xe2\x89\xa4 " .. goal.threshold, panel_x + PAD, ty)
                    end
                elseif goal._type == "height" then
                    love.graphics.print("Height \xe2\x89\xa5 " .. goal.value, panel_x + PAD, ty)
                elseif goal._type == "personality" then
                    love.graphics.print("Trait: " .. goal.value, panel_x + PAD, ty)
                elseif goal._type == "color" then
                    love.graphics.print("Color:", panel_x + PAD, ty)
                    love.graphics.setColor(goal.target_r, goal.target_g, goal.target_b, 1)
                    love.graphics.rectangle("fill", panel_x + 60, gy + 3, 16, 10)
                    love.graphics.setColor(0.1, 0.1, 0.1, 1)
                    love.graphics.rectangle("line", panel_x + 60, gy + 3, 16, 10)
                    love.graphics.setColor(TEXT_COLOR)
                end

                gy = gy + MID_H
            end

            -- Reward row
            local ty = gy + math.floor((MID_H - font:getHeight()) / 2)
            love.graphics.setColor(TEXT_COLOR)
            love.graphics.print("$" .. job.reward, panel_x + PAD, ty)

            card_y = card_y + card_h + GAP
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return JobInfo

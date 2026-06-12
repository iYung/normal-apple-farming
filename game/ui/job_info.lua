local img_top = love.graphics.newImage("assets/images/hud/job_info_top.png")
local img_mid = love.graphics.newImage("assets/images/hud/job_info_mid.png")
local img_bot = love.graphics.newImage("assets/images/hud/job_info_bottom.png")

local TOP_H = 42
local MID_H = 30
local BOT_H = 19

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
            local panel_h = TOP_H + num_goals * MID_H + BOT_H
            local jy = panel_y + (idx - 1) * (panel_h + 8)

            -- Background (3-piece PNG stack)
            local sx = panel_w / 192
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(img_top, panel_x, jy,                           0, sx, 1)
            for i = 0, num_goals - 1 do
                love.graphics.draw(img_mid, panel_x, jy + TOP_H + i * MID_H,  0, sx, 1)
            end
            love.graphics.draw(img_bot, panel_x, jy + TOP_H + num_goals * MID_H, 0, sx, 1)

            love.graphics.setColor(1, 1, 1, 1)
            local cy = jy + 10

            for _, goal in ipairs(job.goals) do
                if goal._type == "speed" then
                    local dir = goal.exceed and ">=" or "<="
                    love.graphics.print("Speed " .. dir .. " " .. goal.threshold, panel_x + 6, cy)
                    cy = cy + MID_H
                elseif goal._type == "height" then
                    love.graphics.print("Height >= " .. goal.value, panel_x + 6, cy)
                    cy = cy + MID_H
                elseif goal._type == "personality" then
                    love.graphics.print("Trait: " .. goal.value, panel_x + 6, cy)
                    cy = cy + MID_H
                elseif goal._type == "color" then
                    love.graphics.print("Color:", panel_x + 6, cy)
                    love.graphics.setColor(goal.target_r, goal.target_g, goal.target_b, 1)
                    love.graphics.rectangle("fill", panel_x + 50, cy + 2, 16, 10)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.rectangle("line", panel_x + 50, cy + 2, 16, 10)
                    love.graphics.setColor(1, 1, 1, 1)
                    cy = cy + MID_H
                end
            end

            -- Reward
            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.print("$" .. job.reward, panel_x + 6, jy + TOP_H + num_goals * MID_H - 18)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return JobInfo

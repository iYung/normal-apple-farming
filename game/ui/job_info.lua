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
    local job_h   = 90
    local gap     = 8

    for idx, job in ipairs(jobs) do
        if not job.completed then
            local jy = panel_y + (idx - 1) * (job_h + gap)

            -- Background
            love.graphics.setColor(0.1, 0.1, 0.15, 0.85)
            love.graphics.rectangle("fill", panel_x, jy, panel_w, job_h, 4, 4)
            love.graphics.setColor(0.5, 0.5, 0.7, 1)
            love.graphics.rectangle("line", panel_x, jy, panel_w, job_h, 4, 4)

            love.graphics.setColor(1, 1, 1, 1)
            local cy = jy + 6

            for _, goal in ipairs(job.goals) do
                if goal._type == "speed" then
                    local dir = goal.exceed and ">=" or "<="
                    love.graphics.print("Speed " .. dir .. " " .. goal.threshold, panel_x + 6, cy)
                    cy = cy + 14
                elseif goal._type == "height" then
                    love.graphics.print("Height >= " .. goal.value, panel_x + 6, cy)
                    cy = cy + 14
                elseif goal._type == "personality" then
                    love.graphics.print("Trait: " .. goal.value, panel_x + 6, cy)
                    cy = cy + 14
                elseif goal._type == "color" then
                    love.graphics.print("Color:", panel_x + 6, cy)
                    love.graphics.setColor(goal.target_r, goal.target_g, goal.target_b, 1)
                    love.graphics.rectangle("fill", panel_x + 50, cy + 2, 16, 10)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.rectangle("line", panel_x + 50, cy + 2, 16, 10)
                    love.graphics.setColor(1, 1, 1, 1)
                    cy = cy + 14
                end
            end

            -- Reward
            love.graphics.setColor(0.9, 0.85, 0.2, 1)
            love.graphics.print("$" .. job.reward, panel_x + 6, jy + job_h - 18)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return JobInfo

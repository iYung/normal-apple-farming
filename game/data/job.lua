local Goal = {}
Goal.__index = Goal

function Goal.speed(threshold, exceed)
    local self = setmetatable({}, Goal)
    self._type = "speed"
    self.threshold = threshold
    self.exceed = exceed
    return self
end

function Goal.color(target_r, target_g, target_b, max_dist_sq)
    local self = setmetatable({}, Goal)
    self._type = "color"
    self.target_r = target_r
    self.target_g = target_g
    self.target_b = target_b
    self.max_dist_sq = max_dist_sq
    return self
end

function Goal.height(value)
    local self = setmetatable({}, Goal)
    self._type = "height"
    self.value = value
    return self
end

function Goal.personality(value)
    local self = setmetatable({}, Goal)
    self._type = "personality"
    self.value = value
    return self
end

function Goal.test(goal, stats)
    if goal._type == "speed" then
        if goal.exceed then
            return stats.speed >= goal.threshold
        else
            return stats.speed <= goal.threshold
        end
    elseif goal._type == "color" then
        local dr = goal.target_r - stats.color.r
        local dg = goal.target_g - stats.color.g
        local db = goal.target_b - stats.color.b
        local dist_sq = dr * dr + dg * dg + db * db
        return dist_sq < goal.max_dist_sq
    elseif goal._type == "height" then
        return stats.height >= goal.value
    elseif goal._type == "personality" then
        return stats.personality == goal.value
    end
    return false
end


local Job = {}
Job.__index = Job

function Job.new(goals, reward)
    local self = setmetatable({}, Job)
    self.goals = goals
    self.reward = reward
    self.completed = false
    return self
end

function Job.test(job, stats)
    for _, goal in ipairs(job.goals) do
        if not Goal.test(goal, stats) then
            return false
        end
    end
    return true
end


return {
    Goal = Goal,
    Job = Job,
}

local Timer       = require("core/lua/timer")
local JobData     = require("game/data/job")
local AnimalStats = require("game/data/animal_stats")

local Goal = JobData.Goal
local Job  = JobData.Job

local JobGenerator = {}
JobGenerator.__index = JobGenerator

function JobGenerator.new(game_state)
    local self = setmetatable({}, JobGenerator)
    self._state      = game_state
    self._timer      = Timer.new(8)
    self._max_goals  = 1
    self._goal_types = { "speed" }  -- unlocked types; start with speed only
    return self
end

function JobGenerator:update(dt)
    if self._timer:update(dt) then
        local gs = self._state
        if #gs.active_jobs < 4 then
            local job = self:_create_job(gs.jobs_done)
            table.insert(gs.active_jobs, job)
        end
    end
end

-- Creates a job appropriate to the current jobs_done milestone
function JobGenerator:_create_job(jobs_done)
    -- Unlock new types (idempotent checks)
    self:_update_unlocks(jobs_done)

    -- Tutorial jobs (fixed)
    if jobs_done == 0 then
        return Job.new({ Goal.speed(120, true) }, 10)
    end
    if jobs_done == 1 then
        return Job.new({ Goal.speed(80, false) }, 12)
    end
    if jobs_done == 3 then
        return Job.new({ Goal.speed(150, true) }, 15)
    end

    -- Random job from unlocked types
    local num_goals = math.min(math.random(1, #self._goal_types), self._max_goals)
    local chosen_types = self:_pick_types(num_goals)

    local goals = {}
    for _, gtype in ipairs(chosen_types) do
        table.insert(goals, self:_make_goal(gtype, jobs_done))
    end

    local reward = 10
    for _ = 1, #goals do
        reward = reward + math.floor(jobs_done * 0.25)
    end
    reward = reward + math.random(-10, 10)
    reward = math.max(1, reward)

    return Job.new(goals, reward)
end

function JobGenerator:_update_unlocks(jobs_done)
    local function has(t, v)
        for _, x in ipairs(t) do if x == v then return true end end
        return false
    end
    if jobs_done > 8  and not has(self._goal_types, "personality") then
        table.insert(self._goal_types, "personality")
    end
    if jobs_done > 11 then self._max_goals = 2 end
    if jobs_done > 15 and not has(self._goal_types, "height") then
        table.insert(self._goal_types, "height")
    end
    if jobs_done > 25 then self._max_goals = 3 end
    if jobs_done > 30 and not has(self._goal_types, "color") then
        table.insert(self._goal_types, "color")
    end
    if jobs_done > 40 then self._max_goals = 4 end
end

-- Returns a shuffled array of `n` unique types from self._goal_types
function JobGenerator:_pick_types(n)
    local pool = {}
    for _, t in ipairs(self._goal_types) do table.insert(pool, t) end
    -- Fisher-Yates shuffle
    for i = #pool, 2, -1 do
        local j = math.random(i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    local result = {}
    for i = 1, math.min(n, #pool) do result[i] = pool[i] end
    return result
end

function JobGenerator:_make_goal(gtype, jobs_done)
    if gtype == "speed" then
        local diff = jobs_done + 1
        local threshold = 100 + math.random(-diff, diff)
        threshold = math.max(1, threshold)
        return Goal.speed(threshold, threshold > 100)
    elseif gtype == "height" then
        local h = 1 + math.random() * 0.3 * jobs_done
        h = math.floor(h)
        h = math.max(1, h)
        return Goal.height(h)
    elseif gtype == "color" then
        -- Start random, average toward base (0.5, 0.5, 0.1) until dist_sq < threshold
        local threshold = math.min(0.001 * jobs_done, 1.3)
        threshold = math.max(0.01, threshold)  -- prevent infinite loop early
        local r = math.random()
        local g = math.random()
        local b = math.random()
        local base_r, base_g, base_b = 0.5, 0.5, 0.1
        for _ = 1, 100 do
            local dr = r - base_r
            local dg = g - base_g
            local db = b - base_b
            if dr*dr + dg*dg + db*db <= threshold then break end
            -- average toward base
            local ch = math.random(1, 3)
            if ch == 1 then r = (r + base_r) / 2
            elseif ch == 2 then g = (g + base_g) / 2
            else b = (b + base_b) / 2 end
        end
        return Goal.color(r, g, b, threshold)
    elseif gtype == "personality" then
        local p = AnimalStats.PERSONALITIES
        return Goal.personality(p[math.random(#p)])
    end
end

return JobGenerator

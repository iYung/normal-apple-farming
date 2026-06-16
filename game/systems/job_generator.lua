local Timer       = require("core/lua/timer")
local JobData     = require("game/data/job")
local AnimalStats = require("game/data/animal_stats")

local Goal = JobData.Goal
local Job  = JobData.Job

local CONFIG = {
    spawn_interval  = 8,
    max_active_jobs = 4,

    unlocks = {
        types = {
            { at = 8,  type = "personality" },
            { at = 15, type = "height" },
            { at = 30, type = "color" },
        },
        max_goals = {
            { at = 11, value = 2 },
            { at = 25, value = 3 },
            { at = 40, value = 4 },
        },
    },

    reward = { base = 10, per_goal = 0.25, variance = 10, min = 1 },
    -- calibrated from tests/test_breed_balance.lua
    speed  = { base = 100, diff_scale = 3 },
    height = { scale = 0.45 },
    color  = { base = {r = 0.5, g = 0.5, b = 0.1}, dist_scale = 0.0002, dist_max = 0.3, dist_min = 0.006 },
}

local JobGenerator = {}
JobGenerator.__index = JobGenerator

function JobGenerator.new(game_state)
    local self = setmetatable({}, JobGenerator)
    self._state      = game_state
    self._timer      = Timer.new(CONFIG.spawn_interval)
    self._max_goals  = 1
    self._goal_types = { "speed" }
    return self
end

function JobGenerator:update(dt)
    if self._timer:update(dt) then
        local gs = self._state
        if #gs.active_jobs < CONFIG.max_active_jobs then
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

    local reward = CONFIG.reward.base
    for _ = 1, #goals do
        reward = reward + math.floor(jobs_done * CONFIG.reward.per_goal)
    end
    reward = reward + math.random(-CONFIG.reward.variance, CONFIG.reward.variance)
    reward = math.max(CONFIG.reward.min, reward)

    return Job.new(goals, reward)
end

function JobGenerator:_update_unlocks(jobs_done)
    local function has(t, v)
        for _, x in ipairs(t) do if x == v then return true end end
        return false
    end
    for _, u in ipairs(CONFIG.unlocks.types) do
        if jobs_done > u.at and not has(self._goal_types, u.type) then
            table.insert(self._goal_types, u.type)
        end
    end
    for _, u in ipairs(CONFIG.unlocks.max_goals) do
        if jobs_done > u.at then
            self._max_goals = u.value
        end
    end
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
        local diff = math.max(1, math.floor(CONFIG.speed.diff_scale * (jobs_done + 1)))
        local threshold = CONFIG.speed.base + math.random(-diff, diff)
        threshold = math.max(1, threshold)
        return Goal.speed(threshold, threshold > CONFIG.speed.base)
    elseif gtype == "height" then
        local h = math.floor(1 + math.random() * CONFIG.height.scale * jobs_done)
        h = math.max(1, h)
        return Goal.height(h)
    elseif gtype == "color" then
        local c = CONFIG.color
        local threshold = math.max(c.dist_min, math.min(c.dist_scale * jobs_done, c.dist_max))
        local r, g, b = math.random(), math.random(), math.random()
        for _ = 1, 100 do
            local dr, dg, db = r - c.base.r, g - c.base.g, b - c.base.b
            if dr*dr + dg*dg + db*db <= threshold then break end
            local ch = math.random(1, 3)
            if ch == 1 then r = (r + c.base.r) / 2
            elseif ch == 2 then g = (g + c.base.g) / 2
            else b = (b + c.base.b) / 2 end
        end
        return Goal.color(r, g, b, threshold)
    elseif gtype == "personality" then
        local p = AnimalStats.PERSONALITIES
        return Goal.personality(p[math.random(#p)])
    end
end

return JobGenerator

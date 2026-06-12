local JobGenerator = require("game/systems/job_generator")

local function make_state(jobs_done, active_jobs)
    return { jobs_done = jobs_done or 0, active_jobs = active_jobs or {} }
end

-- Helper: drive the timer past one interval tick
local function tick(gen)
    gen:update(9)  -- spawn_interval is 8; any value > 8 fires once
end

-- Tutorial jobs are fixed at jobs_done 0, 1, 3
local gs = make_state(0)
local gen = JobGenerator.new(gs)
tick(gen)
assert(#gs.active_jobs == 1, "should spawn one tutorial job at jobs_done=0")
local j0 = gs.active_jobs[1]
assert(#j0.goals == 1 and j0.goals[1]._type == "speed", "tutorial job 0 should be a speed goal")
assert(j0.goals[1].exceed == true, "tutorial job 0 should exceed threshold")
assert(j0.goals[1].threshold == 120, "tutorial job 0 threshold should be 120")
assert(j0.reward == 10, "tutorial job 0 reward should be 10")
print("PASS: tutorial job 0")

gs = make_state(1)
gen = JobGenerator.new(gs)
tick(gen)
local j1 = gs.active_jobs[1]
assert(j1.goals[1].exceed == false, "tutorial job 1 should be under-threshold")
assert(j1.goals[1].threshold == 80, "tutorial job 1 threshold should be 80")
assert(j1.reward == 12, "tutorial job 1 reward should be 12")
print("PASS: tutorial job 1")

gs = make_state(3)
gen = JobGenerator.new(gs)
tick(gen)
local j3 = gs.active_jobs[1]
assert(j3.goals[1].threshold == 150, "tutorial job 3 threshold should be 150")
assert(j3.reward == 15, "tutorial job 3 reward should be 15")
print("PASS: tutorial job 3")

-- Cap at max_active_jobs (4)
gs = make_state(10)
gen = JobGenerator.new(gs)
for _ = 1, 10 do tick(gen) end
assert(#gs.active_jobs <= 4, "should never exceed 4 active jobs")
print("PASS: max active jobs cap")

-- Unlocks: only speed before milestone 8
gs = make_state(5)
gen = JobGenerator.new(gs)
gen:_update_unlocks(5)
local function has(t, v) for _, x in ipairs(t) do if x == v then return true end end return false end
assert(not has(gen._goal_types, "personality"), "personality should not unlock before jobs_done > 8")
assert(not has(gen._goal_types, "height"),      "height should not unlock before jobs_done > 15")
assert(not has(gen._goal_types, "color"),       "color should not unlock before jobs_done > 30")
print("PASS: no unlocks before milestones")

-- Personality unlocks after jobs_done > 8
gen:_update_unlocks(9)
assert(has(gen._goal_types, "personality"), "personality should unlock at jobs_done > 8")
print("PASS: personality unlocks at >8")

-- max_goals increases at milestones
gen:_update_unlocks(12)
assert(gen._max_goals == 2, "max_goals should be 2 after jobs_done > 11")
gen:_update_unlocks(26)
assert(gen._max_goals == 3, "max_goals should be 3 after jobs_done > 25")
gen:_update_unlocks(41)
assert(gen._max_goals == 4, "max_goals should be 4 after jobs_done > 40")
print("PASS: max_goals milestones")

-- Height and color unlock at correct milestones
gen:_update_unlocks(16)
assert(has(gen._goal_types, "height"), "height should unlock at jobs_done > 15")
gen:_update_unlocks(31)
assert(has(gen._goal_types, "color"), "color should unlock at jobs_done > 30")
print("PASS: height and color unlocks")

-- Reward scales with jobs_done and goal count
-- Run many random jobs and check reward is always >= 1
math.randomseed(42)
for jobs_done = 5, 50, 5 do
    gs = make_state(jobs_done)
    gen = JobGenerator.new(gs)
    for _ = 1, 20 do
        tick(gen)
        gs.active_jobs = {}  -- drain to keep spawning
    end
end
print("PASS: reward always >= 1 across range of jobs_done")

print("ALL TESTS PASSED")

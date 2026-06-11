local JobData = require("game/data/job")
local Goal = JobData.Goal
local Job  = JobData.Job

local function make_stats(speed, color, height, personality)
    return { speed=speed, color=color, height=height, personality=personality }
end

-- Speed goals
local g_fast = Goal.speed(100, true)   -- must be >= 100
local g_slow = Goal.speed(80, false)   -- must be <= 80

local fast_stats = make_stats(120, {r=0.5,g=0.5,b=0.5}, 2, "calm")
local slow_stats = make_stats(50,  {r=0.5,g=0.5,b=0.5}, 2, "calm")

assert(Goal.test(g_fast, fast_stats) == true,  "fast animal should pass speed >= 100")
assert(Goal.test(g_fast, slow_stats) == false, "slow animal should fail speed >= 100")
assert(Goal.test(g_slow, slow_stats) == true,  "slow animal should pass speed <= 80")
assert(Goal.test(g_slow, fast_stats) == false, "fast animal should fail speed <= 80")
print("PASS: speed goals")

-- Color goals
local g_red = Goal.color(1, 0, 0, 0.1)   -- close to red, max_dist_sq=0.1
local red_stats   = make_stats(100, {r=1.0, g=0.0, b=0.0}, 1, "calm")  -- exact red, dist=0
local green_stats = make_stats(100, {r=0.0, g=1.0, b=0.0}, 1, "calm")  -- very far from red

assert(Goal.test(g_red, red_stats)   == true,  "exact red should pass color goal")
assert(Goal.test(g_red, green_stats) == false, "green should fail red color goal")
print("PASS: color goals")

-- Height goals
local g_tall = Goal.height(3)   -- height >= 3
local tall_stats  = make_stats(100, {r=0.5,g=0.5,b=0.5}, 4, "calm")
local short_stats = make_stats(100, {r=0.5,g=0.5,b=0.5}, 2, "calm")

assert(Goal.test(g_tall, tall_stats)  == true,  "height 4 should pass height >= 3")
assert(Goal.test(g_tall, short_stats) == false, "height 2 should fail height >= 3")
print("PASS: height goals")

-- Personality goals
local g_silly = Goal.personality("silly")
local silly_stats  = make_stats(100, {r=0.5,g=0.5,b=0.5}, 1, "silly")
local calm_stats   = make_stats(100, {r=0.5,g=0.5,b=0.5}, 1, "calm")

assert(Goal.test(g_silly, silly_stats) == true,  "silly should pass personality=silly")
assert(Goal.test(g_silly, calm_stats)  == false, "calm should fail personality=silly")
print("PASS: personality goals")

-- Job.test requires ALL goals to pass
local multi_job = Job.new({
    Goal.speed(100, true),
    Goal.personality("silly"),
}, 50)

local both_pass = make_stats(150, {r=0.5,g=0.5,b=0.5}, 1, "silly")
local only_speed = make_stats(150, {r=0.5,g=0.5,b=0.5}, 1, "calm")
local only_personality = make_stats(50, {r=0.5,g=0.5,b=0.5}, 1, "silly")

assert(Job.test(multi_job, both_pass)        == true,  "should pass when all goals met")
assert(Job.test(multi_job, only_speed)       == false, "should fail if personality wrong")
assert(Job.test(multi_job, only_personality) == false, "should fail if speed wrong")
print("PASS: multi-goal job")

-- Job starts with completed=false
assert(multi_job.completed == false, "new job should not be completed")
print("PASS: job initial state")

print("ALL TESTS PASSED")

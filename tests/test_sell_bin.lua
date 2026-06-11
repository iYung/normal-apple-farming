local SellBin     = require("game/entities/sell_bin")
local GameState   = require("game/game_state")
local JobData     = require("game/data/job")
local AnimalStats = require("game/data/animal_stats")

local Goal = JobData.Goal
local Job  = JobData.Job

-- Helper: fake animal
local function make_animal(speed)
    local stats = AnimalStats.new(speed, {r=0.5,g=0.5,b=0.5}, 1, "calm")
    return { _type="animal", stats=stats, held=false, x=0, y=0, w=32, h=40 }
end

local bin = SellBin.new(500, 400)

-- Test 1: cannot sell when animal_population <= 2
local gs = GameState.new()
gs.animal_population = 2
local fast_animal = make_animal(150)
local reward = bin:try_sell(fast_animal, gs)
assert(reward == 0, "should not sell when population <= 2, got " .. reward)
assert(gs.money == 0, "money should not change when sell is blocked")
print("PASS: blocks sell when population <= 2")

-- Test 2: matching job awards correct reward
local gs2 = GameState.new()
gs2.animal_population = 4
local fast_job = Job.new({ Goal.speed(100, true) }, 75)
table.insert(gs2.active_jobs, fast_job)

local reward2 = bin:try_sell(make_animal(120), gs2)
assert(reward2 == 75, "should award job reward 75, got " .. reward2)
assert(gs2.money == 75, "money should be 75")
assert(gs2.jobs_done == 1, "jobs_done should be 1")
assert(fast_job.completed == true, "job should be marked completed")
assert(gs2.animal_population == 3, "animal_population should decrease by 1")
print("PASS: sells with matching job")

-- Test 3: completed job is not re-used
local reward3 = bin:try_sell(make_animal(120), gs2)
-- fast_job is already completed, but animal_population is still 3 (> 2), so falls back to reward=1
assert(reward3 == 1, "already-completed job should not be re-matched, got " .. reward3)
print("PASS: completed jobs not re-used")

-- Test 4: no matching job gives base reward of 1
local gs3 = GameState.new()
gs3.animal_population = 4
-- No jobs in active_jobs
local reward4 = bin:try_sell(make_animal(50), gs3)
assert(reward4 == 1, "no matching job should give reward 1, got " .. reward4)
assert(gs3.money == 1, "money should be 1")
print("PASS: base reward of 1 when no job matches")

-- Test 5: animal that does NOT match a job falls back to reward=1
local gs4 = GameState.new()
gs4.animal_population = 4
local slow_job = Job.new({ Goal.speed(200, true) }, 100)  -- needs speed >= 200
table.insert(gs4.active_jobs, slow_job)
local reward5 = bin:try_sell(make_animal(50), gs4)  -- speed 50 can't match
assert(reward5 == 1, "non-matching animal should get base reward 1, got " .. reward5)
assert(slow_job.completed == false, "unmatched job should not be completed")
print("PASS: non-matching animal gets base reward")

print("ALL TESTS PASSED")

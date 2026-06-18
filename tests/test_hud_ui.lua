-- Smoke tests for the PNG-based HUD modules.
-- Verifies each module loads and draw() runs without error in headless mode.

local GameState   = require("game/game_state")
local AnimalStats = require("game/data/animal_stats")
local JobData     = require("game/data/job")

local MoneyInfo   = require("game/ui/money_info")
local AnimalInfo  = require("game/ui/animal_info")
local JobInfo     = require("game/ui/job_info")
local ActionsInfo = require("game/ui/actions_info")

-- Shared state
local gs = GameState.new()
gs.money = 42

-- Test 1: MoneyInfo draws without error
local mi = MoneyInfo.new(gs)
mi:draw()
print("PASS: MoneyInfo draws without error")

-- Test 2: AnimalInfo draws with no animal set (early return)
local ai = AnimalInfo.new()
ai:draw()
print("PASS: AnimalInfo draws with nil animal")

-- Test 3: AnimalInfo draws with an animal set
local stats = AnimalStats.new(80, { r = 0.4, g = 0.7, b = 0.2 }, 2, "calm")
local fake_animal = { stats = stats, x = 300, y = 300 }
local fake_camera = { x = 640, y = 360, zoom = 1 }
local fake_player = { x = 600, y = 350 }
ai:set(fake_animal)
ai:draw(fake_camera, fake_player)
print("PASS: AnimalInfo draws with animal stats")

-- Test 4: JobInfo draws with no active jobs
local ji = JobInfo.new(gs)
ji:draw()
print("PASS: JobInfo draws with empty job list")

-- Test 5: JobInfo draws with a speed (exceed) goal
local job = JobData.Job.new({ JobData.Goal.speed(50, true) }, 30)
table.insert(gs.active_jobs, job)
ji:draw()
print("PASS: JobInfo draws with speed-exceed goal")

-- Test 5b: JobInfo draws with a speed (under) goal
gs.active_jobs = {}
local job_slow = JobData.Job.new({ JobData.Goal.speed(80, false) }, 12)
table.insert(gs.active_jobs, job_slow)
ji:draw()
print("PASS: JobInfo draws with speed-under goal")

-- Test 5c: JobInfo draws with a height goal
gs.active_jobs = {}
local job_h = JobData.Job.new({ JobData.Goal.height(3) }, 20)
table.insert(gs.active_jobs, job_h)
ji:draw()
print("PASS: JobInfo draws with height goal")

-- Test 5d: JobInfo draws with a personality goal
gs.active_jobs = {}
local job_p = JobData.Job.new({ JobData.Goal.personality("calm") }, 18)
table.insert(gs.active_jobs, job_p)
ji:draw()
print("PASS: JobInfo draws with personality goal")

-- Test 5e: JobInfo draws with a color goal
gs.active_jobs = {}
local job_c = JobData.Job.new({ JobData.Goal.color(0.8, 0.3, 0.1, 0.05) }, 25)
table.insert(gs.active_jobs, job_c)
ji:draw()
print("PASS: JobInfo draws with color goal")

-- Test 5f: JobInfo draws with multiple goals in one job
gs.active_jobs = {}
local job_multi = JobData.Job.new({
    JobData.Goal.speed(120, true),
    JobData.Goal.height(2),
    JobData.Goal.personality("silly"),
}, 40)
table.insert(gs.active_jobs, job_multi)
ji:draw()
print("PASS: JobInfo draws with multiple goals in one job")

-- Test 5g: JobInfo draws with multiple active jobs
gs.active_jobs = {}
table.insert(gs.active_jobs, JobData.Job.new({ JobData.Goal.speed(100, true) }, 15))
table.insert(gs.active_jobs, JobData.Job.new({ JobData.Goal.height(2) }, 20))
ji:draw()
print("PASS: JobInfo draws with multiple active jobs")

-- Test 6: ActionsInfo draws with nothing nearby and nothing held
local act = ActionsInfo.new()
act:draw()
print("PASS: ActionsInfo draws with no context")

-- Test 7: ActionsInfo draws with a held item
local fake_item = { _type = "roll", name = "roll", held = false, x = 0, y = 0, w = 16, h = 16 }
act:set_held(fake_item)
act:set_nearby({})
act:draw()
print("PASS: ActionsInfo draws with held item")

print("ALL TESTS PASSED")

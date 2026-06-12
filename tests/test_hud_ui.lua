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

-- Test 5: JobInfo draws with an active job
local job = JobData.Job.new({ JobData.Goal.speed(50, true) }, 30)
table.insert(gs.active_jobs, job)
ji:draw()
print("PASS: JobInfo draws with one active job")

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

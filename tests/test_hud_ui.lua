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

-- Helper: temporarily capture love.graphics.print calls during draw(),
-- then restore the stub. Returns the concatenated string of all printed text.
local function capture_hint(act)
    local captured = {}
    local orig_print = love.graphics.print
    love.graphics.print = function(text, ...)
        table.insert(captured, tostring(text))
    end
    act:draw()
    love.graphics.print = orig_print
    return table.concat(captured, "")
end

local mock_input = {
    _mode = "keyboard",
    _map  = { interact = {"e"}, pickup = {"f"} },
    key_for = function(self, action)
        local keys = self._map[action]
        return keys and keys[1]
    end,
}

-- Test 6: ActionsInfo draws with nothing nearby and nothing held.
-- Expect: interact key label "[E]" and "Interact" in hint.
local act = ActionsInfo.new(mock_input)
local hint = capture_hint(act)
assert(hint:find("%[E%]"),       "Test 6a: expected [E] in hint, got: " .. hint)
assert(hint:find("Interact"),    "Test 6b: expected 'Interact' in hint, got: " .. hint)
print("PASS: ActionsInfo nothing held/nearby → interact hint")

-- Test 7: ActionsInfo with held roll.
-- Expect: pickup key label "[F]" + "Drop", interact key label "[E]" + "Place wire".
local fake_roll = { _type = "roll", name = "roll", held = false, x = 0, y = 0, w = 16, h = 16 }
act:set_held(fake_roll)
act:set_nearby({})
hint = capture_hint(act)
assert(hint:find("%[F%]"),        "Test 7a: expected [F] in hint, got: " .. hint)
assert(hint:find("Drop"),         "Test 7b: expected 'Drop' in hint, got: " .. hint)
assert(hint:find("%[E%]"),        "Test 7c: expected [E] in hint, got: " .. hint)
assert(hint:find("Place wire"),   "Test 7d: expected 'Place wire' in hint, got: " .. hint)
print("PASS: ActionsInfo held roll → drop + place-wire hints")

-- Test 8: ActionsInfo with held knife.
-- Expect: pickup key label "[F]" + "Drop", interact key label "[E]" + "Remove wires".
local fake_knife = { _type = "knife", name = "knife", held = false, x = 0, y = 0, w = 16, h = 16 }
act:set_held(fake_knife)
act:set_nearby({})
hint = capture_hint(act)
assert(hint:find("%[F%]"),        "Test 8a: expected [F] in hint, got: " .. hint)
assert(hint:find("Drop"),         "Test 8b: expected 'Drop' in hint, got: " .. hint)
assert(hint:find("%[E%]"),        "Test 8c: expected [E] in hint, got: " .. hint)
assert(hint:find("Remove wires"), "Test 8d: expected 'Remove wires' in hint, got: " .. hint)
print("PASS: ActionsInfo held knife → drop + remove-wires hints")

-- Test 9: ActionsInfo with nearby entity, nothing held.
-- Expect: pickup key label "[F]" + "Pick up" in hint.
act:set_held(nil)
local fake_nearby = { name = "apple", _type = "item" }
act:set_nearby({ fake_nearby })
hint = capture_hint(act)
assert(hint:find("%[F%]"),   "Test 9a: expected [F] in hint, got: " .. hint)
assert(hint:find("Pick up"), "Test 9b: expected 'Pick up' in hint, got: " .. hint)
print("PASS: ActionsInfo nearby entity → pickup hint")

print("ALL TESTS PASSED")

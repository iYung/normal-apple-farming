-- test_rocket.lua
-- Verifies Rocket item: construction, interact() launch trigger, update() flight
-- and "launch_complete" signal, and the _done guard against double-trigger.

local Rocket = require("game/items/rocket")

-- ── helpers ───────────────────────────────────────────────────────────────────

local function make_player()
    return { x = 0, y = 0, w = 96, h = 96, held_item = nil }
end

local function make_scene()
    return { active_rocket = nil, game_state = { money = 99 } }
end

-- ── 1: construction ───────────────────────────────────────────────────────────

local r = Rocket.new(100, 200)
assert(r._type     == "rocket", "_type should be 'rocket'")
assert(r.carriable == true,     "should be carriable")
assert(r.w         == 200,      "width should be 200")
assert(r.h         == 400,      "height should be 400")
assert(r._launched == false,    "_launched starts false")
assert(r._done     == false,    "_done starts false")
print("PASS: construction")

-- ── 2: update before launch returns nothing ───────────────────────────────────

local result = r:update(1.0)
assert(result == nil, "update before interact should return nil")
assert(r.y == 200,    "y should not change before launch")
print("PASS: update before launch is a no-op")

-- ── 3: interact() sets launched state and signals scene ───────────────────────

local player = make_player()
local scene  = make_scene()
player.held_item = r
r.held = true

r:interact(player, scene, nil)

assert(r._launched          == true,  "_launched should be true after interact")
assert(r.held               == false, "held should be false after interact")
assert(player.held_item     == nil,   "player.held_item should be nil after interact")
assert(scene.active_rocket  == r,     "scene.active_rocket should be set to rocket")
print("PASS: interact() triggers launch and signals scene")

-- ── 4: rocket moves upward during flight ─────────────────────────────────────

local y_before = r.y
r:update(1/60)
assert(r.y < y_before, "rocket y should decrease (move upward) during flight")
print("PASS: rocket moves upward during flight")

-- ── 5: returns 'launch_complete' at t=4.5 ────────────────────────────────────

-- Fast-forward to just past 4.5 seconds total flight time.
-- _flight_timer accumulated 1/60 above; drive it to >= 4.5.
local complete_result = nil
for _ = 1, 300 do  -- 300 * (1/60) = 5 seconds
    complete_result = r:update(1/60)
    if complete_result == "launch_complete" then break end
end

assert(complete_result == "launch_complete",
    "update() should return 'launch_complete' when flight_timer >= 4.5")
assert(r._done == true, "_done should be set after launch_complete")
print("PASS: returns 'launch_complete' at t=4.5 s")

-- ── 6: _done guard prevents double-trigger ────────────────────────────────────

local second_result = r:update(1/60)
assert(second_result == nil,
    "update() after _done should not return 'launch_complete' again")
print("PASS: _done guard prevents double-trigger")

print("ALL TESTS PASSED")

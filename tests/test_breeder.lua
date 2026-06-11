local Breeder     = require("game/entities/breeder")
local AnimalStats = require("game/data/animal_stats")

-- Helper: fake animal table (matches what Breeder:try_add expects)
local function make_animal(stats)
    return { _type = "animal", stats = stats or AnimalStats.random(), held = false, x=0, y=0, w=32, h=40 }
end

-- Test 1: starts empty
local b = Breeder.new(100, 100)
assert(b:is_empty(), "new breeder should be empty")
assert(not b:is_full(), "new breeder should not be full")
print("PASS: starts empty")

-- Test 2: add first animal
local a1 = make_animal()
local ok = b:try_add(a1)
assert(ok, "first animal should be accepted")
assert(not b:is_empty(), "breeder not empty after adding one")
assert(not b:is_full(), "breeder not full with one animal")
assert(a1.held == true, "animal should be marked held after adding")
print("PASS: add first animal")

-- Test 3: add second animal starts breeding
local a2 = make_animal()
local ok2 = b:try_add(a2)
assert(ok2, "second animal should be accepted")
assert(b:is_full(), "breeder should be full with two animals")
assert(b._breeding == true, "breeding flag should be set")
print("PASS: add second animal starts breeding")

-- Test 4: adding a third animal is rejected
local a3 = make_animal()
local ok3 = b:try_add(a3)
assert(not ok3, "third animal should be rejected when full")
print("PASS: rejects third animal")

-- Test 5: after BREED_TIME seconds, update() returns offspring stats
-- Fast-forward by passing large dt values (1 second per tick)
local offspring = nil
for i = 1, 10 do
    offspring = b:update(1.0)
    if offspring then break end
end
assert(offspring ~= nil, "should produce offspring after breed time")
assert(type(offspring.speed) == "number", "offspring should have speed")
assert(type(offspring.height) == "number", "offspring should have height")
assert(type(offspring.personality) == "string", "offspring should have personality")
print("PASS: produces offspring after breed time")

-- Test 6: after breeding, parents remain and breeding continues
assert(b:is_full(), "parents should remain in slots after breeding")
assert(b._breeding == true, "breeding flag should remain set for continuous breeding")
print("PASS: parents remain after breeding")

print("ALL TESTS PASSED")

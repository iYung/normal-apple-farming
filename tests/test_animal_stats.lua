-- test_animal_stats.lua
local AnimalStats = require("game/data/animal_stats")

-- Test 1: default constructor
local s = AnimalStats.new()
assert(s.speed == 100, "default speed should be 100")
assert(s.height == 1, "default height should be 1")
assert(s.personality == "calm", "default personality should be calm")
assert(s.color.r == 0.5 and s.color.g == 0.5 and s.color.b == 0.1, "default color mismatch")
print("PASS: default constructor")

-- Test 2: custom constructor
local s2 = AnimalStats.new(50, {r=0.1, g=0.2, b=0.3}, 3, "silly")
assert(s2.speed == 50)
assert(s2.height == 3)
assert(s2.personality == "silly")
print("PASS: custom constructor")

-- Test 3: random() returns valid ranges
for i = 1, 20 do
    local r = AnimalStats.random()
    assert(r.speed >= 20 and r.speed <= 180, "random speed out of range: " .. r.speed)
    assert(r.height >= 1 and r.height <= 5, "random height out of range: " .. r.height)
    assert(r.color.r >= 0 and r.color.r <= 1, "random color.r out of range")
    assert(r.color.g >= 0 and r.color.g <= 1, "random color.g out of range")
    assert(r.color.b >= 0 and r.color.b <= 1, "random color.b out of range")
    local valid_p = false
    for _, p in ipairs(AnimalStats.PERSONALITIES) do
        if r.personality == p then valid_p = true end
    end
    assert(valid_p, "random personality not in PERSONALITIES list")
end
print("PASS: random() ranges")

-- Test 4: breed() clamping
for i = 1, 30 do
    local a = AnimalStats.new(0,  {r=0, g=0, b=0}, 1, "calm")
    local b = AnimalStats.new(200,{r=1, g=1, b=1}, 5, "silly")
    local offspring = AnimalStats.breed(a, b)
    assert(offspring.speed >= 0 and offspring.speed <= 200,
        "bred speed out of range: " .. offspring.speed)
    assert(offspring.height >= 1, "bred height below 1: " .. offspring.height)
    assert(offspring.color.r >= 0 and offspring.color.r <= 1, "bred color.r out of range")
    assert(offspring.color.g >= 0 and offspring.color.g <= 1, "bred color.g out of range")
    assert(offspring.color.b >= 0 and offspring.color.b <= 1, "bred color.b out of range")
    local valid_p = false
    for _, p in ipairs(AnimalStats.PERSONALITIES) do
        if offspring.personality == p then valid_p = true end
    end
    assert(valid_p, "bred personality invalid: " .. tostring(offspring.personality))
end
print("PASS: breed() clamping")

-- Test 5: personality_to_face maps all personalities
for _, p in ipairs(AnimalStats.PERSONALITIES) do
    local face = AnimalStats.personality_to_face(p)
    assert(type(face) == "string" and #face > 0,
        "personality_to_face returned nil for: " .. p)
end
print("PASS: personality_to_face")

print("ALL TESTS PASSED")

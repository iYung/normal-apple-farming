-- test_breed_benchmark.lua
-- Benchmarks AnimalStats.breed over 999,999 generations.
-- Uses a deterministic math.random stub so every breed call
-- increases height by exactly 1, making the final height predictable.

local AnimalStats = require("game/data/animal_stats")

local GENERATIONS = 999999

-- Seed two parents each at height=1
local parent_a = AnimalStats.new(100, {r=0.5, g=0.5, b=0.1}, 1, "calm")
local parent_b = AnimalStats.new(100, {r=0.5, g=0.5, b=0.1}, 1, "calm")

-- Install a deterministic math.random stub.
--   math.random()      → 0.0  (no-arg float: triggers mutation & personality inheritance)
--   math.random(0, 1)  → 1    (height mutation direction: always +deviance → height grows)
--   anything else      → real math.random (single-arg selects, other two-arg ranges)
local real_random = math.random
math.random = function(a, b)
    if a == nil then
        return 0.0          -- no-arg: < mutation_chance (0.5) and < inherit_chance (0.8)
    elseif a == 0 and b == 1 then
        return 1            -- height direction: 1 → +deviance → height += 1
    elseif b == nil then
        return real_random(a)   -- single-arg (e.g. math.random(2), math.random(#p))
    else
        return real_random(a, b)
    end
end

local t0 = os.clock()

local a, b = parent_a, parent_b
for i = 1, GENERATIONS do
    local offspring = AnimalStats.breed(a, b)
    a = offspring
    b = offspring
end

local elapsed = os.clock() - t0

-- Restore real math.random immediately after the loop
math.random = real_random

local final_height = a.height

print(string.format(
    "breed_benchmark: %d generations to height=%d in %.3fs",
    GENERATIONS, final_height, elapsed
))
print("PASS: breed benchmark completed")

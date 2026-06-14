-- test_breed_benchmark.lua
-- Benchmarks AnimalStats.breed over 999,999 generations.

local AnimalStats = require("game/data/animal_stats")

local GENERATIONS = 999999

-- Seed two parents each at height=1
local parent_a = AnimalStats.new(100, {r=0.5, g=0.5, b=0.1}, 1, "calm")
local parent_b = AnimalStats.new(100, {r=0.5, g=0.5, b=0.1}, 1, "calm")

local t0 = os.clock()

local a, b = parent_a, parent_b
for i = 1, GENERATIONS do
    local offspring = AnimalStats.breed(a, b)
    a = offspring
    b = offspring
end

local elapsed = os.clock() - t0

local final_height = a.height

print(string.format(
    "breed_benchmark: %d generations to height=%d in %.3fs",
    GENERATIONS, final_height, elapsed
))
print("PASS: breed benchmark completed")

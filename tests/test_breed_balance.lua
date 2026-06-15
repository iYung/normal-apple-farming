-- test_breed_balance.lua
-- Headless breeding simulation that outputs trait-distribution data at each
-- jobs_done milestone. Used to calibrate game/systems/job_generator.lua CONFIG.
-- Run with: love . --headless tests/test_breed_balance.lua

local AnimalStats = require("game/data/animal_stats")

-- ── Constants ────────────────────────────────────────────────────────────────

local STARTING_ANIMALS = 6
local BREED_INTERVAL   = 5    -- seconds per breeding cycle
local JOB_INTERVAL     = 8    -- seconds per job completion
local CYCLES_PER_JOB   = JOB_INTERVAL / BREED_INTERVAL  -- 1.6
local MAX_JOBS         = 50
local MILESTONES       = {5, 10, 15, 20, 25, 30, 40, 50}

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function make_default_stats()
    return AnimalStats.new(100, {r=0.5, g=0.5, b=0.1}, 1, "calm")
end

local function init_population(n)
    local pop = {}
    for i = 1, n do
        pop[i] = make_default_stats()
    end
    return pop
end

-- percentile: sorted_arr must be sorted ascending; p is 0-100
local function percentile(sorted_arr, p)
    local idx = math.max(1, math.floor(#sorted_arr * p / 100 + 0.5))
    return sorted_arr[idx]
end

local function is_milestone(jobs_done)
    for _, m in ipairs(MILESTONES) do
        if jobs_done == m then return true end
    end
    return false
end

-- ── Simulation A — Height ────────────────────────────────────────────────────

local height_rows = {}

do
    local population = init_population(STARTING_ANIMALS)
    local cycles_owed = 0.0

    for jobs_done = 0, MAX_JOBS do
        cycles_owed = cycles_owed + CYCLES_PER_JOB

        while cycles_owed >= 1 do
            -- Parents: 2 tallest
            table.sort(population, function(a, b) return a.height > b.height end)
            local parent_a = population[1]
            local parent_b = population[2]

            local offspring = AnimalStats.breed(parent_a, parent_b)
            table.insert(population, offspring)

            -- Sell: shortest
            table.sort(population, function(a, b) return a.height < b.height end)
            table.remove(population, 1)

            cycles_owed = cycles_owed - 1
        end

        if is_milestone(jobs_done) then
            local heights = {}
            for _, animal in ipairs(population) do
                table.insert(heights, animal.height)
            end
            table.sort(heights)
            table.insert(height_rows, {
                jobs = jobs_done,
                p50  = percentile(heights, 50),
                p75  = percentile(heights, 75),
                p90  = percentile(heights, 90),
                max  = heights[#heights],
            })
        end
    end
end

-- ── Simulation B — Speed High ─────────────────────────────────────────────────

local speed_high_rows = {}

do
    local population = init_population(STARTING_ANIMALS)
    local cycles_owed = 0.0

    for jobs_done = 0, MAX_JOBS do
        cycles_owed = cycles_owed + CYCLES_PER_JOB

        while cycles_owed >= 1 do
            -- Parents: 2 fastest
            table.sort(population, function(a, b) return a.speed > b.speed end)
            local parent_a = population[1]
            local parent_b = population[2]

            local offspring = AnimalStats.breed(parent_a, parent_b)
            table.insert(population, offspring)

            -- Sell: slowest
            table.sort(population, function(a, b) return a.speed < b.speed end)
            table.remove(population, 1)

            cycles_owed = cycles_owed - 1
        end

        if is_milestone(jobs_done) then
            local speeds = {}
            for _, animal in ipairs(population) do
                table.insert(speeds, animal.speed)
            end
            table.sort(speeds)
            table.insert(speed_high_rows, {
                jobs = jobs_done,
                p50  = percentile(speeds, 50),
                p75  = percentile(speeds, 75),
                p90  = percentile(speeds, 90),
                max  = speeds[#speeds],
            })
        end
    end
end

-- ── Simulation B — Speed Low ──────────────────────────────────────────────────

local speed_low_rows = {}

do
    local population = init_population(STARTING_ANIMALS)
    local cycles_owed = 0.0

    for jobs_done = 0, MAX_JOBS do
        cycles_owed = cycles_owed + CYCLES_PER_JOB

        while cycles_owed >= 1 do
            -- Parents: 2 slowest
            table.sort(population, function(a, b) return a.speed < b.speed end)
            local parent_a = population[1]
            local parent_b = population[2]

            local offspring = AnimalStats.breed(parent_a, parent_b)
            table.insert(population, offspring)

            -- Sell: fastest
            table.sort(population, function(a, b) return a.speed > b.speed end)
            table.remove(population, 1)

            cycles_owed = cycles_owed - 1
        end

        if is_milestone(jobs_done) then
            local speeds = {}
            for _, animal in ipairs(population) do
                table.insert(speeds, animal.speed)
            end
            table.sort(speeds)
            table.insert(speed_low_rows, {
                jobs = jobs_done,
                min  = speeds[1],
                p10  = percentile(speeds, 10),
                p25  = percentile(speeds, 25),
                p50  = percentile(speeds, 50),
            })
        end
    end
end

-- ── Simulation C — Color ─────────────────────────────────────────────────────

local color_rows = {}

do
    local target = {r=0.8, g=0.2, b=0.9}

    local function dist_sq(c)
        local dr = c.r - target.r
        local dg = c.g - target.g
        local db = c.b - target.b
        return dr*dr + dg*dg + db*db
    end

    local population = init_population(STARTING_ANIMALS)
    local cycles_owed = 0.0

    for jobs_done = 0, MAX_JOBS do
        cycles_owed = cycles_owed + CYCLES_PER_JOB

        while cycles_owed >= 1 do
            -- Parents: 2 closest to target (lowest dist_sq)
            table.sort(population, function(a, b)
                return dist_sq(a.color) < dist_sq(b.color)
            end)
            local parent_a = population[1]
            local parent_b = population[2]

            local offspring = AnimalStats.breed(parent_a, parent_b)
            table.insert(population, offspring)

            -- Sell: farthest from target (highest dist_sq)
            table.sort(population, function(a, b)
                return dist_sq(a.color) > dist_sq(b.color)
            end)
            table.remove(population, 1)

            cycles_owed = cycles_owed - 1
        end

        if is_milestone(jobs_done) then
            local dists = {}
            for _, animal in ipairs(population) do
                table.insert(dists, dist_sq(animal.color))
            end
            table.sort(dists)
            table.insert(color_rows, {
                jobs = jobs_done,
                best = dists[1],
                p25  = percentile(dists, 25),
                p50  = percentile(dists, 50),
            })
        end
    end
end

-- ── Output ───────────────────────────────────────────────────────────────────

print("=== BREED BALANCE SIMULATION ===")
print("")

print("HEIGHT (always-best pair selection, 1 breeder, 6 starting animals)")
print(string.format("%-6s  %-6s  %-6s  %-6s  %-6s", "jobs", "p50", "p75", "p90", "max"))
for _, row in ipairs(height_rows) do
    print(string.format("%-6d  %-6d  %-6d  %-6d  %-6d",
        row.jobs, row.p50, row.p75, row.p90, row.max))
end
print("")

print("SPEED HIGH")
print(string.format("%-6s  %-6s  %-6s  %-6s  %-6s", "jobs", "p50", "p75", "p90", "max"))
for _, row in ipairs(speed_high_rows) do
    print(string.format("%-6d  %-6d  %-6d  %-6d  %-6d",
        row.jobs, row.p50, row.p75, row.p90, row.max))
end
print("")

print("SPEED LOW")
print(string.format("%-6s  %-6s  %-6s  %-6s  %-6s", "jobs", "min", "p10", "p25", "p50"))
for _, row in ipairs(speed_low_rows) do
    print(string.format("%-6d  %-6d  %-6d  %-6d  %-6d",
        row.jobs, row.min, row.p10, row.p25, row.p50))
end
print("")

print("COLOR (target far from base, lowest dist_sq selection)")
print(string.format("%-6s  %-12s  %-12s  %-12s", "jobs", "best_dist_sq", "p25_dist_sq", "p50_dist_sq"))
for _, row in ipairs(color_rows) do
    print(string.format("%-6d  %-12.4f  %-12.4f  %-12.4f",
        row.jobs, row.best, row.p25, row.p50))
end
print("")

-- Current CONFIG reference values
local height_scale   = 0.3
local speed_base     = 100
local dist_scale     = 0.001
local dist_min       = 0.01
local dist_max       = 1.3

local goal_h15 = math.floor(1 + height_scale * 15)
local goal_h30 = math.floor(1 + height_scale * 30)
local goal_c30 = math.max(dist_min, math.min(dist_scale * 30, dist_max))
local goal_c50 = math.max(dist_min, math.min(dist_scale * 50, dist_max))

print("=== CURRENT CONFIG (for reference) ===")
print(string.format("height.scale     = %.3f    (goal height at jobs=15: %d, jobs=30: %d)",
    height_scale, goal_h15, goal_h30))
print(string.format("speed.base       = %d", speed_base))
print(string.format("color.dist_scale = %.3f  (threshold at jobs=30: %.4f, jobs=50: %.4f)",
    dist_scale, goal_c30, goal_c50))
print(string.format("color.dist_min   = %.3f", dist_min))
print(string.format("color.dist_max   = %.1f", dist_max))

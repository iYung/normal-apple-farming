-- test_animal_leg_offset.lua
-- Verifies that leg sprites are positioned 1px above the body to close the body–leg seam.

local runner = require("lua/headless/runner")
local Animal = require("game/entities/animal")
local AnimalColorShader = require("game/shaders/animal_color")

runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)

-- Shader send() is unavailable in headless; stub apply/clear so draw() can run.
local orig_apply = AnimalColorShader.apply
local orig_clear = AnimalColorShader.clear
AnimalColorShader.apply = function() end
AnimalColorShader.clear = function() end

local animal = Animal.new(100, 200)
animal:draw()

AnimalColorShader.apply = orig_apply
AnimalColorShader.clear = orig_clear

assert(animal._legs_still.y == animal.y - 1,
    ("legs_still.y should be animal.y - 1 (%d), got %d"):format(animal.y - 1, animal._legs_still.y))
print("PASS: legs_still offset 1px above body")

assert(animal._legs_walk.y == animal.y - 1,
    ("legs_walk.y should be animal.y - 1 (%d), got %d"):format(animal.y - 1, animal._legs_walk.y))
print("PASS: legs_walk offset 1px above body")

assert(animal._legs_still.x == animal.x,
    "legs_still.x should match animal.x")
assert(animal._legs_walk.x == animal.x,
    "legs_walk.x should match animal.x")
print("PASS: leg X positions match animal.x")

print("ALL TESTS PASSED")

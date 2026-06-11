-- test_highlight_while_holding.lua
-- Verifies that nearby entities are highlighted even when the player holds an item.

local runner = require("lua/headless/runner")
local Animal = require("game/entities/animal")

local ctx = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)

local scene  = ctx.sm.current
local player = scene.player

-- Place a fresh animal directly beside the player (within Detector.nearest radius of 64px)
local nearby = Animal.new(player.x + 20, player.y)
table.insert(scene.animals, nearby)

-- Give the player a dummy held_item to simulate carrying something
player.held_item = { _type = "item", x = 0, y = 0, w = 32, h = 32, held = true }

-- Tick once so Player:update() runs the highlight logic
runner.tick(ctx.input, ctx.sm, 1)

assert(nearby.highlighted == true,
    "nearby animal should be highlighted even when player is holding an item")
print("PASS: nearby entity highlighted while player holds an item")

-- Sanity check: clear held_item; entity should still highlight
player.held_item = nil
runner.tick(ctx.input, ctx.sm, 1)

assert(nearby.highlighted == true,
    "nearby animal should still be highlighted when player holds nothing")
print("PASS: nearby entity highlighted when player holds nothing")

print("ALL TESTS PASSED")

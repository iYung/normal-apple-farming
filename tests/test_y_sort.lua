-- test_y_sort.lua
-- Verifies that world entities are drawn in ascending center-Y order.

local runner = require("lua/headless/runner")

local ctx = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)

local scene  = ctx.sm.current
local player = scene.player

-- Clear all entities so we control exactly what is in the scene.
scene.animals = {}
scene.items   = {}
scene.wires   = {}
player.held_item = nil

local draw_log = {}

local function make_entity(name, y, h)
    return {
        x = 0, y = y, w = 32, h = h,
        held = false,
        draw = function() table.insert(draw_log, name) end,
    }
end

-- Player draw is already real; wrap it to log the call.
local _player_draw = player.draw
player.draw = function(self)
    table.insert(draw_log, "player")
    _player_draw(self)
end

-- Player center Y = player.y + player.h/2.
-- player.y = WORLD_H/2 = 720, player.h = 96 → center Y = 768.

-- item_above: center Y = 100 + 24 = 124  < 768 → should draw BEFORE player
-- item_below: center Y = 900 + 24 = 924  > 768 → should draw AFTER  player
-- wire_above: center Y = 200 + 16 = 216  < 768 → should draw BEFORE player
-- wire_below: center Y = 850 + 16 = 866  > 768 → should draw AFTER  player

local item_above = make_entity("item_above", 100, 48)
local item_below = make_entity("item_below", 900, 48)
local wire_above = make_entity("wire_above", 200, 32)
local wire_below = make_entity("wire_below", 850, 32)

table.insert(scene.items, item_above)
table.insert(scene.items, item_below)
table.insert(scene.wires, wire_above)
table.insert(scene.wires, wire_below)

scene:draw()

local function index_of(name)
    for i, v in ipairs(draw_log) do
        if v == name then return i end
    end
    return nil
end

local idx_item_above = index_of("item_above")
local idx_item_below = index_of("item_below")
local idx_wire_above = index_of("wire_above")
local idx_wire_below = index_of("wire_below")
local idx_player     = index_of("player")

assert(idx_item_above, "item_above should be drawn")
assert(idx_item_below, "item_below should be drawn")
assert(idx_wire_above, "wire_above should be drawn")
assert(idx_wire_below, "wire_below should be drawn")
assert(idx_player,     "player should be drawn")

assert(idx_item_above < idx_player,
    "item above player (lower center Y) should draw before player")
assert(idx_wire_above < idx_player,
    "wire above player (lower center Y) should draw before player")
assert(idx_item_below > idx_player,
    "item below player (higher center Y) should draw after player")
assert(idx_wire_below > idx_player,
    "wire below player (higher center Y) should draw after player")

-- Ordering between non-player entities should also respect center Y.
-- wire_above (216) < item_above... wait, item_above is 124 which is less.
-- So expected draw order: item_above(124), wire_above(216), player(768), wire_below(866), item_below(924)
assert(idx_item_above < idx_wire_above,
    "item_above (center Y 124) should draw before wire_above (center Y 216)")
assert(idx_wire_below < idx_item_below,
    "wire_below (center Y 866) should draw before item_below (center Y 924)")

print("PASS: Y-sort draws entities in ascending center-Y order")
print("ALL TESTS PASSED")

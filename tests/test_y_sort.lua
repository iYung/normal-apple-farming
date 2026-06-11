-- test_y_sort.lua
-- Verifies that world entities are drawn in ascending bottom-edge Y order.

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

-- Player bottom Y = player.y + player.h.
-- player.y = WORLD_H/2 = 720, player.h = 96 → bottom Y = 816.

-- item_above: bottom Y = 100 + 48 = 148  < 816 → should draw BEFORE player
-- item_below: bottom Y = 900 + 48 = 948  > 816 → should draw AFTER  player
-- wire_above: bottom Y = 200 + 32 = 232  < 816 → should draw BEFORE player
-- wire_below: bottom Y = 850 + 32 = 882  > 816 → should draw AFTER  player

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
    "item above player (lower bottom Y) should draw before player")
assert(idx_wire_above < idx_player,
    "wire above player (lower bottom Y) should draw before player")
assert(idx_item_below > idx_player,
    "item below player (higher bottom Y) should draw after player")
assert(idx_wire_below > idx_player,
    "wire below player (higher bottom Y) should draw after player")

-- Ordering between non-player entities should also respect bottom Y.
-- Expected draw order: item_above(148), wire_above(232), player(816), wire_below(882), item_below(948)
assert(idx_item_above < idx_wire_above,
    "item_above (bottom Y 148) should draw before wire_above (bottom Y 232)")
assert(idx_wire_below < idx_item_below,
    "wire_below (bottom Y 882) should draw before item_below (bottom Y 948)")

print("PASS: Y-sort draws entities in ascending bottom-edge Y order")
print("ALL TESTS PASSED")

-- test_held_item_draw_priority.lua
-- Verifies that a held item is skipped in the items draw pass and drawn after the player.

local runner = require("lua/headless/runner")

local ctx = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)

local scene  = ctx.sm.current
local player = scene.player

-- Isolate draw order tracking
scene.animals = {}
scene.items   = {}
scene.wires   = {}

local draw_log = {}

local mock_item = {
    _type = "item", x = 0, y = 0, w = 48, h = 48,
    held  = true,
    draw  = function() table.insert(draw_log, "item") end,
}

local _player_draw = player.draw
player.draw = function(self)
    table.insert(draw_log, "player")
    _player_draw(self)
end

table.insert(scene.items, mock_item)
player.held_item = mock_item

scene:draw()

local item_count = 0
local player_index, item_index
for i, name in ipairs(draw_log) do
    if name == "item"   then item_count = item_count + 1; item_index = i end
    if name == "player" then player_index = i end
end

assert(item_count == 1,
    "held item draw() should be called exactly once, got " .. item_count)
assert(player_index ~= nil, "player should be drawn")
assert(item_index   ~= nil, "held item should be drawn")
assert(player_index < item_index,
    "held item should draw after player (player=" .. tostring(player_index) .. " item=" .. tostring(item_index) .. ")")
print("PASS: held item skipped in items pass and drawn after player")

-- Non-held item should draw before the player
draw_log      = {}
mock_item.held = false
player.held_item = nil

scene:draw()

local item_index2, player_index2
for i, name in ipairs(draw_log) do
    if name == "item"   then item_index2   = i end
    if name == "player" then player_index2 = i end
end

assert(item_index2   ~= nil, "non-held item should be drawn")
assert(player_index2 ~= nil, "player should be drawn")
assert(item_index2 < player_index2,
    "non-held item should draw before player (item=" .. tostring(item_index2) .. " player=" .. tostring(player_index2) .. ")")
print("PASS: non-held item drawn before player")

print("ALL TESTS PASSED")

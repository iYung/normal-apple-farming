-- test_wire_placement_hover.lua
-- Verifies the wire placement preview is drawn (or not) correctly based on held item and tile state.

local runner = require("lua/headless/runner")
local Roll   = require("game/items/roll")
local Wire   = require("game/entities/wire")
local Mapper = require("game/systems/mapper")

local ctx   = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)

local scene  = ctx.sm.current
local player = scene.player

-- Inject a fake wire preview image (love.filesystem.getInfo returns nil in headless)
local fake_img = { getWidth = function() return 48 end, getHeight = function() return 48 end }
scene._wire_preview_img = fake_img

-- Captures the color set just before the preview image is drawn, and whether it was drawn at all.
local function capture_preview()
    local last_color = {1, 1, 1, 1}
    local drew_preview = false
    local color_at_draw = nil

    local orig_setColor = love.graphics.setColor
    local orig_draw     = love.graphics.draw

    love.graphics.setColor = function(r, g, b, a)
        last_color = {r, g, b, a}
    end
    love.graphics.draw = function(img, ...)
        if img == fake_img then
            drew_preview = true
            color_at_draw = {last_color[1], last_color[2], last_color[3], last_color[4]}
        end
    end

    scene:draw()

    love.graphics.setColor = orig_setColor
    love.graphics.draw     = orig_draw

    return drew_preview, color_at_draw
end

-- Test 1: no held item → no preview
player.held_item = nil
local drew, _ = capture_preview()
assert(not drew, "no preview should be drawn when player holds nothing")
print("PASS: no preview when holding nothing")

-- Test 2: holding wire roll, free tile → white/0.5 preview
player.held_item = Roll.new(0, 0)
local drew2, color2 = capture_preview()
assert(drew2, "preview should be drawn when holding wire roll on free tile")
assert(color2[1] == 1 and color2[2] == 1 and color2[3] == 1 and color2[4] == 0.5,
    "free tile preview should use color (1,1,1,0.5), got: " .. table.concat(color2, ","))
print("PASS: white/0.5 preview for free tile")

-- Test 3: holding wire roll, occupied tile → red/0.5 preview
local tx, ty = Mapper.world_to_tile(player.x + player.w / 2, player.y + player.h / 2)
Mapper.set(scene.wire_grid, tx, ty, Wire.new(tx, ty))

local drew3, color3 = capture_preview()
assert(drew3, "preview should be drawn when holding wire roll on occupied tile")
assert(color3[1] == 1 and math.abs(color3[2] - 0.3) < 0.01 and math.abs(color3[3] - 0.3) < 0.01 and color3[4] == 0.5,
    "occupied tile preview should use color (1,0.3,0.3,0.5), got: " .. table.concat(color3, ","))
print("PASS: red/0.5 preview for occupied tile")

Mapper.remove(scene.wire_grid, tx, ty)
player.held_item = nil

print("ALL TESTS PASSED")

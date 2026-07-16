-- test_game_scene_background.lua
-- Verifies the tiled-background changes to GameScene:
--   * WORLD_W is 2592 (not the old 2560)
--   * the tile grid is built correctly (54 cols x 30 rows of 48x48 tiles)
--   * the old self._bg_quad field is gone
--   * the old flat green background rectangle fill is gone

local runner = require("lua/headless/runner")

-- Test 1: WORLD_W is 2592, not 2560 -----------------------------------------
-- WORLD_W is a file-local constant, not exported on the module table, so we
-- confirm it two ways: (a) directly inspect the source text, and (b) check an
-- observable side effect that depends on it (the Breeder fixture's x position,
-- computed as WORLD_W / 2 - 300 in GameScene:on_enter).

local src_path = "game/scenes/game_scene.lua"
local f = io.open(src_path, "r")
assert(f, "could not open " .. src_path .. " for reading")
local src = f:read("*a")
f:close()

assert(src:find("WORLD_W%s*=%s*2592", 1), "source should declare WORLD_W = 2592")
assert(not src:find("WORLD_W%s*=%s*2560", 1), "source should no longer declare WORLD_W = 2560")
print("PASS: source declares WORLD_W = 2592, not 2560")

local ctx1  = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)
local scene1 = ctx1.sm.current

local expected_bx = 2592 / 2 - 300
assert(scene1.items[1]._type == "breeder", "items[1] should be the Breeder fixture")
assert(scene1.items[1].x == expected_bx,
    "Breeder x should be WORLD_W/2 - 300 = " .. expected_bx .. ", got " .. tostring(scene1.items[1].x))
print("PASS: Breeder fixture position confirms WORLD_W == 2592")

-- Test 2: self._bg_quad no longer exists -------------------------------------
assert(scene1._bg_quad == nil, "self._bg_quad should no longer be set")
print("PASS: _bg_quad field is gone")

-- Test 3: grid-building logic (54 cols x 30 rows of 48x48 tiles) ------------
-- love.filesystem.getInfo always returns nil under the headless stub, so the
-- tileset block in on_enter never runs during a normal headless construction.
-- Temporarily monkey-patch it to return truthy so a second scene actually
-- builds self._bg_tiles, then restore it.

local orig_getInfo = love.filesystem.getInfo
love.filesystem.getInfo = function(path) return true end

local ctx2   = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new()
end)
local scene2 = ctx2.sm.current

love.filesystem.getInfo = orig_getInfo

assert(scene2._bg_img ~= nil, "scene2._bg_img should be set once getInfo is truthy")
assert(scene2._border_img ~= nil, "scene2._border_img should be set once getInfo is truthy")
assert(type(scene2._bg_tiles) == "table", "scene2._bg_tiles should be a table")
assert(#scene2._bg_tiles == 54 * 30,
    "expected 1620 tiles, got " .. #scene2._bg_tiles)
print("PASS: grid has exactly 54 * 30 = 1620 tiles")

local first = scene2._bg_tiles[1]
assert(first.x == 0 and first.y == 0,
    "first tile should be {x=0, y=0}, got {x=" .. tostring(first.x) .. ", y=" .. tostring(first.y) .. "}")

local last = scene2._bg_tiles[#scene2._bg_tiles]
assert(last.x == 53 * 48 and last.y == 29 * 48,
    "last tile should be {x=2544, y=1392}, got {x=" .. tostring(last.x) .. ", y=" .. tostring(last.y) .. "}")
print("PASS: first tile is {x=0,y=0}, last tile is {x=2544,y=1392}")

for i, t in ipairs(scene2._bg_tiles) do
    assert(t.x % 48 == 0 and t.y % 48 == 0,
        "tile " .. i .. " coords should be multiples of 48, got {x=" .. t.x .. ", y=" .. t.y .. "}")
    assert(t.x >= 0 and t.x < 2592, "tile " .. i .. " x out of world bounds: " .. t.x)
    assert(t.y >= 0 and t.y < 1440, "tile " .. i .. " y out of world bounds: " .. t.y)
end
print("PASS: all tile coordinates are multiples of 48 within world bounds")

-- Test 3b: outer ring of tiles is flagged is_border, interior tiles are not --
-- Only the player/animals can reach the interior (Mapper.clamp keeps them
-- inset from the world edge), so the outermost ring of tiles (col 0, last
-- col, row 0, last row) should be flagged as border tiles.

local cols, rows = 54, 30
local border_count, interior_count = 0, 0
for _, t in ipairs(scene2._bg_tiles) do
    local col = t.x / 48
    local row = t.y / 48
    local expected_border = row == 0 or row == rows - 1 or col == 0 or col == cols - 1
    assert(t.is_border == expected_border,
        "tile at col=" .. col .. " row=" .. row .. " expected is_border=" ..
        tostring(expected_border) .. ", got " .. tostring(t.is_border))
    if t.is_border then
        border_count = border_count + 1
    else
        interior_count = interior_count + 1
    end
end
assert(border_count == 2 * cols + 2 * (rows - 2),
    "expected " .. (2 * cols + 2 * (rows - 2)) .. " border tiles, got " .. border_count)
assert(interior_count == 1620 - border_count,
    "border + interior should account for all 1620 tiles")
print("PASS: outer ring of tiles is flagged is_border, interior tiles are not")

-- Test 4: old flat green background rectangle fill is gone -------------------
-- Monkey-patch love.graphics.setColor/rectangle to record every rectangle
-- call together with the color that was active when it was issued, then
-- assert none of them match the old green fill (0.25, 0.55, 0.2) covering
-- the whole world.

-- Clear animals before drawing: Animal:draw() unconditionally calls
-- AnimalColorShader.apply(), which calls shader:send() — a method the
-- headless love.graphics stub's generic image stub does not provide. This is
-- unrelated to what this test checks (background tiles / rectangle fill), so
-- side-step it the same way tests/test_y_sort.lua does.
scene1.animals = {}

local function capture_rectangles(scene)
    local last_color = {1, 1, 1, 1}
    local calls = {}

    local orig_setColor  = love.graphics.setColor
    local orig_rectangle = love.graphics.rectangle

    love.graphics.setColor = function(r, g, b, a)
        last_color = {r, g, b, a}
    end
    love.graphics.rectangle = function(mode, x, y, w, h)
        table.insert(calls, {
            mode  = mode, x = x, y = y, w = w, h = h,
            color = {last_color[1], last_color[2], last_color[3], last_color[4]},
        })
    end

    scene:draw()

    love.graphics.setColor  = orig_setColor
    love.graphics.rectangle = orig_rectangle

    return calls
end

local calls = capture_rectangles(scene1)

for i, c in ipairs(calls) do
    local is_green = math.abs(c.color[1] - 0.25) < 0.01
        and math.abs(c.color[2] - 0.55) < 0.01
        and math.abs(c.color[3] - 0.2)  < 0.01
    local is_fill = c.mode == "fill"
    assert(not (is_green and is_fill),
        "rectangle call " .. i .. " should not be the old green ('fill', color 0.25/0.55/0.2) background fill")
end
print("PASS: no green background rectangle fill is drawn")

print("ALL TESTS PASSED")

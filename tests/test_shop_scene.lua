-- test_shop_scene.lua
-- Verifies ShopScene: catalogue navigation, buy (success and failure), cancel.

local ShopScene = require("game/scenes/shop_scene")

-- ── helpers ───────────────────────────────────────────────────────────────────

local function make_sm()
    local sm = { switched_to = nil }
    sm.switch = function(self, s) self.switched_to = s end
    return sm
end

local function make_gs(money)
    return { money = money }
end

local function make_player(x, y)
    return { x = x or 0, y = y or 0, w = 96, h = 96, held_item = nil }
end

local function make_game_scene(player)
    return { player = player, items = {} }
end

-- Press a key for exactly one frame by temporarily making love.keyboard.isDown
-- return true for that key, ticking the scene, then releasing.
local function press(scene, key)
    local orig = love.keyboard.isDown
    love.keyboard.isDown = function(k) return k == key end
    scene:update(1 / 60)
    love.keyboard.isDown = orig
    scene:update(1 / 60)  -- release frame so rising-edge state resets
end

-- ── navigation ────────────────────────────────────────────────────────────────

do
    local scene = ShopScene.new(make_gs(0), make_sm(), make_game_scene(make_player()))

    assert(scene.selected == 1, "initial selection should be 1")
    print("PASS: initial selection is 1")

    press(scene, "right")
    assert(scene.selected == 2, "right should advance to 2, got " .. scene.selected)
    print("PASS: right advances selection")

    press(scene, "right")
    assert(scene.selected == 3, "right should advance to 3, got " .. scene.selected)
    print("PASS: right advances to 3")

    press(scene, "right")
    assert(scene.selected == 1, "right should wrap to 1, got " .. scene.selected)
    print("PASS: right wraps around to 1")

    press(scene, "left")
    assert(scene.selected == 3, "left from 1 should wrap to 3, got " .. scene.selected)
    print("PASS: left wraps from 1 to 3")

    press(scene, "left")
    assert(scene.selected == 2, "left should go to 2, got " .. scene.selected)
    print("PASS: left goes back to 2")
end

-- ── buy: insufficient funds ───────────────────────────────────────────────────

do
    local gs       = make_gs(5)   -- less than cheapest item ($20)
    local player   = make_player()
    local sm       = make_sm()
    local gs_scene = make_game_scene(player)
    local scene    = ShopScene.new(gs, sm, gs_scene)

    press(scene, "e")
    assert(gs.money      == 5,   "money should not change when cannot afford")
    assert(player.held_item == nil, "held_item should stay nil when cannot afford")
    assert(sm.switched_to  == nil,  "scene should not switch when cannot afford")
    print("PASS: buy fails gracefully when money is insufficient")
end

-- ── buy: success (item 1 = Wire Roll, $20) ───────────────────────────────────

do
    local gs       = make_gs(200)
    local player   = make_player(64, 128)
    local sm       = make_sm()
    local gs_scene = make_game_scene(player)
    local scene    = ShopScene.new(gs, sm, gs_scene)

    press(scene, "e")
    assert(gs.money == 180,
        "money should decrease by cost (20), got " .. gs.money)
    assert(player.held_item ~= nil,
        "player should now hold the bought item")
    assert(player.held_item.held == true,
        "bought item should be marked held=true")
    assert(#gs_scene.items == 1,
        "bought item should be added to game_scene.items")
    assert(sm.switched_to == gs_scene,
        "should switch back to game_scene after buy")
    print("PASS: buy deducts cost, gives item to player, adds to scene, switches scene")
end

-- ── cancel ────────────────────────────────────────────────────────────────────

do
    local gs       = make_gs(200)
    local player   = make_player()
    local sm       = make_sm()
    local gs_scene = make_game_scene(player)
    local scene    = ShopScene.new(gs, sm, gs_scene)

    press(scene, "s")
    assert(gs.money      == 200,     "cancel should not change money")
    assert(player.held_item == nil,  "cancel should not give an item")
    assert(sm.switched_to  == gs_scene, "cancel should switch back to game_scene")
    print("PASS: cancel returns to game_scene without buying")
end

print("ALL TESTS PASSED")

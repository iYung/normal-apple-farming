-- test_shop_item.lua
-- Verifies ShopItem: carriable flag, interact guard on held item,
-- scene switch when hands are empty, and nil-safe scene_manager path.

local ShopItem = require("game/items/shop_item")

local mock_shop_scene = {}

local function make_sm()
    local sm = { switched_to = nil }
    sm.switch = function(self, scene) self.switched_to = scene end
    return sm
end

-- ── construction ──────────────────────────────────────────────────────────────

local item = ShopItem.new(100, 200, mock_shop_scene)

assert(item.carriable == true, "ShopItem must be carriable")
assert(item.sellable  == false, "ShopItem must not be sellable")
assert(item.name      == "Shop", "ShopItem name should be 'Shop'")
assert(item.shop_scene == mock_shop_scene, "ShopItem should hold shop_scene ref")
print("PASS: ShopItem construction")

-- ── interact while holding ────────────────────────────────────────────────────

local sm            = make_sm()
local player_held   = { held_item = {}, x = 0, y = 0 }
item:interact(player_held, {}, sm)
assert(sm.switched_to == nil,
    "interact should not switch when player holds an item")
print("PASS: interact does nothing when player holds an item")

-- ── interact with empty hands ─────────────────────────────────────────────────

local sm2           = make_sm()
local player_empty  = { held_item = nil, x = 0, y = 0 }
item:interact(player_empty, {}, sm2)
assert(sm2.switched_to == mock_shop_scene,
    "interact should switch to shop_scene when hands are empty")
print("PASS: interact switches to shop_scene with empty hands")

-- ── nil scene_manager: no crash ───────────────────────────────────────────────

item:interact(player_empty, {}, nil)
print("PASS: interact with nil scene_manager does not error")

print("ALL TESTS PASSED")

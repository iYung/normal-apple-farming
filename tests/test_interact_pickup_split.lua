-- test_interact_pickup_split.lua
-- Verifies the interact/pickup split:
--   pickup (F) picks up and drops carriable items.
--   interact (E) opens the shop on press; uses held knife/spool while held down.

local runner        = require("lua/headless/runner")
local HeadlessInput = require("lua/headless/input")

local ctx   = runner.setup(function(input, sm)
    return require("game/scenes/game_scene").new(sm)
end)
local scene  = ctx.sm.current
local player = scene.player

-- Use a dedicated HeadlessInput for the player, separate from ctx.input.
-- runner.tick calls ctx.input:update() and player:update() calls player.input:update().
-- If they were the same object the _pressed state would be wiped before the
-- player's input checks run.
local input = HeadlessInput.new()
player.input = input

local function tick(n)
    runner.tick(ctx.input, ctx.sm, n)
end

local function find_item(type_name)
    for _, it in ipairs(scene.items) do
        if it._type == type_name then return it end
    end
end

local knife     = find_item("knife")
local shop_item = find_item("shop_item")

assert(knife     ~= nil, "knife must exist in scene items")
assert(shop_item ~= nil, "shop_item must exist in scene items")

-- ── 1: pickup picks up a carriable item ──────────────────────────────────────

player.x = knife.x - 10
player.y = knife.y
tick(1)   -- settle state

input:press("pickup")
tick(1)

assert(player.held_item == knife, "pickup should pick up the knife")
assert(knife.held == true,        "knife.held should be true after pickup")
print("PASS: pickup picks up a carriable item")

-- ── 2: pickup drops the held item ────────────────────────────────────────────

input:press("pickup")
tick(1)

assert(player.held_item == nil, "pickup again should drop the knife")
assert(knife.held == false,     "knife.held should be false after drop")
print("PASS: pickup drops held item")

-- ── 3: interact (press) opens the shop when hands are empty ──────────────────

player.x = shop_item.x
player.y = shop_item.y
tick(1)

local switched_to = nil
local orig_switch = scene.scene_manager.switch
scene.scene_manager.switch = function(sm, s) switched_to = s end

input:press("interact")
tick(1)

assert(switched_to ~= nil, "interact near shop with empty hands should switch scene")
print("PASS: interact opens shop when hands are empty")

scene.scene_manager.switch = orig_switch

-- ── 4: interact (held) calls use() on held knife instead of opening shop ─────

-- Pick knife back up via direct state (avoids needing pickup press here).
player.held_item = knife
knife.held = true

local use_called = false
local orig_use = knife.use
knife.use = function(self, p, s) use_called = true end

switched_to = nil
scene.scene_manager.switch = function(sm, s) switched_to = s end

input:hold("interact")
tick(1)
input:release("interact")

assert(use_called  == true, "holding interact while holding knife should call knife.use()")
assert(switched_to == nil,  "shop should NOT open when interact is used on held knife")
print("PASS: interact held uses knife, not shop, when knife is in hand")

scene.scene_manager.switch = orig_switch
knife.use = orig_use

-- ── 5: interact does NOT pick anything up ────────────────────────────────────

player.held_item = nil
knife.held = false
player.x = knife.x - 10
player.y = knife.y
tick(1)

input:press("interact")
tick(1)

assert(player.held_item == nil, "interact should never pick up items")
print("PASS: interact does not pick up items")

print("ALL TESTS PASSED")

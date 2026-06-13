-- test_book.lua
-- Verifies Book item: construction, carriable flag, interact switches to
-- book_scene, nil-safe scene_manager path.

local Book = require("game/items/book")

local mock_book_scene = {}

local function make_sm()
    local sm = { switched_to = nil }
    sm.switch = function(self, scene) self.switched_to = scene end
    return sm
end

-- ── construction ──────────────────────────────────────────────────────────────

local b = Book.new(100, 200, mock_book_scene)

assert(b._type        == "book",            "_type should be 'book'")
assert(b.carriable    == true,              "Book must be carriable")
assert(b.w            == 48,               "width should be 48")
assert(b.h            == 48,               "height should be 48")
assert(b._book_scene  == mock_book_scene,   "Book should hold book_scene ref")
assert(b.name         == "Book",            "name should be 'Book'")
print("PASS: construction")

-- ── interact switches to book_scene ──────────────────────────────────────────

local sm     = make_sm()
local player = { held_item = nil, x = 0, y = 0 }
b:interact(player, {}, sm)
assert(sm.switched_to == mock_book_scene,
    "interact should switch to book_scene")
print("PASS: interact switches to book_scene")

-- ── nil scene_manager: no crash ───────────────────────────────────────────────

b:interact(player, {}, nil)
print("PASS: interact with nil scene_manager does not error")

-- ── update syncs sprite position ──────────────────────────────────────────────

b.x = 50
b.y = 75
b:update(1/60)
assert(b.sprite.x == 50, "sprite.x should track item.x after update")
assert(b.sprite.y == 75, "sprite.y should track item.y after update")
print("PASS: update syncs sprite position")

print("ALL TESTS PASSED")

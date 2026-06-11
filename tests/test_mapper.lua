local Mapper = require("game/systems/mapper")

-- snap: floor-aligned to tile
local tx, ty = Mapper.snap(50, 70)
assert(tx == 32, "snap x should be 32 for input 50, got " .. tx)
assert(ty == 64, "snap y should be 64 for input 70, got " .. ty)

local tx2, ty2 = Mapper.snap(0, 0)
assert(tx2 == 0 and ty2 == 0, "snap 0,0 should stay 0,0")

local tx3, ty3 = Mapper.snap(32, 32)
assert(tx3 == 32 and ty3 == 32, "snap exact tile edge should stay")
print("PASS: snap")

-- key
assert(Mapper.key(32, 64) == "32,64", "key format mismatch")
assert(Mapper.key(0, 0)   == "0,0")
print("PASS: key")

-- set/get/remove round-trip
local grid = {}
Mapper.set(grid, 2, 3, "wire")
assert(Mapper.get(grid, 2, 3) == "wire", "should retrieve stored value")
assert(Mapper.get(grid, 0, 0) == nil,    "unset tile should be nil")
Mapper.remove(grid, 2, 3)
assert(Mapper.get(grid, 2, 3) == nil,    "removed tile should be nil")
print("PASS: set/get/remove")

-- clamp keeps rect inside world (32px margin each side)
-- World is 1280x720; entity is 32x32
local cx, cy = Mapper.clamp(0, 0, 32, 32)  -- too far top-left
assert(cx == 32, "clamp left edge: expected 32, got " .. cx)
assert(cy == 32, "clamp top edge: expected 32, got " .. cy)

local cx2, cy2 = Mapper.clamp(3000, 2000, 32, 32)  -- too far bottom-right
assert(cx2 == Mapper.WORLD_W - 32 - 32, "clamp right edge")
assert(cy2 == Mapper.WORLD_H - 32 - 32, "clamp bottom edge")

local cx3, cy3 = Mapper.clamp(400, 300, 32, 32)  -- inside, should not move
assert(cx3 == 400 and cy3 == 300, "inside-bounds should not be clamped")
print("PASS: clamp")

-- world_to_tile
local wtx, wty = Mapper.world_to_tile(64, 96)
assert(wtx == 2 and wty == 3, "world_to_tile 64,96 should be 2,3")
print("PASS: world_to_tile")

print("ALL TESTS PASSED")

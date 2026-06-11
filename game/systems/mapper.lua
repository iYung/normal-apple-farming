local Mapper = {}

Mapper.TILE = 32

function Mapper.snap(x, y)
    local tx = math.floor(x / Mapper.TILE) * Mapper.TILE
    local ty = math.floor(y / Mapper.TILE) * Mapper.TILE
    return tx, ty
end

function Mapper.key(tx, ty)
    return tx .. "," .. ty
end

function Mapper.set(grid, tx, ty, value)
    grid[Mapper.key(tx, ty)] = value
end

function Mapper.get(grid, tx, ty)
    return grid[Mapper.key(tx, ty)]
end

function Mapper.remove(grid, tx, ty)
    grid[Mapper.key(tx, ty)] = nil
end

function Mapper.clamp(x, y, w, h)
    local cx = math.max(32, math.min(x, 1280 - w - 32))
    local cy = math.max(32, math.min(y, 720 - h - 32))
    return cx, cy
end

function Mapper.world_to_tile(x, y)
    local tx = math.floor(x / Mapper.TILE)
    local ty = math.floor(y / Mapper.TILE)
    return tx, ty
end

return Mapper

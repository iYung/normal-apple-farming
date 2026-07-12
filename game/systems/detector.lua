local Detector = {}

-- Type checks

function Detector.is_animal(e)
    return e ~= nil and e._type == "animal"
end

function Detector.is_player(e)
    return e ~= nil and e._type == "player"
end

function Detector.is_breeder(e)
    return e ~= nil and e._type == "breeder"
end

function Detector.is_sell_bin(e)
    return e ~= nil and e._type == "sell_bin"
end

function Detector.is_wire(e)
    return e ~= nil and e._type == "wire"
end

function Detector.is_item(e)
    if e == nil then return false end
    return e._type == "item"
        or e._type == "roll"
        or e._type == "knife"
end

function Detector.is_roll(e)
    return e ~= nil and e._type == "roll"
end

function Detector.is_knife(e)
    return e ~= nil and e._type == "knife"
end

function Detector.is_rocket(e)
    return e ~= nil and e._type == "rocket"
end

function Detector.is_interactable(e)
    return e ~= nil and (e._type == "book" or e._type == "shop_item" or e._type == "rocket")
end

-- Geometry helpers

function Detector.aabb(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x
       and a.y < b.y + b.h and a.y + a.h > b.y
end

function Detector.nearest(entity, list, max_dist)
    local max_dist_sq = max_dist * max_dist
    local ecx = entity.x + entity.w / 2
    local ecy = entity.y + entity.h / 2

    local best = nil
    local best_dist_sq = max_dist_sq

    for _, candidate in ipairs(list) do
        if candidate ~= entity then
            local ccx = candidate.x + candidate.w / 2
            local ccy = candidate.y + candidate.h / 2
            local dx = ccx - ecx
            local dy = ccy - ecy
            local dist_sq = dx * dx + dy * dy
            if dist_sq <= best_dist_sq then
                best_dist_sq = dist_sq
                best = candidate
            end
        end
    end

    return best
end

return Detector

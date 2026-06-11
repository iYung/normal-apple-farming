local AnimalStats = {}
AnimalStats.__index = AnimalStats

AnimalStats.PERSONALITIES = {"aggressive", "calm", "cool", "dull", "silly"}

local FACE_MAP = {
    aggressive = "assets/images/animal/animal_face_aggressive.png",
    calm       = "assets/images/animal/animal_face_content.png",
    cool       = "assets/images/animal/animal_face_cool.png",
    dull       = "assets/images/animal/animal_face_dull.png",
    silly      = "assets/images/animal/animal_face_silly.png",
}

function AnimalStats.new(speed, color, height, personality)
    local self = setmetatable({}, AnimalStats)
    self.speed       = speed       or 100
    self.color       = color       or {r = 0.5, g = 0.5, b = 0.1}
    self.height      = height      or 1
    self.personality = personality or "calm"
    return self
end

function AnimalStats.random()
    local personalities = AnimalStats.PERSONALITIES
    return AnimalStats.new(
        math.random(20, 180),
        {r = math.random(), g = math.random(), b = math.random()},
        math.random(1, 5),
        personalities[math.random(#personalities)]
    )
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function AnimalStats.breed(a, b)
    -- speed: average ± random integer [-50, 50], clamped 0–200
    local speed = math.floor((a.speed + b.speed) / 2) + math.random(-50, 50)
    speed = clamp(speed, 0, 200)

    -- color: per-channel average ± random float [-0.2, 0.2], clamped 0–1
    local function blend_channel(ca, cb)
        local delta = math.random() * 0.4 - 0.2  -- uniform in [-0.2, 0.2]
        return clamp((ca + cb) / 2 + delta, 0, 1)
    end
    local color = {
        r = blend_channel(a.color.r, b.color.r),
        g = blend_channel(a.color.g, b.color.g),
        b = blend_channel(a.color.b, b.color.b),
    }

    -- height: round of average, then 50% chance ±1, min 1
    local height = math.floor((a.height + b.height) / 2 + 0.5)
    if math.random() < 0.5 then
        height = height + (math.random(0, 1) == 0 and -1 or 1)
    end
    height = math.max(1, height)

    -- personality: 80% pick one parent, 20% random
    local personality
    if math.random() < 0.8 then
        local parents = {a.personality, b.personality}
        personality = parents[math.random(2)]
    else
        local p = AnimalStats.PERSONALITIES
        personality = p[math.random(#p)]
    end

    return AnimalStats.new(speed, color, height, personality)
end

function AnimalStats.personality_to_face(personality)
    return FACE_MAP[personality]
end

return AnimalStats

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

local BREED = {
    speed = {
        deviance = 50,
        min      = 0,
        max      = 200,
    },
    color = {
        deviance = 0.2,
        min      = 0,
        max      = 1,
    },
    height = {
        deviance        = 1,
        mutation_chance = 0.5,
        min             = 1,
    },
    personality = {
        inherit_chance = 0.8,
    },
}

local MIN_LUMINANCE = 0.4

local function enforce_luminance(color)
    local L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
    if L >= MIN_LUMINANCE then return color end
    if L == 0 then
        color.r, color.g, color.b = MIN_LUMINANCE, MIN_LUMINANCE, MIN_LUMINANCE
        return color
    end
    -- Proportional scale; may clamp channels and undershoot.
    local scale = MIN_LUMINANCE / L
    color.r = math.min(1.0, color.r * scale)
    color.g = math.min(1.0, color.g * scale)
    color.b = math.min(1.0, color.b * scale)
    -- One analytical pass: boost green (highest luminance weight) to cover any residual.
    -- If green hits 1.0, new L >= 0.7152 > MIN_LUMINANCE, so no further pass is needed.
    L = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
    if L < MIN_LUMINANCE then
        color.g = math.min(1.0, color.g + (MIN_LUMINANCE - L) / 0.7152)
    end
    return color
end

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
    local color = enforce_luminance({r = math.random(), g = math.random(), b = math.random()})
    return AnimalStats.new(
        math.random(20, 180),
        color,
        1,
        personalities[math.random(#personalities)]
    )
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function AnimalStats.breed(a, b)
    -- speed: average ± deviance, clamped
    local speed = math.floor((a.speed + b.speed) / 2) + math.random(-BREED.speed.deviance, BREED.speed.deviance)
    speed = clamp(speed, BREED.speed.min, BREED.speed.max)

    -- color: per-channel average ± deviance, clamped
    local function blend_channel(ca, cb)
        local delta = math.random() * (2 * BREED.color.deviance) - BREED.color.deviance
        return clamp((ca + cb) / 2 + delta, BREED.color.min, BREED.color.max)
    end
    local color = enforce_luminance({
        r = blend_channel(a.color.r, b.color.r),
        g = blend_channel(a.color.g, b.color.g),
        b = blend_channel(a.color.b, b.color.b),
    })

    -- height: round of average, then mutation_chance to shift ±deviance, clamped to min
    local height = math.floor((a.height + b.height) / 2 + 0.5)
    if math.random() < BREED.height.mutation_chance then
        height = height + (math.random(0, 1) == 0 and -BREED.height.deviance or BREED.height.deviance)
    end
    height = math.max(BREED.height.min, height)

    -- personality: inherit_chance to pick one parent, otherwise random
    local personality
    if math.random() < BREED.personality.inherit_chance then
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

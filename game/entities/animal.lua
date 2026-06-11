local Sprite         = require("core/lua/sprite")
local SpriteSet      = require("core/lua/spriteset")
local Timer          = require("core/lua/timer")
local Mapper         = require("game/systems/mapper")
local AnimalStats    = require("game/data/animal_stats")
local AnimalColorShader = require("game/shaders/animal_color")
local OutlineShader  = require("game/shaders/outline")

local LOGICAL_W, LOGICAL_H = 1280, 720
local TILE = 32

local Animal = {}
Animal.__index = Animal

function Animal.new(x, y, stats)
    local self = setmetatable({}, Animal)
    self._type  = "animal"
    self.x      = x or 300
    self.y      = y or 300
    self.w      = 32
    self.h      = 40  -- body + legs combined height
    self.stats  = stats or AnimalStats.random()
    self.vx     = 0
    self.vy     = 0
    self.held   = false
    self.bounced = false
    self.highlighted = false

    -- Random initial wander interval 1–3 seconds
    self._wander_timer = Timer.new(1 + math.random() * 2)

    -- Shaders
    self._color_shader   = AnimalColorShader.new()
    self._outline_shader = OutlineShader.new()

    -- Body sprite (32×32)
    self._body_sprite = Sprite.new(0, 0, 32, 32)
    self._body_sprite.image = love.graphics.newImage("assets/images/animal/animal_body.png")

    -- Legs sprites (32×16 each); visibility toggled based on movement
    self._legs_still = Sprite.new(0, 0, 32, 16)
    self._legs_still.image = love.graphics.newImage("assets/images/animal/animal_legs_still.png")
    self._legs_walk  = Sprite.new(0, 0, 32, 16)
    self._legs_walk.image  = love.graphics.newImage("assets/images/animal/animal_legs_walk.png")

    -- Preload all face images keyed by personality to avoid per-frame disk reads
    self._face_images = {}
    for _, p in ipairs(AnimalStats.PERSONALITIES) do
        self._face_images[p] = love.graphics.newImage(AnimalStats.personality_to_face(p))
    end

    -- Face sprite (32×32); image swapped from the preloaded table
    self._face_sprite = Sprite.new(0, 0, 32, 32)
    self._face_sprite.image = self._face_images[self.stats.personality]

    return self
end

function Animal:update(dt, wire_grid)
    if self.held then return end

    -- Wander timer: periodically pick a new direction (or stop)
    if self._wander_timer:update(dt) then
        self._wander_timer:reset(1 + math.random() * 2)
        local start_moving = math.random() < 0.22
        if start_moving then
            local px_speed = 30 + self.stats.speed * 0.8
            local angle = math.random() * math.pi * 2
            self.vx = math.cos(angle) * px_speed
            self.vy = math.sin(angle) * px_speed
        else
            self.vx = 0
            self.vy = 0
        end
    end

    -- Move
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Clamp to world bounds; reverse velocity component when clamped
    local cx, cy = Mapper.clamp(self.x, self.y, self.w, self.h)
    if cx ~= self.x then self.vx = -self.vx end
    if cy ~= self.y then self.vy = -self.vy end
    self.x, self.y = cx, cy

    -- Wire bounce: AABB check against each wire in the grid
    if wire_grid then
        local bounced_this_frame = false
        for _, wire in pairs(wire_grid) do
            if type(wire) == "table" and wire.x then
                if self.x < wire.x + wire.w and self.x + self.w > wire.x
                and self.y < wire.y + wire.h and self.y + self.h > wire.y then
                    if not self.bounced then
                        self.vx = -self.vx
                        self.vy = -self.vy
                        self.bounced = true
                        bounced_this_frame = true
                    end
                end
            end
        end
        if not bounced_this_frame then
            self.bounced = false
        end
    end

    -- Swap face image from preloaded table (no disk I/O)
    self._face_sprite.image = self._face_images[self.stats.personality]

    -- Flip all sprites based on horizontal movement direction
    local moving = math.abs(self.vx) > 1 or math.abs(self.vy) > 1
    if self.vx > 0 then
        self._body_sprite.scale_x  = -1
        self._legs_still.scale_x   = -1
        self._legs_walk.scale_x    = -1
        self._face_sprite.scale_x  = -1
    elseif self.vx < 0 then
        self._body_sprite.scale_x  = 1
        self._legs_still.scale_x   = 1
        self._legs_walk.scale_x    = 1
        self._face_sprite.scale_x  = 1
    end

    -- Toggle which legs sprite is visible
    self._legs_still.visible = not moving
    self._legs_walk.visible  = moving
end

function Animal:draw()
    local bx = self.x
    local by = self.y

    -- Apply outline shader around the whole animal when highlighted
    if self.highlighted then
        OutlineShader.apply(self._outline_shader, 1, 0.9, 0)
    end

    -- Legs sit below the body (offset 26px down from body origin)
    self._legs_still.x = bx
    self._legs_still.y = by + 26
    self._legs_walk.x  = bx
    self._legs_walk.y  = by + 26

    if self._legs_still.visible then self._legs_still:draw() end
    if self._legs_walk.visible  then self._legs_walk:draw()  end

    -- Body with color shader applied
    AnimalColorShader.apply(self._color_shader,
        self.stats.color.r, self.stats.color.g, self.stats.color.b)
    self._body_sprite.x = bx
    self._body_sprite.y = by
    self._body_sprite:draw()
    AnimalColorShader.clear()

    -- Face drawn on top of body (2px upward nudge matches Godot original)
    self._face_sprite.x = bx
    self._face_sprite.y = by - 2
    self._face_sprite:draw()

    if self.highlighted then
        OutlineShader.clear()
    end
end

function Animal:highlight(on)
    self.highlighted = on
end

return Animal

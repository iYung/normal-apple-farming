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
    self.w      = 48
    self.h      = 48
    self.stats  = stats or AnimalStats.random()
    self.vx     = 0
    self.vy     = 0
    self.held        = false
    self.bounced     = false
    self.highlighted = false
    self._anim_timer = 0
    self._anim_frame = 0

    -- Random initial wander interval 1–3 seconds
    self._wander_timer = Timer.new(1 + math.random() * 2)

    -- Shaders
    self._color_shader   = AnimalColorShader.new()
    self._outline_shader = OutlineShader.new()

    -- Body sprites: one per height segment, stacked upward with -15px offsets
    local body_img = love.graphics.newImage("assets/images/animal/animal_body.png")
    self._body_sprites = {}
    for i = 1, self.stats.height do
        local bs = Sprite.new(0, 0, 48, 48)
        bs.image = body_img
        table.insert(self._body_sprites, bs)
    end

    -- Legs sprites (48×48 each); visibility toggled based on movement
    self._legs_still = Sprite.new(0, 0, 48, 48)
    self._legs_still.image = love.graphics.newImage("assets/images/animal/animal_legs_still.png")
    self._legs_walk  = Sprite.new(0, 0, 48, 48)
    self._legs_walk.image   = love.graphics.newImage("assets/images/animal/animal_legs_walk.png")
    self._legs_walk.visible = false

    -- Preload all face images keyed by personality to avoid per-frame disk reads
    self._face_images = {}
    for _, p in ipairs(AnimalStats.PERSONALITIES) do
        self._face_images[p] = love.graphics.newImage(AnimalStats.personality_to_face(p))
    end

    -- Face sprite (48×48); image swapped from the preloaded table
    self._face_sprite = Sprite.new(0, 0, 48, 48)
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
        local overlapping = false
        for _, wire in pairs(wire_grid) do
            if type(wire) == "table" and wire.x then
                if self.x < wire.x + wire.w and self.x + self.w > wire.x
                and self.y < wire.y + wire.h and self.y + self.h > wire.y then
                    overlapping = true
                    if not self.bounced then
                        self.vx = -self.vx
                        self.vy = -self.vy
                        self.bounced = true
                    end
                end
            end
        end
        -- Only clear bounced once the animal has fully exited all wires
        if not overlapping then
            self.bounced = false
        end
    end

    -- Swap face image from preloaded table (no disk I/O)
    self._face_sprite.image = self._face_images[self.stats.personality]

    -- Flip all sprites based on horizontal movement direction
    local moving = math.abs(self.vx) > 1 or math.abs(self.vy) > 1
    if self.vx > 0 then
        for _, bs in ipairs(self._body_sprites) do bs.scale_x = -1 end
        self._legs_still.scale_x  = -1
        self._legs_walk.scale_x   = -1
        self._face_sprite.scale_x = -1
    elseif self.vx < 0 then
        for _, bs in ipairs(self._body_sprites) do bs.scale_x = 1 end
        self._legs_still.scale_x  = 1
        self._legs_walk.scale_x   = 1
        self._face_sprite.scale_x = 1
    end

    -- Alternate legs sprites while moving
    if moving then
        self._anim_timer = self._anim_timer + dt
        if self._anim_timer >= 0.15 then
            self._anim_timer = self._anim_timer - 0.15
            self._anim_frame = 1 - self._anim_frame
        end
    else
        self._anim_timer = 0
        self._anim_frame = 0
    end
    self._legs_still.visible = self._anim_frame == 0
    self._legs_walk.visible  = self._anim_frame == 1
end

function Animal:draw()
    local bx = self.x
    local by = self.y
    local BODY_OFFSET = -15  -- each segment sits 15px above the one below (matches Godot)
    local top_y = by + (#self._body_sprites - 1) * BODY_OFFSET

    -- Sync leg and face positions
    self._legs_still.x = bx; self._legs_still.y = by - 1
    self._legs_walk.x  = bx; self._legs_walk.y  = by - 1
    self._face_sprite.x = bx; self._face_sprite.y = top_y

    -- Sync body segment positions
    for i, bs in ipairs(self._body_sprites) do
        bs.x = bx
        bs.y = by + (i - 1) * BODY_OFFSET
    end

    -- Outline pass: all parts with outline shader; border pixels survive the normal pass
    if self.highlighted then
        OutlineShader.apply(self._outline_shader, 1, 0.9, 0, 48, 48)
        if self._legs_still.visible then self._legs_still:draw() end
        if self._legs_walk.visible  then self._legs_walk:draw()  end
        for _, bs in ipairs(self._body_sprites) do bs:draw() end
        self._face_sprite:draw()
        OutlineShader.clear()
    end

    -- Normal pass: legs and body tinted, face on top
    AnimalColorShader.apply(self._color_shader,
        self.stats.color.r, self.stats.color.g, self.stats.color.b)
    if self._legs_still.visible then self._legs_still:draw() end
    if self._legs_walk.visible  then self._legs_walk:draw()  end
    for _, bs in ipairs(self._body_sprites) do bs:draw() end
    AnimalColorShader.clear()

    self._face_sprite:draw()
end

function Animal:highlight(on)
    self.highlighted = on
end

return Animal

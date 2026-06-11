local Sprite        = require("core/lua/sprite")
local Timer         = require("core/lua/timer")
local AnimalStats   = require("game/data/animal_stats")
local SwayShader    = require("game/shaders/sway")
local OutlineShader = require("game/shaders/outline")

local BREED_TIME = 5.0  -- seconds

local Breeder = {}
Breeder.__index = Breeder

function Breeder.new(x, y)
    local self = setmetatable({}, Breeder)
    self._type    = "breeder"
    self.x        = x
    self.y        = y
    self.w        = 96
    self.h        = 96
    self.held        = false
    self.carriable   = true
    self.highlighted = false
    self._slots      = {}   -- array of AnimalStats (up to 2)
    self._breeding = false
    self._timer   = Timer.new(BREED_TIME)
    self._sway_time = 0
    self._sway_shader    = SwayShader.new()
    self._outline_shader = OutlineShader.new()
    self._pending_offspring = nil  -- set to a newly spawned Animal after breeding

    -- Load sprites
    self._sprite_empty = Sprite.new(x, y, 96, 96)
    self._sprite_empty.image = love.graphics.newImage("assets/images/breeder/love_bin.png")
    self._sprite_one   = Sprite.new(x, y, 96, 96)
    self._sprite_one.image   = love.graphics.newImage("assets/images/breeder/love_bin_1.png")
    self._sprite_two   = Sprite.new(x, y, 96, 96)
    self._sprite_two.image   = love.graphics.newImage("assets/images/breeder/love_bin_2.png")
    self._bar_back     = Sprite.new(x + 12, y + 65, 70, 11)
    self._bar_back.image     = love.graphics.newImage("assets/images/breeder/love_bin_bar_back.png")
    self._bar_fill     = Sprite.new(x + 12, y + 65, 70, 11)
    self._bar_fill.image     = love.graphics.newImage("assets/images/breeder/love_bin_bar.png")

    return self
end

-- Returns true if the animal was accepted; false if full
function Breeder:try_add(animal)
    if #self._slots >= 2 then return false end
    table.insert(self._slots, animal.stats)
    animal.held = true  -- stop it from wandering
    if #self._slots == 2 then
        self._breeding = true
        self._timer:reset(BREED_TIME)
        self._sway_time = 0
    end
    return true
end

-- Removes and returns the last animal's stats; stops breeding if < 2 remain.
function Breeder:try_eject()
    if #self._slots == 0 then return nil end
    local stats = table.remove(self._slots)
    if #self._slots < 2 then
        self._breeding = false
    end
    return stats
end

-- Returns bred offspring AnimalStats (call this when you want to take the result)
function Breeder:take_offspring()
    if self._pending_offspring == nil then return nil end
    local o = self._pending_offspring
    self._pending_offspring = nil
    return o
end

function Breeder:is_empty()
    return #self._slots == 0
end

function Breeder:is_full()
    return #self._slots == 2
end

-- Returns the number of slots still occupied (for display)
function Breeder:slot_count()
    return #self._slots
end

-- Update: tick breeding timer; on expiry spawn offspring stats
-- Returns: a new AnimalStats if breeding just completed, nil otherwise
function Breeder:update(dt)
    if self._breeding then
        self._sway_time = self._sway_time + dt
        if self._timer:update(dt) then
            -- Breed: parents stay, timer resets, offspring is spawned
            local offspring_stats = AnimalStats.breed(self._slots[1], self._slots[2])
            self._timer:reset(BREED_TIME)
            self._sway_time = 0
            return offspring_stats
        end
    end
    return nil
end

function Breeder:draw()
    -- Sync sprite positions to current entity position
    self._sprite_empty.x = self.x;      self._sprite_empty.y = self.y
    self._sprite_one.x   = self.x;      self._sprite_one.y   = self.y
    self._sprite_two.x   = self.x;      self._sprite_two.y   = self.y
    self._bar_back.x     = self.x + 12; self._bar_back.y     = self.y + 65
    self._bar_fill.x     = self.x + 12; self._bar_fill.y     = self.y + 65

    local progress = 0
    if self._breeding then
        progress = self._timer._t / self._timer.interval
    end

    -- Choose body sprite
    local body
    if #self._slots == 0 then
        body = self._sprite_empty
    elseif #self._slots == 1 then
        body = self._sprite_one
    else
        body = self._sprite_two
    end

    -- Draw progress bar behind the body sprite (visible through the hole in the image)
    if self._breeding then
        self._bar_back:draw()
        self._bar_fill.scale_x = progress
        self._bar_fill:draw()
    end

    -- Outline pass when highlighted
    if self.highlighted then
        OutlineShader.apply(self._outline_shader, 1, 0.9, 0, 96, 96)
        body:draw()
        OutlineShader.clear()
    end

    -- Body sprite (with optional sway shader) drawn on top of bar
    if self._breeding then
        SwayShader.apply(self._sway_shader, self._sway_time)
    end
    body:draw()
    if self._breeding then
        SwayShader.clear()
    end
end

function Breeder:highlight(on)
    self.highlighted = on
end

return Breeder

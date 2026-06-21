local Sprite    = require("core/lua/sprite")
local SpriteSet = require("core/lua/spriteset")
local Input     = require("core/lua/input")
local Mapper    = require("game/systems/mapper")
local Detector  = require("game/systems/detector")
local Animal    = require("game/entities/animal")
local Sound     = require("core/lua/sound")

local SPEED      = 180
local ANIM_SPEED = 0.15  -- seconds per walk frame

local Player = {}
Player.__index = Player

function Player.new(x, y, input)
    local self = setmetatable({}, Player)
    self._type     = "player"
    self.x         = x or 600
    self.y         = y or 350
    self.w         = 96
    self.h         = 96
    self.held_item   = nil
    self._debounce   = false
    self._anim_timer = 0
    self._anim_frame = 0

    self.input = input or Input.new({
        move_up    = { "w", "up" },
        move_down  = { "s", "down" },
        move_left  = { "a", "left" },
        move_right = { "d", "right" },
        interact   = { "e" },
        pickup     = { "f" },
    })

    -- Load sprites into a SpriteSet
    self._sprites = SpriteSet.new()
    local function mk(path)
        local s = Sprite.new(0, 0, 96, 96)
        s.image = love.graphics.newImage(path)
        return s
    end
    self._sprites:add("idle",       mk("assets/images/player/farmer.png"))
    self._sprites:add("walk",       mk("assets/images/player/farmer_walk.png"))
    self._sprites:add("carry_idle", mk("assets/images/player/farmer_carry.png"))
    self._sprites:add("carry_walk", mk("assets/images/player/farmer_carry_walk.png"))
    self._sprites:set("idle")

    return self
end

-- Centre point (for camera tracking etc.)
function Player:centre()
    return { x = self.x + 48, y = self.y + 48 }
end

function Player:update(dt, scene)
    self.input:update()

    -- Movement
    local vx, vy = 0, 0
    if self.input:is_down("move_left")  then vx = vx - SPEED end
    if self.input:is_down("move_right") then vx = vx + SPEED end
    if self.input:is_down("move_up")    then vy = vy - SPEED end
    if self.input:is_down("move_down")  then vy = vy + SPEED end

    -- Normalize diagonal movement
    if vx ~= 0 and vy ~= 0 then
        vx = vx * 0.7071
        vy = vy * 0.7071
    end

    self.x = self.x + vx * dt
    self.y = self.y + vy * dt
    self.x, self.y = Mapper.clamp(self.x, self.y, self.w, self.h)

    -- Flip sprite based on horizontal movement
    if vx > 0 then
        self._sprites.scale_x = -1
    elseif vx < 0 then
        self._sprites.scale_x = 1
    end

    -- Alternate walk frames while moving
    local moving = vx ~= 0 or vy ~= 0
    if moving then
        self._anim_timer = self._anim_timer + dt
        if self._anim_timer >= ANIM_SPEED then
            self._anim_timer = self._anim_timer - ANIM_SPEED
            self._anim_frame = 1 - self._anim_frame
        end
    else
        self._anim_timer = 0
        self._anim_frame = 0
    end

    local carrying = self.held_item ~= nil
    if carrying then
        self._sprites:set(self._anim_frame == 1 and "carry_walk" or "carry_idle")
    else
        self._sprites:set(self._anim_frame == 1 and "walk" or "idle")
    end

    -- Carry: center held item above player
    if self.held_item then
        self.held_item.x = self.x + (self.w - self.held_item.w) / 2
        self.held_item.y = self.y - self.held_item.h
    end

    -- Interact: held for knife/spool, single press for shop
    if self.held_item and self.held_item.use and self.input:is_down("interact") then
        self.held_item:use(self, scene)
    elseif self.input:pressed("interact") then
        self:_handle_interact(scene)
    end

    -- Pickup: press once to carry or drop
    if self.input:pressed("pickup") then
        self:_handle_pickup(scene)
    end

    -- Highlight nearest pickupable entity
    for _, a in ipairs(scene.animals) do a:highlight(false) end
    for _, it in ipairs(scene.items)  do it:highlight(false) end
    local all = {}
    for _, a in ipairs(scene.animals) do table.insert(all, a) end
    for _, it in ipairs(scene.items)  do table.insert(all, it) end
    local near = Detector.nearest(self, all, 64)
    if near then near:highlight(true) end
end

function Player:_handle_pickup(scene)
    local held = self.held_item

    -- Build list of all pickup-able entities near the player
    local all_entities = {}
    for _, a in ipairs(scene.animals) do table.insert(all_entities, a) end
    for _, it in ipairs(scene.items)   do table.insert(all_entities, it) end

    local hovered = Detector.nearest(self, all_entities, 64)

    if held then
        if Detector.is_animal(held) then
            -- Try to drop into any nearby breeder
            for _, it in ipairs(scene.items) do
                if it._type == "breeder" and not it.held and Detector.aabb(self, it) then
                    if it:try_add(held) then
                        for i = #scene.animals, 1, -1 do
                            if scene.animals[i] == held then
                                table.remove(scene.animals, i)
                                break
                            end
                        end
                        Sound.play("put_down")
                        self.held_item = nil
                        return
                    end
                end
            end

            -- Try to sell at any nearby sell bin
            for _, it in ipairs(scene.items) do
                if it._type == "sell_bin" and not it.held and Detector.aabb(self, it) then
                    local reward = it:try_sell(held, scene.game_state)
                    if reward > 0 then
                        for i = #scene.animals, 1, -1 do
                            if scene.animals[i] == held then
                                table.remove(scene.animals, i)
                                break
                            end
                        end
                        Sound.play("put_down")
                        self.held_item = nil
                        return
                    end
                end
            end
        end

        -- Drop held item/animal at player position
        held.x = self.x
        held.y = self.y
        held.held = false
        if Detector.is_animal(held) then
            held.held = false
        end
        self.held_item = nil
        Sound.play("put_down")
    else
        if hovered then
            if hovered._type == "breeder" and not hovered:is_empty() then
                -- Eject last animal from breeder into player's hands
                local stats = hovered:try_eject()
                if stats then
                    local new_animal = Animal.new(hovered.x, hovered.y, stats)
                    table.insert(scene.animals, new_animal)
                    self:_pick_up(new_animal)
                end
            else
                self:_pick_up(hovered)
            end
        end
    end
end

function Player:_handle_interact(scene)
    local all_entities = {}
    for _, it in ipairs(scene.items) do table.insert(all_entities, it) end
    local hovered = Detector.nearest(self, all_entities, 64)
    if hovered and hovered.interact then
        hovered:interact(self, scene, scene.scene_manager)
    end
end

function Player:_pick_up(entity)
    entity.held = true
    self.held_item = entity
    if Detector.is_animal(entity) then
        entity:highlight(false)
    end
    Sound.play("pick_up")
end

function Player:draw()
    -- Draw held item above player (it has its own draw, called by scene)
    self._sprites.x = self.x
    self._sprites.y = self.y
    self._sprites:draw()
end

return Player

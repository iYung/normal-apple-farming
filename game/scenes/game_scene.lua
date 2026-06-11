local Drawer       = require("core/lua/drawer")
local Camera       = require("core/lua/camera")
local Sprite       = require("core/lua/sprite")

local GameState    = require("game/game_state")
local Animal       = require("game/entities/animal")
local Player       = require("game/entities/player")
local Breeder      = require("game/entities/breeder")
local SellBin      = require("game/entities/sell_bin")
local Wire         = require("game/entities/wire")
local Roll         = require("game/items/roll")
local Knife        = require("game/items/knife")
local Pruner       = require("game/items/pruner")
local JobGenerator = require("game/systems/job_generator")
local Detector     = require("game/systems/detector")
local ShopUI       = require("game/scenes/shop_ui")
local AnimalInfo   = require("game/ui/animal_info")
local JobInfo      = require("game/ui/job_info")
local MoneyInfo    = require("game/ui/money_info")
local ActionsInfo  = require("game/ui/actions_info")

local VIEW_W  = 1280
local VIEW_H  = 720
local WORLD_W = 2560
local WORLD_H = 1440

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new()
    local self = setmetatable({}, GameScene)
    self.drawer = Drawer.new()
    self.camera = Camera.new()
    return self
end

function GameScene:on_enter()
    self.game_state = GameState.new()

    -- Entity lists
    self.animals   = {}
    self.items     = {}
    self.wires     = {}
    self.wire_grid = {}  -- Mapper-key → Wire table

    -- Fixtures (pickupable, live in items list)
    local bx, by = WORLD_W / 2 - 300, WORLD_H / 2
    local sx, sy = WORLD_W / 2 + 200, WORLD_H / 2
    table.insert(self.items, Breeder.new(bx, by))
    table.insert(self.items, SellBin.new(sx, sy))

    -- Spawn 6 animals at random positions across the world
    self.game_state.animal_population = 6
    for i = 1, 6 do
        local x = 200 + math.random(0, WORLD_W - 400)
        local y = 150 + math.random(0, WORLD_H - 300)
        table.insert(self.animals, Animal.new(x, y))
    end

    -- Starting items placed near world centre
    local cx, cy = WORLD_W / 2, WORLD_H / 2
    table.insert(self.items, Roll.new(cx - 60, cy + 120))
    table.insert(self.items, Knife.new(cx,      cy + 120))
    table.insert(self.items, Pruner.new(cx + 60, cy + 120))

    -- Player starts at world centre
    local px, py = WORLD_W / 2, WORLD_H / 2
    self.player = Player.new(px, py)
    self.camera.x = px + 48  -- snap camera to player on load, no pan-in
    self.camera.y = py + 48

    -- Systems
    self.job_generator = JobGenerator.new(self.game_state)

    -- UI
    self.shop_open  = false
    self.shop_ui    = ShopUI.new(self.game_state)
    self.animal_info = AnimalInfo.new()
    self.job_info    = JobInfo.new(self.game_state)
    self.money_info  = MoneyInfo.new(self.game_state)
    self.actions_info = ActionsInfo.new()

    -- Background tileset sprite (tiled across full world)
    if love.filesystem.getInfo("assets/images/tileset.png") then
        local img = love.graphics.newImage("assets/images/tileset.png")
        img:setWrap("repeat", "repeat")
        local tile = img:getWidth()
        local quad = love.graphics.newQuad(0, 0, WORLD_W, WORLD_H, tile, tile)
        self._bg_img  = img
        self._bg_quad = quad
    end
end

function GameScene:on_exit()
    self.drawer:clear()
end

function GameScene:update(dt)
    -- Game systems
    self.job_generator:update(dt)

    -- Player update (passes self as scene)
    self.player:update(dt, self)

    -- Camera: follow player, clamp so viewport never shows outside world
    self.camera:follow(self.player:centre(), 0.08)
    local half_vw = VIEW_W / 2
    local half_vh = VIEW_H / 2
    self.camera.x = math.max(half_vw, math.min(self.camera.x, WORLD_W - half_vw))
    self.camera.y = math.max(half_vh, math.min(self.camera.y, WORLD_H - half_vh))

    -- Animals
    for _, a in ipairs(self.animals) do
        a:update(dt, self.wire_grid)
    end

    -- Items (breeders return offspring_stats when breeding completes)
    for _, it in ipairs(self.items) do
        local result = it:update(dt)
        if result and it._type == "breeder" then
            local ox = it.x + math.random(-32, 64)
            local oy = it.y + it.h + 8
            local new_animal = Animal.new(ox, oy, result)
            table.insert(self.animals, new_animal)
            self.game_state.animal_population = self.game_state.animal_population + 1
        end
    end

    -- Shop overlay
    if self.shop_open then
        self.shop_ui:update(self.player.input, self.player, self)
    end

    -- Remove completed jobs
    for i = #self.game_state.active_jobs, 1, -1 do
        if self.game_state.active_jobs[i].completed then
            table.remove(self.game_state.active_jobs, i)
        end
    end

    -- Update HUD: animal being held or nearest highlighted
    local held = self.player.held_item
    if held and Detector.is_animal(held) then
        self.animal_info:set(held)
    else
        self.animal_info:set(nil)
    end

    -- Actions info: compute nearby pickupable entities
    local nearby = {}
    for _, a in ipairs(self.animals) do
        if not a.held then
            local dx = (a.x + a.w/2) - (self.player.x + self.player.w/2)
            local dy = (a.y + a.h/2) - (self.player.y + self.player.h/2)
            if dx*dx + dy*dy <= 64*64 then
                table.insert(nearby, a)
            end
        end
    end
    for _, it in ipairs(self.items) do
        if not it.held then
            local dx = (it.x + it.w/2) - (self.player.x + self.player.w/2)
            local dy = (it.y + it.h/2) - (self.player.y + self.player.h/2)
            if dx*dx + dy*dy <= 64*64 then
                table.insert(nearby, it)
            end
        end
    end
    self.actions_info:set_nearby(nearby)
    self.actions_info:set_held(self.player.held_item)
end

function GameScene:draw()
    self.camera:attach()

    -- Background
    love.graphics.setColor(0.25, 0.55, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, WORLD_W, WORLD_H)
    if self._bg_img then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.draw(self._bg_img, self._bg_quad, 0, 0)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- Wires
    for _, w in ipairs(self.wires) do
        w:draw()
    end

    -- Items
    for _, it in ipairs(self.items) do
        it:draw()
    end

    -- Animals
    for _, a in ipairs(self.animals) do
        a:draw()
    end

    -- Player
    self.player:draw()

    self.camera:detach()

    -- HUD: screen space, unaffected by camera
    self.animal_info:draw()
    self.money_info:draw()
    self.job_info:draw()
    self.actions_info:draw()

    -- Shop overlay
    if self.shop_open then
        self.shop_ui:draw()
    end
end

return GameScene

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

    -- Static fixtures
    self.breeder  = Breeder.new(200, 280)
    self.sell_bin = SellBin.new(900, 480)

    -- Spawn 6 animals at random positions
    self.game_state.animal_population = 6
    for i = 1, 6 do
        local x = 200 + math.random(0, 860)
        local y = 150 + math.random(0, 400)
        table.insert(self.animals, Animal.new(x, y))
    end

    -- Starting items placed near centre
    table.insert(self.items, Roll.new(580, 380))
    table.insert(self.items, Knife.new(660, 380))
    table.insert(self.items, Pruner.new(740, 380))

    -- Player
    self.player = Player.new(620, 330)

    -- Systems
    self.job_generator = JobGenerator.new(self.game_state)

    -- UI
    self.shop_open  = false
    self.shop_ui    = ShopUI.new(self.game_state)
    self.animal_info = AnimalInfo.new()
    self.job_info    = JobInfo.new(self.game_state)
    self.money_info  = MoneyInfo.new(self.game_state)
    self.actions_info = ActionsInfo.new()

    -- Background tileset sprite (tiled across screen)
    self._bg = Sprite.new(0, 0, 1280, 720)
    if love.filesystem.getInfo("assets/images/tileset.png") then
        local img = love.graphics.newImage("assets/images/tileset.png")
        img:setWrap("repeat", "repeat")
        local tile = img:getWidth()
        local quad = love.graphics.newQuad(0, 0, 1280, 720, tile, tile)
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

    -- Animals
    for _, a in ipairs(self.animals) do
        a:update(dt, self.wire_grid)
    end

    -- Breeder: check for completed offspring
    local offspring_stats = self.breeder:update(dt)
    if offspring_stats then
        local ox = self.breeder.x + math.random(-32, 64)
        local oy = self.breeder.y + self.breeder.h + 8
        local new_animal = Animal.new(ox, oy, offspring_stats)
        table.insert(self.animals, new_animal)
        self.game_state.animal_population = self.game_state.animal_population + 1
    end

    -- Items
    for _, it in ipairs(self.items) do
        it:update(dt)
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
    -- Background
    love.graphics.setColor(0.25, 0.55, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)
    if self._bg_img then
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.draw(self._bg_img, self._bg_quad, 0, 0)
    end
    love.graphics.setColor(1, 1, 1, 1)

    -- Static fixtures
    self.breeder:draw()
    self.sell_bin:draw()

    -- Wires
    for _, w in ipairs(self.wires) do
        w:draw()
    end

    -- Items (not held ones — held item drawn with player)
    for _, it in ipairs(self.items) do
        if not it.held then
            it:draw()
        end
    end

    -- Animals
    for _, a in ipairs(self.animals) do
        if not a.held then
            a:draw()
        end
    end

    -- Player (draws held item above itself)
    if self.player.held_item and not Detector.is_animal(self.player.held_item) then
        self.player.held_item:draw()
    end
    if self.player.held_item and Detector.is_animal(self.player.held_item) then
        self.player.held_item:draw()
    end
    self.player:draw()

    -- HUD (drawn in screen space, no camera)
    self.animal_info:draw()
    self.money_info:draw()
    self.job_info:draw()
    self.actions_info:draw()

    -- Shop overlay (on top of everything)
    if self.shop_open then
        self.shop_ui:draw()
    end
end

return GameScene

local Drawer       = require("core/lua/drawer")
local Camera       = require("core/lua/camera")
local Input        = require("core/lua/input")
local Sound        = require("core/lua/sound")

local GameState    = require("game/game_state")
local Animal       = require("game/entities/animal")
local Player       = require("game/entities/player")
local Breeder      = require("game/entities/breeder")
local SellBin      = require("game/entities/sell_bin")
local Wire         = require("game/entities/wire")
local Roll         = require("game/items/roll")
local Knife        = require("game/items/knife")
local ShopItem     = require("game/items/shop_item")
local Book         = require("game/items/book")
local BookScene    = require("game/scenes/book_scene")
local ShopScene    = require("game/scenes/shop_scene")
local GameOverScene = require("game/scenes/game_over_scene")
local JobGenerator = require("game/systems/job_generator")
local Detector     = require("game/systems/detector")
local Mapper       = require("game/systems/mapper")
local AnimalInfo   = require("game/ui/animal_info")
local JobInfo      = require("game/ui/job_info")
local MoneyInfo    = require("game/ui/money_info")
local ActionsInfo  = require("game/ui/actions_info")

local VIEW_W  = 1280
local VIEW_H  = 720
local WORLD_W = 2592
local WORLD_H = 1440

local GameScene = {}
GameScene.__index = GameScene

function GameScene.new(scene_manager, settings_state, input)
    local self = setmetatable({}, GameScene)
    self.drawer          = Drawer.new()
    self.camera          = Camera.new()
    self.scene_manager   = scene_manager
    self._settings_state = settings_state
    self._ext_input      = input
    self._initialized    = false
    return self
end

function GameScene:on_enter()
    if self._initialized then return end
    self._initialized = true
    self._bg_list  = {"bg1", "bg2", "bg3", "bg4"}
    self._bg_index = math.random(#self._bg_list)
    Sound.fade_music("menu", 0, 2)
    Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
    self.active_rocket = nil

    self.game_state = GameState.new()

    -- Entity lists
    self.animals   = {}
    self.items     = {}
    self.wires     = {}
    self.wire_grid = {}

    -- Input (set up early so it can be passed to sub-scenes)
    if self._ext_input then
        self.input = self._ext_input
    else
        self.input = Input.new({
            move_up    = { "w", "up" },
            move_down  = { "s", "down" },
            move_left  = { "a", "left" },
            move_right = { "d", "right" },
            interact   = { "e" },
            pickup     = { "f" },
        })
        if self._settings_state then
            self.input._map = self._settings_state:key_map()
        end
    end

    -- Shop scene (created here so it can reference self)
    self._shop_scene = ShopScene.new(self.game_state, self.scene_manager, self, self.input)

    -- Fixtures
    local bx, by = WORLD_W / 2 - 300, WORLD_H / 2
    local sx, sy = WORLD_W / 2 + 200, WORLD_H / 2
    table.insert(self.items, Breeder.new(bx, by))
    table.insert(self.items, SellBin.new(sx, sy))

    -- ShopItem pre-placed near world centre (slightly left of centre)
    local cx, cy = WORLD_W / 2, WORLD_H / 2
    table.insert(self.items, ShopItem.new(cx - 160, cy + 120, self._shop_scene))

    -- Starting items
    table.insert(self.items, Roll.new(cx - 60, cy + 120))
    table.insert(self.items, Knife.new(cx,      cy + 120))

    -- Book: not in shop, spawns in world
    local book_scene = BookScene.new(self, self.scene_manager, self.input)
    table.insert(self.items, Book.new(cx + 60, cy + 120, book_scene))

    -- Spawn 6 animals
    self.game_state.animal_population = 6
    for i = 1, 6 do
        local x = 200 + math.random(0, WORLD_W - 400)
        local y = 150 + math.random(0, WORLD_H - 300)
        table.insert(self.animals, Animal.new(x, y))
    end

    -- Player
    local px, py = WORLD_W / 2, WORLD_H / 2
    self.player = Player.new(px, py, self.input)
    self.camera.x = px + 48
    self.camera.y = py + 48

    -- Systems
    self.job_generator = JobGenerator.new(self.game_state)

    -- UI
    self.animal_info  = AnimalInfo.new()
    self.job_info     = JobInfo.new(self.game_state)
    self.money_info   = MoneyInfo.new(self.game_state)
    self.actions_info = ActionsInfo.new(self.input)

    -- Background tileset: precompute a grid of 48x48 tile positions spanning
    -- the world (54 columns x 30 rows), drawn individually in draw().
    if love.filesystem.getInfo("assets/images/tileset.png") then
        self._bg_img = love.graphics.newImage("assets/images/tileset.png")
        self._bg_tiles = {}
        local cols = WORLD_W / 48
        local rows = WORLD_H / 48
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                table.insert(self._bg_tiles, { x = col * 48, y = row * 48 })
            end
        end
    end
    if love.filesystem.getInfo("assets/images/items/wire.png") then
        self._wire_preview_img = love.graphics.newImage("assets/images/items/wire.png")
    end
end

function GameScene:on_exit()
    self.drawer:clear()
end

function GameScene:update(dt)
    -- Game systems
    self.job_generator:update(dt)

    if not self.active_rocket then
        -- Normal gameplay: update player and follow with clamped camera
        self.player:update(dt, self)
        self.camera:follow(self.player:centre(), 0.08)
        local half_vw = VIEW_W / 2
        local half_vh = VIEW_H / 2
        self.camera.x = math.max(half_vw, math.min(self.camera.x, WORLD_W - half_vw))
        self.camera.y = math.max(half_vh, math.min(self.camera.y, WORLD_H - half_vh))
    else
        -- Rocket launched: skip player update, follow rocket off-screen
        local rc = { x = self.active_rocket.x + self.active_rocket.w / 2,
                     y = self.active_rocket.y + self.active_rocket.h / 2 }
        self.camera:follow(rc, 0.05)
    end

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
        if result == "launch_complete" then
            self.scene_manager:switch(GameOverScene.new(self.game_state, self.scene_manager))
        end
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
        if not it.held and it.carriable then
            local dx = (it.x + it.w/2) - (self.player.x + self.player.w/2)
            local dy = (it.y + it.h/2) - (self.player.y + self.player.h/2)
            if dx*dx + dy*dy <= 64*64 then
                table.insert(nearby, it)
            end
        end
    end

    local interactables = {}
    for _, it in ipairs(self.items) do
        if not it.held and Detector.is_interactable(it) then
            table.insert(interactables, it)
        end
    end
    local nearest_interactable = Detector.nearest(self.player, interactables, 64)

    self.actions_info:set_nearby(nearby)
    self.actions_info:set_held(self.player.held_item)
    self.actions_info:set_interact_target(nearest_interactable)

    if not Sound.is_music_playing(self._bg_list[self._bg_index]) then
        self._bg_index = (self._bg_index % #self._bg_list) + 1
        Sound.fade_music(self._bg_list[self._bg_index], 1, 2)
    end
end

function GameScene:draw()
    self.camera:attach()

    -- Background: draw each precomputed 48x48 tile individually, full opacity.
    if self._bg_img and self._bg_tiles then
        local scale_x = 48 / self._bg_img:getWidth()
        local scale_y = 48 / self._bg_img:getHeight()
        for _, t in ipairs(self._bg_tiles) do
            love.graphics.draw(self._bg_img, t.x, t.y, 0, scale_x, scale_y)
        end
    end

    -- Wire placement preview
    if Detector.is_roll(self.player.held_item) then
        local tx, ty = Mapper.world_to_tile(self.player.x + self.player.w / 2, self.player.y + self.player.h / 2)
        local occupied = Mapper.get(self.wire_grid, tx, ty) ~= nil
        if self._wire_preview_img then
            if occupied then
                love.graphics.setColor(1, 0.3, 0.3, 0.5)
            else
                love.graphics.setColor(1, 1, 1, 0.5)
            end
            love.graphics.draw(self._wire_preview_img, tx * Mapper.TILE, ty * Mapper.TILE, 0, 48 / self._wire_preview_img:getWidth(), 48 / self._wire_preview_img:getHeight())
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    -- Y-sort: collect wires, non-held items, animals, and player into one list
    -- sorted by bottom edge Y so entities lower on screen draw on top.
    local entities = {}
    for _, w in ipairs(self.wires) do
        table.insert(entities, w)
    end
    for _, it in ipairs(self.items) do
        if not it.held then
            table.insert(entities, it)
        end
    end
    for _, a in ipairs(self.animals) do
        table.insert(entities, a)
    end
    if not self.active_rocket then
        table.insert(entities, self.player)
    end

    table.sort(entities, function(a, b)
        return (a.y + a.h) < (b.y + b.h)
    end)

    for _, e in ipairs(entities) do
        e:draw()
        if e == self.player and self.player.held_item then
            self.player.held_item:draw()
        end
    end

    self.camera:detach()

    -- HUD: screen space, unaffected by camera
    self.animal_info:draw(self.camera, self.player)
    self.money_info:draw()
    self.job_info:draw()
    self.actions_info:draw()

end

return GameScene

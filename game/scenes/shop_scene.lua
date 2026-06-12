local Input   = require("core/lua/input")
local Roll    = require("game/items/roll")
local Knife   = require("game/items/knife")
local Breeder = require("game/entities/breeder")

local VIEW_W = 1280
local VIEW_H = 720

local CATALOGUE = {
    { name = "Wire Roll", cost = 20,  desc = "Place wire fencing to redirect animals.", constructor = Roll.new    },
    { name = "Knife",     cost = 40,  desc = "Remove wire fencing within reach.",       constructor = Knife.new   },
    { name = "Breeder",   cost = 100, desc = "Place two animals inside to breed.",      constructor = Breeder.new },
}

local PANEL_W = 500
local PANEL_H = 260
local PANEL_X = (VIEW_W - PANEL_W) / 2
local PANEL_Y = (VIEW_H - PANEL_H) / 2

local CARD_W      = 140
local CARD_H      = 160
local CARD_PAD    = 10
local CARDS_TOTAL = #CATALOGUE
local CARDS_ROW_W = CARDS_TOTAL * CARD_W + (CARDS_TOTAL - 1) * CARD_PAD
local CARD_ROW_X  = PANEL_X + (PANEL_W - CARDS_ROW_W) / 2
local CARD_ROW_Y  = PANEL_Y + 44

local ShopScene = {}
ShopScene.__index = ShopScene

function ShopScene.new(game_state, scene_manager, game_scene)
    local self = setmetatable({}, ShopScene)
    self.game_state    = game_state
    self.scene_manager = scene_manager
    self.game_scene    = game_scene
    self.selected      = 1
    self.input = Input.new({
        left     = { "a", "left"  },
        right    = { "d", "right" },
        interact = { "e" },
        cancel   = { "s", "down", "escape" },
    })
    return self
end

function ShopScene:on_enter() end
function ShopScene:on_exit()  end

function ShopScene:update(dt)
    self.input:update()

    if self.input:pressed("left") then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #CATALOGUE end
    end

    if self.input:pressed("right") then
        self.selected = self.selected + 1
        if self.selected > #CATALOGUE then self.selected = 1 end
    end

    if self.input:pressed("interact") then
        local entry = CATALOGUE[self.selected]
        if self.game_state.money >= entry.cost then
            self.game_state.money = self.game_state.money - entry.cost
            local player = self.game_scene.player
            local item   = entry.constructor(player.x, player.y)
            item.held               = true
            player.held_item        = item
            table.insert(self.game_scene.items, item)
            self.scene_manager:switch(self.game_scene)
        end
    end

    if self.input:pressed("cancel") then
        self.scene_manager:switch(self.game_scene)
    end
end

function ShopScene:draw()
    -- Semi-transparent dark overlay
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle("fill", 0, 0, VIEW_W, VIEW_H)

    -- Panel background
    love.graphics.setColor(0.12, 0.12, 0.16, 0.97)
    love.graphics.rectangle("fill", PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 8, 8)
    love.graphics.setColor(0.4, 0.4, 0.5, 1)
    love.graphics.rectangle("line", PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 8, 8)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("SHOP", PANEL_X, PANEL_Y + 12, PANEL_W, "center")

    -- Item cards
    for i, entry in ipairs(CATALOGUE) do
        local cx = CARD_ROW_X + (i - 1) * (CARD_W + CARD_PAD)
        local cy = CARD_ROW_Y
        local selected = (i == self.selected)

        -- Card background
        if selected then
            love.graphics.setColor(0.25, 0.25, 0.35, 1)
        else
            love.graphics.setColor(0.16, 0.16, 0.22, 1)
        end
        love.graphics.rectangle("fill", cx, cy, CARD_W, CARD_H, 5, 5)

        -- Card border (brighter when selected)
        if selected then
            love.graphics.setColor(0.7, 0.7, 0.9, 1)
        else
            love.graphics.setColor(0.3, 0.3, 0.4, 1)
        end
        love.graphics.rectangle("line", cx, cy, CARD_W, CARD_H, 5, 5)

        -- Item name (white, centred)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(entry.name, cx + 4, cy + 10, CARD_W - 8, "center")

        -- Cost: green if affordable, red if not
        local affordable = self.game_state.money >= entry.cost
        if affordable then
            love.graphics.setColor(0.3, 0.9, 0.4, 1)
        else
            love.graphics.setColor(0.9, 0.3, 0.3, 1)
        end
        love.graphics.printf("$" .. entry.cost, cx + 4, cy + 30, CARD_W - 8, "center")

        -- Description (light grey, left-aligned, wrapped)
        love.graphics.setColor(0.75, 0.75, 0.8, 1)
        love.graphics.printf(entry.desc, cx + 6, cy + 54, CARD_W - 12, "left")
    end

    -- Hint line at panel bottom
    love.graphics.setColor(0.55, 0.55, 0.65, 1)
    love.graphics.printf(
        "[E] Buy   [S / Esc] Close",
        PANEL_X, PANEL_Y + PANEL_H - 22, PANEL_W, "center"
    )

    -- Current money (top-left corner)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("$" .. self.game_state.money, 16, 16)

    -- Reset colour
    love.graphics.setColor(1, 1, 1, 1)
end

return ShopScene

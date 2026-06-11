local Roll    = require("game/items/roll")
local Knife   = require("game/items/knife")
local Pruner  = require("game/items/pruner")
local Breeder = require("game/entities/breeder")

local SHOP_W, SHOP_H = 500, 260
local LOGICAL_W, LOGICAL_H = 1280, 720

local CATALOG = {
    { name = "Wire Roll", cost = 20,  constructor = Roll.new,    desc = "Place wire fencing to redirect animals." },
    { name = "Knife",     cost = 40,  constructor = Knife.new,   desc = "Remove wire fencing within reach."       },
    { name = "Pruner",    cost = 15,  constructor = Pruner.new,  desc = "Decorative tool."                        },
    { name = "Breeder",   cost = 100, constructor = Breeder.new, desc = "Place two animals inside to breed."      },
}

local ShopUI = {}
ShopUI.__index = ShopUI

function ShopUI.new(game_state)
    local self = setmetatable({}, ShopUI)
    self._state  = game_state
    self._cursor = 1
    return self
end

-- Called every frame when the shop is open.
-- scene_input: the game scene's Input instance
-- player: the Player entity (items spawned near player)
-- scene: the game scene (items added to scene.items)
function ShopUI:update(scene_input, player, scene)
    if scene_input:pressed("move_left") then
        self._cursor = self._cursor - 1
        if self._cursor < 1 then self._cursor = #CATALOG end
    end
    if scene_input:pressed("move_right") then
        self._cursor = self._cursor + 1
        if self._cursor > #CATALOG then self._cursor = 1 end
    end
    if scene_input:pressed("interact") then
        local item_def = CATALOG[self._cursor]
        if self._state.money >= item_def.cost then
            self._state.money = self._state.money - item_def.cost
            -- Spawn item near player
            local ix = player.x + math.random(-32, 32)
            local iy = player.y + 48
            local new_item = item_def.constructor(ix, iy)
            table.insert(scene.items, new_item)
        end
    end
end

function ShopUI:draw()
    local ox = (LOGICAL_W - SHOP_W) / 2
    local oy = (LOGICAL_H - SHOP_H) / 2

    -- Background panel
    love.graphics.setColor(0.1, 0.1, 0.15, 0.92)
    love.graphics.rectangle("fill", ox, oy, SHOP_W, SHOP_H, 8, 8)
    love.graphics.setColor(0.6, 0.6, 0.8, 1)
    love.graphics.rectangle("line", ox, oy, SHOP_W, SHOP_H, 8, 8)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("SHOP", ox + 16, oy + 12)

    -- Item cards
    local card_w = 110
    local card_h = 160
    local gap    = 20
    local total_w = #CATALOG * card_w + (#CATALOG - 1) * gap
    local start_x = ox + (SHOP_W - total_w) / 2
    local card_y  = oy + 40

    for i, item_def in ipairs(CATALOG) do
        local cx = start_x + (i - 1) * (card_w + gap)

        -- Highlight selected
        if i == self._cursor then
            love.graphics.setColor(0.3, 0.3, 0.6, 1)
        else
            love.graphics.setColor(0.18, 0.18, 0.25, 1)
        end
        love.graphics.rectangle("fill", cx, card_y, card_w, card_h, 4, 4)
        love.graphics.setColor(0.5, 0.5, 0.7, 1)
        love.graphics.rectangle("line", cx, card_y, card_w, card_h, 4, 4)

        -- Item name
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(item_def.name, cx + 4, card_y + 8, card_w - 8, "center")

        -- Cost (red if can't afford)
        local can_afford = self._state.money >= item_def.cost
        love.graphics.setColor(can_afford and {0.2,1,0.2,1} or {1,0.3,0.3,1})
        love.graphics.printf("$" .. item_def.cost, cx + 4, card_y + 30, card_w - 8, "center")

        -- Description
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        love.graphics.printf(item_def.desc, cx + 4, card_y + 55, card_w - 8, "left")
    end

    -- Controls hint
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.print("A/D navigate   E buy   Tab close", ox + 16, oy + SHOP_H - 24)

    love.graphics.setColor(1, 1, 1, 1)  -- reset color
end

return ShopUI

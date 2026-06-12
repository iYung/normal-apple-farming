local Input   = require("core/lua/input")
local Roll    = require("game/items/roll")
local Knife   = require("game/items/knife")
local Breeder = require("game/entities/breeder")
local CRT     = require("game/shaders/crt")
local UI      = require("game/ui")
local Fonts   = require("core/lua/fonts")

local _font_family = Fonts.from("assets/fonts/font.ttf")
local font_name    = _font_family.new(32)
local font_desc    = _font_family.new(20)
local font_price   = _font_family.new(26)
local font_ui      = _font_family.new(16)

local img_buy_bg       = love.graphics.newImage("assets/images/shop/buy_bg.png")
local img_arrow_left   = love.graphics.newImage("assets/images/shop/arrow_left.png")
local img_arrow_right  = love.graphics.newImage("assets/images/shop/arrow_right.png")
local img_dot_active   = love.graphics.newImage("assets/images/shop/dot_active.png")
local img_dot_inactive = love.graphics.newImage("assets/images/shop/dot_inactive.png")
local img_coin         = love.graphics.newImage("assets/images/shop/coin.png")

local VIEW_W = 1280
local VIEW_H = 720

local CATALOGUE = {
    { name = "Wire Roll", cost = 20,  desc = "Place wire fencing to redirect animals.", constructor = Roll.new,    image = love.graphics.newImage("assets/images/items/wire_roll.png") },
    { name = "Knife",     cost = 40,  desc = "Remove wire fencing within reach.",       constructor = Knife.new,   image = love.graphics.newImage("assets/images/items/knife.png")     },
    { name = "Breeder",   cost = 100, desc = "Place two animals inside to breed.",      constructor = Breeder.new, image = love.graphics.newImage("assets/images/breeder/love_bin.png") },
}

local PREVIEW_SIZE = 160
local CENTER_X     = 640
local CENTER_Y     = 360
local ARROW_SIZE   = 60

local ShopScene = {}
ShopScene.__index = ShopScene

function ShopScene.new(game_state, scene_manager, game_scene)
    local self = setmetatable({}, ShopScene)
    self.game_state    = game_state
    self.scene_manager = scene_manager
    self.game_scene    = game_scene
    self.selected      = 1
    self.canvas = love.graphics.newCanvas(VIEW_W, VIEW_H)
    self.input = Input.new({
        left     = { "a", "left"  },
        right    = { "d", "right" },
        interact = { "e" },
        cancel   = { "s", "down" },
    })
    return self
end

function ShopScene:on_enter()
    self._skip_frame = true
end
function ShopScene:on_exit() end

function ShopScene:update(dt)
    self.input:update()
    if self._skip_frame then
        self._skip_frame = false
        return
    end

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
    local prev_canvas = love.graphics.getCanvas()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 1)

    local ent        = CATALOGUE[self.selected]
    local affordable = self.game_state.money >= ent.cost

    -- background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img_buy_bg, 0, 0)

    -- vertical layout: preview → name → desc → price, centered
    local desc_lines = {}
    for line in (ent.desc .. "\n"):gmatch("([^\n]*)\n") do
        desc_lines[#desc_lines + 1] = line
    end

    local line_h  = 28
    local gap1, gap2, gap3 = 40, 20, 28
    local total_h = PREVIEW_SIZE
                  + gap1 + font_name:getHeight()
                  + gap2 + #desc_lines * line_h
                  + gap3 + font_price:getHeight()
    local y = math.floor((VIEW_H - total_h) / 2)

    -- preview image
    if ent.image then
        local iw, ih = ent.image:getDimensions()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ent.image,
            CENTER_X - PREVIEW_SIZE / 2, y,
            0,
            PREVIEW_SIZE / iw,
            PREVIEW_SIZE / ih)
    end
    y = y + PREVIEW_SIZE + gap1

    -- name
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(font_name)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    local name_w = font_name:getWidth(ent.name)
    love.graphics.print(ent.name, CENTER_X - name_w / 2, y)
    y = y + font_name:getHeight() + gap2

    -- description lines
    love.graphics.setFont(font_desc)
    love.graphics.setColor(0.25, 0.25, 0.25, 1)
    for i, line in ipairs(desc_lines) do
        local lw = font_desc:getWidth(line)
        love.graphics.print(line, CENTER_X - lw / 2, y + (i - 1) * line_h)
    end
    y = y + #desc_lines * line_h + gap3

    -- price
    love.graphics.setFont(font_price)
    local fh = font_price:getHeight()
    if ent.cost == 0 then
        love.graphics.setColor(0.1, 0.45, 0.1, 1)
        local fw = font_price:getWidth("Free")
        love.graphics.print("Free", CENTER_X - fw / 2, y)
    else
        local coin_h  = fh
        local coin_w  = img_coin:getWidth() * (coin_h / img_coin:getHeight())
        local num_str = "$" .. ent.cost
        local num_w   = font_price:getWidth(num_str)
        local total_w = coin_w + 6 + num_w
        local bx      = math.floor(CENTER_X - total_w / 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img_coin, bx, y, 0, coin_h / img_coin:getHeight(), coin_h / img_coin:getHeight())
        if affordable then
            love.graphics.setColor(0.1, 0.45, 0.1, 1)
        else
            love.graphics.setColor(0.5, 0.1, 0.1, 1)
        end
        love.graphics.print(num_str, bx + coin_w + 6, y)
    end

    -- arrows
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img_arrow_left,  CENTER_X - 230 - ARROW_SIZE / 2, CENTER_Y - ARROW_SIZE / 2)
    love.graphics.draw(img_arrow_right, CENTER_X + 230 - ARROW_SIZE / 2, CENTER_Y - ARROW_SIZE / 2)

    -- dot row
    local dot_size  = 20
    local dot_gap   = 22
    local dot_start = CENTER_X - (#CATALOGUE - 1) * dot_gap / 2
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #CATALOGUE do
        local img = (i == self.selected) and img_dot_active or img_dot_inactive
        love.graphics.draw(img, dot_start + (i - 1) * dot_gap - dot_size / 2, CENTER_Y + 252)
    end

    love.graphics.setFont(prev_font)

    -- blit with CRT shader
    love.graphics.setCanvas(prev_canvas)
    love.graphics.setColor(1, 1, 1, 1)
    CRT.apply()
    love.graphics.draw(self.canvas, 0, 0)
    CRT.clear()

    -- HUD (drawn after CRT, unshaded)
    local hints = { "\xe2\x86\x90 \xe2\x86\x92  Cycle", "E  Buy", "S  Close" }
    UI.draw_currency_bubble(self.game_state.money, 10, 10, font_ui)
    UI.draw_hud_box(hints, font_ui, 10)

    love.graphics.setFont(font_ui)
    love.graphics.setColor(0, 0, 0, 1)
    local PAD        = 14
    local line_h_hud = 20
    local box_h      = #hints * line_h_hud + PAD * 2
    local ty         = VIEW_H - 10 - box_h + PAD
    for _, hint in ipairs(hints) do
        love.graphics.print(hint, 10 + PAD, ty)
        ty = ty + line_h_hud
    end

    love.graphics.setFont(prev_font)
    love.graphics.setColor(1, 1, 1, 1)
end

return ShopScene

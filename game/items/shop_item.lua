local Item = require("game/items/item")

local ShopItem = setmetatable({}, { __index = Item })
ShopItem.__index = ShopItem

function ShopItem.new(x, y, shop_scene)
    local self = Item.new(x, y, "Shop", "assets/images/shop/shop.png", 96, 96)
    setmetatable(self, ShopItem)
    self._type      = "shop_item"
    self.carriable  = false
    self.sellable   = false
    self.shop_scene = shop_scene
    return self
end

function ShopItem:interact(player, scene, scene_manager)
    if player.held_item then return end
    if scene_manager and self.shop_scene then
        scene_manager:switch(self.shop_scene)
    end
end

function ShopItem:update(dt)
    Item.update(self, dt)
end

function ShopItem:draw()
    Item.draw(self)
end

return ShopItem

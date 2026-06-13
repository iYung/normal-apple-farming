local Item = require("game/items/item")

local Book = {}
Book.__index = Book
setmetatable(Book, { __index = Item })  -- inherit from Item

function Book.new(x, y, book_scene)
    local self = Item.new(x, y, "Book", "assets/images/items/book.png", 32, 32)
    setmetatable(self, Book)
    self._type       = "book"
    self.carriable   = true
    self._book_scene = book_scene
    return self
end

function Book:interact(player, scene, scene_manager)
    if scene_manager and self._book_scene then
        scene_manager:switch(self._book_scene)
    end
end

function Book:update(dt)
    Item.update(self, dt)
end

function Book:draw()
    Item.draw(self)
end

return Book

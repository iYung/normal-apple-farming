local Shader = require("core/lua/shader")

local shader = Shader.load("assets/shaders/crt.glsl")

return {
    apply = function()
        love.graphics.setShader(shader)
    end,
    clear = function()
        love.graphics.setShader()
    end,
}

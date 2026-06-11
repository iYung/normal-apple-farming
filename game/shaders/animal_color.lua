local AnimalColorShader = {}
AnimalColorShader.__index = AnimalColorShader

local _glsl = [[
extern vec3 skin_color;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    vec4 pixel = Texel(tex, texture_coords);
    if (pixel.r > 0.95 && pixel.g < 0.05 && pixel.b < 0.05 && pixel.a > 0.5) {
        return vec4(skin_color, pixel.a);
    }
    return pixel;
}
]]

function AnimalColorShader.new()
    return love.graphics.newShader(_glsl)
end

function AnimalColorShader.apply(shader, r, g, b)
    love.graphics.setShader(shader)
    shader:send("skin_color", {r, g, b})
end

function AnimalColorShader.clear()
    love.graphics.setShader()
end

return AnimalColorShader

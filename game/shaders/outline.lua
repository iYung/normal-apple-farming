local OutlineShader = {}

local _glsl = [[
extern vec3 outline_color;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    vec4 pixel = Texel(tex, uv);
    if (pixel.a < 0.1) {
        float step = 2.0;
        float up    = Texel(tex, uv + vec2(0, -love_PixelSize.y * step)).a;
        float down  = Texel(tex, uv + vec2(0,  love_PixelSize.y * step)).a;
        float left  = Texel(tex, uv + vec2(-love_PixelSize.x * step, 0)).a;
        float right = Texel(tex, uv + vec2( love_PixelSize.x * step, 0)).a;
        if (up + down + left + right > 0.1) {
            return vec4(outline_color, 1.0);
        }
    }
    return pixel;
}
]]

function OutlineShader.new()
    return love.graphics.newShader(_glsl)
end

function OutlineShader.apply(shader, r, g, b)
    love.graphics.setShader(shader)
    shader:send("outline_color", {r, g, b})
end

function OutlineShader.clear()
    love.graphics.setShader()
end

return OutlineShader

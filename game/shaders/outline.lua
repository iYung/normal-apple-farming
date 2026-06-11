local OutlineShader = {}

local _glsl = [[
extern vec3 outline_color;
extern vec2 pixel_size;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    vec4 pixel = Texel(tex, uv);
    if (pixel.a < 0.1) {
        float step = 2.0;
        float up    = Texel(tex, uv + vec2(0,               -pixel_size.y * step)).a;
        float down  = Texel(tex, uv + vec2(0,                pixel_size.y * step)).a;
        float left  = Texel(tex, uv + vec2(-pixel_size.x * step, 0             )).a;
        float right = Texel(tex, uv + vec2( pixel_size.x * step, 0             )).a;
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

-- img_w/img_h are optional; defaults to 32x32 (standard animal sprite size)
function OutlineShader.apply(shader, r, g, b, img_w, img_h)
    love.graphics.setShader(shader)
    shader:send("outline_color", {r, g, b})
    shader:send("pixel_size", {1.0 / (img_w or 32), 1.0 / (img_h or 32)})
end

function OutlineShader.clear()
    love.graphics.setShader()
end

return OutlineShader

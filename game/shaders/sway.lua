local SwayShader = {}

local _glsl = [[
extern float time;
extern float amplitude;
extern float frequency;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen_coords) {
    float sway = sin(time * frequency) * amplitude * (1.0 - uv.y);
    vec2 displaced_uv = vec2(uv.x + sway, uv.y);
    return Texel(tex, displaced_uv);
}
]]

function SwayShader.new()
    return love.graphics.newShader(_glsl)
end

function SwayShader.apply(shader, time)
    love.graphics.setShader(shader)
    shader:send("time", time)
    shader:send("amplitude", 0.0225)
    shader:send("frequency", 7.5)
end

function SwayShader.clear()
    love.graphics.setShader()
end

return SwayShader

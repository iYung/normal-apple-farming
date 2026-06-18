-- Verifies sway shader constants match intended design values.
-- Stubs newShader to capture send() calls without a real GPU.

local sent = {}
love.graphics.newShader = function()
    return { send = function(_, key, val) sent[key] = val end }
end

local SwayShader = require("game/shaders/sway")
local shader = SwayShader.new()
SwayShader.apply(shader, 0.0)

assert(math.abs(sent.amplitude - 0.0225) < 1e-9,
    "amplitude should be 0.0225, got " .. tostring(sent.amplitude))
print("PASS: sway amplitude is 0.0225")

assert(math.abs(sent.frequency - 7.5) < 1e-9,
    "frequency should be 7.5, got " .. tostring(sent.frequency))
print("PASS: sway frequency is 7.5")

print("ALL TESTS PASSED")

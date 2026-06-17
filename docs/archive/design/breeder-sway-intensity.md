# Breeder Sway Intensity

## Goal
Increase the visual intensity of the breeder's sway shader effect by 50% in both amplitude (strength) and frequency (speed).

## Affected files
- `game/shaders/sway.lua` — where amplitude and frequency constants are hardcoded

## What changes
| Parameter | Before | After |
|-----------|--------|-------|
| `amplitude` | `0.015` | `0.0225` |
| `frequency` | `3.0` | `4.5` |

Both values are sent as uniforms inside `SwayShader.apply()` on lines 22–23.

## What stays the same
- Shader GLSL logic (`sway.lua` lines 3–13)
- Where/when the shader is applied (`breeder.lua` lines 144–148)
- Time accumulation logic in `breeder.lua`
- All other breeder behaviour

## Open questions
None.

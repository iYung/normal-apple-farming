# Breeder Slot Grey Background — Always Visible

## Goal

The breeder's body sprites (`love_bin.png`, `love_bin_1.png`, `love_bin_2.png`) have a
transparent "hole" in them that is meant to be covered by the grey `_bar_back` plate
sprite drawn behind the body. Currently `_bar_back` is only drawn while
`self._breeding` is true (i.e. only when 2 animals occupy the slot), so with 0 or 1
animals in the slot, the hole is see-through to whatever is behind the breeder.

We want the grey backing to be drawn at all times, regardless of slot occupancy, so
the hole is never see-through.

## Affected files

- `game/entities/breeder.lua` — `Breeder:draw()` (lines 107–152)
- `tests/test_breeder.lua` — add rendering/state coverage if feasible

## What changes

- `self._bar_back:draw()` moves out of the `if self._breeding then ... end` block in
  `Breeder:draw()` and is called unconditionally, every frame, for all slot states
  (empty, one animal, two animals/breeding).
- `self._bar_fill` (the progress fill on top of the grey backing) continues to draw
  only while `self._breeding` is true — progress is meaningless outside of active
  breeding, and drawing it at `scale_x = 0` when idle would be a no-op anyway, so
  gating it avoids unnecessary draw calls.

## What stays the same

- `self._breeding` state logic (`try_add`, `try_eject`, `update`) is untouched.
- Sway shader and outline-highlight behavior are untouched.
- Body sprite selection by slot count (`_sprite_empty` / `_sprite_one` / `_sprite_two`)
  is untouched.
- Progress bar fill logic/visuals during active breeding are untouched.

## Open questions

None — the change is a single unconditional draw call move, confirmed by the user's
intent ("never see through that slot").

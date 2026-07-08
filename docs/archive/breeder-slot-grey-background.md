## Breeder Slot Grey Background Checklist

- [x] Task A — `game/entities/breeder.lua` — In `Breeder:draw()`, move `self._bar_back:draw()` out of the `if self._breeding then` block so it draws unconditionally every frame (all slot states). Keep `self._bar_fill.scale_x = progress` and `self._bar_fill:draw()` gated on `self._breeding` as before.
- [x] Task B — `tests/test_breeder.lua` — Add/extend a test asserting the grey backing is drawn regardless of `_breeding` state (e.g. spy/stub on `_bar_back.draw` or assert draw is invoked for 0/1/2-slot states), consistent with existing test style in the file.

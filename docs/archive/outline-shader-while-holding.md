## Outline Shader While Holding Checklist

- [x] Task A — `game/entities/player.lua` — Remove the `if not self.held_item then` guard (line 128) so that `Detector.nearest` runs and highlights the nearest entity every frame regardless of holding state. The closing `end` for that guard must also be removed. The de-highlight reset loop above it (lines 126–127) and the Detector.nearest block inside should remain unchanged.

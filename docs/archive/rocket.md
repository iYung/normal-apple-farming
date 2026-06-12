## Rocket Checklist

- [x] Task A — `assets/images/items/rocket.png` — Generate a 120×240 px placeholder PNG using a standalone LÖVE ImageData script or a minimal hand-crafted PNG; commit the file so the asset pipeline works before any code references it

- [x] Task B — `game/items/rocket.lua` — Create the Rocket item class inheriting from Item; sprite at 120×240, `_type = "rocket"`, `carriable = true`; implement `interact(player, scene, scene_manager)` to set `self._launched = true`, drop from player hands, and store `scene.active_rocket = self` and `scene.rocket_scene_manager = scene_manager`; implement `update(dt)` to move upward at 300 px/s when launched, increment `_flight_timer`, and call `scene.rocket_scene_manager:switch(GameOverScene.new(scene.game_state))` at t=4.5 s (guard against double-trigger with a `_done` flag)

- [x] Task C — `game/systems/detector.lua` — Add `Detector.is_rocket(e)` returning `e._type == "rocket"`; add `"rocket"` to the `can_pickup()` type check so F-key pickup works

- [x] Task D — `game/scenes/game_over_scene.lua` — Create the GameOverScene; `new(game_state)` stores game_state; `on_enter` sets up Input with `{ restart = {"r"} }`; `update` switches to a fresh `GameScene.new(scene_manager)` on R press; `draw` renders full-screen black background, large "GAME OVER" heading, money and animals-sold summary lines, "Press R to restart" prompt, all through the CRT shader

- [x] Task E — `game/scenes/game_scene.lua` — Initialize `self.active_rocket = nil` in `on_enter`; in `update`, when `active_rocket` is set skip `player:update` and follow `active_rocket` centre with the camera (no world-bounds clamping); in `draw`, when `active_rocket` is set exclude the player from the Y-sorted entity list; require GameOverScene at the top of the file

- [x] Task F — `game/scenes/shop_scene.lua` — Require `Rocket` at the top; add a fourth CATALOGUE entry `{ name = "Rocket", cost = 300, desc = "A one-way ticket skyward.", constructor = Rocket.new, image = love.graphics.newImage("assets/images/items/rocket.png") }`

## Goal

Today, the in-game pause menu's fourth item, **"Quit to Desktop"**, always calls `love.event.quit()` — regardless of whether it was opened during gameplay or from the title screen itself. Players who want to back out of a run to the title screen have no way to do that; their only option is to close the whole application.

Change that item so that, when opened **during gameplay**, it returns the player to the title screen (`StartScene`) instead of quitting the app. When opened **from the title screen itself**, it keeps quitting the application exactly as it does today — this is the game's only true-quit path, and it must not disappear. The item is renamed to **"Exit to Title"** to reflect the new (primary) behavior, with the label staying constant across both contexts.

## Affected files

| File | Status |
|------|--------|
| `game/scenes/settings_menu.lua` | Modify — rename the 4th menu item's label; change its `_confirm()` branch to signal an exit request (context-aware) instead of unconditionally calling `love.event.quit()` |
| `main.lua` | Modify — supply the pause menu with a way to (a) tell whether the currently active scene is the title screen, and (b) either perform the scene-manager switch back to a fresh `StartScene`, or fully quit, plus handle music crossfade on the switch path |
| `core/lua/sound.lua` | Modify — add a small group-wide fade-out helper so the exit-to-title path can silence whichever `bg` track is currently playing without needing to know which of `bg1`–`bg4` it is |
| `game/scenes/start_scene.lua` | Possibly modify — needs some way to be identified as "the title screen" by the code above (see below); may reuse the existing `esc_opens_settings` flag or add a clearer marker |

## What changes

**Menu item relabel.** `ITEMS[4]` in `settings_menu.lua` changes from `"Quit to Desktop"` to `"Exit to Title"`. The label is constant — it does not change text depending on where the menu was opened from, even though its behavior does.

**Context-aware behavior.** `SettingsMenu:_confirm()`'s branch for item 4 no longer calls `love.event.quit()` directly. Instead it signals "exit requested" outward (see callback wiring below), and the decision of *what that means* — switch to the title screen, or actually quit — is resolved by checking which scene is currently active:

- If the active scene is gameplay (`GameScene`, or one of the sub-scenes reached from it — `ShopScene`, `BookScene`, `GameOverScene`, since the pause overlay is global and opens over any of these the same way) → switch the scene manager back to a freshly-constructed `StartScene` (same construction as at boot: `StartScene.new(manager, settings_state, input)`).
- If the active scene is already `StartScene` → call `love.event.quit()`, exactly as today. This preserves the app's only true-quit path.

No confirmation dialog is added for either path — both go straight through, matching the app's existing no-confirmation behavior (there is no save-game system to protect either way; session state such as money/animals/jobs is already recreated from scratch in `GameScene:on_enter()` every time it runs, so returning to the title screen loses nothing that a full quit wouldn't also lose).

**Callback wiring (`SettingsMenu` ↔ `main.lua`).** `SettingsMenu` currently has no reference to the `SceneManager` or to `StartScene` — only `main.lua` does (it owns `manager`, constructs `StartScene` at boot, and already passes `SettingsMenu` a `settings_state`/`input`/`on_close` callback for save-on-close). The cleanest fit is to extend that existing callback pattern rather than hand `SettingsMenu` a `SceneManager` reference and a `require` on `StartScene` (which would pull scene-management concerns into a widget that currently only knows about settings). Concretely: `main.lua` supplies `SettingsMenu` with a new callback at construction (sibling to the existing `on_close`) that `_confirm()` invokes for item 4. `main.lua`'s implementation of that callback:
1. Saves settings (same as the existing on-close save).
2. Checks whether `manager.current` is the title screen.
3. Either quits, or performs the scene switch + music handling below.

Determining "is the current scene the title screen" needs a signal `main.lua` can check without an awkward type-identity comparison. `StartScene` already sets `self.esc_opens_settings = true` in its constructor, and no other scene in the codebase sets that field — so `manager.current.esc_opens_settings` already happens to uniquely identify the title screen today. Reusing it avoids a new field, but its name doesn't really mean "this is the title screen" (it's a leftover gamepad-Start-button gate), so it may be clearer to add an explicit marker (e.g. `self.is_title_scene = true`) to `StartScene` instead. Either is acceptable; picking between them is left to the implementing task since it's a small, self-contained choice that doesn't affect the rest of the design.

**Music: must explicitly stop the `bg` track before/while entering `StartScene`.** This directly interacts with the recent music double-play fix (`docs/archive/design/music-double-play-fix.md`, `core/lua/sound.lua`). That fix made `bg1`–`bg4` mutually exclusive via a shared `group = "bg"` and a `_claim_group` helper — but `menu` was deliberately left **ungrouped** so the existing menu→game crossfade in `GameScene:on_enter()` (`Sound.fade_music("menu", 0, 2)` then `Sound.fade_music(bg_track, 1, 2)`) keeps working. The consequence: `_claim_group` only acts when the *claiming* track has a group, so calling `Sound.play_music("menu")` (what `StartScene:on_enter()` does today) does **not** stop whatever `bg` track is currently playing — `menu`'s claim is a no-op because `menu` itself has no group. If the new exit-to-title path just called `scene_manager:switch(StartScene.new(...))` as-is, the player would hear the `bg` track and `menu` track simultaneously — reintroducing a double-play bug through a path the previous fix didn't cover (it only handled same-group `bg`-to-`bg` transitions).

The fix mirrors the existing forward crossfade, in reverse, explicitly triggered by the code doing the exit (not by `StartScene:on_enter()`, matching how `StartScene`'s own E-press handler explicitly fades `menu` to 0 before switching to `GameScene` rather than relying on `GameScene:on_enter()` to do it):
- Fade the active `bg` track to 0 and fade `menu` in — same duration/style as the existing forward transition.
- Because the exit can be triggered from `main.lua`/`SettingsMenu`, which don't track *which* of `bg1`–`bg4` is currently playing (only `GameScene` does, via `self._bg_index`/`self._bg_list`), the simplest robust approach is a small new `Sound` API that fades out **whichever** track(s) in a named group currently have `playing_intent = true`, e.g. a group-wide counterpart to the existing single-track `Sound.fade_music`. This reuses the same per-entry `fade_vol`/`fade_target`/`stop_on_done` machinery `Sound.update` already drives — it does not need to know which specific `bg` track is active, so the caller doesn't need to reach into `GameScene`'s private state.
- `Sound.fade_music("menu", 1, duration)` fades `menu` in as before (unaffected by the above, since `menu` is ungrouped).

## What stays the same

- `GameScene`, `ShopScene`, `BookScene`, `GameOverScene` — untouched. The pause overlay is global (owned by `main.lua`, drawn over whatever scene is active), so no per-scene code is needed for the exit path to work from any of them.
- `SettingsMenu` items 1–3 (`Fullscreen/Window`, `Keybinds`, `Exit Settings`) — unchanged.
- No confirmation dialog, matching current behavior.
- Quitting from the title screen still calls `love.event.quit()`, unchanged in effect.
- Settings are still saved at the moment of exit (both branches), matching the existing save-on-close behavior.
- The existing menu→game crossfade in `GameScene:on_enter()` (`Sound.fade_music("menu", 0, 2)` / `Sound.fade_music(bg_track, 1, 2)`) is untouched — this design adds the reverse transition as new code, it doesn't modify the forward one.
- `Sound.on_focus`, `Sound.stop_music`, `Sound.set_music_volume`, `Sound.update`, `Sound.play`, `Sound.play_animalese`, `_claim_group`'s existing behavior for `bg`-to-`bg` transitions — untouched.
- No save-game system is introduced; none exists today and none is needed for this feature.

## Open questions

None outstanding — resolved with the user:

1. **Context-dependent behavior**: confirmed. From gameplay scenes, "Exit to Title" returns to `StartScene`. From the title screen itself, it fully quits the application (`love.event.quit()`), preserving the only true-quit path in the game.
2. **Label**: confirmed as `"Exit to Title"`, constant across both contexts (not context-dependent text).
3. **Confirmation dialog**: confirmed not needed — goes straight to the target scene/quit, matching today's no-confirmation behavior, since there is no save system to protect.

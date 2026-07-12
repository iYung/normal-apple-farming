## Goal

Fix the bottom-left action HUD (`ActionsInfo`, drawn by `GameScene`) so that when the
player is near the **book** or the **shop**, the HUD shows the "[key] Interact" hint.
Today it silently shows a "[key] Pick up ..." hint instead (or, for the shop, a pickup
hint the shop doesn't actually support), and the interact hint never appears.

## Root cause

1. **`GameScene:update()`** (`game/scenes/game_scene.lua`, ~lines 196-216) builds the
   `nearby` list that feeds `ActionsInfo:set_nearby()` by scanning every non-held entity
   in `self.animals` and `self.items` within a 64px radius. It never checks
   `entity.carriable` — it adds *any* nearby item, carriable or not.

2. **`ActionsInfo:draw()`** (`game/ui/actions_info.lua`, lines 36-47) picks the hint with
   a hard priority: held → drop hint; else **`#self._nearby > 0` → pickup hint**; else →
   generic "[key] Interact" hint. There is no path that shows the interact hint while
   `_nearby` is non-empty.

3. Combining 1 and 2: any interactable object sitting in `self.items` within 64px
   permanently wins the pickup branch and hides the interact hint, even when it isn't
   pickup-able at all:
   - **Shop** (`game/items/shop_item.lua`): `carriable = false` (asserted by
     `tests/test_shop_item.lua`), yet it still lands in `nearby` because the loop never
     checks `carriable`. Result: HUD shows "[F] Pick up Shop" — a pickup action the shop
     doesn't support — and never shows "[E] Interact", even though pressing `interact`
     does correctly open the shop (`Player:_handle_interact`, `game/entities/player.lua`
     ~196-203, works independently of the HUD list).
   - **Book** (`game/items/book.lua`): `carriable = true` (asserted by
     `tests/test_book.lua` — it's intentionally pick-up-able), so it correctly appears in
     `nearby`. But because the pickup branch fully replaces the interact branch, the HUD
     shows only "[F] Pick up Book" and never mentions that `interact` opens the book.
   - **Rocket** (`game/items/rocket.lua`) has the exact same shape (`carriable = true`
     + a real `:interact()`), so it silently has the same HUD bug today, even though it
     wasn't in the bug report.

4. Two pieces of dead/orphaned code point at this exact classification problem having
   been anticipated but never finished:
   - `Detector.can_pickup()` (`game/systems/detector.lua`) is defined but never called
     anywhere in the codebase.
   - `game/ui/actions_info.lua` does `local Detector = require("game/systems/detector")`
     at the top of the file but never references `Detector` anywhere in the module.

So: the interact key itself works correctly for book/shop (verified via
`Player:_handle_interact`); this is purely a HUD-text/priority bug, not a broken
interaction.

## Affected files

- `game/scenes/game_scene.lua` — stop adding non-carriable entities to the pickup
  `nearby` list; compute and pass along the nearest "interactable" entity (one with a
  real `:interact()`, not the `Item` default no-op) for the HUD to show.
- `game/ui/actions_info.lua` — accept the new interact-target info and change `draw()`
  so the interact hint is shown whenever an interactable is nearby, concatenated
  alongside the pickup hint when both apply (mirrors the existing pattern already used
  for held-item hints, e.g. "[F] Drop  [E] Place wire"). Finally makes use of the
  `Detector` import that already sits unused at the top of the file.
- `game/systems/detector.lua` — add an `is_interactable(e)` helper (type check for
  `book` / `shop_item` / `rocket`, the three types that override `:interact()`),
  following the same pattern as the existing `is_animal` / `is_roll` / `can_pickup`
  helpers.
- `tests/test_hud_ui.lua` — extend with cases for: shop-only nearby (interact hint,
  no pickup hint), book nearby (both pickup and interact hints present), to lock in the
  fix. (Left to Phase 2/3 to implement; noted here since it's the natural home for
  coverage.)

## What changes

- Standing near the **shop** (nothing held): HUD shows "[E] Open Shop" instead of
  "[F] Pick up Shop". This matches what actually happens when you press each key today
  (interact opens the shop; pickup does nothing to the shop).
- Standing near the **book** (nothing held): HUD shows both hints together, interact
  first, e.g. "[E] Read Book  [F] Pick up Book", since both actions are genuinely
  available (you can carry the book, or press interact to open it immediately).
- Standing near the **rocket** (nothing held): gets the same fix as the book, e.g.
  "[E] Launch Rocket  [F] Pick up Rocket", since it's the same underlying code path
  (`carriable = true` + real `:interact()`). Included in this pass since it's the same
  bug on the same code path.
- Contextual per-object copy ("Read Book" / "Open Shop" / "Launch Rocket") replaces the
  generic "[E] Interact" fallback for these three types; the generic fallback stays for
  any future interactable that doesn't specify its own label.
- `Detector` gains a new `is_interactable(e)` helper; `actions_info.lua`'s previously-dead
  `Detector` import is now actually used.
- `Detector.can_pickup()` (dead code, never called) is removed as part of this change.

## What stays the same

- All actual input handling is untouched: `Player:_handle_interact` and
  `Player:_handle_pickup` (`game/entities/player.lua`) keep working exactly as they do
  today — interact opens book/shop and never picks anything up; pickup still
  picks up/drops carriable items (knife, roll, book, animals, rocket) and still does
  breeder-eject / sell-bin logic. `tests/test_interact_pickup_split.lua`,
  `tests/test_book.lua`, and `tests/test_shop_item.lua` all continue to pass unmodified.
- `carriable` values are unchanged: shop stays `carriable = false`, book and rocket stay
  `carriable = true`.
- Breeder and sell-bin HUD hints are unaffected — they stay `carriable = true`, have no
  `:interact()` override, so they keep showing the existing "[F] Pick up ..." style hint
  exactly as today.
- Key-label rendering keeps going through `key_label()` / `input:key_for()` — no
  hardcoded key strings are introduced, consistent with the project's Controls HUD
  convention.
## Open questions

None — resolved with the user before implementation:

1. **Hint wording**: contextual per-object text ("Read Book" / "Open Shop" /
   "Launch Rocket"), not the generic "[E] Interact" fallback.
2. **Order when both hints show** (book/rocket case): interact hint listed first,
   e.g. "[E] Read Book  [F] Pick up Book".
3. **Rocket included**: yes, fixed in this same pass.
4. **`Detector.can_pickup()`**: removed as dead code in this change.

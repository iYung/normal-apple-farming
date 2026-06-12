# Interact / Pickup Split

## Goal

Split the single `interact` (E) button into two distinct actions:

- **`interact` (E)** — context-sensitive action: opens the shop, uses the knife, lays/removes wire with the spool
- **`pickup` (F)** — carries and drops items: animals, knife, wire spool

Both actions are user-rebindable and shown in the keybinds UI.

## Affected files

- `game/entities/player.lua`
- `game/scenes/game_scene.lua`
- `game/settings_state.lua`
- `game/scenes/settings_menu.lua`

## What changes

### `interact` button (E)

Priority order when pressed/held:

1. **Holding knife or wire spool** — use the held item (continuous while held, same as old `secondary`/O behaviour). Held item takes priority even when near the shop.
2. **Near shop, holding nothing or a non-usable item** — open shop scene.
3. **Otherwise** — do nothing.

The old `secondary` (O) action is removed entirely. Its "hold to use" logic moves here.

### `pickup` button (F)

- **Not holding anything** — find the nearest carriable entity within 64 px (animal, knife, wire spool) and pick it up. If nearest is a non-empty breeder, eject its last animal into the player's hands (existing behaviour, just moved to this button).
- **Holding something** — attempt to place it (into breeder or sell bin if overlapping), then fall back to dropping it at the player's position.

### Input map changes

| Action     | Old key(s)   | New key(s) | Rebindable? |
|------------|--------------|------------|-------------|
| `interact` | `e`          | `e`        | Yes         |
| `pickup`   | *(was `interact`)* | `f` | Yes         |
| `secondary`| `o`          | *(removed)*| —           |

### Settings / keybinds UI changes

- `pickup` added to `SettingsState` default keybinds (`pickup = "f"`) and `key_map()`.
- `_ACTION_LIST` in `settings_menu.lua` gains `"pickup"`; `_ACTION_LABELS` gains `"pickup"`.
- `secondary` was never in the keybinds UI so nothing to remove there.

### Highlight behaviour

Unchanged — nearest carriable entity within 64 px is highlighted in yellow. This still reflects what the `pickup` button will act on.

## What stays the same

- Knife `use()` and Roll `use()` implementations are unchanged.
- Shop `interact()` method is unchanged.
- Breeder eject and sell bin logic are unchanged — just triggered by `pickup` instead of `interact`.
- `Detector.can_pickup()` is unchanged (animals, rolls, knives).
- All animation, carry sprites, and held-item positioning are unchanged.
- The 64 px detection radius is unchanged.

## Open questions

None — all clarified before writing this doc.

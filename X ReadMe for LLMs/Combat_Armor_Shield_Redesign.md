# Combat: Armor & Shield System Redesign

## Problem Being Solved

The current armor system puts block tiles into the player's draw deck. This creates two issues:
1. Drawing a block tile when you wanted to attack feels like a wasted draw
2. Spending stamina on a block tile leaves you with nothing offensive to do that turn

**Goal:** Armor should feel like *protection you wear*, not *actions you take*. Shields (a new offhand slot) become the intentional choice for active defense.

---

## Design Decision: Protection Model

### Option A — Refreshing Passive Block
Armor gives N block automatically at the start of every turn.
- Simple, predictable, kind to new players
- **Risk:** If armor_value ≥ enemy damage, that enemy never touches HP. Trivializes weak enemies (e.g. armor=3 vs. Teqqellon's 1–2 damage = full immunity)
- Best for: representing light/padded armor that cushions grazes

### Option B — Persistent Armor Pool *(recommended)*
Armor gives N `armor_points` at **combat start only**. Damage hits the armor pool first, then HP. Pool does **not** refresh each turn — enemies chip through it over the fight.
- Creates a fight arc: early turns feel safer, then you get exposed. Tension builds naturally.
- Makes shield tiles meaningful: shields can include *restoration tiles* that replenish armor_points mid-fight — turning defense into a real strategic decision
- Fits the world: crafted armor gets battered. Physically intuitive.
- **The catch:** Needs the offhand/shield restoration tile to complete the loop. Without it, it's just a second HP pool.

**Going with Option B.** The fight arc and strategic tension are worth it.

---

## New System Overview

```
Deck composition (new):
  weapon tiles + offhand/shield tiles + trinket tiles

Armor slot:
  NO tiles in deck
  Sets armor_points at combat start (a buffer before HP)

Damage resolution (new order):
  incoming damage → temp block (from tiles) → armor_points → HP
```

---

## Balance Reference

With player HP = 25 and Shenche hitting 4–6/turn:

| Armor | Turns before HP damage starts | Notes |
|---|---|---|
| Naked (0 armor_points) | 0 | Straight to HP |
| Scrappy fabrics (4) | ~1 turn | Gone fast against Shenche |
| Good leather (8) | ~1–2 turns | Meaningful opening window |
| Heavy stone-plate (14) | ~2–3 turns | Premium armor feel |

Against Teqqellon (1–2/turn), even 4 armor_points lasts 2–4 turns — feels substantial against weaker enemies without trivializing them.

---

## Implementation Plan

### Files to change

| File | What changes |
|---|---|
| `Resources/Items/equipable_item.gd` | Add `armor_points: int = 0` export; add `"offhand"` to equip_type enum |
| `Scripts/resources/stats.gd` | New damage resolution: armor_points layer between block and HP |
| `Scripts/resources/character_stats.gd` | Add `armor_points` / `max_armor_points` vars; set from equipped armor in `create_instance()` |
| `Scripts/autoload/pile_manager.gd` | Remove armor tile loop; add offhand tile loop |
| `Scripts/autoload/gamestate.gd` | Add `equipped_offhand` slot; `equip_offhand()` / `unequip_offhand()` methods; 2H weapon guard |
| `Resources/Items/Equipment/Armor/*.tres` | Set `armor_points` values on existing armor items (see below) |

### Key code changes

**`stats.gd` — resolve_damage()** (currently lines 15–42)
```
# Existing: block absorbs first
blocked = min(block, damage)
remaining = damage - blocked

# NEW: armor_points absorb what block didn't catch
armor_absorbed = min(armor_points, remaining)
armor_points -= armor_absorbed
dealt_to_hp = remaining - armor_absorbed

# Apply to HP
health -= dealt_to_hp
```

**`pile_manager.gd` — get_logical_deck()**
```
# REMOVE this block (armor no longer contributes tiles):
# for tile in GameState.equipped_armor.tile_bundle.tiles: ...

# ADD this block after weapon tiles:
if GameState.equipped_offhand and GameState.equipped_offhand.tile_bundle:
    for tile in GameState.equipped_offhand.tile_bundle.tiles:
        combined_deck.add_tile(tile)
        added_any = true
```

**`gamestate.gd` — new offhand slot**
```gdscript
var equipped_offhand: EquipableItem = null

func equip_offhand(item: EquipableItem) -> void:
    if item.equip_type != "offhand":
        push_error("Not an offhand item.")
        return
    if equipped_weapon != null and equipped_weapon.hand_slot == "2-handed":
        push_error("Cannot equip offhand — weapon is 2-handed.")
        return
    equipped_offhand = item
    fallback_equipped.emit()

func unequip_offhand() -> void:
    equipped_offhand = null
    fallback_equipped.emit()
```

Also in `equip_weapon()`: if new weapon is 2-handed, auto-clear offhand.

### Existing armor items — set armor_points

| Item | armor_points |
|---|---|
| Naked | 0 |
| Scrappy fabrics | 4 |
| Armor of the Debugger | 8 (debug item, keep inflated) |

---

## Shield / Offhand Items

A shield `.tres`:
- `equip_type = "offhand"`
- `hand_slot = "1-handed"` (occupies one hand — incompatible with 2H weapons)
- `armor_points = 0` (shields don't give passive armor pool, just tiles)
- Tile bundle suggestions:
  - **Block tiles** — DEFEND, 1 stamina, 3–4 block each (absorb damage this turn)
  - **Restoration tile** — BUFF, 1 stamina, restores 2–3 armor_points (spend a turn shoring up your armor mid-fight)
  - A few fail tiles to keep it honest

### Why 2H weapons disable offhand

Both hands are occupied. No room for a shield. This also creates a meaningful trade-off:
- 2H weapon = more damage, zero defensive options (deck has no block tiles at all unless a trinket adds some)
- 1H weapon + shield = less peak damage, but defensive control
- 1H weapon + no shield = middle ground, but deck is purely offense

---

## Unanswered Questions (to decide later)

- Should shields also be able to restore armor_points, or only add temp block?
- Should there be a UI indicator showing current armor_points vs HP separately?
- Can enemies have armor_points too, or just HP + their own block actions?
- Should trinkets be able to interact with armor_points (e.g. a trinket that restores 1 armor at turn start)?

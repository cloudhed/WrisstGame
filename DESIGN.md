# Wrisst — Design Document

**What this file is:** the top-level description of what Wrisst is, what the core loop
is, and which systems actually exist today. It is the answer to "what am I building and
where is it at."

**What this file is not:** lore, worldbuilding, or writing rules. Those live elsewhere —
see [Where Everything Lives](#where-everything-lives) at the bottom.

Last verified against the codebase: 2026-07-31.

---

## 1. The Pitch

Wrisst is a **Godot 4.4 adult narrative RPG**. The player character is a human — the only
human in existence — who arrived through an unknown gateway with no memory of how. Every
other inhabitant is either **Monsterfolk** (sapient) or a **Creature** (feral). The setting
is low-fantasy with a frontier / Wild West flavor.

The genre frame is an **authored-encounter narrative RPG**. The writing, the art, and the
creature interactions *are* the product. Systems exist to pace access to that content, not
to replace it.

Design relatives: Teraurge (area gating), early CoC (flavor encounter saturation),
Disco Elysium (dialogue as gameplay), Darkest Dungeon (expedition budget), Morrowind
(soft gates, no invisible walls).

---

## 2. The Core Loop

> Leave town with a reason → encounter things at a cost → use consumables to extend the trip
> → find or earn something to bring back → return to town and exchange it → something new
> unlocks → leave with a new reason.

Every link is load-bearing. **The weakest link is currently "leave town with a reason"** —
that is where design effort should go first.

Klyftet is the home base and anchors the loop three ways:

- **Social anchor** — who knows you, who distrusts you, who needs you
- **Mechanical anchor** — rest, trade, progression, rumors, contracts
- **Moral anchor** — your reputation is measured here

---

## 3. Design Rules

These are decisions already made. Treat them as settled unless deliberately revisited.

| Rule | Detail |
|------|--------|
| **Combat is the cost of exploration, not the purpose** | Rewards: small öre, occasionally a trade good, sometimes nothing |
| **No XP, no levels** | Progression = narrative unlocks, reputation depth, world knowledge, equipment variety |
| **No hard map gates** | Use geography as funnel, NPC conversation as unlock, preparation cost as soft gate |
| **Consumables are an expedition loadout** | Not potions. Decided before departure. Three types: survival (field healing), encounter-altering (lures/repellents), gate-key (lamp, rope, diving kit) |
| **Flavor encounters outnumber combat variety** | Non-combat situational moments are the world's idle animation. Formula: surprising discoverable moment + simple choice + small consequence. 2–3 nodes is fine |
| **Town healing is two distinct things** | Bwavrek's hotbaths (cheap, fast, pure recovery) vs. Tavo-Pavo's inn (costs more, also advances time — buys clock control) |

### Currency tiers

- **öre** — comfort. Hotbath, inn, basic salves.
- **crowns** — access. Equipment, specialized consumables, NPC services.
- **drots** — legacy. 2–3 per arc. Never sold in a shop.

### Things to avoid

- Loot-table economy (teaches players to play for numbers, not experience)
- Hard mechanical map gates (a jRPG solution to a problem Wrisst doesn't have)
- Making combat the main event
- Healing that's too cheap (no expedition tension) or too punishing (miserable return trips)
- Fast travel before late game (removes the "world is big" feeling that makes returning meaningful)
- XP / leveling (wrong frame for this game's audience)

### The north star

> "You built a world and forgot to give the player a job in it. Fix the job.
> The world is already good."

When designing any new system, ask: *does this help reveal authored content at the right
pace, or does it distract from it? Does it close a link in the loop, or open a new island?*

---

## 4. Systems — What Exists Today

Verified against the codebase on 2026-07-31.

### Combat: equipment-driven tile deck

The player's equipped weapon / armor / trinkets each carry a `TileBundle`, and those
combine into the combat deck. Enemies can inject temporary tiles mid-fight.

| Piece | Status | Location |
|-------|--------|----------|
| `EquipableItem` with tile bundle | Built | [equipable_item.gd](Resources/Items/equipable_item.gd) |
| `TileBundle` resource | Built | [tile_bundle.gd](Resources/Tiles/TileBundles/tile_bundle.gd) |
| Equipment slots + swapping | Built | [gamestate.gd](Scripts/autoload/gamestate.gd) |
| Draw / discard piles per battle | Built | [pile_manager.gd](Scripts/autoload/pile_manager.gd) |
| Enemy deck modification (dud tiles) | Built | [add_player_dud_tiles_action.gd](Scripts/entities/enemies/runtime/actions/add_player_dud_tiles_action.gd) |
| Deck preview screen | Not built | — |
| Weapon/armor synergy bonuses | Not built | — |

### Dialog engine

Custom JSON-driven visual-novel system — not Dialogic. Parses JSON, drives portraits,
executes inline `@COMMAND` directives.

- Core: [Scripts/dialog/](Scripts/dialog/) — parser, flow manager, command executor,
  logic handler, line spawner, scene loader
- Content: [Narrative/DialogScenes/Locations/](Narrative/DialogScenes/Locations/) for
  world locations, `enemies/<id>/` for creature pre/post/loss dialog, `Characters/<name>/`
  for NPCs
- Commands include `@OPEN_BARTER`, flag setting, portrait control

### State, save, and progression

- **`GameState`** ([gamestate.gd](Scripts/autoload/gamestate.gd)) — single source of truth:
  player stats, inventory, currency, flags, NPC relationships
- **`SaveManager`** ([save_manager.gd](Scripts/autoload/save_manager.gd)) — one JSON file at
  `user://save_0.json`. Autosaves on leaving an encounter, on window close, and on
  escape-quit. Boot auto-continues.
- **Persistent health** — combat results write back to `GameState.player_stats`, so HP
  carries across the overworld as an expedition budget
- **Flags** — `set_flag` / `has_flag` / `clear_flag`, typed by category (`event`, `dialog`,
  `temp`, `sex`)

### Economy and town

- **Barter / shop** — [barter_screen.gd](Scenes/UI/Barter/barter_screen.gd) driven by
  `ShopInventory` resources. Reachable in game: [klyftet_ext_day.json:203](Narrative/DialogScenes/Locations/Klyftet/klyftet_ext_day.json#L203)
  opens [klyftet_market_shop.tres](Resources/Shops/Klyftet/klyftet_market_shop.tres).
- **Logbook** — [logbook_screen.gd](Scenes/UI/Logbook/logbook_screen.gd) +
  [logbook_data.gd](Scripts/logbook_data.gd). Entries are granted from dialog.

### Autoload roster

`Manager`, `Events`, `DebugPanel`, `Shaker`, `GameState`, `AbilitySystem`, `SceneManager`,
`DialogSceneSelector`, `PileManager`, `GameUI`, `MusicPlayer`, `SFXPlayer`,
`AmbiencePlayer`, `SaveManager`.

Architecture is singleton-heavy by design. `Events` is the global signal bus that keeps
major systems decoupled.

---

## 5. Known Structural Debt

Tracked properly in [ROADMAP.md](ROADMAP.md); listed here for context.

- **Flag and command names are bare strings.** A typo fails silently. A const registry
  would make these fail loud.
- **`Data/` is an empty directory tree.** A migration created it; dialog JSON never moved
  there. `Narrative/DialogScenes/` is the real home.
- **`Archive/phase1_candidates/`** holds 38 superseded files from the March migration.
- **Overworld movement is not gated while `GameUI` is open** — known since the March
  migration, still open.

---

## Where Everything Lives

| What | Where |
|------|-------|
| **This document** — game design, core loop, system status | `DESIGN.md` |
| **Current priorities and quest status** | [ROADMAP.md](ROADMAP.md) |
| **Lore, worldbuilding, writing style, bestiary examples** | `X ReadMe for LLMs/(ReadMe for LLMs) Wrisst Knowledge Database & Design plan 05-03-2026.txt` |
| **Quest structure** (1 main quest + 3 side quests) | [ROADMAP.md](ROADMAP.md#quest-structure) — the authority |
| **Klyftet story north star** — premise, dramatic question, return-and-depart engine | `X ReadMe for LLMs/Wrisst_Story_Planning_Document_Klyftet_Arc.txt` (its quest tables are obsolete) |
| **NPC / species / bestiary sheets** | `X ReadMe for LLMs/CharacterSheets/` |
| **Machine-loadable writing + architecture rules** | [.clinerules/](.clinerules/) |
| **LLM context index** | [CLAUDE.md](CLAUDE.md) |
| **Historical migration records** | [Tools/migration/](Tools/migration/) |

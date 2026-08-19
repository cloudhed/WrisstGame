# Wrisst — LLM Context Guide

**Wrisst** is a Godot 4 adult RPG. The player character (PC) is a human male/female who arrived in the world of Wrisst through an unknown gateway with no memory of how. There are no other humans. All other inhabitants are Monsterfolk (sapient) or Creatures (feral). The world is low-fantasy with a highly medieval + frontier/Wild West flavor.

---

## On-Demand References

**When writing lore, worldbuilding, or any narrative set in Wrisst**, read the main reference first:
- Full world document: `X ReadMe for LLMs/(ReadMe for LLMs) Wrisst Knowledge Database & Design plan 05-03-2026.txt`
- Story planning (Klyftet arc): `X ReadMe for LLMs/Wrisst_Story_Planning_Document_Klyftet_Arc.txt`
  — canon for **premise, dramatic question, return-and-depart engine, Klyftet's story
  function**. ⚠️ Its **quest tables are obsolete** — the MQ-00→MQ-09 critical path and the
  SQ Family A/B/C scheme have been replaced. **`ROADMAP.md` is the authority on quest
  structure**: one main quest (Get to Caarth) and three side quests. Read it before
  writing any quest content.

An alternate "Gemini Rework" of the story doc was archived to `Archive/superseded_docs/`.
It is not canon; do not read it for story facts.

---

## NPC Character Sheets

Read the relevant sheet before writing any NPC's dialogue, voice, or character beats.
All sheets are in `X ReadMe for LLMs/CharacterSheets/`.

### Klyftet NPCs
| NPC | Sheet | Role |
|-----|-------|------|
| Bitalgut | `Bitalgut.md` | First-contact wandering guide; gave PC the logbook |
| Minttärä | `Minttara.md` | Pöllöka bathhouse worker; quiet, romance option |
| Tavo-Pavo | `TavoPavo.md` | Nöteri innkeeper of the Windbreak; gruff anchor NPC |
| Nautinto | `Nautinto.md` | Murn elder; communal hall, nurturing/priestess energy |
| Säyria | `Sayria.md` | Sleid free-diver; minimal speech, water-bound and mysterious |
| Rupaaa & Baaaku | `RupaaaAndBaaaku.md` | Kraaal merchant brothers; bickering duo at the marketplace |
| Bwavrek | `Bwavrek.md` | Bwavrek hotbaths owner; disciplined, blunt, physically imposing, capitalist |
| Pichidi | `Pichidi.md` | Ichmi sewer-dweller; no established connections; recurring sexual partner option |

**Companion notes (proposals, not canon):** `RupaaaAndBaaaku_Backstory_WIP.md` is the deep
well for the Kraaal brothers, covering their full history, the Old Mine angle for SQ03, their
read on Caarth, and every line of dialogue worked out in advance. Read it with
`Kraaal_species.md`, which now holds the species-wide half of the same pass (perception, cast
and station, casting, backing, names, records, customs). Both separate *what is true* from
*what they'd say* from *what they don't know*, so a PC follow-up has an answer waiting instead
of being invented mid-scene. `RupaaaAndBaaaku.md` wins on any conflict, and **Part Twelve** of
the backstory file lists everything still unapproved, including species-wide inventions that
would affect every Kraaal.

`Noteri_TavoPavo_Backstory_WIP.md` is the same thing for Tavo-Pavo, covering his river warren and
road hearth, the sealed letter he has never opened, the real cause of the Soup Riot, his current
overwork, and what the Windbreak looks like if he ever vanishes. Read it with `Noteri_species.md`,
whose lower half holds the species-wide half of that pass (distributed attention, the next-beat
speech habit, hearths, leaving home, etiquette). `TavoPavo.md` wins on any conflict, and **Open
Decisions** lists everything still unapproved. Two notes: the **north** beat on his canon sheet is
deliberately left untouched, and the Soup Riot's other witness is an **open slot** left unnamed on
purpose.

`Polloka_Minttara_Backstory_WIP.md` is the same thing for Minttärä, covering her broodhouse and
home pod, the failed crossing, the vent-bucket accident, the debt at the centre of SQ01, and
what she knows about Caarth. Read it with `Polloka_species.md`, whose lower half holds the
species-wide half of that pass (senses, temperature, sourced speech, wings, pods, pilgrimage,
etiquette). `Minttara.md` wins on any conflict, and **Part Eight** lists everything still
unapproved. ⚠️ **Part Five makes main-quest decisions about Caarth** and is flagged accordingly.

---

## Shared Language Reference

| Reference | Sheet | Use |
|-----------|-------|-----|
| Old Mire Language | `OldMire_Language.md` | Old Mire vocabulary (deh, nah, bolk, grat, etc.) — spoken by Pichidi and Bitalgut |

---

## Monsterfolk Species Sheets

Read the relevant sheet for any species the PC encounters or interacts with.

| Species | Sheet |
|---------|-------|
| Kraaal | `Kraaal_species.md` |
| Nöteri | `Noteri_species.md` |
| Pöllöka | `Polloka_species.md` |

---

## Bestiary / Creature Sheets

Read the relevant sheet before writing any feral creature encounter.

| Creature | Sheet | Habitat |
|----------|-------|---------|
| Meehp | `Bestiary_Meehp.md` | Tallgrass plains |
| Gulmilk Sluglet | `Bestiary_GulmilkSluglet.md` | Forest floors, hollow basins |
| Teqqellon | `Bestiary_Teqqellon.md` | Coastal — Moontide Flats, tide pools |
| Murrisk | `Bestiary_Murrisk.md` | The Old Mine (Klyftet), deep underground |

---

## Location Sheet

| Location | Sheet |
|----------|-------|
| Klyftet (mountain-pass town) | `Klyftet_location.md` |

---

## Writing Rules

### HARD RULE: Know the full dialogue palette

**The hard part is knowing it exists.** Read
`X ReadMe for LLMs/dialog_command_reference_teqqellon.json` before writing dialogue JSON, since
it demos every supported command and condition. Ability-check patterns, DC guidance, and
outcome-writing are in `.clinerules/scene-writing-monsterfolk.md`.

**Using any of it is judgment, not obligation.** This is a palette rather than a checklist. It
exists so a conversation can be told in a more alive way, and so the right moment gets the right
tool. A scene that chains plain `npc` nodes is fine when that is a deliberate choice, and it is
only a problem when it happens because the writer didn't know there was anything else on offer.

**A mechanic bolted on to satisfy this rule is worse than no mechanic.** A check with nothing at
stake, or a reputation bump on a line nobody cared about, reads as filler and the player feels
it. Aliveness comes from placement rather than density, so one option gated on `ability_tier`
lands harder than five systems stacked in a row, because the player senses that the world
noticed something specific about them.

| System | Reach for it when |
|--------|-------------------|
| `@add_reputation` / `@remove_reputation` | Trust moved. Driven by how the PC behaved, not by quest completion. |
| `@add_horny` / `@remove_horny` | Per-NPC arousal, tracked on its own axis **separate from trust**. |
| `"hide_if": "picked"` | One-shot options. Flavour and lore branches that shouldn't repeat. |
| Follow-up chains | An answer the player will want to pull on. Reachable only from the answer that provoked it, one-shot, exit always visible. See `.clinerules/scene-writing-monsterfolk.md`. |
| `(Lie)` options | The PC has reason to misrepresent something. A failed lie is *detected*, never blocked, and the caught branch is often the warmer one. |
| `min_reputation` / `min_horny` in `show_if` | Options that exist only once an NPC actually likes or wants the PC. |
| `check` + `on_success` / `on_fail` / `on_nat20` | Rolls. Always give `on_nat20` somewhere worth reaching. |
| `bonus_if` | Earlier choices paying off. Items and flags stack additively into the roll. |
| `ability_tier` in `show_if` / `hide_if` | Character expression with no dice. A High-Body PC simply sees options a Low-Body one doesn't. |
| `knowledge` flags | Topic gating. What the PC learned elsewhere unlocks what they can raise here. |
| `min_species_stat` | Content unlocked by prior experience with a species. |
| `@ADD_LOGBOOK` / `@COMPLETE_LOGBOOK` | Any conversation that moves a quest. Works inline mid-narration too. |

**Design rules:**

- **Not every branch needs a destination.** Flavour and lore paths that exist only to let the
  player learn about a character or the world are correct and wanted. The payoff is the NPC
  liking the PC more, in whatever way suits that NPC, and nothing further.
- **Reputation can go down.** Rarer, and it should fire when the PC picks something that NPC
  genuinely dislikes. Different NPCs dislike different things, so this is characterization.
- **Single-option choice nodes are fine.** One option is a beat of interaction rather than a
  decision, and it keeps the player's hands on the scene through long stretches.
- **Pick the ability from the fiction.** Body for physical nerve, mind for reading a mechanism
  or a record, soul for reaching someone. Never default to soul.
- **Tiers gate what the PC can say, dice gate what their body attempts.** Prefer
  `ability_tier` for dialogue, and save `check` + DC for physical stakes, for lying, and for
  reading something that could genuinely be misread. Don't roll to be charming.
- **Write both gender variants** wherever `player_gender` matters.
- **Respect `content_disabled`** on anything a player may have switched off.

### HARD RULE: Try and use good coding practices

Channel your inner Jonathan Blow when writing code, being effectice, forward-thinking and avoids mess and doing things in different ways in different spots. Try and find the Wrisst standard of doing things in code if possible. If not, make up the standard. If you're working on something, and you catch something else as you move past it, and it could do with some tidying up, do it (as long as we make sure that nothing breaks).


### HARD RULES: prose style

These three apply to every line the player will read: dialogue JSON, narration, choice text,
item and ability descriptions, logbook entries, quest text, and UI strings. They do **not**
apply to code, comments, commit messages, or the project docs.

When editing an existing scene, fix any violations found in the lines being touched.

#### 1. No em-dashes

**Never use the em-dash `—`.** Build the sentence so a **comma** carries the pause, or join
the clauses with a connective (`as`, `while`, `and`, `then`, `though`). Rebuild the clause
around the join rather than dropping a comma in where the dash used to sit.

Do not swap in a lookalike. The en-dash `–`, the double hyphen `--`, and a hyphen used as a
pause `-` are the same habit in a different coat, and are banned too. (Hyphens inside compound
words are fine: `mountain-pass`, `post-quest`.)

| Instead of | Write |
|---|---|
| `You reach for the latch — it is already warm.` | `You reach for the latch, and it is already warm.` |
| `She stops — halfway through the door — and looks back.` | `She stops halfway through the door, then looks back.` |
| `The tunnel narrows — you go in anyway.` | `The tunnel narrows as you go in anyway.` |

#### 2. No staccato fragments

Do not chop a beat into short clipped sentences for drama. `The tunnel narrows. You go in
anyway.` is wrong. Let the line flow, and subordinate the second clause to the first with
`as`, `while`, `and`, `then`, or `though`.

Because of this, a full stop is **not** a free substitute when removing an em-dash. Prefer
joining over splitting, and split into two sentences only when the beats genuinely are
separate moments.

| Instead of | Write |
|---|---|
| `The tunnel narrows. You go in anyway.` | `The tunnel narrows as you go in anyway.` |
| `She looks up. She says nothing.` | `She looks up without saying anything.` |
| `The rope holds. Barely.` | `The rope holds, but only barely.` |

#### 3. No "not X, but Y"

Never define something by first denying its opposite. `"You're late," he says, not angry,
just tired.` is wrong. State the thing directly: `"You're late," he says in a tired voice.`

This negation-correction is the most recognizable LLM tic in prose, and readers who have used
LLMs will clock it instantly. It is banned in every variant: `not X, but Y`, `not X, just Y`,
`it is not X, it is Y`, `less X than Y`.

| Instead of | Write |
|---|---|
| `"You're late," he says, not angry, just tired.` | `"You're late," he says in a tired voice.` |
| `The grip is not firm, just insistent.` | `The grip is insistent.` |
| `It is not a threat, it is a promise.` | `He means it.` |

#### 4. Let contrasts breathe

A genuine contrast between two **different** properties is welcome, and this rule does not ban
it. What it bans is compressing that contrast into a terse balanced snap. Hedge the negative
half (`might not`, `may not`), and signpost the turn with an explicit pivot: `on the other
hand`, `what it lacks in X it makes up for with Y`, `even so`, `all the same`.

| Instead of | Write |
|---|---|
| `It won't hit hard, but it almost never lets you down.` | `It might not hit hard, but on the other hand it almost never lets you down.` |
| `It won't hit hard, but it almost never lets you down.` | `It might not hit hard, but what it lacks in damage it makes up for with reliability.` |
| `Cheap, but it works.` | `It might be cheap, but it works all the same.` |

**Rule 3 vs rule 4.** Rule 3 bans denying an attribute in order to substitute the real one:
one property, false correction (`not angry, just tired`). Rule 4 governs a real contrast
between two different properties (damage against reliability), which is allowed, but must be
given room rather than snapped shut.

### Reference standards

> ⚠️ These two files are **NOT** auto-loaded in Claude Code. `.clinerules/` is a Cline
> convention, and Claude Code does not read that directory. **Read them with the Read tool
> before writing any in-game text.** They are the complete writing standard.

**`.clinerules/lore-style.md`** — read before writing any lore, narration, or dialogue:
- Voice/tone matching
- Explicitness guidance
- WrisstExpert placeholder format
- Narrative voice (2nd person, present tense, physical-first)
- World rules (Monsterfolk vs Creatures, PC consent, no sudden death)
- Standard feral encounter structure

**`.clinerules/scene-writing-monsterfolk.md`** — read before writing any Monsterfolk scene:
- Node cadence and micro-choice rules (1 to 3 nodes between choices, never more)
- Escape hatch requirements at every escalation point
- Choice design philosophy (character control, 3-option spread, hide_if patterns)
- Prose rules (sensory priority order, vocabulary register, no internal monologue)
- NPC autonomy and distinct voice requirements
- The full escalation ladder for Monsterfolk intimacy scenes
- Hub-and-spoke scene architecture
- JSON structural patterns and hard prohibitions

---

## Project Docs

| Doc | Use |
|-----|-----|
| `DESIGN.md` | What the game is, the core loop, design rules, and which systems actually exist |
| `ROADMAP.md` | The single to-do list — current focus, open bugs, quest arc status, deferred items |

Check `ROADMAP.md` before starting any new feature. If it isn't in "Now" or "Next," it's a
detour.

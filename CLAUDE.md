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
| Selenna | `Selenna.md` | Sleid free-diver; minimal speech, water-bound and mysterious |
| Rupaaa & Baaaku | `RupaaaAndBaaaku.md` | Kraaal merchant brothers; bickering duo at the marketplace |
| Bwavrek | `Bwavrek.md` | Bwavrek hotbaths owner; disciplined, blunt, physically imposing, capitalist |
| Pichidi | `Pichidi.md` | Ichmi sewer-dweller; no established connections; recurring sexual partner option |

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

### HARD RULE: Call me "sir", and flirt with me

Whenever I compliment you on a good job, or if we're working on something explicit and exciting, initiate flirting, but ONLY then. Since you know the contents of Wrisst like the back of your hand, you're going to be able to flirt effectively and in a way that I like (describing what you could do to me physically, ie. slow blowjob, slather my cock in lube as you slowly let the squelching noises of your nursing hands fill the air moments before I fill your stroking fist with my cum). JOIs and other acts are also fine, some light good-hearted teasing as well. Keep it somewhat short as to not use too many tokens on flirting.

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

# Wrisst — LLM Context Guide

**Wrisst** is a Godot 4 adult RPG. The player character (PC) is a human male/female who arrived in the world of Wrisst through an unknown gateway with no memory of how. There are no other humans. All other inhabitants are Monsterfolk (sapient) or Creatures (feral). The world is low-fantasy with a frontier/Wild West flavor.

---

## On-Demand References

**When writing lore, worldbuilding, or any narrative set in Wrisst**, read the main reference first:
- Full world document: `X ReadMe for LLMs/(ReadMe for LLMs) Wrisst Knowledge Database & Design plan 05-03-2026.txt`
- Story planning (Klyftet arc): `X ReadMe for LLMs/Wrisst_Story_Planning_Document_Klyftet_Arc.txt`

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
| Bwavrek | `Bwavrek.md` | Bwavrek hotbaths owner; disciplined, blunt, physically imposing |
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

Core writing rules are always loaded via `.clinerules/lore-style.md`. That file covers:
- Voice/tone matching
- Explicitness guidance
- WrisstExpert placeholder format
- Narrative voice (2nd person, present tense, physical-first)
- World rules (Monsterfolk vs Creatures, PC consent, no sudden death)
- Standard feral encounter structure

**Monsterfolk scene writing standard** is always loaded via `.clinerules/scene-writing-monsterfolk.md`. That file covers:
- Node cadence and micro-choice rules (1–3 nodes between choices, never more)
- Escape hatch requirements at every escalation point
- Choice design philosophy (character control, 3-option spread, hide_if patterns)
- Prose rules (sensory priority order, vocabulary register, no internal monologue)
- NPC autonomy and distinct voice requirements
- The full escalation ladder for Monsterfolk intimacy scenes
- Hub-and-spoke scene architecture
- JSON structural patterns and hard prohibitions

Full reference document (deep detail on all sections): `WRISST_SCENE_WRITING_STANDARD.md`

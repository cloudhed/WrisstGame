# Wrisst — Roadmap

**What this file is:** the single to-do list. What's being worked on now, what's next,
what's deliberately deferred, and how far the planned quest arc actually is.

**Rule:** before starting any new feature, check it against the ordering below. If it isn't
in "Now" or "Next," it's a detour.

Last verified against the codebase: 2026-07-31.

---

## Current Focus — Close the MVP Loop

This ordering came out of a July 2026 design audit. The verdict was: stop building world
and toolchain, make the 20-minute loop playable and savable, then play it daily.

### ✅ Step 1 — Save / load (done 2026-07-13)

`SaveManager` autoload, one JSON at `user://save_0.json`, autosave on encounter exit /
window close / escape-quit, boot auto-continues. Verified with a headless round-trip test
(19 checks). See [DESIGN.md](DESIGN.md#state-save-and-progression).

### 🔜 Step 2 — Close the loop (current)

| # | Task | Status |
|---|------|--------|
| a | Persistent overworld HP verified end-to-end **by actually playing it** | Code is in place; play-verification outstanding |
| b | **MQ-00 "Ask around in Klyftet"** + **SQ01 The Pilgrimage** — use existing flag + logbook commands, no new quest engine | Not started. Tavo-Pavo has a portrait deck and character resource but no dialogue content |
| c | **Rupaaa & Baaaku shop** — sells salves + gate-key items, buys creature materials | Mechanism done. `@OPEN_BARTER` works and `klyftet_market_shop.tres` is reachable from Klyftet exterior. Remaining: make it *theirs*, and stock it to serve the loop |

**(b) is the critical path.** It is the smallest thing that gives the player a reason to
leave town, and the loop does not close without it.

The MVP loop is now: **MQ-00 sends you around Klyftet → you meet the three givers → each
hands you a side quest → each is a reason to leave town.** Three quests, three givers,
three destinations. Build MQ-00 and SQ01 first; SQ02 and SQ03 can follow once the shape
proves out in play.

### 🧹 Step 3 — Timeboxed cleanup (only after the loop is playable)

- Delete `Archive/phase1_candidates/` (38 superseded files)
- Delete the empty `Data/` directory tree
- Remove dead commented-out blocks
- One const registry for flag and command strings, so typos fail loud instead of silent
- Formally abandon the folder-migration plan (now at
  [Tools/migration/implementation_plan.md](Tools/migration/implementation_plan.md))

---

## Open Bugs / Loose Ends

| Item | Source | Status |
|------|--------|--------|
| Overworld movement is possible while `GameUI` is open — should be gated | March migration smoke test | Open |
| Flag and command names are bare strings; a typo fails silently | Step 3 above | Open |

---

## Quest Structure

> ⚠️ **This section supersedes the quest architecture in
> `X ReadMe for LLMs/Wrisst_Story_Planning_Document_Klyftet_Arc.txt`.** That doc's
> MQ-00→MQ-09 critical path and its SQ Family A/B/C scheme are **no longer the plan**. The
> story doc is still canon for its Level 0 material — premise, dramatic question, the
> return-and-depart engine, Klyftet's story function. Ignore its quest tables.

> **No quest IDs exist in code.** Progress is tracked by ad-hoc flags (`heard_where`,
> `hotbaths_entered_once`, `hotbaths_paid_shortrest`, …). Building these with flags +
> logbook commands rather than a quest engine is a deliberate choice — see
> [Explicitly Deferred](#explicitly-deferred).

ID convention below follows the notes: `SQ01-00` = side quest 01, opening node.

### Main quest — Get to Caarth

**There is exactly one main quest.** Everything else is a side quest.

| Node | Beat | Status |
|------|------|--------|
| MQ-00 | **Ask around in Klyftet** — seek help/direction toward Caarth | Not written |
| MQ-01+ | Onward from Klyftet | Not designed |

**Caarth is already seeded in the lore**, which the notes may or may not have intended:

- The **Library of Caarth** is where Minttärä was *supposed* to go on her Pöllöka
  pilgrimage. Rough tides rerouted her to Wrisst and she was shipped to Klyftet instead.
  Her sheet calls it *"an unfinished sentence in her life."*
- She *"may know more about something stirring in Caarth than she'll say."*
- Rupaaa & Baaaku *"may hold old trade records or coded messages tied to Bitalgut, Caarth,
  or the PC's arrival."*

So two of the three side-quest givers already have a latent thread to the main quest, and
SQ01 is literally about a derailed pilgrimage to Caarth. That is a strong spine — worth
leaning on rather than inventing new hooks.

### SQ01 — The Pilgrimage

**Giver:** Tavo-Pavo · **Subject:** Minttärä · **Location:** Hotbaths

Tavo-Pavo sends the PC to the Hotbaths to deliver goods to Minttärä "for reasons." She has
a problem.

**Working theory (refined 2026-08-04, still not locked):** Minttärä arrived in Klyftet
stranded and broke, and **Bwavrek** advanced her the passage, a replacement heat stone,
food, and her first nights of lodging. She has been working it off ever since. She can't
close her pilgrimage while the account is open.

**The premise turns on a number nobody has said.** Bwavrek's ledger is honest and always
has been. Minttärä is a trained record keeper who could read it in a minute, and in three
cycles she has never asked the total, because asking would turn the night he took her in
into a transaction. He has never volunteered it, because naming a figure to a worker who
hasn't asked is pressure, and he doesn't do that to people who are performing. So the PC's
job is **not an audit and there is no fraud**. It's getting a number spoken aloud between
two people who both consider asking to be beneath them.

**Open questions:**
- ~~Is she fleeing, or negotiating?~~ Negotiating. She will not leave an account unsettled.
- ~~What did she borrow for?~~ Passage, heat stone, food, and lodging on arrival.
- What are the solution branches, and what does each cost?
- Does the debt ever get an on-screen figure, or does it stay unquantified and get settled
  some other way?

**Existing material:** Minttärä intro dialogue written; sheets exist for Minttärä,
Tavo-Pavo, and Bwavrek. Her pilgrimage backstory and the Bwavrek-took-her-in detail are
already canon in the knowledge database — this quest is consistent with it.
`Polloka_Minttara_Backstory_WIP.md` holds her full history, the vent-bucket accident, and
her Caarth knowledge as proposals. **Its Part Five makes MQ decisions about Caarth and
needs a ruling before use.**

### SQ02 — The Disturbed Lake

**Giver:** Säyria · **Location:** Lake Silv shoreline

*Sjölfisk* are disappearing — numbers dropping. Serious, because they're one of the
village's most important resources.

**Shape:**
1. Investigate — fishing, diving (badly), piecing it together
2. Find traces leading **up the cliffs** beside the lake
3. Find a strange Monsterfolk: an **alchemist**, bad at communicating orally
4. Realize they've been brewing something to **give themselves wings**. Repeated failures,
   dumped experiments, which trickled into the lake
5. The reveal: **look up** — sjölfisk with wings, flying high into the sky. (Reachable
   earlier via clues for observant players)
6. Stop them somehow → report to Säyria

**Outcomes:** kill / help / something else — not decided. Either the lake reverts, or
Säyria adapts and takes up flyfishing or bow-and-arrow.

**Open questions:**
- What "stopping them" actually means mechanically, and how many endings
- Is the alchemist a new species, or an existing one?

**Existing material:** Säyria has a full sheet — Sleid, free-diver, speaks in slow
measures, treats the lake with reverence others read as superstition. She was renamed
from Selenna and redesigned as a crustacean; her sheet and the master database carry the
new body, and Sleid is unchanged as the species name. *Sjölfisk* are
already canon: *"soft-bodied creatures that glow faintly in the deep water,"* which
Säyria free-dives for and sells sparingly. The old story doc also had a random encounter
**"Silv Surface Lights"** (shoreline, night, eerie) — that's a ready-made clue delivery
vector for the winged-fisk reveal.

### SQ03 — The Closed Mine

**Giver:** Rupaaa & Baaaku · **Location:** The Old Mine

They need someone to sneak into the abandoned mine and look for things they can sell.
**A guard is posted outside during the day** — so this is a time-of-day gated approach.

**Status:** opening premise only. The rest is unwritten — notes pending.

**Existing material:** strongest of the three. The Old Mine already has four scene files
(`Oldmine01Entrance` → `Oldmine04`) plus dialogue JSON. The **Murrisk** bestiary sheet
lists its habitat as *"The Old Mine (Klyftet), deep underground"* — so the mine's creature
encounter already exists and has somewhere to belong.

---

## Content Inventory

What's actually written and playable today.

**Locations with dialogue:** Klyftet exterior, Windbreak Inn, Klyftet Sewers, Old Mine,
Temple Ruins, Kemen Woods, Old Tree

**NPCs with written content:** Bitalgut (intro), Minttärä (intro)

**NPCs with sheets + art but no dialogue:** Tavo-Pavo, Bwavrek, Nautinto, Säyria,
Rupaaa & Baaaku, Pichidi

**Creatures with full pre/post/loss dialogue:** Meehp, Teqqellon, Murrisk, Shenche,
plus a default-creature fallback set

---

## Parked Designs

Designed enough not to lose, deliberately **not** scheduled. Both came out of the August 2026
Teraurge comparison pass.

### The Klyftet talk network

Sex and other notable PC behaviour currently terminates in a flag. It should become something
the town says back to the PC.

**The design problem is that Klyftet has no widely-connected partner.** Pichidi has no
established connections at all, and the rest are known to a handful of people each. So the
network cannot hang off *who the PC slept with*. It has to hang off **hubs** — the NPCs whose
job is hearing things:

| Hub | Hears about | Why it's plausible |
|-----|-------------|--------------------|
| **Tavo-Pavo** | Anyone who drinks or lodges at the Windbreak | Innkeeper. Distributed attention is already his species trait |
| **Rupaaa & Baaaku** | Anything that moves through the marketplace | Two merchants who bicker for a living and already trade in records |
| **Bwavrek** | Minttärä specifically | They share a workplace and he holds her account. This one is nearly free |

**Rules if it gets built:**
- A hub reacts in character rather than reporting neutrally. Tavo-Pavo's read on the same news is not the brothers' read.
- Reaching a hub takes a plausible route. Bwavrek noticing something about his own worker is free; the marketplace knowing what happened in the sewers is not.
- The PC gets a way to ask for discretion, and it should sometimes be honoured and sometimes not, depending on the hub.
- Nothing here should gate quest progress. It is texture and reputation, and that is the whole point.

**Prerequisite:** at least two NPCs with written intimate content and a reason to be talked
about. Not true today.

### ~~`asked_node` dialogue condition~~ — rejected 2026-08-11

Considered, then rejected on inspection. **Not a "later" item, a "no" item.**

Teraurge's `showif.index_is` is its single most common condition, but it does not mean "the
player asked this earlier." It means **"which of this block's alternate text lines is currently
on screen."** Their authoring format packs several NPC lines and *one shared option list* into a
block, and `index_is` is the key that decompresses it.

Our format has no such compression: every `choice` node owns its own `options` array (39 of them
in `sewers_day.json`, each with a private list). A follow-up is therefore made unreachable by
simply living on the node the answer points to. The graph already says it.

The one case that does need a condition is a **hub** option gated on knowledge acquired
elsewhere, and there a `knowledge` flag is correct, since it has to survive leaving and
returning. A conversation-scoped condition would be actively wrong for it.

Cost of our approach versus theirs: one extra choice node per link. Benefit: no condition to get
wrong. Accepted trade.

---

## Explicitly Deferred

Do not start these until the loop has been played daily for a couple of weeks.

- Architecture refactors
- Combat expansions (deck preview screen, weapon/armor synergy)
- New content beyond what MQ-00 and SQ01 need
- Unit tests
- Fast travel
- SQ02 and SQ03 build-out (designed, but not until SQ01 proves the shape in play)
- Anything past Klyftet on the road to Caarth
- A formal quest engine with tracked quest objects — flags + logbook are enough for three
  side quests and one main thread
- The Klyftet talk network (see [Parked Designs](#parked-designs))
- Reworking the knowledge database doc — acknowledged as worth doing eventually, since
  parts have been superseded, but the bestiary examples and writing rules are good as-is

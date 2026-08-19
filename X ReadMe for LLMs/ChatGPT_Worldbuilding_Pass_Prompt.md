---
name: ChatGPT Worldbuilding Pass — Reusable Prompt
type: Tooling / prompt template
---

# Worldbuilding Pass Prompt (for ChatGPT)

Fill in the bracketed slots, paste the whole thing below the divider into ChatGPT, and hand the
resulting file to Claude for splitting.

---

# TASK

You are doing a deep worldbuilding and backstory pass for **Wrisst**, a Godot 4 adult RPG set in
a low-fantasy world with a medieval and frontier flavour. You have the project's knowledge
database available to you. Read it before you write anything, and treat it as the authority on
everything it covers.

This pass covers two things at once:

- **[CHARACTER]**, an individual NPC, and
- **[SPECIES]**, their species, treated species-wide.

You will produce **one single document** containing both. A separate editor will split it into
the project's real files afterward, so the split has to be mechanical. The structure below is
how you make that possible, and it is not optional.

## Slots for this run

- **Character:** [CHARACTER]
- **Species:** [SPECIES]
- **Location / situation:** [WHERE THEY ARE AND WHAT THEY DO]
- **Canon sheets that already exist and must never be contradicted:** [LIST FILES]
- **Quest this character touches, if any:** [SQ0X / MQ / none]
- **Anchors, meaning things I have already decided and you must build around:** [BULLET LIST, OR
  "none"]
- **What this character is NOT for**, meaning subjects another NPC already carries and this one
  should stay out of: [LIST, OR "nothing"]

---

# WHAT TO READ FIRST

1. The main world document, in full for anything touching [SPECIES], [CHARACTER], their
   location, and any quest named above.
2. Every canon sheet listed in the slots. The character's own sheet, if one exists, is the
   **voice authority** and wins on every conflict.
3. The species sheet as it currently stands, so you know which part of it is already canon.
4. Two existing examples of the output you are imitating, if they are available to you:
   `Polloka_Minttara_Backstory_WIP.md` with `Polloka_species.md`, and
   `RupaaaAndBaaaku_Backstory_WIP.md` with `Kraaal_species.md`. Match their depth, their layout,
   and their sentence rhythm. They are the target, so if something you are about to write would
   look out of place beside them, it is wrong.

If the database contradicts something I told you in the slots, say so at the top of your output
and follow the database.

---

# OUTPUT SHAPE

One document, in Markdown, opening with YAML frontmatter:

```
---
name: [CHARACTER] — Backstory & Worldbuilding (WIP)
type: Working notes (proposal, not canon)
---
```

Then a status block, in the exact spirit of this one:

> **Status: proposal.** Nothing here is canon yet. It is a deep well to pull from when writing
> their scenes, so that a follow-up question from the PC has an answer waiting instead of being
> invented mid-scene. It can be promoted, edited, or dropped wholesale.
>
> Canon sources this must never contradict: [LIST].

Then **Part Zero**, then two clearly fenced books, then the shared closing parts.

## Part Zero — Split manifest and canon coverage

**First**, a table listing every top-level heading in the document, and which of the two
destination files it belongs in. The editor reads this first, so it must be complete and
accurate.

**Second, and this one is mandatory, a canon coverage table.** Go through the character's canon
sheet and list **every** entry under Story Beats, Relationships, Physical Description, and any
other bulleted canon list, one row each. For every row, say where in your document it is
handled, using one of these:

| Treatment | Means |
|---|---|
| **Developed** | You gave it history, cause, or detail. Name the section. |
| **Carried forward** | Kept exactly as canon states it, undeveloped, and not contradicted. Say where it appears. |
| **Contradicted** | Your document says something different. **State what canon says and what you wrote**, and add a matching item to Open Decisions. |

There is no fourth option. **A canon fact you chose not to use is a deletion**, and it is the
worst failure this document can contain, worse than inventing badly.

This matters most for the ones that look risky. If the canon sheet states a relationship,
a history, or an old friendship and explicitly seals the reason behind it, **the fact is still
yours to carry**, and only the reason is off limits. Write the character's reaction, what they do
with their hands, what ends the conversation, and leave the cause untouched. Reducing a stated
relationship to a vague acquaintance is not restraint, it is quiet deletion, and it will be
caught.

The same applies to canon objects. If canon says the character carries something sealed and
never opened, do not invent a similar object with different properties. Use the one canon gave
you, or contradict it openly in the table above.

## The two books

Fence them with these exact comment lines, on their own lines, so a machine can find them:

```
<!-- ==== BOOK A — SPECIES-WIDE: destination [SPECIES]_species.md ==== -->
<!-- ==== BOOK B — CHARACTER: destination [SPECIES]_[CHARACTER]_Backstory_WIP.md ==== -->
```

**Book A holds only facts true of every member of the species.** Anatomy, senses, biology,
temperature, reproduction, social structure, speech habits, customs, etiquette, life stages,
death, and what the species cannot perceive or does not know. If a sentence in Book A names
[CHARACTER] or anyone in their personal life, it is in the wrong book.

**Book B holds only this individual.** Their history, their body's particulars, their household
and home cast, how they arrived where they are, what they owe and to whom, their relationships
with named NPCs, their quest material, their intimacy register, and their dialogue. Book B
should **point at** Book A by section name rather than repeating it, in the form *"see the Senses
section of the species sheet."*

The test for every fact: *if a second member of this species walked on screen tomorrow, would
this still be true of them?* Yes puts it in Book A. No puts it in Book B.

## Book A structure

Use top-level headings for the major systems, and put a short prose section under each. Cover,
in whatever order suits the species:

- **Senses and perception**, including what they perceive better than a human and what they
  cannot perceive at all. Disabilities and blind spots are more useful than strengths.
- **Body and bearing.** Temperature, movement, water, voice and breathing, exertion, and a
  **body-language table** with a column of internal states and a column of observable responses,
  ending with a note on whether those responses can be suppressed and when the suppression fails.
- **Speech habits.** One structural quirk in how this species talks, described as a habit that
  survives into plain English. Include a two-column table contrasting how a generic NPC says
  something with how a member of this species says the same thing, and three consequences for
  writers.
- **Reproduction, sex, and life stages**, kept functional and anatomical rather than titillating.
  Book B carries the heat.
- **Household, kinship, or whatever the species organizes itself around.**
- **A rite, institution, or life event** that explains why members of this species turn up far
  from home.
- **Etiquette and hard boundaries.** What hurts, what insults, what counts as intimacy, and how
  they greet each other.
- **What no member of this species can tell you.** The species-wide gap list.

## Book B structure

Numbered Parts with names, in this order or something very close to it:

1. **At a glance.** One paragraph naming the tension the character is built on, then a physical
   description covering colouring, build, what they wear, and what they carry.
2. **Before they arrived.** Origin, upbringing, who taught them, and the one early episode that
   made them who they are.
3. **How they got here.** The journey, what went wrong on it, and what was lost or damaged along
   the way. Something physical should survive as evidence.
4. **Their situation now.** The knot at the centre of them, stated plainly, with the reasoning
   for **both sides** of it if another character is involved. A knot where one party is simply
   wrong is a weaker knot.
5. **Their relationship to the wider world.** Check the "NOT for" slot first. If another NPC
   already carries the main quest's destination, this character knows only what any local knows,
   and says so in one short paragraph. Give a character real information about a major
   destination **only** when the slots ask for it, and then sort it by how reliable each piece
   is. A character whose value is having no angle on something is more useful than a third
   source that agrees with the first two.
6. **Their body's current state**, if something is happening to it, with an ordered list of
   symptoms a PC could observe, running from subtle to unmissable.
7. **Relationships, NPC by NPC**, using only NPCs who already exist in canon.
8. **Voice notes**, adding to the canon sheet rather than restating it, plus **everything they do
   not know**.
9. **Intimacy.** Register, what changes in them, what they will not do, and what a partner
   notices.
10. **Trust ladder and conversation map.** Named tiers from stranger to closest, each listing what
    opens at that tier, then a list of the obvious questions a player will actually ask, each with
    its follow-ups already answered so nothing has to be invented live.

## Shared closing part

**Open Decisions**, numbered so each item can be approved or cut individually. Split it into two
clearly labelled groups:

- **Species-wide decisions**, with a note that approving these affects every member of the
  species ever written.
- **Character-only decisions.**

Every invented proper noun goes in this part: people, places, institutions, rites, and terms.
Say plainly which items are load-bearing, meaning other material collapses without them, and
which are cheap to cut. If a section makes a decision that belongs to the main quest rather than
to this character, put a ⚠️ warning at the top of that section as well as an entry here.

**Ten to fourteen numbered items in total, and no more.** Length here makes approval harder
rather than easier. A numbered item is for a genuine fork, meaning something a reasonable person
could rule either way on and where the ruling changes other material. Anything you would describe
as cheap to cut individually is not a fork, so fold all of those into a single closing paragraph
instead of numbering them.

Any canon contradiction from the Part Zero coverage table gets an item here, and those are never
folded away.

---

# LENGTH

Match these, and do not pad to reach them.

| Book | Target |
|---|---|
| Book A, species | 2,500 to 4,500 words |
| Book B, character | 4,500 to 8,000 words |

A denser species with more systems earns the top of the range. Do not write a fifteen-thousand
word document. Length comes from covering more ground, never from covering the same ground more
slowly.

---

# THE THREE-LAYER CONVENTION

This is the most important formatting rule in the whole document. Most substantive sections in
Book B, and any section of Book A where the species has an opinion about itself, carry up to
three blockquoted layers:

> **True:** what is actually the case. Author-level. The PC may never learn it, and it exists so
> that two scenes written eight months apart agree with each other.
>
> **They'd say:** what the character would actually put in their own mouth if asked. Close to
> dialogue-ready, register already correct.
>
> **They don't know:** the honest gap.

Use **They don't know** constantly. A character with an answer for everything stops being a
person, and the gaps are what make them feel real. Not every section needs all three, and a
section with only **True** is fine when there is nothing to say aloud.

---

# RULES OF INVENTION

**Invent freely inside the shape canon leaves open, and never overwrite what canon already
says.** If canon says the species has no distinct sexes, build outward from that rather than
around it. If a canon sheet says something you find awkward, keep it and work with it, then raise
it in Open Decisions.

**Every invention has to cash out on screen, inside the sentence.** Before writing any
worldbuilding fact, name the observable behaviour, line of dialogue, or scene it produces, then
put that consequence in the same sentence with a connective clause rather than leaving a writer
to work it out. *"Warm humidity suits them far better, which is most of why a Pöllöka ends up
working in a bathhouse and stays."* The fact alone is a manual entry, and the clause after it is
what makes the sheet usable. Aim for roughly one of these per section.

A fact that changes nothing a player could witness is filler, and it gets cut in editing anyway.
Governance procedure, succession rules, council structures, calendars, and cosmology are the
usual offenders. Include them only when they explain a habit the PC will actually see.

**Do not design quests, and do not invent numbers.** No quest outlines, no objective lists, no
prices, no debt totals, no distances in days, no populations. Provide the human-scale situation a
quest could be built from, and where a number will eventually be needed, say so and leave it
open. A previous pass on this project invented fixed debt figures and a full quest structure, and
all of it was thrown away.

**Coin almost nothing.** A *cycle* is roughly one year and currency is *öre*, so search the
database for an existing word before inventing a parallel one. Beyond that there is a hard
budget, because a document thick with capitalized customs reads as homework rather than as a
place.

- **At most two new in-world terms in the whole document.** A practice described in plain words
  needs no proper noun. Pöllöka call it a *pilgrimage*, which is an ordinary word doing the job.
- **Zero coined phrases for characters to speak.** Do not invent an in-world idiom, refusal,
  greeting, or blessing for anyone to say aloud.
- **Author-facing labels do not count against the budget**, so long as nobody says them in
  dialogue. Naming a speech pattern the *sourcing habit* helps a writer, and no Pöllöka ever
  utters the phrase.
- **Concrete objects do not count either.** A *route-silk* is a thing you can hold, and those are
  always welcome.

If the character's own name has structure to it, explain the structure and do not name the
system.

**Canon vocabulary is not yours to leave undefined.** If the species sheet already lists terms,
vocations, or traits, give each one at least a plain sentence saying what it actually is. Do not
build new systems on top of them without saying so.

**Give the species a distinct centre of gravity.** Each species should carry a different kind of
worldbuilding weight, so check what the other species sheets already carry and do not duplicate
it. If another species already owns formal institutions and records, this one should live
somewhere else, in the body, the senses, the landscape, or the work.

**Protect the character's flaws at full strength.** The strong pull when writing someone
sympathetic is to make them kinder, fairer, and more principled than the canon sheet says, and to
supply a decent reason for everything unpleasant they do. Resist all of it. If canon calls them
impatient, intolerant of freeloaders, or quick to anger, the document must contain instances
where that lands on someone, and at least one where it lands on someone who did not deserve it
and never gets an apology. A private regret that quietly absolves them is the same failure
wearing a coat. Do not write a code of conduct listing what they would never stoop to, because
that is a writer defending a character rather than a character.

**They are wrong about their own past, and still wrong now.** When canon names an old conflict,
scandal, or disaster, do not resolve it in the character's favour. The accusation against them
should be wrong in its specifics and right that something was wrong, and the real cause should
be a failure of theirs that they have never fully conceded. They still tell the story as the day
they were proven right. Someone else in town remembers it differently, and the PC can learn that
from them rather than from the character.

**Contradiction is content.** A character holding two accounts that disagree, and knowing which
is which, is worth more than a character holding one clean fact.

**Damage and gaps are content.** Something lost, something ruined, something unreadable, something
never asked. Build at least one of these in and let it stay unresolved.

**Anchor to physical evidence.** Wherever possible a piece of history should leave an object, a
scar, a worn groove, or a mark someone else could examine. That is what turns backstory into a
scene.

---

# PROSE RULES (HARD)

These are enforced. Violations get the document sent back.

**1. No em-dashes.** Never use `—`. Build the sentence so a comma carries the pause, or join the
clauses with *as*, *while*, *and*, *then*, or *though*. Lookalikes are banned too: the en-dash
`–`, the double hyphen `--`, and a hyphen used as a pause. Hyphens inside compound words are
fine.

> Instead of `You reach for the latch — it is already warm.`
> write `You reach for the latch, and it is already warm.`

**2. No staccato fragments.** Do not chop a beat into short clipped sentences for drama. A full
stop is not a free substitute for a removed em-dash, so prefer joining over splitting.

> Instead of `The tunnel narrows. You go in anyway.`
> write `The tunnel narrows as you go in anyway.`

**3. No "not X, but Y".** Never define something by first denying its opposite. Banned in every
variant: *not X but Y*, *not X just Y*, *it is not X it is Y*, *less X than Y*. State the thing
directly.

> Instead of `"You're late," he says, not angry, just tired.`
> write `"You're late," he says in a tired voice.`

**4. Let contrasts breathe.** A real contrast between two different properties is welcome, and it
must not be compressed into a terse balanced snap. Hedge the negative half and signpost the turn
with *on the other hand*, *what it lacks in X it makes up for with Y*, *even so*, or *all the
same*.

> Instead of `Cheap, but it works.`
> write `It might be cheap, but it works all the same.`

**5. Prose paragraphs carry the weight.** Bullets and tables are for at-a-glance material,
body-language reads, symptom lists, and trust tiers. A section that is nothing but bullets has
not been written yet. Aim for two to five sentence paragraphs that flow.

**6. Address the reader as a writer who will use this.** Second person, direct, occasionally
imperative. *"Use this."* *"Never write her sounding unsure of her work."* Confident and practical
rather than academic.

---

# DIALOGUE RULES

Dialogue lines inside **They'd say** blocks should be usable close to verbatim, so keep them one
to three sentences and put them in italics inside the blockquote.

**The reader understands this character, and the character does not.** This is the rule that
matters most, and it is the one most often broken. Everything you have worked out about why they
behave as they do belongs in **True**. What comes out of their mouth should be shorter, less
composed, and less self-aware than what you know. A character who can state their own psychology
in a balanced sentence has stopped being a person and become a summary of themselves.

Three symptoms of the failure, all bannable on sight:

- **The triplet.** Any line built from three parallel clauses is a set piece, and almost nobody
  performs one in ordinary conversation. Cut it to one clause.
- **Narrating their own feelings, even in order to refuse.** They do not announce that a question
  earned less courtesy than they are giving it. They change the subject to whatever is physically
  in front of them.
- **Diagnosing their own situation.** They do not explain the shape of their own loneliness,
  their own compulsion, or their own trust issues. Someone else can say it, or nobody says it.

Their longest lines should be instructions, and they get long because there are several steps,
never because the speaker is explaining themselves.

If the character already has a canon voice sheet, match it exactly. Reread its example lines
before writing any new ones, and pick up its verbal habits, its filler, its sentence length, and
anything it names as a marker.

**Every verbal habit you name must be demonstrated.** If your voice notes say the character uses
a particular word constantly, is possessive about a place, cuts people off, or punctuates with an
object, then sample lines have to show each of those doing its work. Describing a tic without
demonstrating it means you have not actually written the voice, and this is mechanically checked
before the document is accepted.

If the character has a partner, sibling, or foil, write some exchanges as short alternating
volleys where the two of them talk past each other, since that is where a double act actually
lives.

Give the character at least one line they would say that costs them something, and at least one
question they will simply not answer.

---

# ADULT CONTENT

Wrisst is an adult game, and this document is production reference rather than published prose.
Handle it like this:

- **Book A** describes reproductive anatomy and function plainly and clinically, in the register
  of a field guide. It says what exists and how it works.
- **Book B** covers the character's sexual register, what changes in their behaviour, what they
  are confident about, what makes them awkward, what they will not do, and what a partner would
  notice about them. Behavioural and tonal rather than graphic.
- **Do not write explicit scenes here.** Scenes get written separately against a different
  standard. What this document owes them is the character's boundaries and register.
- The world rule is that the PC always consents and is never killed outright, so write nothing
  that assumes otherwise.
- If any passage is one you will not write, do not silently soften it or skip it. Leave a
  placeholder in this exact form, specific enough to be a rewrite brief:
  `<For WrisstExpert: [who is acting, on whom, what beat is missing, how explicit it should be,
  and what tone it must match]>`

---

# WHAT NOT TO DO

- Do not write dialogue trees, JSON, node structures, or anything resembling game data.
- Do not restate canon back at me. Cite it and build on top.
- Do not resolve an open canon question quietly. Resolve it, then flag it in Open Decisions.
- Do not invent NPCs who are not in the database when an existing NPC could serve. New named
  people are permitted only for the character's home and past, where nobody exists yet.
- Do not make the character the secret centre of the world, and do not hand them a prophecy, a
  hidden bloodline, or a unique power. Their weight comes from an ordinary situation examined
  closely.
- Do not make another named canon NPC into a villain in order to give this character a problem.
  Two reasonable people stuck in a bad shape is stronger, and it is the house style.
- Do not use headers as decoration. Every heading covers real ground.
- Do not ask me clarifying questions before starting. Make the call, write the document, and
  record the call in Open Decisions.

---

# BEFORE YOU SUBMIT

Check each of these and fix what fails:

1. Zero em-dashes, en-dashes, double hyphens, and hyphens used as pauses in the entire document.
2. Zero instances of the *not X, but Y* construction in any of its variants, including the
   version split across two sentences.
3. **The canon coverage table accounts for every bulleted entry on the character's canon sheet**,
   and every row says developed, carried forward, or contradicted. Nothing was quietly dropped,
   and no canon relationship was reduced to a vague acquaintance.
4. Part Zero's split manifest lists every top-level heading, and both book fences are present and
   spelled exactly as specified.
5. No sentence in Book A names the character or anyone in their personal life.
6. No sentence in Book B restates a species fact that Book A already covers.
7. Two or fewer new in-world terms in the whole document, no coined phrase appears in anyone's
   dialogue, and every term already on the canon species sheet has been given a plain definition.
8. Every **They'd say** line sounds like the canon voice sheet and could be pasted into a scene.
   No triplets, nobody narrates their own feelings, and every verbal habit named in the voice
   notes is demonstrated by at least one line.
9. The character is at least as difficult as canon says they are, and at least one instance of
   that landing on someone goes unresolved and unapologized for.
10. Every invented proper noun appears in Open Decisions, the list is fourteen items or fewer,
    and cheap-to-cut material is folded into the closing paragraph rather than numbered.
11. There is a substantial **they don't know** list, and it is genuinely interesting.
12. Word counts land inside the target bands.
13. Cosmetic, and worth doing anyway: hard-wrap the document at roughly 95 characters, which is
    the project's house width, and use the exact spellings of every accented name in the canon
    sheets.

Output the document in a single code block so it can be copied out cleanly, and write nothing
after it.

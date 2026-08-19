---
name: ChatGPT Revision Pass — Reusable Prompt
type: Tooling / prompt template
---

# Revision Pass Prompt (for ChatGPT)

Companion to `ChatGPT_Worldbuilding_Pass_Prompt.md`. Use it in the same chat, after the first
draft, to fix specific sections without triggering a rewrite. The generic frame stays the same
every time. Swap out **THE EDIT LIST** for each run.

The version below is filled in for the Tavo-Pavo draft.

---

# TASK

You wrote a worldbuilding and backstory document for **Tavo-Pavo** and the **Nöteri**. It is
mostly right. This is a targeted revision, and it is **not** a rewrite.

## The rule that governs everything below

**Do not regenerate the document.** Most of it is approved and any change to an approved section
is a regression, even if you think the new version is better. Change only what the edit list
names, and leave every other word exactly as it stands.

## What is approved and must not be touched

These landed and are now fixed points. Later edits must stay consistent with them rather than
adjusting them:

- The road-hearth rupture and its reasoning on both sides.
- The apron: the caravan cook-tent panel, the inner seam, and the threshold it marks in Part
  Nine.
- The broken ear, the caravan's departure, and the fair account they left.
- Hearing his own full name inside the split-howl twice.
- The trust ladder tier names, especially **Inside the apron**.
- The conversation map's structure and the follow-up-behind-every-question approach.
- Book A's centre of gravity: distributed attention across several bodies, and its blind spots.
- The body-language table.
- The ordered symptom list in Part Six.
- The key-copies gap in Part Eight.

## Output format

Return, in this order, and nothing else:

1. **A change manifest.** A table with one row per edit, giving the heading affected, the action
   (`replace`, `insert`, `delete`, or `renumber`), and one line on what changed.
2. **The replacement sections themselves.** Each under its exact original heading, marked
   `<!-- REPLACES: [exact original heading] -->` or `<!-- NEW SECTION, insert after: [heading]
   -->` or `<!-- DELETE: [heading] -->`.

Give the **complete** text of every section you touch, so it can be pasted straight over the
original. Do not give diffs, do not use ellipses, and do not summarize unchanged paragraphs. Do
not reproduce any section you did not change.

**Do not expand.** Each replacement should be about the length of the section it replaces, or
shorter. New length is only justified where the edit list explicitly asks for new material.

## Prose rules still apply

No em-dashes and no lookalikes, no en-dashes, no double hyphens, and no hyphens used as a pause.
No staccato fragments, and joining beats over splitting them. No *not X, but Y* in any variant,
including the version split across two sentences (*"The task does not decide who was right. It
shows whether..."*). Let real contrasts breathe with an explicit pivot.

Use the exact spellings **Nöteri**, **Minttärä**, **Pöllöka**, **Bwavrek**, **sjölfisk**, and
**öre**.

---

# THE EDIT LIST

## 1. Bitalgut. Restore the canon relationship. (Hard fix.)

You wrote him as recognizing the name from caravan routes with no direct account. **Canon states
flatly that Tavo-Pavo and Bitalgut are very old friends, and that Tavo knows him better than
almost anyone alive.** Deleting that is not restraint, and it has to be reversed.

Canon also settles how to write it, so follow this rather than inventing:

- The *why* is sealed and **stays** sealed. Do not invent the history. Do not hint at its
  content.
- If the name comes up, something crosses his face that he shuts down immediately, and then he
  finds something to do with his hands.
- He would rather not say the name aloud, and he would rather not hear it. He can live in a town
  where it occasionally surfaces only because he knows nobody will ask him why.
- He will not be asked, and he knows he won't be. That is the arrangement.

**Rewrite the Bitalgut subsection of Part Five** into this, and it belongs in **Part Seven,
Relationships**, not in the wider-world part. Give it the reaction, what he does with his hands,
what happens to the room, and what he says to end it, which should be short and should not be
about Bitalgut.

**Remove** "he does not know whether Bitalgut matters to his past" from Part Eight. Replace it
with the honest gap, which is the PC's: nobody in Klyftet knows what is between them, and Tavo
knows exactly and will not say.

Add a trust-ladder consequence: even at **Inside the apron**, this does not open. It is the one
thing above the top tier.

## 2. The letter is sealed and has never been opened. (Ruling.)

Canon gives him something sealed and old from his past that has never been opened, and your
water-damaged, partly-read version quietly replaced it. The sealed version is now the ruling, and
it is the same object.

Rewrite so that:

- A former hearth-mate's letter reached him after the separation. **He has never opened it.**
- He does not know whether it is an apology, an accusation, an explanation, or a note about the
  weather. **This is now one of the most important things he does not know**, and it stacks with
  his refusal to name who spoke the separation, since the letter might tell him and he has chosen
  not to find out.
- It is sewn into the apron seam. He has carried it against his body for years without reading
  it, which he would describe, if pressed, as never having got round to it.
- Give one physical detail of its current state after years inside a working apron, and let the
  state itself raise the question of whether it is still readable at all.

**Sections to update:** the apron paragraph in Part One, the end of Part Two, the unknowns list
in Part Eight, the top tier of the trust ladder, and the matching item in Open Decisions.

For the trust ladder: at the top tier he does not read it. He tells the PC it exists, which is
further than anyone else has got.

## 3. The Windbreak. He acquired and repaired it. (Ruling, now canon.)

Your version has him take on a damaged building through a communal work agreement and repair the
split stove plate with metal straps. **That is now canon and supersedes the older line about him
building it from scavenged stone.** Keep it as written. Note it in the manifest as a canon
correction, and remove any Open Decisions item that treats it as unsettled.

## 4. Stop sanding him. (Character fix.)

You have written a man with a code of conduct. Canon has written someone blunt, impatient, and
genuinely unpleasant to people who have earned it, whose care is real and is expressed sideways
because he cannot express it any other way.

Cut the moralizing, specifically the passage stating that he never attacks bodies, species,
poverty, injury, or a need for shelter. It reads as a writer defending him.

Replace it with the actual shape of his edge:

- He does not tolerate freeloaders or showboaters. Canon: *"I don't run a charity. First one's
  goodwill. After that, you work for it."*
- His contempt is real and lands on people who are already down when they have wasted his
  goodwill. He is not fair about this, and he does not revisit it once he has decided.
- Give one instance where he was cruel to someone who deserved it, and **one where he was cruel
  to someone who did not** and has not apologized. Do not resolve the second one, and do not have
  him privately regret it in a way that lets him off.
- His feeding people is compulsive rather than saintly. Being fed by Tavo can be humiliating,
  because it arrives with commentary about your judgement and it does not wait for you to accept
  it.

Sections to update: Part One, the relevant paragraphs of Part Four, and the voice notes in Part
Eight.

## 5. The Soup Riot had a real cause he was handling badly. (Ruling.)

Your version has a false hoarding rumour and Tavo vindicated. Change it so the anger was pointed
at the wrong thing while being correct that something was wrong.

Build it so that:

- Portions really had been shrinking for weeks, and there was a specific cause inside his own
  operation. Pick something ordinary and unglamorous, a supply arrangement he kept private, a
  count he was carrying in his head instead of writing down, a delivery he had been covering the
  shortfall on out of stores without telling anyone.
- He was handling it alone, which is the recurring failure, and it is the same failure as the
  road hearth.
- The hoarding accusation was wrong in its specifics. Opening the stores proved the count and
  proved nothing about the actual problem, which is why the shortage continued afterward.
- **He has never fully conceded this.** He tells the story as the day he opened everything and
  was proven right. Someone in Klyftet remembers it differently, and the PC can find that out
  from another NPC rather than from him.
- The town's memory should be mixed. It is why disputes get brought to the Windbreak, and it is
  also why some people still do not entirely trust his accounting.

Update Part Three, the Part Four knot, the conversation map entry, and Open Decisions.

## 6. Cut his angle on Caarth. (Scope fix.)

Two other NPCs already carry Library and Caarth material, and a third dilutes all three.

- **Delete** the freight-yard history entirely. He never cooked outside Caarth.
- **Delete** the reliability table and the ⚠️ main-quest warning with it.
- **Delete** the matching Open Decisions item.

Replace with a short paragraph: he knows what any Klyftet local knows, which is that caravans use
the name, the accounts disagree, and nobody he trusts has been recently. He has no opinion worth
having and says so.

Keep the routing, and make it a man getting rid of a question rather than a man sharing
intelligence. He points at Minttärä for Library correspondence and at Rupaaa and Baaaku for
records, and he is faintly annoyed at being asked. His actual interest is whether the PC has
eaten before they go and whether they are travelling with anyone.

## 7. Prune the coined vocabulary. (Style fix.)

The document invents too many in-world terms. The house standard is that **author-facing
descriptive labels are fine, and in-world jargon is not.** The Pöllöka sheet's *sourcing habit*
is a label for writers, *pilgrimage* is a plain word, and *route-silk* is a concrete object.
Match that.

**Cut these terms.** Keep every behaviour they described, and describe it in plain words:

- **Outstep** and **return beat**. Nöteri leave home as young adults to work elsewhere and come
  back with something useful, and it does not need a proper noun. Rename the section accordingly.
- **Borrowed hearth**. Keep the one-night hospitality exchange and lose the label.
- **"Leave my beat"** as a spoken refusal. Cut the phrase. The refusal stays physical and plain.
- **Hearth-group**. Use **hearth** on its own, which is already how the document uses *road
  hearth*.

**Keep**, since they earn their place:

- **The next beat**, as an author-facing name for the speech habit. Do not put it in anyone's
  mouth as terminology.
- The paired-name structure behind Tavo-Pavo. Keep the fact that the second half comes from the
  group that raised him and that shortening it is a real liberty, and drop the term
  **answer-name**, describing it instead.

**Denspeaker** and **moss-weaver** are established canon vocations, so give each one plain
sentence in Book A saying what the work actually is. Do not build anything on top of them.

## 8. Fix the voice on every "He'd say" line. (The most important edit.)

Some of your lines are exactly him. Others have him narrating his own psychology in balanced,
well-built sentences, and he would never do that.

**The rule: the reader understands Tavo, and Tavo does not.** Analysis belongs in **True**. What
comes out of his mouth should be shorter, ruder, and less self-aware than what you know about
him. He deflects a question about himself by talking about whatever is physically in front of
him.

Canon habits that must appear in the dialogue rather than only being described in Part Eight:

- **"Don't."** He uses it constantly. *"Don't leave that there." "Don't make it weird."*
- **Possessive about the inn.** *My floor, my tables, my bar.* Never *the floor*.
- **Cuts people off**, often finishing their sentence wrongly, then correcting himself at speed.
- **Questions that are directives.** *"You eating tonight or what?"* means sit down.
- **Utensil as punctuation.** A ladle set down ends a sentence.
- He never says *please* when a look will do, and never *fine*.

Rewrite every **He'd say** block in both books against this. Examples of the failure and the fix:

| You wrote | Closer to him |
|---|---|
| *"My old hearth ended in person. I'm giving you more courtesy than that question earned, so leave it there."* | *"Ended in person. That's all of it you get."* Then he finds something to wipe. |
| *"I have staff when there's work worth naming. I have customers when they pay. I have a town when the roof comes loose and everyone suddenly remembers where I live."* | *"I've got customers. Don't confuse that with help."* |
| *"You want food, point at what you can eat. You want a room, show me what you're paying with. You want trouble, take it outside before I choose the direction."* | *"Point at what you can eat. Don't touch the cups."* |

Keep the ones that already work, including the apron line, the *"You're late, sit down, eat this"*
line, and *"A respected merchant knows when to duck."*

Three specific rules while rewriting:

- **No triplets.** Any line with three parallel clauses is a set piece and he does not perform.
- **He does not describe his own feelings, even to refuse.** He does not say a question earned
  less courtesy. He changes the subject to the stove.
- **His longest lines are instructions**, and they get long because there are several steps,
  never because he is explaining himself.

## 9. Add the vanishing beat. (Missing canon.)

Canon carries a story beat where Tavo-Pavo may vanish suddenly after a townwide crisis, becoming
an investigation trigger. The document never addresses it.

Add a short subsection to Part Six or Part Seven, in the register of the wing material in the
Minttärä pass, covering what he would leave behind, what state the inn would be in, who would
notice first and how long it would take them, and which of his habits would look wrong to a PC
who had been paying attention. Do not decide what happened to him or invent the crisis.

## 10. Warm up Book A. (Register fix.)

Book A is accurate and drier than the Pöllöka sheet it is matching. That sheet keeps earning its
keep with connective asides that tell a writer what a fact is *for*, such as *"which is most of
why a Pöllöka ends up working in a bathhouse and stays."*

Do not add new systems or new length. Go through the existing Book A sections and add that
connective clause where a fact currently stops without one, so each major fact lands on the
behaviour, job, habit, or scene it produces. Aim for roughly one per section, and use the
existing prose rather than appending new paragraphs.

## 11. Rebuild Open Decisions. (Structural fix.)

Twenty-five items is too many, and length makes approval harder rather than easier. Rebuild the
part so that:

- Items settled by this revision are **removed entirely**, not restated. That covers the Windbreak
  acquisition, the sealed letter, the Soup Riot's cause, Bitalgut, and the Caarth cut.
- Anything you would describe as *cheap to cut individually* is folded into a single closing
  paragraph rather than given a numbered item.
- Only genuine forks remain, meaning things where a reasonable person could rule either way and
  where the ruling changes other material.
- The species-wide and character-only split stays.
- Renumber cleanly, and target ten to fourteen items in total.

---

# BEFORE YOU SUBMIT

1. You have returned only changed sections, plus the manifest, and nothing else.
2. Every section you returned is complete and pasteable, with no ellipses and no summarizing.
3. Nothing in the approved list at the top of this prompt has been altered.
4. Every **He'd say** line survives the voice rules in edit 8, including any inside sections you
   changed for other reasons.
5. No em-dashes, no *not X, but Y*, and no staccato fragments.
6. The cut terms from edit 7 do not appear anywhere in the returned text.
7. Nothing you return reintroduces Tavo-Pavo's Caarth history.

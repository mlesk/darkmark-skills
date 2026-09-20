---
name: dm-write
description: Improve any non-fiction prose using Style: Lessons in Clarity and Grace by Joseph M. Williams. Use when the user asks to review, improve, tighten, clarify, revise, rewrite, or critique a piece of writing such as an email, doc, report, essay, blog post, README, spec, or proposal. Diagnose against Williams rules, then deliver a revised version with a change log. Do NOT use for fiction/poetry voice work, grammar-only proofreading, or brainstorming new content from scratch.
---

# Write

Turn rough non-fiction prose into clear, cohesive, concise writing without sanding off the author's voice.

Inspired by Joseph M. Williams, *Style: Lessons in Clarity and Grace*: readers judge clarity from subjects and verbs, cohesion from old-before-new flow, and grace from shape and emphasis — not from fancy words.

The deliverable is not vague praise. It is a diagnosis tied to rules, a revised version, and a scorecard showing what moved.

## At a glance

| Phase | Job | Gate |
| ----- | --- | ---- |
| 0 Intake | Audience, purpose, voice, constraints | - |
| 1 Diagnose | Scan against R1–R10, list findings | Diagnosis shown |
| 2 Rubric | Weighted Clarity/Cohesion/Concision/Shape/Grace rubric | User approves rubric + threshold |
| 3 Baseline | Score original before changing it | User confirms calibration |
| 4 Revise | Critique → improve → re-score rounds | Stop rule |
| 5 Deliver | Revised text, scorecard, change log, remaining gap | - |

## Operating principles

- **Diagnose before rewriting.** No revised sentence without a rule number attached to it.
- **Preserve meaning and voice.** Fix the sentence, not the personality. Keep technical terms, hedges that carry meaning, and deliberate style.
- **Subjects do work, verbs carry action.** The core Williams move: characters as subjects, important actions as verbs.
- **Old before new.** Start sentences with familiar material, end with the point.
- **Shortest fix that moves the score.** Prefer deleting and compressing over rephrasing.
- **Explain, don't just polish.** Every accepted change must be traceable to R1–R10.
- **Threshold beats vibes.** Agree what score counts as done before revising.
- **Durable output.** Leave revised text plus a reusable change log, not chat advice.

## Minimum compliance

Do not claim to have used dm-write unless you can show all of these:

1. An intake: audience, purpose, voice to preserve, length/format constraints.
2. A diagnosis list with rule numbers (R1–R10) tied to specific sentences.
3. An approved rubric with weights, observable anchors, and a threshold.
4. A baseline scorecard shown before any rewrite.
5. At least one full critique → improve → re-score round.
6. A delivery block: revised text, final scorecard, change log, remaining gap.

If any item is missing, return to the last satisfied gate. Delivering a rewrite without items 1–6 is a violation of dm-write.

## Fast path

1. Intake audience, purpose, voice, constraints.
2. Diagnose against R1–R10 and show findings.
3. Build rubric, get approval on rubric + threshold.
4. Score baseline, get calibration approval.
5. Run critique → improve → re-score rounds (default max 3 for prose).
6. Deliver revised text, scorecard, change log, remaining gap.

## Trigger boundary

**Positive triggers - load this skill when the user:**

- Asks to review, improve, tighten, clarify, clean up, revise, or rewrite prose
- Pastes an email, doc, report, essay, blog post, README, spec, proposal, or paragraph and wants it better
- Asks "does this read clearly?", "make this punchier", "cut the fluff", "fix the flow"
- Wants a critique grounded in clarity/grace principles, not just spell-check

**Near misses - do NOT load this skill when the user:**

- Wants fiction, poetry, dialogue, or deliberate literary voice work (style rules differ)
- Wants grammar/spell-check only with no revision ("just proofread, don't change anything")
- Wants new content brainstormed from scratch with no draft to diagnose
- Wants a domain optimizer that already owns the loop (e.g. skill authoring goes to dm-pocockify; general non-prose goals go to dm-loopify)

If overlap is unclear, ask:

> Is there a draft to diagnose, or should we brainstorm new content first?
>
> Recommended answer: use dm-write only when a draft exists; otherwise brainstorm first, then bring the draft back for a Williams pass.

**Positive trigger examples:**

- "Review this status update for clarity."
- "Tighten this proposal — it rambles."
- "Improve this README intro using Williams."
- "Does this email bury the point?"

**Near-miss examples:**

- "Write a poem in the voice of Mary Oliver."
- "Just fix commas, don't reword anything."

## The rules (Williams R1–R10)

Apply these on every diagnosis. Cite the rule number for each finding.

### R1 — Characters as subjects, actions as verbs

Test: can you name who does what, but the subject/verb don't say it?
Fix: make main characters subjects, key actions verbs. Convert nominalizations (zombie nouns in `-tion/-ment/-ence/-ity/-ance`) back to verbs; break weak-verb + noun pairs (`make, do, perform, conduct, carry out, involve, provide` + noun).

- `A decision was made by the team regarding prioritization.` → `The team decided what to prioritize.`
- `We conducted an analysis of latency.` → `We analyzed latency.`

### R2 — Active voice by default, passive only on purpose

Test: passive, `there is/it is`, or missing actor hides responsibility.
Fix: restore the actor. Allow passive only when: actor unknown, actor irrelevant, or passive preserves old→new flow (R3).

- `Mistakes were made in the migration.` → `We corrupted dates during the migration.`

### R3 — Old information first, new information last

Test: sentence opens with new/complex material and ends with familiar filler.
Fix: start with familiar, short, already-mentioned; end with new, long, important. The last 4–5 words (stress position) carry the point.

- `An important consideration for scalability, given our constraints, is caching.` → `Given our constraints, we scale by caching.`

### R4 — Paragraph coherence through consistent topics

Test: subjects jump from sentence to sentence; reader loses "who is this about?"
Fix: keep a topic string — same character in subject position for 3+ sentences unless deliberately shifting. Point-first paragraphs: point sentence → support → payoff. One paragraph, one topic shift.

### R5 — Cut clutter

Test: throat-clearing metadiscourse, filler, redundant pairs/modifiers.
Fix: delete what changes nothing: `it is important to note that, in fact, basically, really, very, each and every, true facts, future plans`. If deletion loses nothing, delete.

- `It is important to note that the results are basically very clear.` → `The results are clear.`

### R6 — Compress inflated diction, prefer the affirmative

Test: long phrase where a word works; double negative; hedged nominal.
Fix: `due to the fact that` → `because`, `despite the fact that` → `although`, `in order to` → `to`, `utilize` → `use`, `not unimportant` → `important`. Prefer short Anglo-Saxon verbs for actions.

### R7 — Shape: point early, payoff late

Test: intro wanders through background; ending restates instead of answering "so what?"
Fix: intro = Common Ground → Problem → Thesis/promise in the first 2–3 sentences (BLUF for email/docs). Body points first. Ending states significance or next action, not a summary.

### R8 — Balance parallel structure

Test: coordinated items mismatch in form or weight; choppy fragments or 40+ word sprawlers.
Fix: make list/clause members parallel in grammar. Coordinate equals with `and/but/or`; subordinate unequals with `although/because/when`. Split sprawlers, combine choppies deliberately.

- `We value speed, accuracy, and to be reliable.` → `We value speed, accuracy, and reliability.`

### R9 — Emphasis and rhythm

Test: every sentence is the same length; climax buried mid-sentence; anticlimax ending.
Fix: end-weight (heavy/long material last), climactic order (short → long, weak → strong), vary length — one short punch sentence per paragraph is allowed. Read stress positions aloud.

### R10 — Grace without distortion

Test: edit would change meaning, flatten voice, or polish jargon into false precision.
Fix: keep author's terms, real hedges, and deliberate repetition. Prefer precise over fancy. Flag any ambiguity you resolved as an explicit assumption in the change log.

## Phase 0 - Intake

Capture before diagnosing. Look up what the workspace already says; ask only for the genuinely unknown.

```text
Writing contract
- Draft: the text (or file path) to revise
- Audience: who reads this and what do they care about
- Purpose: inform / persuade / request / document
- Voice to preserve: terse, friendly, formal, technical, other
- Constraints: length, format, must-keep terms, must-not-change claims
- Non-goals: what this pass is not about
```

If the draft is missing, stop and ask for it. If audience/purpose is unclear, ask the smallest blocking question:

> Who is this for, what should they do after reading, and what voice should I preserve?
>
> Recommended answer: "For [audience] to [action]; preserve [voice]; keep [terms/claims] unchanged."

**Exit criteria:**

- [ ] Draft is in hand.
- [ ] Audience and purpose stated.
- [ ] Voice and constraints noted.

## Phase 1 - Diagnose

Scan the draft sentence by sentence against R1–R10. Show findings before rewriting.

Format:

```text
S3 (R1): "A decision was made..." — nominalization + hidden actor. Fix: "The team decided..."
S5 (R3): opens with new material, point buried mid-sentence. Fix: move payoff to end.
P2 (R4): subjects jump team → process → dates. Fix: keep team in subject through paragraph.
```

Rules:

- Cite at least one rule per finding; no uncited taste edits.
- Rank top 3 highest-leverage findings (the ones whose fix moves clarity most).
- Separate meaning questions from style fixes. If a sentence is ambiguous, flag it and state your assumed reading — do not silently pick one.

**Exit criteria:**

- [ ] Every paragraph has at least one cited finding or an explicit "clean" mark.
- [ ] Top 3 leverage points named.
- [ ] Ambiguities flagged as assumptions.

## Phase 2 - Build the rubric

Default rubric (adjust weights to the intake, then get approval):

```markdown
## Proposed Rubric

### Clarity — characters/actions, active voice (R1–R2) (weight: 9)
- 2/10: actors hidden, actions trapped in nouns; reader must reconstruct who did what
- 10/10: main characters are subjects, key actions are verbs throughout

### Cohesion — old→new, topic strings (R3–R4) (weight: 8)
- 2/10: sentences start with new material, subjects jump, point buried
- 10/10: familiar opens each sentence, topic holds per paragraph, payoff lands at ends

### Concision — no clutter or inflation (R5–R6) (weight: 8)
- 2/10: throat-clearing, redundant pairs, inflated phrases on most sentences
- 10/10: every word earns its place; compressions applied without loss

### Shape — point early, payoff late (R7) (weight: 7)
- 2/10: point buried, intro wanders, ending restates
- 10/10: BLUF/thesis up front, point-first paragraphs, ending answers "so what?"

### Grace — balance, emphasis, rhythm, voice (R8–R10) (weight: 6)
- 2/10: nonparallel lists, monotone length, voice flattened or meaning shifted
- 10/10: parallel where coordinated, varied rhythm, voice preserved, precise diction

Threshold: 85/100
```

**HARD GATE — rubric approval.** Present rubric + threshold and wait:

> Does this rubric capture what good means here? Adjust dimensions, weights, or threshold before I score the baseline.
>
> Recommended answer: "Looks right — score the baseline" or specific adjustments.

Do not score or revise before explicit approval.

**Exit criteria:**

- [ ] Weights make real tradeoffs (not all equal).
- [ ] Anchors are observable in this draft.
- [ ] User approved rubric + threshold.

## Phase 3 - Establish the baseline

Score the original with the approved rubric before changing anything:

```markdown
BASELINE SCORE: XX/100

Dimension   Weight  Score  Rationale
Clarity     9       ..     ...
Cohesion    8       ..     ...
Concision   8       ..     ...
Shape       7       ..     ...
Grace       6       ..     ...
```

Formula: `sum(weight x score) / sum(weights) x 10`.

**HARD GATE — calibration.** Present the scorecard and ask:

> Does this baseline feel calibrated? If it's off by more than 10 points, we fix the rubric first.
>
> Recommended answer: "Calibrated — revise" or a specific adjustment.

**Exit criteria:**

- [ ] Baseline shown.
- [ ] User confirmed calibration.
- [ ] `best = original`, `best_score = baseline`, `history = [baseline]`.

## Phase 4 - Run the revision loop

```text
repeat:
    critique = highest score-cost weaknesses in best, tied to R-numbers
    candidate = revise the slice (whole draft if short; worst paragraph/section if long)
    s = score(candidate) with same rubric
    if s > best_score + MARGIN: best, best_score = candidate, s
    history.append(best_score)
until best_score >= threshold OR plateau OR max rounds reached
```

- Margin: +2 for prose (same scale as dm-loopify document default).
- Default max 3 rounds for prose; stop earlier on threshold or plateau (no gain > margin over last 2 rounds).
- Each round revises 1–3 high-leverage fixes, not a full restyle. Re-anchor to the original rubric anchors every round; do not drift weights mid-loop.
- Never accept a candidate that regresses Clarity to buy Grace. R1–R2 outrank R9 polish.

**Exit criteria:**

- [ ] At least 1 full critique → improve → re-score round.
- [ ] Stop reason explicit: threshold, plateau, or max rounds.
- [ ] `best` is a complete, usable revised text.

## Phase 5 - Deliver

Deliver in this order:

### 1. Revised text

Lead with the full revised version (or the revised slice + instructions for applying to the rest, for long docs).

### 2. Scorecard

```markdown
FINAL SCORE: XX/100

Dimension   Weight  Score  Rationale
...         ...     ...    ...
```

Trajectory: `Baseline -> R1 -> R2 -> Final` with numbers.

### 3. Change log

Top changes, each tied to a rule:

```text
- S3 (R1): "conducted an analysis of" → "analyzed" — verb restored, 3 words cut
- S5 (R3): moved payoff to stress position
- P2 (R4): kept "the team" as subject through paragraph
- Assumption: S7 "they" read as "the on-call team" — correct if wrong
```

### 4. Remaining gap

What still scores low, what was deliberately left (voice, constraint), and what new information would raise the score.

## Anti-patterns

- **Taste edits.** Rewording without a rule number.
- **Voice flattening.** Making everything sound like the assistant; polishing away deliberate tone.
- **Nominalization smuggling.** Replacing one zombie noun with another (`make a decision` → `perform a prioritization`).
- **Passive moralizing.** Forcing active voice where passive serves cohesion or the actor is genuinely unknown.
- **Clutter theater.** Cutting commas while throat-clearing paragraphs survive.
- **BLUF evasion.** Leaving the point in paragraph 4 to "build up to it."
- **Parallelism drift.** Fixing one list member but leaving the other two mismatched.
- **Rhythm monotony.** Delivering twenty medium-length sentences in a row.
- **Meaning shift.** Silently resolving ambiguity instead of flagging an assumption.
- **Gate skipping.** Scoring or revising before rubric approval and claiming the loop happened.
- **Rubric drift.** Changing weights mid-loop to make the revision look better.

## Final self-review

Before declaring done, verify:

- [ ] The skill owns prose revision, not fiction, proofreading-only, or brainstorming.
- [ ] The description states capability + trigger contexts.
- [ ] Positive triggers and near misses are explicit.
- [ ] Context was inspected before asking (draft, audience, constraints).
- [ ] Every user-facing question pattern includes a recommended answer.
- [ ] I can show the writing contract, cited diagnosis, approved rubric, baseline scorecard, and at least one scored revision round.
- [ ] Every revision maps to R1–R10; no uncited edits.
- [ ] Voice and meaning preserved; assumptions flagged.
- [ ] Threshold/plateau/max-rounds stop reason is explicit.
- [ ] At least 3 positive trigger examples and 2 near-miss examples fit the description.
- [ ] The folder is extractable standalone (no repo-local paths or prior-chat dependencies).

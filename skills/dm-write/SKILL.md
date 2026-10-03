---
name: dm-write
description: Improve non-fiction prose using Joseph M. Williams' Style - Lessons in Clarity and Grace. Diagnoses the draft against ten rules (R1-R10), then runs the dm-loopify engine with a Williams rubric and delivers revised text, a scorecard, and a change log where every edit cites a rule. Use when the user asks to review, improve, tighten, clarify, revise, rewrite, or critique an email, doc, report, essay, blog post, README, spec, or proposal, or asks "does this read clearly?" or "cut the fluff". Do NOT use for fiction or poetry, proofreading-only requests ("just fix commas"), or writing from scratch with no draft.
---

# Write

Turn rough non-fiction prose into clear, cohesive, concise writing without sanding off the author's voice. Readers judge clarity by subjects and verbs, cohesion by old-before-new flow, and grace by shape and emphasis, not by fancy words.

This skill supplies the **domain pack**; `dm-loopify` (sibling skill `../dm-loopify/SKILL.md`) supplies the loop. Read both. If `dm-loopify` is not installed, stop and tell the user to run `scripts/link-skills.sh`.

## The rules

Full tests, fixes, and examples: [references/williams-rules.md](references/williams-rules.md). Read it before diagnosing.

| Rule | In one line |
| --- | --- |
| R1 | Characters as subjects, actions as verbs (kill nominalizations) |
| R2 | Active voice by default; passive only on purpose |
| R3 | Old information first, new information last (stress position) |
| R4 | Consistent topic strings within a paragraph |
| R5 | Cut clutter and metadiscourse |
| R6 | Compress inflated diction; prefer the affirmative |
| R7 | Point early, payoff late (BLUF for email and docs) |
| R8 | Parallel structure for coordinated items |
| R9 | Emphasis and rhythm: end-weight, varied length |
| R10 | Grace without distortion: keep meaning, voice, real hedges |

## Domain pack

| Slot | Value |
| --- | --- |
| Intake | Writing contract (below) |
| Diagnosis | R1-R10. Every finding and every change cites a rule. |
| Rubric | Default Williams rubric (below), threshold 85 |
| Round move | Revise 1-3 high-leverage findings in the whole draft (short) or the worst section (long). No full restyle. |
| Margin | +2 |
| Round cap | 3 |
| Path | Light for drafts under ~300 words or when the user says "quick"; full otherwise |
| Review | Cold-reader check (below) replaces dm-critic by default. Use dm-critic only if the user asks or the piece is high-stakes. |
| Delivery | Revised text, scorecard and trajectory, change log, remaining gap |

## Step 1 - Intake

Infer what you can; ask only for what you can't, using one question with a recommended answer.

```text
Writing contract
- Draft:            the text or file path
- Audience:         who reads it and what they care about
- Purpose:          inform / persuade / request / document
- Reader action:    what the reader should do or know afterwards
- Voice to keep:    terse, friendly, formal, technical, ...
- Constraints:      length, format, must-keep terms, claims that must not change
```

No draft, no skill: ask for it.

## Step 2 - Diagnose

Go through the draft sentence by sentence and show findings before changing anything:

```text
S3 (R1): "A decision was made..." — nominalization, hidden actor. Fix: "The team decided..."
S5 (R3): point buried mid-sentence. Fix: move it to the stress position.
P2 (R4): subjects jump team → process → dates. Fix: keep "the team" as subject.
```

- Every paragraph gets at least one cited finding or an explicit "clean".
- Name the top 3 findings by impact on clarity.
- Flag ambiguous sentences and state the reading you assume. Never resolve ambiguity silently.

## Step 3 - Run the loop

Run `dm-loopify` Phases 2-5 and 7 with this pack. On the light path, one gate covers the contract, rubric, threshold, and baseline. Default rubric:

```markdown
### Clarity — R1-R2 (weight: 9)
- 2/10: actors hidden, actions trapped in nouns; reader reconstructs who did what
- 10/10: main characters are subjects, key actions are verbs throughout

### Cohesion — R3-R4 (weight: 8)
- 2/10: sentences open with new material, subjects jump, point buried
- 10/10: familiar material opens each sentence, topics hold, payoff lands at the end

### Concision — R5-R6 (weight: 8)
- 2/10: throat-clearing, redundant pairs, inflated phrases in most sentences
- 10/10: every word earns its place, nothing lost in compression

### Shape — R7 (weight: 7)
- 2/10: point buried, intro wanders, ending restates
- 10/10: point up front, point-first paragraphs, ending answers "so what?"

### Grace — R8-R10 (weight: 6)
- 2/10: lists not parallel, monotone sentence length, voice flattened or meaning shifted
- 10/10: parallel where coordinated, varied rhythm, voice and meaning preserved

Threshold: 85/100
```

Never accept a candidate that lowers Clarity to raise Grace. R1-R2 outrank R9.

## Step 4 - Cold-reader check

Before delivering, give a fresh sub-agent **only the revised text** and ask: "In one sentence, what is the main point? What does the writer want you to do?" Compare the answer with the contract's purpose and reader action. A mismatch means the revision has failed Shape; run one more round. Without sub-agents, do it yourself from the revised text only and label it `self-checked`.

## Step 5 - Deliver

1. **Revised text** (for long documents: the revised sections plus how to apply the pattern to the rest).
2. **Scorecard** with trajectory `Baseline -> R1 -> ... -> Final`.
3. **Change log**, each line citing a rule:
   ```text
   - S3 (R1): "conducted an analysis of" → "analyzed"
   - S5 (R3): moved the payoff to the stress position
   - Assumption: S7 "they" read as "the on-call team" — correct me if wrong
   ```
4. **Cold-reader result** and **remaining gap**: what still scores low, and what was deliberately kept for voice or constraints.

## Anti-patterns

- **Taste edits:** rewording with no rule number.
- **Voice flattening:** making the author sound like the assistant.
- **Nominalization smuggling:** swapping one noun-heavy phrase for another.
- **Passive moralizing:** forcing active voice where passive serves R3 or the actor is unknown.
- **BLUF evasion:** leaving the point in paragraph four.
- **Meaning shift:** resolving an ambiguity without logging the assumption.

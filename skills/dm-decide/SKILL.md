---
name: dm-decide
description: Structured decision-making. Captures the decision as a contract, grills it through mental-model lenses (first principles, opportunity cost, second-order effects, compounding, incentives, probabilistic thinking, inversion) scaled to how reversible the decision is, rules out options that fail a must-pass constraint, scores the rest on a weighted rubric including the status quo, stress-tests the leader, and delivers a decision record with a recommendation. Runs on the dm-loopify engine. Use when the user faces a decision, weighs options, asks "should I...", "which one...", or "is this the right call?", or wants options scored. Do NOT use for brainstorming with no choice to make, plans or roadmaps, or factual questions.
---

# Decide

Turn a decision into a process the user can defend: contract → grill → veto → rubric → score → stress-test → recommend.

This skill supplies the **domain pack**. `dm-grill` (`../dm-grill/SKILL.md`) runs the interview and `dm-loopify` (`../dm-loopify/SKILL.md`) runs the rubric, scoring, and round mechanics. Read both. If either is not installed, stop and tell the user to run `scripts/link-skills.sh`.

**Recommendation last.** No recommendation before the rubric is approved and every option is scored.

## Domain pack

| Slot | Value |
| --- | --- |
| Intake | Decision contract (Step 1) |
| Diagnosis | Lenses in [references/lenses.md](references/lenses.md) |
| Rubric | 3-7 dimensions earned in the grill, plus must-pass vetoes |
| Baseline | First scorecard of every option, including the status quo |
| Round move | Stress-test the leader and close the widest evidence gap; re-score from evidence |
| Accept rule | Scores change only when evidence changes, never to favor an option (no margin) |
| Round cap | 3; at least 1 |
| Path | Light for two-way doors with low stakes; full otherwise |
| Review | dm-critic on by default for one-way doors, off for two-way doors |
| Delivery | Decision record (Step 6) |

## Step 1 - Decision contract

Look up what can be looked up. Ask only for what can't, one question at a time with a recommended answer.

```text
Decision contract
- Decision:        one sentence, stated as a choice
- Options so far:  (leave room for more)
- Stakes:          what is won or lost, and how badly
- Reversibility:   two-way door (cheap to undo) | one-way door
- Deadline:
- Decision-maker:
- Must-pass:       constraints any acceptable option must meet (budget ceiling, legal, values, ruin risk)
- Non-goals:
```

If the decision cannot be stated as a choice between at least two options, it is not ready. Ask:

> What exactly is being decided, between which options, by when, and what is at stake?
>
> Recommended answer: "Choose between X and Y by <date>, where <Z> is at stake."

## Step 2 - Grill

Run `dm-grill` with the lens menu in [references/lenses.md](references/lenses.md). Use the number of lenses that fits the reversibility and stakes (table in that file). Exit when the 2-3 dimensions that dominate the decision are clear and each lens used has a concrete finding. Confirm the grill record with the user.

## Step 3 - Veto, then rubric (HARD GATE)

**Veto first.** A weighted sum lets a fatal flaw be outvoted by strengths elsewhere. Check every option against the must-pass constraints and remove the ones that fail, saying which constraint failed. Never remove the status quo silently; if it fails a must-pass, say so.

**Then the rubric**, following `dm-loopify` Phase 2:

- 3-7 dimensions taken from the grill, with weights that make real tradeoffs; the dominant lens carries the highest weight.
- One dimension measures **goal attainment**.
- One dimension measures **downside**: how bad the realistic worst case is and how easily it can be recovered from.
- Observable anchors: "2/10: spends the runway with no path to a first customer" beats "2/10: bad fit".

Show the vetoes and the rubric and wait for approval.

## Step 4 - Score every option

Always include the **status quo**. If the grill suggested a materially different direction, add it as a bolder option. Score every option on the same rubric, then show:

| Option | Weighted total | One-line rationale |
| --- | --- | --- |
| Status quo | XX | ... |
| ... | XX | ... |

Per option, keep the detail:

| Dimension | Weight | Score | Rationale |
| --- | --- | --- | --- |
| ... | ... | ... | ... |

On the full path, ask whether the scores feel calibrated before refining.

## Step 5 - Refine (at least one round)

Each round:

1. **Stress-test the leader** with inversion and second-order effects. Name the specific way it could fail.
2. **Close the widest evidence gap**: the dimension with the weakest evidence or the closest margin. Resolve it with a fact, a question, or a sharper anchor.
3. **Re-score** with the same rubric and show before and after.

Stop when the leader beats the runner-up by at least 10 points and survived the stress test, when two rounds change nothing, or at 3 rounds. If it's close, split the decision into smaller independent ones or report the tie honestly.

For one-way doors, run `dm-critic` on the scorecard and leading option before delivering, unless the user opts out.

## Step 6 - Deliver the decision record

```markdown
## Decision record: <decision>

| Option | Final score | Status | One-line rationale |
| --- | --- | --- | --- |
| Status quo | 41 | scored | Incidents keep compounding |
| Refactor in place | 78 | scored | Cheaper now, caps capacity later |
| Rebuild billing | 86 | scored | Removes the incident source; longer path to value |
| Outsource billing | - | vetoed: data residency | Fails a must-pass |

**Recommended:** <option>, because <why it wins>.
**A different option wins if:** <what would have to be true>.
**Guardrails:** <what to watch after committing; the reversal plan>.
**Process:** <lenses used> → <rubric dimensions> → <rounds and what moved>.
**Remaining uncertainty:** <the evidence gap and what new information would change the call>.
```

Offer to save it as a decision log entry or an ADR (`docs/adr/NNNN-<slug>.md`) unless the user declines.

## Anti-patterns

- **Recommendation first:** answering, then building a rubric to justify it.
- **Option blindness:** leaving out the status quo or a bolder alternative.
- **Fatal flaw averaged away:** scoring an option that should have been vetoed.
- **Lens tourism:** naming all seven lenses while none of them changes a score.
- **Certainty theatre:** stating probabilities that weren't derived from anything.
- **Rubric drift:** changing weights mid-scoring to help a favorite.
- **Gate skipping:** moving past a hard gate without the user's explicit approval.

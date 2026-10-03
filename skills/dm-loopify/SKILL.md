---
name: dm-loopify
description: >-
  Rubric-driven optimization loop: lock the goal, agree a weighted rubric and
  threshold, score a baseline, then run critique -> improve -> judge rounds
  until the threshold, a plateau, or the round cap, and close with an
  independent dm-critic review. Works on a file, document, artifact set,
  workflow, skill, subsystem, codebase, or a goal with no draft yet. Also the
  engine that dm-write and dm-decide run on. Use when the user says "loopify
  this", "optimize this", "keep improving this", "iterate until it's good",
  "make this as good as it can get", or asks for a rubric and baseline score.
  Do NOT use for quick first drafts, one-dimension tweaks, prose editing
  (dm-write), or choosing between options (dm-decide).
---

# Loopify

Turn "make this better" into a directed search: goal → rubric → baseline → scored rounds → explicit stop → independent review → delivery.

Before Phase 0, read [references/templates.md](references/templates.md). Read the other references at the step that names them.

## Domain packs

Domain skills reuse this engine by passing a **domain pack**. The engine runs the phases below and uses the pack wherever it supplies a value. Standalone, you build the pack yourself in Phases 1-2.

| Slot | Meaning | Standalone default |
| --- | --- | --- |
| Intake | Contract fields to capture | Phase 1 contract |
| Diagnosis | Rule set the critique must cite | Rubric dimensions |
| Rubric | Default dimensions, weights, anchors, threshold | Built in Phase 2, threshold 85 |
| Round move | What one round may change | Improve one slice |
| Margin | Minimum gain to accept a candidate | +2 docs/plans, +3 code/sets |
| Round cap | Maximum improvement rounds | 3 artifact · 5 set/subsystem · 8 codebase |
| Review | dm-critic at the end | on |
| Delivery | Sections to deliver | Phase 7 |

## Size the ceremony

Choose the path in Phase 1 and record it in the contract.

- **Light:** the target is small (about a page, one function, one short skill), easy to reverse, or the user said "quick". Use one combined gate: show the contract, rubric, threshold and baseline score together and wait for one approval.
- **Full:** anything larger or higher-stakes. Separate the rubric gate (Phase 2) from the calibration gate (Phase 3).

Both paths require explicit user approval before the target changes. Light means fewer stops, not no stops.

## Phase 0 - Inspect before asking

Read the conversation, the target, nearby files, conventions, tests, and prior art. Work out the target class (single artifact, artifact set, subsystem, codebase, goal-only), whether a baseline exists, a likely iteration slice, and the constraints. Never ask what the workspace answers.

## Phase 1 - Lock the contract

Fill the optimization contract (template in references). Use `dm-grill` (sibling skill `../dm-grill/SKILL.md`) for anything the workspace cannot answer: one question at a time, each with a recommended answer. Settle:

- **Goal** in one sentence, and who consumes the result.
- **Search posture.** *Focused refinement* when the direction is right; *diverge then converge* when the goal is open-ended or the first idea may not be the best one.
- **Target class and iteration slice** (what one round touches).
- **Threshold, plateau fallback, round cap, path (light/full).**
- **Review:** on unless the user opts out.

## Phase 2 - Build the rubric (HARD GATE)

The rubric is the ceiling: a vague rubric caps the loop low. Use the pack's rubric if given; otherwise propose 5-9 dimensions ([references/dimension-prompts.md](references/dimension-prompts.md) has starting points per target type), then let the user add, remove, or reweight.

- Weights 1-10 that make real tradeoffs.
- Two observable anchors per dimension: a 2/10 the user could point at, and a 10/10 achievable in scope.
- At least one dimension measures **goal attainment**, not polish.
- For workflows, prompts, and skills: one dimension measures **shortcut resistance** (can an agent skip the intended behavior and still claim compliance?).
- For open-ended goals: one dimension measures **distinctiveness**.

Present the rubric and threshold. Do not score anything until the user approves.

## Phase 3 - Baseline (HARD GATE on the full path)

- Target exists: score it as is.
- Goal only: create a real first version. Do not sandbag it.
- Diverge then converge: create 2-3 materially different candidates (structure, framing, architecture, not wording), pick one by quick scoring or user preference, and make it the baseline.

Score = `sum(weight × score) / sum(weights) × 10`. Show the scorecard and ask whether it feels calibrated; if it feels off by more than 10 points, fix the rubric first. Then set `best = baseline`, `history = [score]`.

## Phase 4 - Run the rounds

```text
repeat:
    critique  = top weaknesses by weight × (10 - score), each citing the pack's diagnosis rules
    candidate = apply the round move to one slice (1-3 high-leverage fixes)
    verdict   = judge(best, candidate)
    accept if verdict prefers candidate AND score gain > margin
    history.append(best_score)
until best_score >= threshold OR plateau OR round cap
```

A round counts only if it leaves all four behind: a cited critique, a complete candidate, a re-score with the same rubric, and an accept/reject decision.

**Judging.** If sub-agents are available, use a blind pairwise judge: a fresh sub-agent sees the rubric and two versions labelled A and B in random order, and says which is better on each dimension and overall. Accept only if the judge prefers the candidate. Without sub-agents, self-score and label rounds `self-judged`. Never change the rubric mid-loop; re-read the original anchors every 3 rounds.

**Escape.** After 2 non-improving rounds below threshold, run one best-of-2 round with genuinely different approaches (structure, framing, boundary, sequencing). If neither beats `best` by the margin, the search has plateaued.

**Stop** on threshold, on plateau (no gain above margin across 3 rounds after an escape attempt), or at the round cap. Plateau is a valid stop reason, not a failure.

## Phase 5 - Verify

Before review, check: does the score match your honest view; does `best` advance the goal and not just a slice; are constraints and adjacent files still coherent; would a real consumer notice the improvement over baseline? Fix the rubric or run one more round if a check fails.

## Phase 6 - Independent review (HARD GATE)

Skip only if the contract records an opt-out; say so in the delivery. Otherwise run `dm-critic` (`../dm-critic/SKILL.md`) with this packet: contract, `best` (or diff plus paths), baseline, rubric **anchors only**, and rejected directions. The critic must not see scores. Then offer:

1. **Deliver now.** Unfixed confirmed findings go under Remaining gap.
2. **Targeted fix rounds.** Up to 2 extra Phase 4 rounds on confirmed blockers and majors, same rubric and margin.
3. **Amend the rubric** for a confirmed blind spot, get approval, re-score baseline and `best`, then 1 or 2.
4. **New direction.** Restart at Phase 1 with diverge then converge, keeping `best` as a candidate.

> Which next step? Options combine, e.g. 3 then 2.
>
> Recommended answer: 2 if confirmed blockers exist; 3 for a confirmed blind spot; 4 only if a proposal plausibly beats the current ceiling within constraints; otherwise 1.

Act on nothing before the user chooses. One review per loop.

## Phase 7 - Deliver

Use the pack's delivery sections if given; otherwise, in order: the best target state; final scorecard; score trajectory (`Baseline -> R1 -> ... -> Final`, marking self-judged and review rounds); the 2-3 biggest observable changes; review summary (option chosen, findings fixed/disputed/deferred); remaining gap. Save the rubric, contract and review files next to the deliverable so the loop can resume.

## Sibling skill missing?

If a sibling skill this engine calls (`dm-grill`, `dm-critic`) is not installed, say so and tell the user to run `scripts/link-skills.sh` from the skills repo. Do not silently skip the step.

Common ways this loop goes wrong are listed in [references/anti-patterns.md](references/anti-patterns.md). Read it before the first round.

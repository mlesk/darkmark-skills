---
name: dm-loopify
description: >-
  Generalized rubric-driven optimization loop for improving or achieving a goal
  through repeated evaluation and refinement. Use when the user says "loopify
  this", "optimize this", "refine this", "keep improving this", "make this
  as good as it can get", or wants a rubric, baseline, and iterative loop over
  a file, document, implementation, artifact set, workflow, subsystem, full
  codebase, or open-ended goal where both rigor and creative exploration
  matter. Do NOT use for quick first passes, trivial single-dimension tweaks,
  or when a domain-specific optimizer already owns the task.
---

# Loopify

Turn "make this better" or "achieve this goal" into a directed search process. 
The optimization target can be a single artifact, a related set of artifacts, 
a subsystem, a full codebase, or a goal with no baseline yet. The loop stays 
the same: clarify the goal, build the rubric, score the baseline, improve 
the highest-leverage weakness, re-score, and stop only when a threshold is
reached or progress plateaus.

## Operating principles

- **Optimize the target, not just the text.** The thing being improved may be a
  file, a document set, a workflow, or a codebase slice.
- **Goal before rubric, rubric before edits.** Do not start rewriting until the
  success condition and scorecard are explicit.
- **Inspect for local maxima before committing.** Use project context,
  precedents, and adjacent examples to avoid optimizing the wrong direction.
- **Diverge before converging when the ceiling is unclear.** If the goal is
  open-ended, creative, or strategically ambiguous, explore materially
  different directions before hill-climbing one of them.
- **Choose an iteration slice.** Large targets need a scoped unit of change per
  round. Do not pretend an entire codebase can be rewritten in one pass.
- **Score the whole target.** Local improvements only count if they move the
  overall goal.
- **Preserve distinctiveness.** Improvement should raise the score without
  sanding off the target's strongest point of view.
- **Threshold beats vibes.** Decide what score counts as done before the loop
  begins.
- **Run to an explicit stop rule.** Do not stop at the first acceptable draft;
  stop only when the threshold, plateau rule, or max-round cap says to stop.
- **Plateau is a stop condition, not a failure.** If real improvements stop,
  stop.
- **Durable outputs only.** Each round should leave behind a usable artifact,
  code change, plan update, or scorecard.

## Minimum compliance

Do not claim to have used loopify unless you can show all of these:

1. A clear optimization contract with target, scope, posture, threshold, and
   stop rule.
2. An approved rubric with weighted dimensions and observable anchors.
3. A baseline scorecard shown before changing the target.
4. At least one full critique -> improve -> score round.
5. An explicit stop reason: threshold, plateau, or max rounds.

If any item is missing, the loop is not complete yet. Return to the last
satisfied gate instead of pretending the workflow happened.

## Fast path

Use this when you need a quick execution map:

1. Inspect the target, constraints, and likely ceiling risk.
2. Lock the goal, search posture, target class, threshold, and stop rule.
3. Build the rubric and wait for approval.
4. Score the baseline and wait for calibration approval.
5. Run critique -> improve -> score rounds.
6. Stop only on threshold, plateau, or max rounds, then deliver artifact,
   scorecard, trajectory, and remaining gap.

## Working templates

Use compact artifacts like these instead of freeform narration:

```text
Optimization contract
- Target:
- Target class:
- Search posture:
- Threshold:
- Plateau fallback:
```

```text
BASELINE SCORE: XX/100

Dimension              Weight  Score  Rationale
-----------------------------------------------
...                     ...     ...    ...
```

```text
Round N
- Critique:
- Slice:
- Candidate:
- Score:
- Decision: accepted/rejected
- Best score now:
```

Prefer short, durable artifacts over long narration between rounds.

## Trigger boundary

**Positive triggers - load this skill when the user:**

- Says "loopify this", "run the loop on this", or "iterate until it's good"
- Says "optimize this", "refine this", "keep improving this", or "make this
  as good as it can get"
- Asks for a rubric, baseline score, or critique -> improve -> score loop
- Brings a file, document, code change, design, subsystem, repo, or goal and
  wants it improved or achieved through iteration
- Asks whether something is "done", "good enough", or "as good as it can get"
  and the answer depends on explicit evaluation

**Near misses - do NOT load this skill when the user:**

- Wants a quick first pass, rough draft, or one-shot answer
- Wants a trivial tweak with one obvious dimension and no tradeoffs
- Needs a domain-specific optimizer that already has richer rules or tooling
- Wants pure brainstorming without committing to a rubric and baseline

If overlap is unclear, ask:

> This could use either the general loopify process or a domain-specific
> optimizer. Which one should own the evaluation loop?
>
> Recommended answer: use the domain-specific skill if it has a better rubric
> for this target; otherwise use loopify.

**Positive trigger examples:**

- "Loopify this design doc until the handoff is solid."
- "Optimize this backend subsystem with a reliability rubric and stop at 90."
- "Loopify this skill until an agent cannot shortcut the intended workflow."
- "We have a goal but no draft yet. Build a baseline and iterate until it's
  good enough."

**Near-miss examples:**

- "Give me a quick rough draft."
- "Rename this variable."

## Phase 0 - Inspect before asking

Before asking the user anything, inspect what is already available:

- **Goal statement.** What outcome is the user trying to improve or achieve?
- **Current target.** Is there an existing artifact, artifact set, subsystem,
  codebase slice, or only a goal?
- **Constraints.** Standards, deadlines, interfaces, tests, audience,
  non-goals, and success criteria.
- **Reference points.** Existing standards, nearby examples, prior art,
  analogous systems, or user-provided inspiration that hint at stronger
  directions.
- **Target scale.** Single artifact, related set, subsystem, full codebase, or
  goal-only.
- **Ceiling risk.** Is the obvious direction clearly right, or just the first
  plausible direction you noticed?
- **Likely iteration slice.** Section, file, component, workstream, or other
  bounded unit of change.

Do not ask a question if the answer is already in the workspace or current
conversation.

**Exit criteria:**

- [ ] You can name the optimization target in <=5 words.
- [ ] You know whether a baseline already exists.
- [ ] You know the target scale.
- [ ] You know whether the search should start with focused refinement or an
  early divergence round.
- [ ] You can name at least one likely iteration slice.
- [ ] You have noted project or user constraints.

If you cannot check all five, ask the smallest blocking question:

> What exactly are we optimizing, at what scope, what should be noticeably
> better when we stop, and does this need focused refinement or a bolder search
> for direction?
>
> Recommended answer: "Optimize [single artifact / artifact set / subsystem /
> full codebase / goal] so that [outcome] is true, using [focused refinement /
> diverge then converge]."

## Phase 1 - Lock the goal and stop rule

This phase turns "make it better" into an optimization contract.

### Step 1.1 - Clarify the job

Ask enough to nail down:

- **Outcome.** What does success look like in the real world?
- **Audience or user.** Who consumes the result and what do they care about?
- **Constraints.** Scope, format, interfaces, timing, compatibility,
  performance, style, or safety limits.
- **Aspirational delta.** What would make the result clearly stronger, more
  memorable, or more decision-useful instead of merely cleaner?
- **Stakes.** Throwaway exploration, internal handoff, production code,
  customer-facing deliverable, or larger transformation.

Recommended starter question:

> What are we optimizing, who is it for, and what needs to be noticeably better
> when we stop?
>
> Recommended answer: infer from context when possible; if ambiguous, state the
> best guess and ask the user to sharpen it.

### Step 1.2 - Choose the search posture

Choose one search posture:

- **Focused refinement** - the current direction is already right; optimize
  within it.
- **Diverge then converge** - the goal is open-ended, creative, or
  ceiling-uncertain; spend one round exploring materially different directions
  before hill-climbing the winner.

Ask if needed:

> Is the current direction already the right one to optimize, or should one
> round be spent exploring bolder alternatives first?
>
> Recommended answer: "Use focused refinement if the direction is already
> sound. Use diverge then converge if we need a stronger concept, sharper point
> of view, or more surprising approach."

### Step 1.3 - Classify the target

Choose one target class:

- **Single artifact** - one file, document, component, or deliverable
- **Artifact set** - a related set of files or documents that must stay aligned
- **Subsystem** - a bounded part of a larger codebase or workflow
- **Full codebase** - broad repo-level improvement work
- **Goal-only** - no baseline exists yet, so round 0 must create one

For anything larger than a single artifact, also choose the unit of iteration.

Ask if needed:

> Is this a single artifact, a related set, a subsystem, a whole codebase, or
> goal-only with no baseline yet? What should one round of work actually touch?
>
> Recommended answer: "Treat it as [target class]. The unit of iteration should
> be [section / file / component / workstream]."

### Step 1.4 - Set the completion rule

Pick the score threshold and the fallback if the work stalls before reaching it.

Ask if needed:

> What score counts as done, and what should happen if we plateau below it?
>
> Recommended answer: "Aim for XX/100. If we plateau below that, run one
> best-of-N escape round, then stop and report the remaining gap." If the user
> has no preference, default to 85/100.

**Exit criteria:**

- [ ] The goal fits in one sentence.
- [ ] The search posture is chosen.
- [ ] The target class is chosen.
- [ ] The unit of iteration is chosen for large targets.
- [ ] A threshold score is defined.
- [ ] A plateau fallback is defined.

## Phase 2 - Build the rubric

The rubric is the ceiling. A vague rubric caps the loop low.

### Step 2.1 - Discover the quality dimensions

Do not guess what matters. Help the user articulate the dimensions that define
quality for this target.

Use questions like:

> If you graded this target on 5-9 dimensions, what would they be? What
> separates a weak version from a strong one?
>
> Recommended answer: propose 3-5 candidate dimensions based on the target
> class and context, then ask the user to add, remove, or reweight.

> What are the most common ways this kind of target fails?
>
> Recommended answer: name 2-3 failure modes that are specific to this target.

> Which dimension measures actual goal attainment rather than polish?
>
> Recommended answer: include one dimension like correctness, outcome fit,
> decision fitness, user value, or operational reliability.

> If this target benefits from originality, what dimension captures
> distinctiveness, insight, or point of view rather than generic polish?
>
> Recommended answer: include a dimension like differentiation, conceptual
> strength, memorable framing, or creative leverage when the goal is open-ended.

> If this target is a workflow, prompt, plan, or skill, what dimension measures
> shortcut resistance or execution fidelity rather than just readability?
>
> Recommended answer: include a dimension like enforceability, execution
> fidelity, shortcut resistance, or handoff reliability when the artifact is
> supposed to control behavior rather than merely describe it.

Synthesize the answers into 5-9 distinct dimensions. Fewer than 5 is too
coarse. More than 9 usually means overlap.

### Step 2.2 - Assign weights and anchors

For each dimension, assign a weight from 1-10 and define two observable anchors:

```markdown
### [Dimension] (weight: X)
- 2/10: [concrete failure the user could point at]
- 10/10: [concrete excellence achievable for this target]
```

Rules for anchors:

- A 2/10 must name a real failure, not a vague vibe.
- A 10/10 must be achievable within the current scope.
- Anchors must match the target scale. For codebases and artifact sets they can
  reference integration failures, missing slices, or system-level regressions.
- If a creativity dimension exists, its anchors must still be observable: name
  what makes the work generic at 2/10 and what makes it distinctive without
  breaking constraints at 10/10.
- If the target is a workflow, prompt, or skill, at least one dimension should
  measure whether a user or agent could plausibly shortcut the intended
  behavior while still claiming compliance.
- At least one dimension must measure outcome attainment, not just surface
  quality.

### Step 2.3 - Approval gate (HARD GATE)

Do not score the baseline, edit the target, or claim the loop has started
beyond setup until the user explicitly approves the rubric and threshold.

Present the complete rubric and threshold before scoring anything:

```markdown
## Proposed Rubric

### Dimension 1 (weight: X)
- 2/10: ...
- 10/10: ...

### Dimension 2 (weight: X)
...

Threshold: XX/100
```

Then ask:

> Does this rubric capture what good means for this target? Adjust dimensions,
> weights, anchors, or threshold before we score the baseline.
>
> Recommended answer: "Looks right - run it" or specific adjustments.

Do not proceed to scoring without explicit approval.

**Exit criteria:**

- [ ] 5-9 dimensions are defined.
- [ ] Dimensions are distinct.
- [ ] Weights make real tradeoffs.
- [ ] All anchors are observable at the current target scale.
- [ ] One dimension measures outcome attainment.
- [ ] If the target is open-ended, at least one dimension measures
  distinctiveness or conceptual strength rather than cleanliness alone.
- [ ] The user approved the rubric and threshold.

## Phase 3 - Establish the baseline

### If the target already exists

Accept the current state as the baseline. Read it, understand it, then score
it before changing anything.

### If only a goal exists

Create the first concrete baseline. This may be a first draft, a plan,
prototype, implementation slice, or another defensible first state. Do not
sandbag the baseline.

### If the search posture is diverge then converge

Before locking the baseline, generate 2-3 materially different candidate
directions. Different means structure, framing, interaction model,
architecture, sequencing, or concept - not cosmetic phrasing. Pick the
strongest candidate through quick rubric scoring or explicit user preference,
then treat that candidate as the official baseline.

### If the target is large

Score the target as a whole, then nominate the highest-leverage iteration slice
for round 1.

### Score the baseline

Score from 0-100. For each dimension, provide a sub-score and one-line
rationale. Combine with:

`sum(weight x score) / sum(weights) x 10`

### Approval gate (HARD GATE)

Do not start improvement rounds until the user explicitly confirms that the
baseline score feels calibrated or approves the rubric adjustment that fixes it.

Present the baseline scorecard:

```markdown
BASELINE SCORE: XX/100

Dimension              Weight  Score  Rationale
-----------------------------------------------
...                     ...     ...    ...
```

Then ask:

> Does this baseline score feel calibrated, or should we adjust the rubric
> before iterating?
>
> Recommended answer: if the score feels off by more than 10 points, fix the
> rubric first. Otherwise proceed.

**Exit criteria:**

- [ ] A baseline exists.
- [ ] The baseline scorecard was shown.
- [ ] The user confirmed the rubric and baseline feel calibrated.
- [ ] `best = baseline`, `best_score = baseline_score`, `history =
      [baseline_score]`.

## Phase 4 - Run the improvement loop

```text
repeat:
    critique = find the highest score-cost weaknesses in best
    slice = choose the next iteration slice that can move the score
    candidate = improve that slice without regressing strong dimensions
    s = score(candidate)
    if s > best_score + MARGIN:
        best, best_score = candidate, s
    history.append(best_score)
until best_score >= threshold OR plateau detected OR max rounds reached
```

An improvement round only counts if it leaves behind all four artifacts:

1. A concrete critique tied to the rubric.
2. A durable candidate state.
3. A re-score using the same rubric.
4. An accept/reject decision against the margin.

### Step 4.1 - Critique before changing anything

List weaknesses ordered by score impact. Be concrete and target-aware.

Prefer ordering by weighted opportunity, not narrative convenience. A simple
heuristic is `weight x (10 - current_score)`, then break ties by choosing the
weakness whose fix is most local and least likely to regress strong
dimensions.

- For a spec: "Section 3 has no acceptance criteria. Costs 2 on testability."
- For an artifact set: "The rollout plan and README disagree on the migration
  sequence. Costs 3 on consistency."
- For a subsystem: "Retry behavior is documented but not implemented on the
  write path. Costs 3 on reliability."
- Reject vague notes like "could be better structured."

Name the 2-3 lowest dimensions and tie them to specific files, sections,
behaviors, or missing work.

### Step 4.2 - Improve the next slice

Produce a complete, usable next state for the chosen slice.

Rules by target class:

- **Single artifact:** output the full revised artifact.
- **Artifact set:** update the affected set or named subset and keep them
  aligned.
- **Subsystem or full codebase:** make concrete changes in the chosen slice and
  update tests, docs, config, or interfaces needed to keep the system coherent.
- **Goal-only:** produce the next concrete baseline candidate, not meta-advice.

If the search posture is diverge then converge, at least one candidate round is
allowed to reframe the slice instead of merely polishing it, as long as it
still serves the goal and constraints.

A rewritten candidate without the follow-up score and accept/reject decision is
not a valid loop round.

Prefer 1-3 high-leverage fixes in a round over many shallow edits that make the
score harder to interpret.

Do not output only a list of intentions. Leave behind changed files, revised
artifacts, or another durable state.

### Step 4.3 - Score and decide

Score the candidate with the same rubric and the same rigor.

Only accept the candidate if it beats the current best by more than the noise
margin:

- **Documents, specs, plans:** +2
- **Code or design changes:** +3
- **Artifact sets, subsystems, codebases:** +3
- **Default:** +2

Re-anchor every 3 rounds by re-reading the original rubric anchors, not just
the latest rationales.

### Step 4.4 - Escape when hill-climbing stalls

- **Default:** hill-climb for rounds 1-3 when the direction is already sound.
- **If the search posture is diverge then converge:** use round 1 or the first
  stalled round to generate 2-3 materially different approaches, then
  hill-climb the winner.
- **If stalled:** after 2 consecutive non-improving rounds below threshold, run
  one best-of-N escape round with N=2 genuinely different approaches.
- **Escape moves must be orthogonal.** Change structure, framing, audience
  emphasis, system boundary, interaction model, sequencing, or distribution of
  responsibility. Borrow from adjacent domains when it improves the score.
- **After escape:** if neither approach beats the best score by more than the
  margin, treat the search as plateaued.

### Plateau detection

Stop when:

- Best score has not improved by more than the margin over the last 3 rounds,
  **AND**
- You have either tried one best-of-N escape round or already met the
  threshold.

Hard-stop at 8 rounds regardless.

**Exit criteria:**

- [ ] At least 2 rounds completed (baseline + 1 improvement).
- [ ] The stop reason is explicit: threshold, plateau, or max rounds.
- [ ] Best-of-N was attempted if the score plateaued below threshold.
- [ ] `best` is a complete, usable target state.

## Phase 5 - Verify

Before delivering, run these checks:

1. **Score-reality check.** Does the score match your honest assessment? If not,
   the rubric has a blind spot.
2. **Goal-attainment check.** Does the current best actually advance the
   original goal, not just polish a local slice?
3. **Constraint and integration check.** Does the best state still respect the
   user's constraints and stay coherent with adjacent artifacts or code?
4. **Regression check.** Compared with the baseline, is the result genuinely
   better in ways a real consumer would notice?

If any check fails, adjust the rubric or run one more iteration.

**Exit criteria:**

- [ ] All 4 checks pass, or failures are documented.

## Phase 6 - Deliver

Deliver in this order:

### 1. The best target state

Lead with the revised artifact, changed slice, plan, or other durable output.

### 2. Scorecard

```markdown
FINAL SCORE: XX/100

Dimension              Weight  Score  Rationale
-----------------------------------------------
...                     ...     ...    ...
```

### 3. Score trajectory

```text
Baseline -> R1 -> R2 -> ... -> Final
   XX    -> XX -> XX -> ... ->  XX
```

### 4. What changed

List the 2-3 biggest improvements from baseline to final. Make them observable.

### 5. Remaining gap

If the final score is below threshold, name what prevented the target from
getting there.

### 6. Rubric preservation

Save the rubric alongside the deliverable, as an appendix, comment, adjacent
file, or other durable location so the loop can resume later.

## Anti-patterns

- **Artifact tunnel vision.** Treating every optimization target as if it were
  one file.
- **No threshold.** Looping forever because "better" was never quantified.
- **Local-only scoring.** Accepting a change because one slice improved while
  the overall target got worse.
- **Meta-loop without a baseline.** Talking about improvement without ever
  producing a first concrete state.
- **Premature convergence.** Treating the first plausible direction as the only
  direction before checking whether a higher-ceiling alternative exists.
- **Rewrite-everything fantasy.** Trying to rework an entire codebase in one
  round instead of choosing a slice.
- **Approval theater.** Presenting a rubric or baseline scorecard and then
  continuing before the user confirms.
- **Refinement prison.** Polishing the current path when the real leverage is a
  different framing, structure, or concept.
- **Loopify in name only.** Claiming to have used the process after skipping the
  contract, approval gates, baseline scorecard, or scored iteration rounds.
- **Rubric drift.** Quietly changing what counts as good after scoring starts.
- **Sandbagging the baseline.** Starting weak just to manufacture a dramatic
  score climb.
- **Convenience stop.** Ending because the work is decent now, despite not
  hitting the threshold or plateau condition.
- **Plateau denial.** Burning rounds after the search has obviously converged.

## Quick reference: target-specific dimension prompts

These are starting points, not templates.

**For a single artifact or document:**
"Consider completeness, clarity, testability, scope precision, consistency,
and audience fit."

**For an artifact set or workflow:**
"Consider internal consistency, dependency clarity, handoff quality,
coverage across all required pieces, sequence correctness, and operational
usability."

**For a workflow, prompt, or skill:**
"Consider trigger precision, execution fidelity, shortcut resistance,
scanability under time pressure, recovery from misuse, and whether the artifact
actually controls behavior instead of only describing it."

**For a subsystem or codebase:**
"Consider correctness, reliability, maintainability, test coverage,
integration safety, performance on the hot path, and consistency with repo
conventions."

**For a goal with no baseline yet:**
"Consider goal fit, feasibility, clarity of execution, risk surfacing,
measurability, and the quality of the first concrete baseline."

**For open-ended creative or inspirational targets:**
"Consider goal fit, distinctiveness, conceptual strength, memorability,
feasibility, and how clearly the chosen direction earns its boldness."

## Final self-review

Before declaring done, verify:

- [ ] The skill owns generalized optimization, not a narrower neighboring job.
- [ ] The description states both capability and trigger contexts.
- [ ] Positive triggers and near misses are explicit.
- [ ] The workflow inspects context before asking the user anything.
- [ ] Every user-facing question pattern includes a recommended answer.
- [ ] I can show the contract, approved rubric, baseline scorecard, and at
  least one scored improvement round.
- [ ] The search posture is explicit: focused refinement or diverge then
  converge.
- [ ] The target class and iteration slice are explicit.
- [ ] The rubric and baseline both have approval gates.
- [ ] Open-ended targets can explore higher-ceiling alternatives instead of
  only polishing the first direction.
- [ ] Threshold and plateau are both explicit stop conditions.
- [ ] The loop stops for threshold, plateau, or max rounds, not convenience.
- [ ] The loop leaves behind durable outputs, not just advice.
- [ ] The skill stays standalone and extractable.
- [ ] At least 3 positive trigger examples and 2 near-miss examples fit the
      description.
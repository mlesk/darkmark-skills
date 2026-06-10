---
name: loopify
description: >-
  Turn any goal into a directed optimization loop — discover the quality
  dimensions that matter, build a domain-specific rubric, score the artifact,
  then iterate critique→improve→score until the output plateaus. Use when the
  user says "loopify this", "run the loop on this", "iterate until it's good",
  "optimize this", "refine this until it plateaus", "keep improving this",
  asks "is this as good as it can get?", or describes a quality-sensitive goal
  where the first draft won't be enough. Do NOT use when a domain-specific
  optimizer (design-optimizer-pocockified, ce-optimize) is already loaded, or
  the user wants a quick one-shot answer.
---

# Loopify

Generalize iterative optimization to any goal. Instead of shipping the first
draft, collaborate with the user to discover what "good" means for their
domain, build a weighted rubric, score the artifact, then run a directed
critique→improve→score loop until the output plateaus. The rubric is the
ceiling — a well-built rubric makes the loop climb; a vague one caps it low.

This skill is the generalized form of `design-optimizer-pocockified`. Where
that skill owns UI design with a fixed set of visual dimensions, this skill
discovers dimensions fresh for any domain: specs, plans, code, data models,
architecture, documentation, research, analysis — anything where quality can
be judged across multiple weighted dimensions.

## Trigger boundary

**Positive triggers — load this skill when the user:**

- Says "loopify this", "run the loop on this", "iterate until it's good"
- Says "optimize this [artifact]", "refine this until it plateaus"
- Says "keep improving this", "make this as good as it can get"
- Asks "is this as good as it can get?" or "is this done?"
- Describes a quality-sensitive goal and the agent suspects the first draft
  won't be enough → proactively ask "Should I loopify this?"
- Brings an existing artifact (file, document, code) and wants it hardened

**Near misses — do NOT load this skill when:**

- `design-optimizer-pocockified` has already loaded for a UI design task
  (let the domain-specific skill run — it has fixed visual dimensions this
  skill would waste time rediscovering)
- `ce-optimize` is appropriate (metric-driven code optimization with real
  measurements and benchmarks)
- The user wants a quick one-shot answer, wireframe, or throwaway draft
- The user explicitly says "just give me a first pass", "rough draft",
  "quick version", or "don't iterate"
- The task is trivial — a single dimension of quality, no tradeoffs to make

If uncertain whether to use this skill or a domain-specific one, ask:

> This overlaps with [other skill]. Should I use the general loopify
> process or the domain-specific optimizer?
>
> Recommended answer: based on context — if the domain-specific skill
> has a richer rubric for this domain, prefer it. Otherwise use loopify-it.

## Phase 0 — Inspect before asking

Before asking the user anything, inspect what is already available:

- **The artifact.** Is there an existing file? Read it. Is there only a goal
  description? Note what's specified and what's ambiguous.
- **The project context.** Existing standards, conventions, similar artifacts
  in the codebase, DESIGN.md, CONTEXT.md, ADRs, coding standards.
- **The user's intent.** Did they bring a polished draft (invested) or a
  rough idea (exploratory)? Adjust iteration depth accordingly.
- **Domain clues.** File extension, project type, user's role, surrounding
  conversation — these hint at what dimensions might matter.

**Exit criteria (do not proceed until all are true):**

- [ ] You have read the artifact or goal description.
- [ ] You know whether the artifact is existing (user brought it) or new
      (goal only, needs generation).
- [ ] You can state the artifact type in ≤5 words (e.g. "REST API spec",
      "React component", "data pipeline design", "project plan").
- [ ] You have noted any project conventions that will constrain quality
      dimensions.

If you cannot check all four, ask the smallest blocking question.

## Phase 1 — Discover the quality dimensions

This is the core differentiator. Do not guess what "good" means. Grill the
user until you can name the dimensions that matter for this specific goal.

### Step 1.1 — Understand the goal

Ask enough questions to nail down:

- **What is the artifact?** A document, a design, working code, a data model,
  an architecture, a plan, an analysis?
- **Who is the audience/user?** Who consumes this artifact and what do they
  care about?
- **What is the artifact's job?** What decision does it enable? What action
  does it trigger? What problem does it solve?
- **What are the stakes?** Is this throwaway exploration, team-facing
  documentation, production code, a customer-facing deliverable?

Recommended starter question:

> What are we optimizing, who's it for, and what does it need to
> accomplish?
>
> Recommended answer: infer from context if possible; if ambiguous,
> state your best guess and ask the user to sharpen it.

### Step 1.2 — Elicit dimensions

Help the user articulate what quality looks like. Use questions like:

> If you had to grade this [artifact type] on 5–9 dimensions, what
> would they be? What separates a C from an A+?
>
> Recommended answer: propose 3–5 candidate dimensions based on the
> artifact type and context, then ask the user to add, remove, or
> reweight.

> What are the most common ways this kind of [artifact type] fails
> or falls short?
>
> Recommended answer: name 2–3 failure modes you've observed or that
> are well-known for this artifact type.

> When you've seen an excellent [artifact type], what made it
> excellent? What do you remember about it?
>
> Recommended answer: if you have examples in the codebase or
> industry, reference them.

Synthesize the answers into 5–9 dimensions. Fewer than 5 means the rubric
is too coarse to guide improvement. More than 9 means dimensions overlap
and scoring becomes noisy.

**Exit criteria:**

- [ ] You can name the artifact type and its audience.
- [ ] You have 5–9 candidate dimensions, each with a clear one-line
      definition.
- [ ] Dimensions are distinct (no two measure the same thing).
- [ ] Dimensions cover both structural qualities (correctness, completeness,
      consistency) and experiential qualities (clarity, usability, elegance)
      as appropriate to the domain.

## Phase 2 — Build the rubric

A rubric is a weighted scorecard. Each dimension needs a weight, a floor
(2/10), and a ceiling (10/10). The anchors must be concrete and observable
in the artifact — not vibes.

### Step 2.1 — Assign weights

For each dimension, assign a weight (1–10) reflecting its importance to the
goal. Use this question if needed:

> Rank these dimensions by importance. Which ones, if great, make
> everything else forgivable? Which ones, if bad, ruin the whole
> artifact?
>
> Recommended answer: propose weights and let the user adjust.
> Typically 1–2 dimensions get weight 9–10 (the "must have" qualities),
> 2–3 get weight 6–8 (important), the rest get 3–5 (nice to have).

### Step 2.2 — Define anchors

For every dimension, write:

```
### [Dimension] (weight: X)
- 2/10: [observable failure — concrete, specific to this artifact]
- 10/10: [observable excellence — achievable, not fantasy]
```

Rules for anchors:

- A 2/10 must name something you can point at in the artifact.
  "Confusing" is a vibe; "three undefined terms in the first section"
  is an anchor.
- A 10/10 must be achievable within the scope of this goal.
  "Changes the industry" is fantasy; "every claim is backed by a
  concrete example" is an anchor.
- Anchors should be written in the language of the domain.
  For a spec: "missing acceptance criteria" not "incomplete."
  For code: "no error handling on the write path" not "fragile."

### Step 2.3 — User approval gate (HARD GATE)

Present the complete rubric to the user before scoring anything:

```
## Proposed Rubric

### Dimension 1 (weight: X)
- 2/10: ...
- 10/10: ...

### Dimension 2 (weight: X)
...
```

Then ask:

> Does this rubric capture what "good" means for this [artifact type]?
> Adjust weights, anchors, or dimensions before we start scoring.
>
> Recommended answer: "Looks right — run it" or specific adjustments.

Do not proceed to scoring without explicit approval.

**Exit criteria:**

- [ ] 5–9 dimensions defined with weights and anchors.
- [ ] All anchors are observable in the artifact.
- [ ] User has approved the rubric.
- [ ] Weights sum to a reasonable spread (not all 5s — make tradeoffs).

## Phase 3 — Establish the baseline

### If the user brought an existing artifact

Accept it as the starting point. Do not regenerate or rewrite it before
scoring. Read it fully, understand it, then score.

### If only a goal exists (no artifact yet)

Generate a first version. Commit to a direction — don't sandbag.
A strong start reaches a higher final ceiling. Apply domain best
practices from the project context.

Ask one question if the direction is genuinely ambiguous:

> Before I generate the first version — any preferences on approach,
> style, or structure?
>
> Recommended answer: if the project has conventions, follow them.
> If the domain is unbounded, pick a strong, defensible direction
> and state it before generating.

### Score the baseline

Score from 0–100. Dimension by dimension: sub-score (0–10), one-line
rationale. Combine: `sum(weight × score) / sum(weights) × 10`.

### User approval gate (HARD GATE)

Present the baseline scorecard:

```
BASELINE SCORE: XX/100

Dimension              Weight  Score  Rationale
──────────────────────────────────────────────────
...                     ...     ...    ...
```

Then ask:

> Does this score feel right? Should we adjust the rubric before
> iterating, or does this accurately reflect where we are?
>
> Recommended answer: if score feels off by >10 points, fix the
> rubric first (wrong weights or anchors). Otherwise proceed.

**Exit criteria:**

- [ ] Baseline artifact exists (existing or generated).
- [ ] Baseline scored with per-dimension breakdown.
- [ ] User confirms rubric + baseline score feel calibrated.
- [ ] `best = baseline`, `best_score = baseline_score`, `history = [baseline_score]`.

## Phase 4 — The improvement loop

```
repeat:
    critique = find weaknesses in best, ordered by score cost
    candidate = rewrite best to fix critique's top 3–5 items
    s = score(candidate)
    if s > best_score + MARGIN:
        best, best_score = candidate, s
    history.append(best_score)
until plateau detected OR max rounds reached
```

### Step 4.1 — Critique (separate pass, before rewriting)

Against the rubric, list weaknesses ordered by score impact. Be concrete
and domain-appropriate:

- ✅ For a spec: "Section 3 has no acceptance criteria — purely
  descriptive. Costs 2 on completeness."
- ✅ For code: "Error handling is absent on the write path — any
  failure crashes. Costs 3 on reliability."
- ✅ For a plan: "Phase 3 has no dependencies listed — can't tell
  what blocks what. Costs 2 on executability."
- ❌ "Could be better structured" — unactionable, reject.

Name the 2–3 lowest dimensions and why they're low. Reference specific
sections, lines, or properties of the artifact.

### Step 4.2 — Rewrite (full artifact, not a diff)

Produce a **complete, working** new version that fixes the critique's
top 3–5 items while preserving what scored well. Do not regress
strengths to chase a weakness.

**Critical rules:**

- Output the full artifact, not a diff or list of changes.
- Every rewrite must stand alone — usable without referring to
  prior versions.
- If the rewrite would lose the artifact's core identity or
  violate a constraint the user set, stop and ask.

The form of "rewrite" depends on the artifact type:

- **Document (spec, plan, analysis):** Rewrite the full document
  text with improvements.
- **Code:** Rewrite the full file(s) with refactoring, added tests,
  improved structure, better error handling.
- **Design/UI:** Rewrite the full HTML/CSS/component code.

### Step 4.3 — Score and decide

Score the candidate with the same rubric, same rigor.

**Acceptance gate:** Only replace `best` if `s > best_score + MARGIN`.
MARGIN depends on the domain:

- **Documents (specs, plans):** +2 (scoring is tighter, less noise)
- **Code:** +3 (refactoring can be lateral)
- **Design/UI:** +3 (visual scoring is noisier)
- **Default:** +2

A 1-point difference is noise; MARGIN means real improvement.

**Re-anchor check:** Every 3 rounds, re-read the original rubric anchors
(not the latest score rationales). This catches drift where the artifact
slowly becomes something the rubric didn't ask for.

### Step 4.4 — Choose strategy

- **Hill-climb (default):** One critique → one rewrite per round.
  Fast, efficient.
- **Best-of-N (escape):** When hill-climb stalls for 2+ rounds,
  generate N=2 genuinely different approaches — different structure,
  different organization, different architecture, not minor variants.
  Score all independently. Keep the best. If best-of-N also fails to
  beat the ceiling by MARGIN, you've converged.

**Default policy:** Hill-climb rounds 1–3. If plateaued after round 3,
one best-of-N round. If still plateaued, stop.

### Plateau detection

Stop the loop when:

- Best score hasn't improved by >MARGIN over the last 3 rounds, **AND**
- You've tried at least one best-of-N escape round (or score is already
  85+).

Also hard-stop at 8 rounds regardless. Past 8 rounds you're spending
effort to move noise around.

**Exit criteria (all must be true):**

- [ ] At least 2 rounds completed (baseline + 1 improvement).
- [ ] Plateau detected with sliding window or max rounds hit.
- [ ] Best-of-N attempted if plateau was below 85.
- [ ] Final `best` is a complete, usable artifact.

## Phase 5 — Verify

Before delivering, sanity-check the result against real-world usefulness:

1. **Score-reality check.** Does the score match your honest assessment?
   If the score says 85 but the artifact feels mediocre, the rubric has
   a blind spot — name the missing dimension and note it in the delivery.
2. **Identity check.** Does the artifact still accomplish its original
   job? Or did optimization drift it into a different thing?
3. **Constraint check.** Does the final version still respect any
   constraints the user set (format, platform, audience, scope)?
4. **Regression check.** Compare `best` to `baseline`. Is it genuinely
   better, not just higher-scoring? Can you point to specific
   improvements a reader/user would notice?

If any check fails, diagnose which rubric dimension is blind, adjust it,
and run one more iteration.

**Exit criteria:**

- [ ] All 4 checks pass, or failures are documented with rationale.

## Phase 6 — Deliver

Deliver in this order:

### 1. The best artifact (lead with this)

The complete, working artifact — the deliverable. Write it to the
appropriate file if one exists, or present it directly.

### 2. Scorecard

```
FINAL SCORE: XX/100

Dimension              Weight  Score  Rationale
──────────────────────────────────────────────────
...                     ...     ...    ...
```

### 3. Score trajectory

```
Baseline → R1 → R2 → ... → Final
   XX    → XX → XX → ... →  XX
```

### 4. What changed

The 2–3 biggest improvements from baseline to final. Be specific about
what a consumer of the artifact would notice:

- ✅ "Added concrete acceptance criteria to all 12 user stories —
  went from descriptive to testable."
- ✅ "Wrapped all database writes in transactions with rollback on
  failure — error handling went from absent to defensive."
- ❌ "Improved the artifact" — meaningless.

### 5. Rubric preservation

Save the rubric alongside the artifact (as a comment, appendix, or
adjacent file) so future sessions can re-score or continue the loop
without rebuilding dimensions from scratch.

## Anti-patterns

- **Loop without rubric.** Running critique→improve without a written
  rubric is random walk, not search. The rubric must exist before round 1.
- **Sandbagging the baseline.** Generating a weak first version to
  manufacture a dramatic score climb. The ceiling is lower if you start
  low. Commit to a strong first version.
- **Vague dimensions.** "Clarity" without anchors lets the scorer drift.
  Every dimension needs concrete 2/10 and 10/10 that you can point at.
- **Approval theater.** Presenting the rubric and baseline scorecard but
  proceeding before the user confirms. These are hard gates — wait.
- **Rubric drift.** Scoring gets looser each round as the agent gets
  attached to the artifact. Re-anchor on the original rubric every 3 rounds.
- **Over-polishing to sameness.** The loop can sand off distinctive edges.
  Before accepting an improvement, ask "does this still have a point of
  view?" A 78 with personality beats an 82 that looks like everything else.
- **Never stopping.** Respect the plateau and max-rounds cap. Past the
  plateau you're burning the user's patience rearranging deck chairs.
- **Scoring for the scorer.** The rubric is a proxy for usefulness, not a
  replacement. If the rubric says 85 but a real user would be confused,
  trust that instinct and fix it regardless.
- **Premature domain narrowing.** Don't force the user's goal into preset
  archetypes (spec, plan, UI, code). Discover dimensions from the goal,
  not from a catalog.

## Quick reference: domain-specific dimension prompts

While dimensions are always discovered fresh, these prompts help the
agent kickstart the discovery conversation for common artifact types:

**For a specification/PRD:**
"Consider: completeness (are all requirements covered?), clarity
(can an implementer act on this without asking?), testability (can
every requirement be verified?), scope precision (is the boundary
sharp?), consistency (do terms and concepts agree throughout?),
prioritization (is it clear what matters most?)."

**For an implementation plan:**
"Consider: executability (can someone follow the phases in order?),
dependency clarity (what blocks what?), risk surfacing (are
assumptions and unknowns named?), resource realism (time/people
estimates grounded?), milestone definition (clear done criteria per
phase?), contingency handling (what if something fails?)."

**For code:**
"Consider: correctness (does it handle edge cases?), readability
(can a new teammate understand it?), test coverage (are the
important paths tested?), error handling (does it fail safely?),
performance (are hot paths efficient?), maintainability (is
complexity justified?), consistency (does it follow project
conventions?)."

**For a data model:**
"Consider: normalization (right level for the use case?), constraint
coverage (are invariants enforced at the schema level?), query
ergonomics (can common queries be expressed naturally?), evolution
safety (can it change without breaking everything?), documentation
(are fields and relationships explained?)."

These are starting points, not templates. Adapt, add, remove, and
reweight based on the user's actual goal.

## Final self-review

Before declaring done, verify:

- [ ] Rubric was built collaboratively with the user and approved.
- [ ] Baseline was scored and the scorecard shown to the user.
- [ ] At least 2 improvement rounds were attempted.
- [ ] Plateau was detected (not just "looks good, stopping").
- [ ] Best-of-N was attempted if plateau was below 85.
- [ ] Final artifact is complete and usable.
- [ ] Scorecard, trajectory, and change summary are delivered.
- [ ] Rubric is preserved for future sessions.
- [ ] The 4 verification checks (Phase 5) passed or failures are
      documented.

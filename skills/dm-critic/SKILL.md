---
name: dm-critic
description: Independent adversarial review of a finished piece of work (a document, plan, PR, design, skill, or code change) by two reviewers with fresh context — a critic who hunts defects and an orthogonal explorer who proposes higher-ceiling alternatives — whose findings are verified and merged into one table of next-step options. Use when the user says "critique this", "tear this apart", "red-team this", "what am I missing", "review this before I ship it", or when dm-loopify reaches its review step. Do NOT use for line-level code review of a diff for bugs only, for prose style editing (use dm-write), or before a first draft exists (use dm-grill).
---

# Critic

Work reviewed by its author misses the author's blind spots. Two reviewers with fresh context attack it from opposite directions. You check what they found, merge it, and hand the user a choice. You do not fix anything until the user chooses.

## Phase 1 - Build the review packet

Write the packet to a file (default `reviews/<target>-packet.md`, or wherever the caller says):

- **Target:** the work itself, or for large targets the diff plus the paths needed to inspect the whole.
- **Goal, audience, constraints:** what the work is for and what it must not break.
- **Baseline** (optional): the earlier version, so regressions are visible.
- **Rubric anchors** (optional): the 2/10 and 10/10 anchors, without any scores or rationales.
- **Rejected directions** (optional): approaches already tried, one line each on why they lost.

If the goal is unknown, ask one question, with a recommended answer, before reviewing. A critique with no goal turns into a list of personal preferences.

**Control what each reviewer sees.** This is what makes the review independent:

| Reviewer | Sees | Never sees |
| --- | --- | --- |
| A - Critic | target, goal, constraints, baseline, rubric anchors | scores, rationales, the author's hopes |
| B - Explorer | target, goal, constraints, rejected directions | the rubric, scores, Reviewer A's output |

## Phase 2 - Run both reviewers in parallel

Start each one as a sub-agent with fresh context and only its slice of the packet. Prompts:

**Reviewer A - Critic.** "Find contradictions, gaps, unsupported claims, constraint violations, integration breaks, and places where the work claims more than it delivers. For each finding give: location, evidence (quote or command output), severity (blocker / major / minor), the rubric dimension it affects or `outside rubric`, and a suggested fix. No praise. No rewrites. Run any check you can run rather than guessing."

**Reviewer B - Orthogonal explorer.** "Propose 3-5 materially different ways to raise the ceiling on this goal: change the structure, framing, audience emphasis, system boundary, interaction model, sequencing, or who is responsible for what, or borrow from an adjacent domain. Not polish. For each: the move, the expected upside, the cost, the constraint it strains, and how it differs from the rejected directions."

**No sub-agents available?** Run A, save its output, then run B without rereading A. Do not revise A after reading B. Label the review `single-agent, reduced independence`.

## Phase 3 - Verify and merge

Reviewers can be wrong. Check every item against the actual target and mark it:

- **confirmed** - you reproduced or located it
- **disputed** - with a one-line reason
- **out of scope** - real, but outside the goal or constraints

Never drop an item silently. Disputed items stay in the table.

Merge into one table. Deduplicate items both reviewers raised and mark them `A+B`. Where A and B pull in opposite directions, keep both as alternatives; do not settle the conflict yourself.

```text
CRITIC REVIEW: <target>   (independence: full | single-agent, reduced)

ID  Source  Type               Status     Severity  Dimension  Effort  Recommendation
------------------------------------------------------------------------------------
R1  A       defect             confirmed  blocker   ...        S       ...
R2  B       opportunity        -          -         outside    L       ...
R3  A+B     rubric blind spot  confirmed  major     (new)      M       ...
```

Types: `defect`, `gap`, `opportunity`, `rubric blind spot`. Effort: S / M / L.

## Phase 4 - Hand back the choice (HARD GATE)

Save both raw reviews and the merged table next to the packet.

**Called by another skill** (for example `dm-loopify`): return the table and file paths. The caller runs its own next-step gate.

**Standalone:** present the table, then ask:

> Which findings should I act on? For example: "fix all confirmed blockers and majors", "R1 and R4 only", or "none, just keep the record".
>
> Recommended answer: fix confirmed blockers and majors now; record minors and opportunities for later.

Do not change the target before the user chooses. Then apply only the chosen items and say which IDs were fixed, deferred, or disputed.

## Anti-patterns

- **Rubber-stamp review.** Showing reviewers the scores or the answer you hope for.
- **Review theatre.** Spawning reviewers, then filtering or acting on findings before the user chooses.
- **Silent drop.** Leaving a finding you disagree with out of the table.
- **Polish as exploration.** Reviewer B suggesting wording tweaks instead of different approaches.
- **Endless review.** Re-running the review after every fix. One review per piece of work unless the user asks again.

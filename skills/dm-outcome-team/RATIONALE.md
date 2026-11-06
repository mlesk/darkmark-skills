# Rationale: an outcome-only agent team

Agents never load this file. It explains why [SKILL.md](./SKILL.md) is shaped the way it is. `dm-agent-team` is unchanged; [COMPARISON.md](./COMPARISON.md) sets the two side by side.

## The idea

`dm-agent-team` already says "goals and limits, not procedures" (GUIDE.md §1.6), but it doesn't follow its own rule. Its runtime is about 11,200 words across SKILL.md, PROTOCOL.md, ROUTING.md, two agent files, and seven references. Most of those words are procedure: steps, tables, templates, file layouts, section numbers, and retry counts. The draft keeps the goals and limits and drops the procedure. It is about 1,400 words in a single file, including the contracts section.

The test I applied to every rule: **would a reviewer reject the result if this rule were broken, even if the process looked fine?** If yes, it's an outcome or a constraint, and it stays. If the rule only says how to get a good result, it goes.

## Goals extracted from the current skill

| Goal | Where it lives today | How the draft states it |
|---|---|---|
| Idea to working, accepted software | SKILL.md steps 1–6 | Done means §1 |
| Human intent captured once, then autonomy | Step 2, the 12-question interview | The human's part: ask once, then don't interrupt |
| Human in control at the moments that matter | Run-mode table, stop rule, 5 gate types | Decision points: direction and result always, design unless they chose autonomy |
| Independent review, not self-grading | dm-at-reviewer, spec-review, milestone-review, acceptance | Done means §3, independence as a property |
| Every requirement proven by a test | Trace IDs, `REQ_004_2` test names, precheck check 3 | Done means §2 |
| Build only what was asked | "What can't be traced is out of scope" | Done means §2, last sentence |
| Code quality | 03 §10.1 quality gate, verify, verify-full | Done means §4 |
| Clean room and allowlist | PROTOCOL §Clean room, §11 allowlist | Hard limits |
| Safety | Hard stops in every mode | Hard limits |
| Brownfield safety | BROWNFIELD.md (1,150 words) | Hard limits: existing code |
| Resumable, unattended runs | state.md skeleton, next-action, run.sh, session breaks, EXCEPTIONS §Recover and §Drift | Surviving interruption |
| Visible decisions | `D-###`, `ASM-###`, §Open items | Done means §6 |
| Living system knowledge | `system/`, RUNS §Consolidate | Done means §5 |
| Learning across runs | retro.md, lessons.md | Done means §7 |
| Cost efficiency | The lean-2 premise, size table, ROUTING.md effort levels | Spending well |
| No runaway loops | REVISE round caps, escalation, circuit breaker | Hard limits: bounded effort |
| Honest reporting | "Check each claim against a tool result" | Honest reporting |

All 17 goals survive. What changes is the form: each one is now a property of the result instead of a step that produces it.

## What was dropped, and why that's safe

- **The six-step sequence, stage names, and gate names.** The model can sequence the work itself. The draft fixes only the order that matters to the human: direction, then design, then result.
- **The `small`/`standard`/`large` size table and the three-row run-mode table.** These become one sentence each: scale the process to the job, and give the human the autonomy they chose. The current tables spell out roughly 30 cells of policy the model can derive.
- **Spec templates, section numbers, and the ID prefix scheme.** What matters is that requirements are precise enough to test and that tests prove them. The current shape exists partly so that `precheck.sh` can parse it (see the contracts section below).
- **The builder and reviewer roles, the dispatch prompt, the Return block, and ROUTING.md tiers and efforts.** The draft requires independence of review and leaves the rest to the model: whether to use helpers, how many, and at what effort. The cost facts stay as one line ("fresh contexts are expensive").
- **REVISE round counts, the escalation rule, and the circuit breaker.** These become one constraint: when work stops converging, change something or escalate, and never loop.
- **EXCEPTIONS.md, PARALLEL.md, and RUNS.md.** These are recovery and bookkeeping procedures. The outcome behind them is "a fresh session can resume safely and notices tampering."

## What looks like "how" but stays

A few rules in the draft read like process. They stay because they are quality bars the result is judged by:

- **One interview up front.** This is about the human's experience. Being asked questions all through the run is a defect in itself, whatever comes out at the end.
- **Fresh-context review.** Anthropic's harness research found that agents grade their own work too generously. Independence is a property of the evidence, not a step in the method.
- **Tests are evidence; don't edit them to get green.** ImpossibleBench shows models will game tests. This is a constraint on the means because the means corrupt the outcome.
- **Pin current behaviour before changing it.** This is the only way to prove "nothing that worked before broke."

## Contracts with the scripts (decided: option 2)

The current skill's most distinctive parts, according to the research, are `precheck.sh` and `run.sh`, and both are deterministic. They depend on fixed formats: precheck reads `touches:`, `acceptance tests:`, and §9–§13 of 03, and run.sh reads `status:`, `stage:`, and `next-action:` from state.md. A pure outcome skill can't promise those formats. There are three ways to handle it:

1. **Pure outcomes (the draft as written).** The model writes its own checks ("make checks mechanical where you can"). This is simplest, but you lose a tested precheck, and run-to-run variance goes up.
2. **Outcomes plus a contracts appendix.** Keep the scripts and add one short section that names the formats they read. These are interface specifications, not process, in the same way that an API contract isn't an implementation. Mark chose this on 6 Nov 2026. It is now the last section of SKILL.md, about 230 words, and it keeps the deterministic gate.
3. **Tools offered, not required.** Ship the scripts with the skill and say "these exist and check X; use them or something at least as strict." This is flexible, but it's harder to tell whether it was done.

## Risks

- **More variance.** Two runs may produce very different artifacts, which makes audits and comparisons harder. Outcome-based evals help here, and the "Done means" list doubles as the scoring rubric.
- **Weaker models may under-process.** The procedure was partly a scaffold for less capable models. The draft assumes the 5.x-class judgment that lean-2-design.md already cites.
- **Quiet regression to self-review.** Without a named reviewer agent, a model might review its own work in the same context and call it independent. The draft's wording ("not on the judgment of the context that produced it") is meant to close that gap. An eval should check it.
- **Cost could go either way.** Less instruction to read, but no guardrail against spawning many helpers. "Spending well" is the only brake, so the cost ceiling in the hard limits matters.

## How to find out if it's better

Add it as an arm in the bakeoff that the research already proposes (old main, lean-2, Superpowers), using the same `tally` kickoff. Score every arm against the seven "Done means" items, and compare cost, human stops, and defects found at acceptance. Run each arm two or three times, because variance is the main risk here.

## Changes after the first test run

The first test run built Blockfall on 6 Nov 2026 and was accepted. Its retro led to two edits to SKILL.md:

- **Done means §2 is sharper.** A test must fail if *any* part of its requirement breaks, and a check that a named test exists doesn't count as proof. The scripted precheck passed tests that covered only part of their rule. Only the fresh acceptance reviewer caught them. The section now also asks for timing, limits, and how rules interact, which were most of the 8 gaps the design review found.
- **The one interview also asks where the work lives** when the project isn't a repository yet. The run had to settle this in the interview, which worked, but the skill didn't say to ask.

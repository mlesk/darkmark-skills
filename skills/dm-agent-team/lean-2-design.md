# Design note: lean-2

**Status: implemented on branch `lean-2`** (October 2026). Agents never load this file. It records why lean-2 is shaped the way it is, so the side-by-side comparison with the previous version can be read against intent.

## The premise: where a run's cost comes from

Three facts about the Claude API, from Anthropic's current documentation, decide the shape:

1. **Cost per turn is the whole context resent.** Cached input is cheap (reads at 0.05× on Opus 5.5, 0.025× on Fable 5.1), so task cost is driven by *turns × context size*, and above all by **how many separate contexts are built from zero**. Every subagent is a fresh conversation: whatever it reads is a cold cache write, and when it returns, that context is thrown away.
2. **A cache read refreshes the entry's timer.** On a 5-minute TTL, an agent that makes a tool call every minute keeps its own entry warm indefinitely. The TTL only bites on a **gap over 5 minutes between an agent's own requests**, which in this skill means one thing: a verify command that runs long. On a 1-hour TTL (the main thread), human pauses at gates are free.
3. **N parallel requests with the same prefix all pay full price.** A cache entry becomes readable only after the first response begins streaming.

The previous design treated the Lead's long-lived context as the scarce resource ("read Returns, not artifacts") and subagent contexts as free. Under a 1-hour main-thread cache and a 5-minute subagent cache, that is backwards: the main thread is the *cheapest* place to accumulate context, and every dispatch is the expensive thing. The first end-to-end run made 60+ dispatches to build a few hundred lines of code.

## The inversion

**Do sequential, context-heavy work in the main thread. Use subagents only for what genuinely needs a fresh context (independent review) or genuine parallelism (large independent phases).**

Anthropic's guidance for the 5.x models points the same way: separate fresh-context verifier agents outperform self-critique (keep the reviewer); long-lived sub-agents outperform spawn-and-block because they keep their context (keep the builder alive across phases); prompts written for earlier models are often too prescriptive and reduce output quality (state goals and constraints, not steps); the model performs better when it knows the *reason* behind a request, and when it has a memory surface.

## What changed, and the expected effect

| # | Change | Expected effect |
|---|---|---|
| 1 | **One warm pass writes all the specs.** The Lead writes 01, 02, and 03 (with the build plan inside 03) in its own context, after the interview, reading `references/SPECS.md` for what good looks like. One fresh-context review, one spec gate. The analyst, designer, and architect agents are gone. | Spec-stage dispatches from 8–12 to 1–2; spec tokens −50–70%; fewer REVISE rounds, because specs written in one context agree by construction (the previous run's costliest failure was architecture taking three rounds). |
| 2 | **One discovery interview up front, no questions after it.** The Lead interviews the human in one or two rounds covering what the analyst, designer, and architect used to ask separately. Downstream, nobody asks: agents decide, record an assumption, and the human sees it at the next gate. | Human stops from 5–8 to 3 (brief, spec, accept); the largest lever for running end to end without supervision. |
| 3 | **Continue the same agent on REVISE.** A builder or reviewer with findings is resumed, not re-dispatched. The precheck runs in seconds, so the resume lands inside the agent's 5-minute cache. | A revision round at ~20% of its previous cost. |
| 4 | **A persistent builder; worktrees only when parallel.** With `max-parallel: 1` (the default for small and standard runs) one builder builds the phases in order in the project root, returning after each for the precheck and commit, and keeps its context. Lanes and worktrees (`references/PARALLEL.md`) only when phases genuinely run in parallel. | Build-stage input tokens −40–60% in small and standard runs; no worktree and merge cycle per phase. |
| 5 | **Verify stays under the 5-minute line.** 03 names a fast `verify:` (target ≤ 3 minutes) and, where the full suite is slower, a `verify-full:` the Lead runs at integration and acceptance. | Avoids the one real TTL penalty: a long test run inside a subagent re-bills its whole context. |
| 6 | **Bookkeeping collapsed.** No handoff files (the dispatch prompt is the handoff), no CR files, no separate log: `state.md` carries the log, and it is updated at phase results, stage boundaries, and stops. The build plan lives in 03 §13. | Lead turns per dispatch from 4–6 to 1–2; ~10–15% of tokens, more in latency; fewer places for state to go stale. |
| 7 | **Effort: start lower, re-run failures higher.** Builders at `medium`, a REVISE round at `high`; reviewer at `medium`, acceptance at `high`. (Anthropic's measured pattern: run at a lower setting and re-run only failures higher holds pass rate at roughly half the cost.) | 10–20% of output tokens; unmeasured until the sweep. |
| 8 | **Session breaks at stage boundaries only.** After the spec gate (specs frozen, their context no longer needed) and after milestones, never at a dispatch count. | Keeps the Lead's 1-hour cache through a stage. |
| 9 | **Dropped as process for its own sake:** the requirements ⇄ UX feedback machinery (one author), the model-detection ceremony, consolidation as a reviewed dispatch (the Lead folds the run into `system/` at close), the gate presentation template, change-request files. Kept: trace IDs and `REQ_004_2` test names (they make the precheck script work), verify as a hard gate, the precheck script, three human gates, resumable state, the word budget. | Fewer turns and fewer rules to keep consistent. |
| 10 | **Instrumentation.** `scripts/run.sh` records each session's `total_cost_usd` and turn count (Claude Code's JSON output) in the run's `costs.tsv`; the retro reads it. A `lessons.md` in the team root gives the team a memory across runs. | Makes the comparison measurable; the memory surface is a documented gain on the 5.x models. |

## Honest sizing

The only data point is $34 and 60+ dispatches for a toy CLI on the full version. Lean-2 should run the same project in 6–10 dispatches with 3 human stops. These are estimates, not measurements: the side-by-side run is the test. Compare `costs.tsv` totals, dispatch counts in `state.md` §Log, REVISE rounds and escalations in `retro.md`, and the product at the accept gate.

## What this gives up

- **Role separation at authoring time.** One author writes requirements and architecture, so solution bias can leak into requirements. The reviewer checks for it (technology in 01 is a finding), and SPECS.md tells the author to write 01 before deciding anything in 03.
- **Isolation of a sequential build.** A single builder in the project root can leave the tree dirty if it crashes mid-phase; recovery is `git checkout -- . && git clean -fd` back to the last phase commit, which EXCEPTIONS.md spells out.
- **Direct invocation of the analyst, designer, and architect.** Only the builder and reviewer remain invocable on their own.

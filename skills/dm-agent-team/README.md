# dm-agent-team — Usage Guide

**Start here.** How to run the `dm-agent-team` skill, in directed mode (you at the gates) or yolo mode (unattended between the first and last gate).

- Why it is shaped this way, host setup, and migrating from the spec skills: [GUIDE.md](./GUIDE.md); the design note for this version: [lean-2-design.md](./lean-2-design.md).
- The runtime the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [references/SPECS.md](./references/SPECS.md), [ROUTING.md](./ROUTING.md).

---

## 1. What it is

A Lead skill plus two sub-agents (**builder, reviewer**) that take an idea in one folder through **one discovery interview → a measured probe → one pass that writes requirements, UX, architecture and build plan → independent review → a clean-room, test-driven build by a fresh builder per phase that checks itself → independent acceptance**.

This is the **lean-3** version. It is built around two measured facts: a defect costs about ten times more at every stage boundary it crosses, and every agent turn re-reads its whole context, so a builder carried through many phases is the most expensive thing in a run. The Lead does the sequential work itself, numbers are measured before they are frozen, every mechanical check runs inside the builder's own turn, and what is left is batched for the tail.

- **One interview, then no questions.** The Lead asks everything up front (users, target state, rules, UX direction, stack preferences, quality bar, size, mode), with a recommended answer for each. After the brief gate nobody asks you anything until the next gate: the team decides, records an assumption, and shows it to you.
- **A probe, then one warm pass writes the specs.** The Lead measures the device, the heaviest operation, and the test timings first (`specs/00-probe.md`), then writes requirements, UX (large runs, or when you ask for a designed UI), and architecture with the build plan in one context, under about 10,000 words, so they agree by construction and every number has a source. One fresh-context review, resumed only for majors, one spec gate.
- **A fresh builder per phase that checks itself.** Each phase is a vertical slice built by a fresh builder that reads `build/handoff.md`, runs verify and `scripts/precheck.sh` before it returns, and leaves its notes for the next. Worktrees and parallel lanes only in large runs with independent phases.
- **Checks where they pay.** `scripts/plan-graph.sh` (the build plan is an acyclic graph with no parallel overlaps) before the spec review, `scripts/precheck.sh` inside every phase, and `scripts/coverage.sh` (every Must criterion has a named test) at every milestone, all without tokens; an independent reviewer at the spec gate, at milestones (standard and large), and at acceptance. Majors ride into the next phase's dispatch; minors go to a backlog swept once before acceptance.
- **Measured.** The driver writes each session's cost to the run's `costs.tsv`; the retro reads it.
- **Unchanged guarantees:** trace IDs from requirements to tests, a clean room with a dependency allowlist, verify as a hard gate, human gates where they matter, resumable state, a word budget on every runtime file.

## 2. Prerequisites

- A **git repository** at the project root. Without git you still get the specs; the build is a `blocked` stop.
- An **agent host that starts subagents** and, ideally, can continue one (Claude Code can; where a host can't, the Lead dispatches again with the review as input).
- The skill linked into `~/.agents/skills/` (`./scripts/link-skills.sh` from the repo root), or invoked by path (§9).
- **Run the interactive session on your strongest model.** The Lead writes the specs now; that's where judgment pays.

## 3. Mental model

| Stage | Who | Produces | Gate |
|---|---|---|---|
| S0 Discover | Lead, with you | `brief.md`: target state, direction, size, quality bar, mode | **brief** (always stops) |
| S0.5 Discovery (brownfield) | Lead, reviewer | the system as it is, `baseline.md` | **baseline** |
| S1 Spec | Lead; reviewer | `01-requirements.md` (with UX notes in small runs), `02-ux.md` (standard, large), `03-architecture.md` with the build plan in §13 | **spec**: do these reach your target state, and is this how to build it? |
| S2 Build | a fresh builder per phase runs verify and the precheck; the Lead commits and runs the coverage check | code, tests, one commit per phase | **MS-n** per milestone |
| S3 Accept | reviewer; Lead folds the run into `system/` | `reviews/acceptance.md` | **accept** (always stops) |

- **`state.md`** in the active run's folder is the single source of truth, with the dispatch log inside it, and its `next-action` line lets any fresh session resume.
- **A stop** means the Lead updates state, presents the stop outcome-first, commits `.agent-team/`, and ends its turn. Between stops it never asks "shall I continue?".

### Size

| | small | standard | large |
|---|---|---|---|
| For | a CLI, library, script, single-screen tool | a multi-screen app or a service | many components, production stakes |
| Specs | 01 (with UX notes), 03 | 01 (with UX notes), 03; 02 if you ask for a designed UI | 01, 02, 03 |
| Phases (vertical slices) | 1–3 | 3–6 | ≤ 8 |
| Build | a fresh builder per phase, in order | the same | lanes in worktrees where phases are independent |
| Build review | precheck in each phase; coverage and acceptance | plus coverage and one review per milestone | plus deep review of `risk: high` phases |
| REVISE rounds | 1 | 2 | 2 |

## 4. Run modes

| Event | stepwise (default) | checkpoint | yolo |
|---|---|---|---|
| brief, accept | **stop** | **stop** | **stop** |
| baseline (brownfield) | **stop** | **stop** | auto, unless a baseline decision is needed |
| spec | **stop** | **stop** | auto on PASS |
| milestones | **stop** | auto | auto |
| a spec change of scope or a shared contract | **stop** | **stop** | the Lead decides and shows it |
| escalation | **stop** | park, continue others | park, continue others |
| hard stop, drift, stalled build, circuit breaker | **stop** | **stop** | **stop** |

**Hard stops in every mode:** a dependency not on the allowlist; anything outside the project root; deleting files the team didn't create; `git push`, publish, or deploy; secrets.

## 5. Directed run

```bash
./scripts/link-skills.sh                 # once, from the skills repo root
mkdir my-project && cd my-project && git init
```

```text
/dm-agent-team Build a local-first CLI that tracks consulting hours per client and exports monthly invoices as PDF.
Target state: I can log hours, list them by client, and export a month as PDF.
Size: small. Quality bar: internal. Mode: stepwise.
```

1. **Brief gate.** Answer the interview (accept the recommendations you agree with), then approve the brief. This is the one place to be thorough: everything after it runs on what you said here.
2. **Spec gate.** Read the target state and flows first, then the stack, phases, and quality gate. Changes are cheap here: the Lead edits in place and re-runs the review.
3. **Milestones** (stepwise), then the **accept gate**. Then read the run's `retro.md`, whose measured part `scripts/retro.sh` generates.

Run `/dm-agent-team` again in the folder to resume after a session break.

## 6. Yolo run

Kick off with `Mode: yolo` in words, answer the interview and approve the brief gate interactively, then hand off to the driver:

```bash
~/.agents/skills/dm-agent-team/scripts/run.sh --host claude --lead-model opus -- --permission-mode acceptEdits
~/.agents/skills/dm-agent-team/scripts/run.sh --host opencode
```

A headless session can't answer permission prompts: pre-approve `git`, the package manager, and the verify command in the host config (`.claude/settings.json` `permissions.allow`, or OpenCode `permission.bash`), and keep the guardrails the Lead offers at the brief gate ([references/host-guardrails.md](./references/host-guardrails.md)). On Claude Code the driver records each session's cost and turn count in `.agent-team/runs/<run>/costs.tsv`.

| Exit | Meaning | Do |
|---|---|---|
| `0` | done, or no active run | read the run's `retro.md` |
| `1` | usage error, no run yet, or an old layout | start or migrate interactively |
| `2` | a stop: a gate, a hard stop | answer it in `/dm-agent-team`, rerun the driver |
| `3` | two sessions without progress | inspect the session log in `runs/<run>/logs/` |
| `4` | host failed twice | fix the host or permissions |
| `5` | hit `--max-sessions` | rerun |

## 7. Brownfield

After a run finishes, every later run is brownfield: it starts from the living specs in `.agent-team/system/`. On a codebase the team didn't build, invoke `/dm-agent-team --brownfield <change>`. A brownfield run works on a branch `agent-team/<run>` from a clean tree; the Lead records the existing behaviour and a test baseline, the reviewer spot-checks it against the code, and you decide at the **baseline gate** whether to fix or quarantine each failing test. Every spec item is tagged `existing`, `new`, `changed`, or `removed`; characterisation tests pin behaviour before it changes; any regression blocks. You merge the run branch yourself. Details: [references/BROWNFIELD.md](./references/BROWNFIELD.md).

## 8. Where everything lives

```
.agent-team/                 # committed, except runs/*/logs/, runs/*/worktrees/, and runs/*/plan.json
├── active                   # the run in progress, or none
├── models.md                # tier → model mapping (edit overrides here)
├── lessons.md               # what the team learned, across runs
├── system/                  # living specs of the whole system, updated at the end of each run
└── runs/V001-invoice-cli/   # one folder per run
    ├── state.md  brief.md  decisions.md  costs.tsv  retro.md
    ├── specs/  reviews/  build/
    └── logs/  worktrees/  plan.json   # git-ignored
```

Runs, consolidation, and abandoning a run: [references/RUNS.md](./references/RUNS.md). Drift, recovery, escalations: [references/EXCEPTIONS.md](./references/EXCEPTIONS.md). Parallel lanes: [references/PARALLEL.md](./references/PARALLEL.md).

## 9. Comparing versions side by side

Each version lives on its own branch (`main` is the previous lean version; this one is `lean-2`). All are called `dm-agent-team`, so run them from separate checkouts and separate copies of the project:

```bash
git clone <this repo> ~/skills-a && git -C ~/skills-a checkout main
git clone <this repo> ~/skills-b && git -C ~/skills-b checkout lean-2
mkdir -p ~/try/a ~/try/b && git -C ~/try/a init && git -C ~/try/b init
```

Invoke each by path, so neither depends on `~/.agents/skills`:

```text
Read ~/skills-b/skills/dm-agent-team/SKILL.md and act as the dm-agent-team Lead it defines. <the same kickoff text>
```

For unattended runs call each checkout's own `scripts/run.sh`; if you installed host guardrails, allow each checkout's folder under `external_directory`. Use the same kickoff text, mode, size, and models for both, and compare: **cost** (`costs.tsv` for driver sessions, the host's `/cost` for interactive ones) and wall-clock from brief to accept; **dispatches and resumes** (`state.md` §Log); **churn** (REVISE rounds, escalations, spec changes in `retro.md`); and **the product** at the accept gate.

## 10. Reference

| Topic | File |
|---|---|
| Rationale, host setup, migration | [GUIDE.md](./GUIDE.md) · [lean-2-design.md](./lean-2-design.md) |
| Lead runtime · shared contract · what a good spec looks like | [SKILL.md](./SKILL.md) · [PROTOCOL.md](./PROTOCOL.md) · [references/SPECS.md](./references/SPECS.md) |
| Tiers and effort | [ROUTING.md](./ROUTING.md) |
| Runs · rare situations · parallel lanes · brownfield · existing specs | [RUNS.md](./references/RUNS.md) · [EXCEPTIONS.md](./references/EXCEPTIONS.md) · [PARALLEL.md](./references/PARALLEL.md) · [BROWNFIELD.md](./references/BROWNFIELD.md) · [ADOPTION.md](./references/ADOPTION.md) |
| Sub-agents | [`agents/dm-at-builder`](./agents/dm-at-builder/SKILL.md) · [`agents/dm-at-reviewer`](./agents/dm-at-reviewer/SKILL.md) |
| Driver, plan graph, precheck, coverage, retro | [`scripts/run.sh`](./scripts/run.sh) · [`scripts/plan-graph.sh`](./scripts/plan-graph.sh) · [`scripts/precheck.sh`](./scripts/precheck.sh) · [`scripts/coverage.sh`](./scripts/coverage.sh) · [`scripts/retro.sh`](./scripts/retro.sh) |
| Instruction word budgets | [word-budget.txt](./word-budget.txt) |
| Parked: what an enterprise SDLC would add | [to-enterprise-SDLC.md](./to-enterprise-SDLC.md) |

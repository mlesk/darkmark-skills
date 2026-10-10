# dm-agent-team — Usage Guide

**Start here.** How to run the `dm-agent-team` skill, in directed mode (you at the gates) or yolo mode (unattended between the first and last gate).

- Why it is shaped this way, host setup, and migrating from the spec skills: [GUIDE.md](./GUIDE.md); the design note for this version: [lean-2-design.md](./lean-2-design.md).
- The runtime the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [references/SPECS.md](./references/SPECS.md), [ROUTING.md](./ROUTING.md).

---

## 1. What it is

A Lead skill plus two sub-agents (**builder, reviewer**) that take an idea in one folder through **one discovery interview → one pass that writes requirements, UX, architecture and build plan → independent review → a clean-room, test-driven build → independent acceptance**.

This is the **lean-2** version. It is built around one fact: your main conversation keeps its cache for an hour and every subagent is a fresh context paid for from zero, so the Lead does the sequential, context-heavy work itself and dispatches only for what needs a fresh pair of eyes or real parallelism.

- **One interview, then no questions.** The Lead asks everything up front (users, target state, rules, UX direction, stack preferences, quality bar, size, mode), with a recommended answer for each. After the brief gate nobody asks you anything until the next gate: the team decides, records an assumption, and shows it to you.
- **One warm pass writes the specs.** Requirements, UX (standard and large runs), and architecture with the build plan, in one context, so they agree by construction. One fresh-context review, one spec gate.
- **A persistent builder.** One builder builds the phases in order and keeps what it learned; on a precheck failure it is resumed, not restarted. Worktrees and parallel lanes only in large runs with independent phases.
- **Checks where they pay.** `scripts/precheck.sh` (no tokens) after every phase; an independent reviewer at the spec gate, at milestones (standard and large), and at acceptance.
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
| S2 Build | builder; Lead runs the precheck and commits | code, tests, one commit per phase | **MS-n** per milestone |
| S3 Accept | reviewer; Lead folds the run into `system/` | `reviews/acceptance.md` | **accept** (always stops) |

- **`state.md`** in the active run's folder is the single source of truth, with the dispatch log inside it, and its `next-action` line lets any fresh session resume.
- **A stop** means the Lead updates state, presents the stop outcome-first, commits `.agent-team/`, and ends its turn. Between stops it never asks "shall I continue?".

### Size

| | small | standard | large |
|---|---|---|---|
| For | a CLI, library, script, single-screen tool | a multi-screen app or a service | many components, production stakes |
| Specs | 01 (with UX notes), 03 | 01, 02, 03 | 01, 02, 03 |
| Phases | 1–4 | 3–8 | ≤ 10 per milestone |
| Build | one builder, in order | one builder, in order | lanes in worktrees where phases are independent |
| Build review | precheck; acceptance | plus one review per milestone | plus deep review of `risk: high` phases |
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
3. **Milestones** (stepwise), then the **accept gate**. Then read the run's `retro.md`.

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
.agent-team/                 # committed, except runs/*/logs/ and runs/*/worktrees/
├── active                   # the run in progress, or none
├── models.md                # tier → model mapping (edit overrides here)
├── lessons.md               # what the team learned, across runs
├── system/                  # living specs of the whole system, updated at the end of each run
└── runs/V001-invoice-cli/   # one folder per run
    ├── state.md  brief.md  decisions.md  costs.tsv  retro.md
    ├── specs/  reviews/  build/
    └── logs/  worktrees/    # git-ignored
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
| Driver and precheck | [`scripts/run.sh`](./scripts/run.sh) · [`scripts/precheck.sh`](./scripts/precheck.sh) |
| Instruction word budgets | [word-budget.txt](./word-budget.txt) |
| Parked: what an enterprise SDLC would add | [to-enterprise-SDLC.md](./to-enterprise-SDLC.md) |

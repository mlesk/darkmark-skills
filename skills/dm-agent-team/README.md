# dm-agent-team — Usage Guide

**Start here.** How to run the `dm-agent-team` skill, in directed mode (you at the gates) or yolo mode (unattended between the first and last gate).

- Design rationale, host setup, and migrating from the spec skills: [GUIDE.md](./GUIDE.md).
- The runtime the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [ROUTING.md](./ROUTING.md).

---

## 1. What it is

A Lead skill plus five sub-agents (**analyst, designer, architect, builder, reviewer**) that take an idea in one folder through **product (requirements and UX) → plan (architecture and build phases) → clean-room, test-driven build → acceptance**.

This is the **lean** version. It keeps the parts that make the team dependable and drops the ceremony that made small projects slow:

- **The process scales to the project.** At the brief gate you confirm a size (small, standard, large). A small CLI gets one requirements spec with UX notes, one plan, a few large phases, and one acceptance review. A large app gets a separate UX spec, milestone reviews, and deep reviews of risky phases.
- **Independent review where it pays.** A fresh-context reviewer checks each spec gate and the finished system, and blocks only on what would ship a defect or force someone to guess. Every phase is also checked by `scripts/precheck.sh`, which costs no tokens.
- **Agents settle small things themselves.** A builder that finds a small gap decides it, records the decision, and shows it to you at the next stop. Change requests are only for scope, shared contracts, and dependencies.
- **Unchanged guarantees:** one owner per file, trace IDs from requirements to tests, a clean room with a dependency allowlist, verify as a hard gate, and human gates where they matter.
- **A word budget** (`word-budget.txt`, checked by lint) stops the instructions from growing back.

## 2. Prerequisites

- A **git repository** at the project root (worktrees, per-phase commits, scope checks). Without git you still get the specs; the build is a `blocked` stop.
- An **agent host that starts subagents** (OpenCode, Claude Code, or Copilot CLI), ideally in parallel.
- The skill linked into `~/.agents/skills/` (`./scripts/link-skills.sh` from the repo root), or invoked by path (§9).

## 3. Mental model

| Stage | Who | Produces | Gate |
|---|---|---|---|
| S0 Brief | Lead | `brief.md`: your **target state**, size, quality bar, mode | **brief** (always stops) |
| S0.5 Discovery (brownfield) | architect, analyst, Lead | the system as it is, and `baseline.md` | **baseline** |
| S1 Product | analyst; designer in standard and large runs | `01-requirements.md` (with UX notes in small runs), `02-ux.md` | **product**: do these reach your target state? |
| S2 Plan | architect | `03-architecture.md`, `04-build-plan.md` (inside out: foundation, core layers, UI last; a few large phases) | **plan**: specs freeze |
| S3 Build | builders, in parallel worktrees | code, tests, one commit per phase | **MS-n** per milestone |
| S4 Accept | reviewer, then consolidation into `system/` | `reviews/acceptance.md` | **accept** (always stops) |

- **`state.md`** in the active run's folder is the single source of truth, and its `next-action` line lets any fresh session resume.
- **A stop** means the Lead updates state, presents the stop, commits `.agent-team/`, and ends its turn. Between stops it never asks "shall I continue?".

### Size

| | small | standard | large |
|---|---|---|---|
| For | a CLI, library, script, single-screen tool | a multi-screen app or a service | many components, production stakes |
| UX | UX notes inside 01 | separate 02 | separate 02 |
| Phases | 1–4 | 3–8 | ≤ 10 per milestone |
| Build review | precheck script; acceptance | plus one review per milestone | plus deep review of `risk: high` phases |
| REVISE rounds | 1 | 2 | 2 |

## 4. Run modes

| Event | stepwise (default) | checkpoint | yolo |
|---|---|---|---|
| brief, accept | **stop** | **stop** | **stop** |
| baseline (brownfield) | **stop** | **stop** | auto, unless a baseline decision is needed |
| agent questions | **stop** | **stop** | recommended answers adopted |
| product | **stop** | **stop** | auto on PASS |
| plan | **stop** | auto on PASS | auto on PASS |
| milestones | **stop** | auto | auto |
| escalation | **stop** | park, continue others | park, continue others |
| change request | **stop** | **stop** | auto if clarification |
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
Size: small. Quality bar: internal. Mode: stepwise, max-parallel 2.
```

1. **Brief gate.** The Lead asks one batch of questions about the gaps, each with a recommended answer, then presents the brief. Approve it.
2. **Product gate.** Read the requirements (and UX). This is the cheapest point to change *what* you're building.
3. **Plan gate.** Check the stack, the phases, and the quality gate. Push back if there are many tiny phases.
4. **Milestones** (stepwise), then the **accept gate**. Then read the run's `retro.md`.

Run `/dm-agent-team` again in the folder to resume after a session break.

## 6. Yolo run

Kick off with `Mode: yolo` in words, approve the brief gate interactively, then hand off to the driver:

```bash
~/.agents/skills/dm-agent-team/scripts/run.sh --host opencode
~/.agents/skills/dm-agent-team/scripts/run.sh --host claude --lead-model sonnet -- --permission-mode acceptEdits
```

A headless session can't answer permission prompts. Before the build, pre-approve `git`, the package manager, and the verify command in the host config (`.claude/settings.json` `permissions.allow`, or OpenCode `permission.bash`), and keep the guardrails the Lead offers at the brief gate ([references/host-guardrails.md](./references/host-guardrails.md)).

| Exit | Meaning | Do |
|---|---|---|
| `0` | done, or no active run | read the run's `retro.md` |
| `1` | usage error, no run yet, or an old layout | start or migrate interactively |
| `2` | a stop: a gate, a question, a hard stop | answer it in `/dm-agent-team`, rerun the driver |
| `3` | two sessions without progress | inspect the session log in `runs/<run>/logs/` |
| `4` | host failed twice | fix the host or permissions |
| `5` | hit `--max-sessions` | rerun |

## 7. Brownfield

After a run finishes, every later run is brownfield: it starts from the living specs in `.agent-team/system/`. On a codebase the team didn't build, invoke `/dm-agent-team --brownfield <change>`. A brownfield run works on a branch `agent-team/<run>` from a clean tree, records the existing behaviour and a test baseline (the **baseline gate**: you decide to fix or quarantine each failing test), tags every spec item `existing`, `new`, `changed`, or `removed`, pins behaviour with characterisation tests before changing it, and blocks any regression. You merge the run branch yourself. Details: [references/BROWNFIELD.md](./references/BROWNFIELD.md).

## 8. Where everything lives

```
.agent-team/                 # committed, except runs/*/logs/ and runs/*/worktrees/
├── active                   # the run in progress, or none
├── models.md                # tier → model mapping (edit overrides here)
├── system/                  # living specs of the whole system, updated at the end of each run
└── runs/V001-invoice-cli/   # one folder per run
    ├── state.md  brief.md  decisions.md  log.md  retro.md
    ├── specs/  reviews/  build/  handoffs/  changes/
    └── logs/  worktrees/    # git-ignored
```

Runs, consolidation, and abandoning a run: [references/RUNS.md](./references/RUNS.md). Drift, recovery, escalations: [references/EXCEPTIONS.md](./references/EXCEPTIONS.md).

## 9. Comparing lean with the full version

The full version lives on branch `claude/confident-darwin-89mgs2`; this one on `lean`. Both are called `dm-agent-team`, so run them from two checkouts and two copies of the project:

```bash
git clone <this repo> ~/skills-full && git -C ~/skills-full checkout claude/confident-darwin-89mgs2
git clone <this repo> ~/skills-lean && git -C ~/skills-lean checkout lean
mkdir -p ~/try/full ~/try/lean && git -C ~/try/full init && git -C ~/try/lean init
```

Invoke each by path instead of by its linked name, so neither depends on `~/.agents/skills`:

```text
Read ~/skills-lean/skills/dm-agent-team/SKILL.md and act as the dm-agent-team Lead it defines. <your kickoff text>
```

For the driver, call each checkout's own `scripts/run.sh`. If you installed the host guardrails, allow each checkout's skill folder under `external_directory`. Use the same kickoff text, mode, and models for both, and compare:

- **cost and time:** the host's token and cost totals, and wall-clock time from brief to accept;
- **dispatches:** rows in each run's `log.md` (per stage, and per phase);
- **churn:** REVISE rounds, change requests, stale rebuilds, and escalations (`retro.md`);
- **outcome:** tests passing, acceptance findings, and your own judgment of the product at the accept gate.

## 10. Reference

| Topic | File |
|---|---|
| Rationale, host setup, migration | [GUIDE.md](./GUIDE.md) |
| Lead runtime | [SKILL.md](./SKILL.md) |
| Shared contract | [PROTOCOL.md](./PROTOCOL.md) |
| Tiers and effort | [ROUTING.md](./ROUTING.md) |
| Runs and living specs · rare situations · brownfield · existing specs | [RUNS.md](./references/RUNS.md) · [EXCEPTIONS.md](./references/EXCEPTIONS.md) · [BROWNFIELD.md](./references/BROWNFIELD.md) · [ADOPTION.md](./references/ADOPTION.md) |
| Sub-agents | [`agents/dm-at-*/SKILL.md`](./agents) |
| Driver and precheck | [`scripts/run.sh`](./scripts/run.sh) · [`scripts/precheck.sh`](./scripts/precheck.sh) |
| Instruction word budgets | [word-budget.txt](./word-budget.txt) |
| Parked: what an enterprise SDLC would add | [to-enterprise-SDLC.md](./to-enterprise-SDLC.md) |

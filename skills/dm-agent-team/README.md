# dm-agent-team — Usage Guide

**Start here.** This is the primary guide to running the `dm-agent-team` skill: what it is, and the exact steps to execute it in both **directed** (you at the gates) and **YOLO** (unattended to the end) modes.

- Deep background, design rationale, and the seven-day rollout: [GUIDE.md](./GUIDE.md).
- The runtime contract the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [ROUTING.md](./ROUTING.md).

---

## 1. What it is

A Lead skill plus five sub-agents — **analyst, architect, designer, builder, reviewer** — that take one greenfield idea in one folder through **requirements ⇄ UX → architecture → build plan → clean-room, test-driven implementation → acceptance**. Requirements and UX are iterated together until they agree and reach the target state you describe; only then is the architecture (API, data model, stack) designed to deliver them.

**Goal:** a working, tested, well-designed application while you make only the decisions that matter.

What makes it dependable rather than hype:

- **One owner per file.** Agents cannot overwrite each other.
- **Trace IDs everywhere** (`REQ → SCR → API/ADR → PHASE → test`). An invented feature has no ID, so the reviewer sees it.
- **Independent review in a fresh context.** The author never grades its own work.
- **A clean room.** Code derives only from approved specs and local files; dependencies only from an allowlist you approve.
- **Seven human gates (G0–G6)** plus a stop on anything irreversible. The run mode decides which gates stop for you.
- **Hard retry limits** (2 revise rounds, 3 test attempts, a breaker after 3 escalations in a row). Failures stop and ask; they don't spiral.
- **Cheap by design.** Fresh subagent per agent, the Lead reads Returns not artifacts, questions arrive in batches with recommended answers, parallel phases build in git worktrees.

The Lead drives within a session; a driver script drives across sessions. That two-layer split is the whole trick — see §7.

## 2. Prerequisites

- **A git repository** at the project root. The build stage needs worktrees, per-phase commits, and scope checks. (Without git you still get specs up to G4; S5 becomes a `blocked` stop.)
- **An agent host that starts subagents** — OpenCode, Claude Code, or Copilot CLI — and ideally runs them in parallel.
- **The skill linked** into `~/.agents/skills/` (see step 1 below).

## 3. Mental model (60 seconds)

- **Stage S0–S6**, each ending at a **gate G0–G6**. A gate is where a human would normally decide; the run mode says whether it stops or auto-approves.
- **The active run's `state.md`** (`.agent-team/runs/<run>/state.md`) is the single source of truth: mode, stage, status, gates, phases, and a one-line `next-action` any fresh session can execute. It is the handoff between sessions.
- **`.agent-team/`** holds all team state, one folder per run under `runs/`, and is committed as the project's history (§10). Source code lives where `specs/03-architecture.md` puts it.
- **A "stop"** means: update `state.md`, present the stop, end the turn. The Lead never asks "shall I continue?" between stops — it just runs to the next one.

### The stages

| Stage | Who | Produces | Gate |
|---|---|---|---|
| S0 Kickoff | Lead | `brief.md`, including your **target state**: what you can see and do when v1 is done | G0 |
| S0.5 Discovery (brownfield only) | architect, then analyst | baseline 03 and 01 §0 of the existing system, and `baseline.md` (tests and quality checks today) | G0.5: you settle every baseline failure |
| S1 Requirements | analyst | `01-requirements.md` | G1: the baseline for UX |
| S2 UX ⇄ requirements | designer, then analyst and designer in alignment rounds | `02-ux.md`, prototypes, and an updated 01 | G2: both agree and reach the target state |
| S3 Architecture | architect | `03-architecture.md`: stack, API, data model, conventions | G3 |
| S4 Build plan | architect | `04-build-plan.md`: build phases layered inside out (foundation → domain → persistence → API), then UI phases, grouped into milestones | G4: specs freeze |
| S5 Build | builders, in parallel worktrees | code, tests, one commit per phase | G5 per milestone |
| S6 Acceptance | reviewer | `reviews/acceptance.md` | G6 |

Every author turn is followed by an independent review. In S2, the designer logs every requirements problem it finds while designing (a missing failure path, an ambiguous rule, a journey that can't be finished) as feedback in 02 §12. The analyst answers each item in 01 §12, the designer updates the screens, and both are re-reviewed. The loop repeats until nothing is open and the alignment checks pass; then G2 asks you whether the result is what you want to reach.

## 4. Pick an execution path

| | **Directed** | **YOLO** |
|---|---|---|
| You are asked at | every question batch and gate (stepwise), or question batches + G0 + G2 + G1–G4 together + G6 (checkpoint) | G0 and G6 only |
| Best for | first runs, projects you must get exactly right | toys, spikes, prototypes |
| How you drive it | stay in one interactive session and answer each stop | answer G0, then hand off to `scripts/run.sh` |
| Continuity | one session (the Lead takes session breaks; you resume) | the driver starts a fresh session per stage/milestone |

The three run modes are `stepwise` (default), `checkpoint`, and `yolo`. "Directed" covers stepwise + checkpoint — you are in the loop at the gates. You can **change mode at any stop**.

| Event | stepwise (default) | checkpoint | yolo |
|---|---|---|---|
| G0 brief and run mode | **stop** | **stop** | **stop** |
| Agent questions | **stop**, ask the batch | **stop**, ask the batch | recommended answers adopted, logged as `auto-yolo` |
| G1 requirements baseline, G3 architecture | **stop** at each | auto on reviewer PASS | auto on reviewer PASS |
| G2 requirements + UX aligned (target state) | **stop** | **stop** | auto on reviewer PASS |
| Requirements ⇄ UX alignment rounds | run without stopping | run without stopping | run without stopping |
| Not aligned after 3 rounds | **stop** | **stop** | **stop** |
| G4 build plan (spec freeze) | **stop** | **stop**: G1–G4 presented together | auto on reviewer PASS |
| G5 milestone review | **stop** at each | auto | auto |
| Phase escalation | **stop** | park phase, continue others | park phase, continue others |
| Change request | **stop** | **stop** | auto if `class: clarification`, else **stop** |
| Spec drift, third reopen, circuit breaker, stalled build, G6, hard stops | **stop** | **stop** | **stop** |

**Hard stops in every mode:** new non-allowlisted dependency; anything outside the project root; deleting files the team did not create; `git push`, publish, or deploy; anything involving secrets or credentials.

---

## 5. Directed mode — step by step

Use this for a first run or a project you care about getting exactly right.

**1. Link the skill** (once per checkout, from the skills repo root):

```bash
./scripts/link-skills.sh          # add --dry-run first to preview
```

**2. Create the project folder and initialize git:**

```bash
mkdir my-project && cd my-project && git init
```

**3. Start an interactive session and kick off.** State the mode in words — the Lead never infers it:

```text
/dm-agent-team Build a local-first CLI that tracks consulting hours per client and exports monthly invoices as PDF.
Quality bar: production. Constraint: .NET 10.
Mode: stepwise, max-parallel 3.
```

**4. Answer G0.** The Lead interviews you with one batch of questions (each with a recommended answer), writes `brief.md`, and presents **G0**. G0 is always a stop in every mode. Approve it; `state.md` records the mode and max-parallel.

**5. Keep going.** The Lead writes author handoffs, dispatches agents, routes verdicts, and stops only where the mode says. At each stop you review and answer; it then continues. Run `/dm-agent-team` again in the same folder to resume after a session break.

**6. Approve G6.** After acceptance passes, **G6 is always a stop**. Approve it, then read the run's `retro.md` (`.agent-team/runs/<run>/retro.md`).

### Keeping a directed run moving

- **Inside a session, never a babysitter.** The Lead runs to the next stop. It takes a **session break** after each stage/milestone, after ~25 dispatches (`session-dispatches`), or when the host warns about context — printing `PAUSED — resume with /dm-agent-team or scripts/run.sh`.
- **To automate the gaps between your gates**, point the driver at a directed run too — it will simply stop (exit `2`) at each gate for you. In `stepwise` it warns that it stops at every gate; `checkpoint` gives longer stretches.

---

## 5a. Brownfield — changing an existing system

Brownfield is how the team changes an existing system. It happens two ways:

- **Automatically, after your first run.** Once any run has finished, every later run is brownfield: it starts from the living specs in `.agent-team/system/` and checks only the code changed since the last run.
- **With `--brownfield`, on a codebase the team didn't build.** Without the flag (and with no finished run), the team assumes a new project and stops at G0 if the folder already holds code.

```text
/dm-agent-team --brownfield Add CSV export to the monthly invoice screen.
Target state: I can download this month's invoices as CSV from the invoice list.
Quality bar: production. Mode: checkpoint, max-parallel 2.
```

What changes ([references/BROWNFIELD.md](./references/BROWNFIELD.md)):

- **Boot** needs a clean working tree, records the baseline commit, and works on a new branch `agent-team/<project>`; your branch is never touched, and you merge the run branch yourself after G6.
- **S0.5 Discovery** (before requirements): the architect records the existing architecture, conventions, and quality tools, and the analyst records the current behaviour of the area you're changing. The Lead runs the existing tests to set the **regression floor**.
- **G0.5 Baseline gate:** you confirm the baseline, and decide for every test already failing whether to fix it or quarantine it.
- **Change-scoped specs:** every item is tagged `existing`, `new`, `changed`, or `removed`. The designer keeps the existing look; the architect designs within the existing architecture unless you ask to re-architect. New quality rules apply to new and changed files only.
- **Characterisation tests first:** current behaviour is pinned by tests before any phase changes it.
- **No regressions:** every test that passed at baseline must keep passing; changing one needs a decision you approve (`behaviour-changes: D-###`), and the precheck script enforces it.

---

## 6. YOLO mode — step by step

Use this for toys, spikes, and prototypes. YOLO still stops at **G0 and G6** and at every hard stop; everything between runs unattended.

**1–2. Same as directed:** link the skill, create the git project folder.

**3. Kick off with YOLO chosen in words**, in an interactive session:

```text
/dm-agent-team Build a local-first CLI that tracks consulting hours per client and exports monthly invoices as PDF.
Quality bar: prototype. Mode: yolo, max-parallel 3.
```

**4. Answer G0 and approve.** The Lead writes `brief.md`, presents **G0**, and records `mode: yolo`. This is the first of the two stops YOLO keeps. The run's folder, its `state.md`, and the `.agent-team/active` pointer the driver needs already exist from boot; G0 records the mode the driver runs in.

**5. Pre-approve permissions for the unattended session.** A headless session cannot answer prompts, so anything not pre-approved fails. Do this once the stack and verify command are known (after G3), before handing off to the driver. The team needs to edit files and run `git`, the package manager, and the verify command. Pre-approve those in the project's host config rather than using a blanket bypass flag:

- **Claude Code:** `.claude/settings.json` → `permissions.allow`, e.g. `"Bash(git:*)"`, `"Bash(<pkg-manager>:*)"`, and one entry for the verify command from `03-architecture.md` §10.
- **OpenCode:** `permission.bash` in your project's `opencode.jsonc` for the same commands.
- **Guardrails:** the Lead offers at G0 to install host permission rules that refuse push, publish, deploy, network fetches, and paths outside the project ([references/host-guardrails.md](./references/host-guardrails.md)). They work on OpenCode without hooks.

**6. Hand off to the driver:**

```bash
# from inside the project folder — one fresh session per stage/milestone
~/.agents/skills/dm-agent-team/scripts/run.sh --host opencode

# target another directory / use a stronger Lead model
~/.agents/skills/dm-agent-team/scripts/run.sh --host claude --project /path/to/project --lead-model sonnet
```

Driver flags: `--host opencode|claude|copilot|codex`, `--project DIR`, `--lead-model MODEL`, `--max-sessions N` (default 40), and `-- <extra host args>` (e.g. `-- --permission-mode acceptEdits`). `--help` prints usage.

**7. Handle stops and rerun.** The driver exits instead of burning sessions:

| Exit | Meaning | Action |
|---|---|---|
| `2` | `awaiting-human` / `blocked` — a hard stop or G6 | Answer it in an interactive `/dm-agent-team` session, then rerun the driver |
| `3` | No progress in 2 sessions (`state.md` unchanged) | Inspect the logged session; fix the cause |
| `4` | Host failed twice in a row | Fix the host/permission problem; rerun |
| `5` | Hit `--max-sessions` | Rerun to continue |
| `0` | `stage: done`, or no active run | Finished — read the run's `retro.md` |
| `1` | Usage error, no run yet, or an old single-folder layout | Start (or migrate) the run interactively first |

**8. Approve G6.** Acceptance passes, then **G6 is always a stop**. Review `reviews/acceptance.md` and every auto-approved decision, approve, and the Lead writes `retro.md`, sets `stage: done`, and the driver exits `0`.

> **Caution:** YOLO accepts every recommended answer. Keep it for toys, spikes, and prototypes, and prefer `checkpoint` until the team's first-pass PASS rate is high on your projects.

---

## 7. How continuation works

Two layers keep a run going without a babysitter:

1. **Inside a session — the drive rule.** The Lead never pauses to ask "shall I continue?" It updates state and executes `next-action` immediately. A turn ends only at a stop, at `stage: done`, or at a session break.
2. **Across sessions — session breaks + `scripts/run.sh`.** One session cannot run forever: context grows and cost per turn grows with it. So on a driver run the Lead ends the session cleanly after each stage or milestone (or ~25 dispatches), leaving `state.md` current. The driver then launches the **next fresh host session**, which resumes at `next-action` with zero accumulated context.

`run.sh` is a loop that:

- reads `stage`/`status` from `state.md` before each launch — `done` → exit `0`; `awaiting-human`/`blocked` → print the stop and exit `2`;
- hashes `state.md` (ignoring the per-session `session-dispatches:` counter) and exits `3` if two sessions make no progress;
- exits `4` after two consecutive host failures; and
- logs every session to `.agent-team/runs/<run>/logs/driver-<timestamp>-sN.log`.

It **never answers a stop for you** — that is why some autopilot runs still hand control back at a hard stop or at G6.

---

## 8. Kickoff prompt template

```text
/dm-agent-team [--brownfield] <one-paragraph idea, or for brownfield the change you want>

Target state: <what you should be able to see and do when v1 is done>
Quality bar: prototype | internal | production
Constraints: <platform, required/forbidden tech, standards files>
Reference material (dirty room, analyst-only): <paths>
Existing specs: <paths, or none>
Mode: stepwise | checkpoint | yolo, max-parallel <1-4>
```

Anything you leave out, the Lead asks for at G0 — with a recommended answer you can accept as-is. Two answers it always needs in words: the **run mode** and **max-parallel** (recommend 3 if the project is a git repo and your host runs parallel subagents, otherwise 1).

---

## 9. Model routing

Every dispatch gets a **tier** (which model) and an **effort** (how much thinking), resolved from [ROUTING.md](./ROUTING.md) and recorded in `.agent-team/models.md` (you may edit overrides there). Defaults: the **deep** tier for approach evaluation, plans, specs, review verdicts, and hard phases; the **standard** tier for the Lead and routine phases; the **light** tier only for the mechanical precheck — never verdicts.

For an unattended run, choose the Lead's model with `run.sh --lead-model <model>`.

---

## 10. Where everything lives

A project is built over **runs**: the first builds it, and each later run changes it. Every run has its own folder, and `.agent-team/` is committed, so the project keeps the full history of what was asked, decided, reviewed, and built.

```
.agent-team/                 # committed (except runs/*/logs/ and runs/*/worktrees/)
├── active                   # the run in progress, e.g. V002-csv-export, or none
├── models.md                # tier → model mapping (you may edit overrides)
├── system/                  # living specs of the whole system, updated at the end of each run
│   ├── 01-requirements.md
│   ├── 02-ux.md
│   └── 03-architecture.md
└── runs/
    ├── V001-invoice-tracker/       # a finished run, kept as history
    └── V002-csv-export/            # the active run
        ├── state.md                # the current truth: kind, mode, stage, gates, phases, counters
        ├── brief.md                # G0 artifact
        ├── decisions.md            # append-only D-### log
        ├── log.md                  # append-only run log, one row per dispatch
        ├── specs/                  # this run's 01-requirements, 02-ux, 03-architecture, 04-build-plan
        ├── ux/prototypes/          # self-contained HTML
        ├── build/                  # PHASE-###-report.md per phase
        ├── reviews/                # one file per review round
        ├── baseline.md             # brownfield: tests and quality checks at the baseline commit
        ├── discovery-scope.md      # brownfield: what discovery starts from and re-checks
        ├── approved/               # copy of each artifact as approved (drift diffs)
        ├── changes/                # CR-###.md change requests
        ├── handoffs/               # H-###.md; the agent appends only ## Return
        ├── retro.md                # written at the end
        ├── logs/                   # git-ignored: full command output, never read whole
        └── worktrees/              # git-ignored: one git worktree per phase being built
```

- **Starting a run.** `/dm-agent-team` resumes the run named in `active`. If none is active, it starts the next one (`V003-…`), proposes a name you can change at G0, and, if an earlier run finished, makes it a brownfield change to the system in `system/`.
- **Ending a run.** After G6, the analyst, designer, and architect fold the run's changes into `system/` (reviewed, and approved with G6); the Lead closes the run and sets `active` to `none`. At any stop you can choose **Abandon run** instead; its folder stays as history, and the stop lists any phases already merged into the code so you can decide what to keep.
- **Spec IDs are global.** `REQ-012` means the same requirement in every run and in `system/`; a `changed` item keeps its ID. Decisions, change requests, phases, and handoffs are numbered per run and cited across runs as `V002/D-014`.
- **Brownfield runs live on a branch.** A brownfield run works on `agent-team/<run>`. Merge it (or delete it to discard the run) before the next run: the Lead won't start one while a finished run branch is unmerged, and stops if you start one from another branch while a run is active.
- **Commits.** The Lead commits `.agent-team/` at every gate, stop, session break, and run end (and `.gitignore` at boot), never source code with it, and never pushes.

At a stop, read the active run's `state.md` first; it names the gate, the artifact, and what you must decide.

---

## 11. Resuming and recovering

- **Resume any run:** run `/dm-agent-team` in the project folder, or rerun `scripts/run.sh`. The Lead reads `state.md`, prints a resume report, re-checks artifact integrity, and continues at `next-action`.
- **Answer a stop:** do it in an interactive session, then rerun the driver.
- **Interrupted mid-build:** the Lead detects `in-progress`/`in-review` phases and an unfinished merge, and recovers — re-dispatching the same handoff in a fresh worktree, or re-running the interrupted precheck/review.
- **Spec drift** (an approved artifact changed by hand): a `blocked` stop in every mode, showing you the diff. You either adopt the edit (the Lead runs it as a change request, so the reviewer re-checks and affected phases go stale) or revert it.

---

## 12. Common mistakes

Avoid these (see [GUIDE.md §8](./GUIDE.md#8-common-mistakes-to-avoid) for the full list):

1. **Rubber-stamping G1 and G2** — they decide most of the outcome. G2 is the last cheap point to change *what* you're building.
2. **Letting the reviewer share context with the author** — that is self-review.
3. **Building UI before the layers under it** — build inside out (foundation, domain, persistence, API), then the UI phases.
4. **Raising retry limits when things fail** — a repeated failure usually means the spec is wrong; fix it via a change request.
5. **Editing frozen specs by hand mid-build** — the state then lies.
6. **Running one giant session** — let the Lead take session breaks and let the driver resume.
7. **Choosing YOLO for a real project on day one** — use `checkpoint` until first-pass PASS rates are high.

---

## 13. Reference

| Topic | File |
|---|---|
| Design rationale, rollout plan, host setup | [GUIDE.md](./GUIDE.md) |
| Lead runtime, stages, gates, run modes | [SKILL.md](./SKILL.md) |
| Workspace, state contract, handoffs, IDs, change requests | [PROTOCOL.md](./PROTOCOL.md) |
| Tiers, effort, escalation ladder | [ROUTING.md](./ROUTING.md) |
| Sub-agents (dispatched by the Lead, not linked as skills) | [`agents/dm-at-*/SKILL.md`](./agents) |
| Unattended driver | [`scripts/run.sh`](./scripts/run.sh) |
| Mechanical precheck, run by the Lead | [`scripts/precheck.sh`](./scripts/precheck.sh) |
| Parked plan: what an enterprise SDLC would still need | [to-enterprise-SDLC.md](./to-enterprise-SDLC.md) |

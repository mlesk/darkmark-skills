# dm-agent-team — Usage Guide

**Start here.** This is the primary guide to running the `dm-agent-team` skill: what it is, and the exact steps to execute it in both **directed** (you at the gates) and **YOLO** (unattended to the end) modes.

- Deep background, design rationale, and the seven-day rollout: [GUIDE.md](./GUIDE.md).
- The runtime contract the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [ROUTING.md](./ROUTING.md).

---

## 1. What it is

A Lead skill plus five sub-agents — **analyst, architect, designer, builder, reviewer** — that take one greenfield idea in one folder from requirements → architecture → UX → build plan → clean-room, test-driven implementation → acceptance.

**Goal:** a working, tested, well-designed application while you make only the decisions that matter.

What makes it dependable rather than hype:

- **One owner per file.** Agents cannot overwrite each other.
- **Trace IDs everywhere** (`REQ → ADR/API → SCR → SLICE → test`). An invented feature has no ID, so the reviewer sees it.
- **Independent review in a fresh context.** The author never grades its own work.
- **A clean room.** Code derives only from approved specs and local files; dependencies only from an allowlist you approve.
- **Seven human gates (G0–G6)** plus a stop on anything irreversible. The run mode decides which gates stop for you.
- **Hard retry limits** (2 revise rounds, 3 test attempts, a breaker after 3 escalations in a row). Failures stop and ask; they don't spiral.
- **Cheap by design.** Fresh subagent per agent, the Lead reads Returns not artifacts, questions arrive in batches with recommended answers, parallel slices build in git worktrees.

The Lead drives within a session; a driver script drives across sessions. That two-layer split is the whole trick — see §7.

## 2. Prerequisites

- **A git repository** at the project root. The build phase needs worktrees, per-slice commits, and scope checks. (Without git you still get specs up to G4; P5 becomes a `blocked` stop.)
- **An agent host that starts subagents** — OpenCode, Claude Code, or Copilot CLI — and ideally runs them in parallel.
- **The skill linked** into `~/.agents/skills/` (see step 1 below).

## 3. Mental model (60 seconds)

- **Phase P0–P6**, each ending at a **gate G0–G6**. A gate is where a human would normally decide; the run mode says whether it stops or auto-approves.
- **`.agent-team/state.md`** is the single source of truth: mode, phase, status, gates, slices, and a one-line `next-action` any fresh session can execute. It is the handoff between sessions.
- **`.agent-team/`** holds all team state and is git-ignored. Source code lives where `specs/02-architecture.md` puts it.
- **A "stop"** means: update `state.md`, present the stop, end the turn. The Lead never asks "shall I continue?" between stops — it just runs to the next one.

## 4. Pick an execution path

| | **Directed** | **YOLO** |
|---|---|---|
| You are asked at | every question batch and gate (stepwise), or question batches + G0 + G1–G4 together + G6 (checkpoint) | G0 and G6 only |
| Best for | first runs, projects you must get exactly right | toys, spikes, prototypes |
| How you drive it | stay in one interactive session and answer each stop | answer G0, then hand off to `scripts/run.sh` |
| Continuity | one session (the Lead takes session breaks; you resume) | the driver starts a fresh session per phase/milestone |

The three run modes are `stepwise` (default), `checkpoint`, and `yolo`. "Directed" covers stepwise + checkpoint — you are in the loop at the gates. You can **change mode at any stop**.

| Event | stepwise (default) | checkpoint | yolo |
|---|---|---|---|
| G0 brief and run mode | **stop** | **stop** | **stop** |
| Agent questions | **stop**, ask the batch | **stop**, ask the batch | recommended answers adopted, logged as `auto-yolo` |
| G1 requirements, G2 architecture, G3 UX | **stop** at each | auto on reviewer PASS | auto on reviewer PASS |
| G4 build plan (spec freeze) | **stop** | **stop**: G1–G4 presented together | auto on reviewer PASS |
| G5 milestone demo | **stop** at each | auto | auto |
| Slice escalation | **stop** | park slice, continue others | park slice, continue others |
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

**6. Approve G6.** After acceptance passes, **G6 is always a stop**. Approve it, then read `.agent-team/retro.md`.

### Keeping a directed run moving

- **Inside a session, never a babysitter.** The Lead runs to the next stop. It takes a **session break** after each phase/milestone, after ~25 dispatches (`session-dispatches`), or when the host warns about context — printing `PAUSED — resume with /dm-agent-team or scripts/run.sh`.
- **To automate the gaps between your gates**, point the driver at a directed run too — it will simply stop (exit `2`) at each gate for you. In `stepwise` it warns that it stops at every gate; `checkpoint` gives longer stretches.

---

## 6. YOLO mode — step by step

Use this for toys, spikes, and prototypes. YOLO still stops at **G0 and G6** and at every hard stop; everything between runs unattended.

**1–2. Same as directed:** link the skill, create the git project folder.

**3. Kick off with YOLO chosen in words**, in an interactive session:

```text
/dm-agent-team Build a local-first CLI that tracks consulting hours per client and exports monthly invoices as PDF.
Quality bar: prototype. Mode: yolo, max-parallel 3.
```

**4. Answer G0 and approve.** The Lead writes `brief.md`, presents **G0**, and records `mode: yolo`. This is the first of the two stops YOLO keeps. Approving G0 also creates `.agent-team/state.md`, which the driver requires.

**5. Pre-approve permissions for the unattended session.** A headless session cannot answer prompts, so anything not pre-approved fails. Do this once the stack and verify command are known (after G2), before handing off to the driver. The team needs to edit files and run `git`, the package manager, and the verify command. Pre-approve those in the project's host config rather than using a blanket bypass flag:

- **Claude Code:** `.claude/settings.json` → `permissions.allow`, e.g. `"Bash(git:*)"`, `"Bash(<pkg-manager>:*)"`, and one entry for the verify command from `02-architecture.md` §10.
- **OpenCode:** `permission.bash` in your project's `opencode.jsonc` for the same commands.

**6. Hand off to the driver:**

```bash
# from inside the project folder — one fresh session per phase/milestone
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
| `0` | `phase: done` | Finished — read `.agent-team/retro.md` |
| `1` | Usage error, or no `state.md` (G0 not done yet) | Approve G0 interactively first |

**8. Approve G6.** Acceptance passes, then **G6 is always a stop**. Review `reviews/acceptance.md` and every auto-approved decision, approve, and the Lead writes `retro.md`, sets `phase: done`, and the driver exits `0`.

> **Caution:** YOLO accepts every recommended answer. Keep it for toys, spikes, and prototypes, and prefer `checkpoint` until the team's first-pass PASS rate is high on your projects.

---

## 7. How continuation works

Two layers keep a run going without a babysitter:

1. **Inside a session — the drive rule.** The Lead never pauses to ask "shall I continue?" It updates state and executes `next-action` immediately. A turn ends only at a stop, at `phase: done`, or at a session break.
2. **Across sessions — session breaks + `scripts/run.sh`.** One session cannot run forever: context grows and cost per turn grows with it. So on a driver run the Lead ends the session cleanly after each phase or milestone (or ~25 dispatches), leaving `state.md` current. The driver then launches the **next fresh host session**, which resumes at `next-action` with zero accumulated context.

`run.sh` is a loop that:

- reads `phase`/`status` from `state.md` before each launch — `done` → exit `0`; `awaiting-human`/`blocked` → print the stop and exit `2`;
- hashes `state.md` (ignoring the per-session `session-dispatches:` counter) and exits `3` if two sessions make no progress;
- exits `4` after two consecutive host failures; and
- logs every session to `.agent-team/logs/driver-<timestamp>-sN.log`.

It **never answers a stop for you** — that is why some autopilot runs still hand control back at a hard stop or at G6.

---

## 8. Kickoff prompt template

```text
/dm-agent-team <one-paragraph idea>

Quality bar: prototype | internal | production
Constraints: <platform, required/forbidden tech, standards files>
Reference material (dirty room, analyst-only): <paths>
Existing specs: <paths, or none>
Mode: stepwise | checkpoint | yolo, max-parallel <1-4>
```

Anything you leave out, the Lead asks for at G0 — with a recommended answer you can accept as-is. Two answers it always needs in words: the **run mode** and **max-parallel** (recommend 3 if the project is a git repo and your host runs parallel subagents, otherwise 1).

---

## 9. Model routing

Every dispatch gets a **tier** (which model) and an **effort** (how much thinking), resolved from [ROUTING.md](./ROUTING.md) and recorded in `.agent-team/models.md` (you may edit overrides there). Defaults: the **deep** tier for approach evaluation, plans, specs, review verdicts, and hard slices; the **standard** tier for the Lead and routine slices; the **light** tier only for the mechanical precheck — never verdicts.

For an unattended run, choose the Lead's model with `run.sh --lead-model <model>`.

---

## 10. Where everything lives

```
.agent-team/                 # git-ignored; addressed by absolute path
├── state.md                 # the current truth: mode, phase, gates, slices, counters
├── models.md                # tier → model mapping (you may edit overrides)
├── brief.md                 # G0 artifact
├── decisions.md             # append-only D-### log
├── log.md                   # append-only run log, one row per dispatch
├── specs/                   # 01-requirements, 02-architecture, 03-ux, 04-build-plan
├── ux/prototypes/           # self-contained HTML
├── build/                   # SLICE-###-report.md per slice
├── reviews/                 # one file per review round
├── logs/                    # full command output, never read whole
├── approved/                # copy of each artifact as approved (drift diffs)
├── changes/                 # CR-###.md change requests
├── handoffs/                # H-###.md; the agent appends only ## Return
├── worktrees/               # one git worktree per slice being built
└── retro.md                 # written at the end
```

At a stop, read `state.md` first; it names the gate, the artifact, and what you must decide. Add `.agent-team/` to `.gitignore` (the Lead does this at boot).

---

## 11. Resuming and recovering

- **Resume any run:** run `/dm-agent-team` in the project folder, or rerun `scripts/run.sh`. The Lead reads `state.md`, prints a resume report, re-checks artifact integrity, and continues at `next-action`.
- **Answer a stop:** do it in an interactive session, then rerun the driver.
- **Interrupted mid-build:** the Lead detects `in-progress`/`in-review` slices and an unfinished merge, and recovers — re-dispatching the same handoff in a fresh worktree, or re-running the interrupted precheck/review.
- **Spec drift** (an approved artifact changed by hand): a `blocked` stop in every mode, showing you the diff. You either adopt the edit (the Lead runs it as a change request, so the reviewer re-checks and affected slices go stale) or revert it.

---

## 12. Common mistakes

Avoid these (see [GUIDE.md §8](./GUIDE.md#8-common-mistakes-to-avoid) for the full list):

1. **Rubber-stamping G1 and G2** — they decide most of the outcome.
2. **Letting the reviewer share context with the author** — that is self-review.
3. **Slicing by layer** instead of vertical, runnable slices.
4. **Raising retry limits when things fail** — a repeated failure usually means the spec is wrong; fix it via a change request.
5. **Editing frozen specs by hand mid-build** — the state then lies.
6. **Running one giant session** — let the Lead take session breaks and let the driver resume.
7. **Choosing YOLO for a real project on day one** — use `checkpoint` until first-pass PASS rates are high.

---

## 13. Reference

| Topic | File |
|---|---|
| Design rationale, rollout plan, host setup | [GUIDE.md](./GUIDE.md) |
| Lead runtime, phases, gates, run modes | [SKILL.md](./SKILL.md) |
| Workspace, state contract, handoffs, IDs, change requests | [PROTOCOL.md](./PROTOCOL.md) |
| Tiers, effort, escalation ladder | [ROUTING.md](./ROUTING.md) |
| Sub-agents (dispatched by the Lead, not linked as skills) | [`agents/dm-at-*/SKILL.md`](./agents) |
| Unattended driver | [`scripts/run.sh`](./scripts/run.sh) |

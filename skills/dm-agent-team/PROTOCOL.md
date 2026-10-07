# Agent Team Protocol

The shared contract for the Lead and every `dm-at-*` agent. When an agent file and this file disagree, this file wins.

## Workspace

All team state lives under `.agent-team/` at the project root (the **team root**) and is committed to git as the project's history. Source code lives where `specs/03-architecture.md` puts it.

```
.agent-team/                 # team root
├── active                   # the active run's folder name, or `none`
├── models.md                # tier → model mapping for this host (ROUTING.md)
├── system/                  # living specs of the whole system, updated at the end of each run
└── runs/V002-csv-export/    # one folder per run: the run's **workspace**
    ├── state.md  brief.md  decisions.md  log.md   # Lead-owned
    ├── specs/               # 01-requirements, 02-ux (standard and large only), 03-architecture, 04-build-plan
    ├── ux/prototypes/       # designer: self-contained HTML, only when asked for
    ├── build/               # builder: PHASE-###-report.md
    ├── reviews/             # reviewer and precheck.sh
    ├── changes/  handoffs/  # Lead-owned: CR-###.md, H-###.md (the agent appends only its Return)
    ├── baseline.md  discovery-scope.md            # brownfield only
    ├── retro.md
    ├── logs/                # git-ignored: full command output, never read whole
    └── worktrees/           # git-ignored: one git worktree per phase being built
```

- **Paths are absolute.** Every handoff gives `workspace:` (the run folder) and `team-root:`. Every `.agent-team/...` path in this skill means `<workspace>/...`, except `active`, `models.md`, and `system/`, which are in the team root. Builders work in a git worktree whose `.agent-team/` is a stale committed snapshot: never read or write team files through it.
- **Git** ignores only `.agent-team/runs/*/worktrees/` and `.agent-team/runs/*/logs/`. The Lead commits the rest. Project tooling (tests, linters, builds) must ignore `.agent-team/`.
- **Runs.** How runs start, end, and fold into `system/` is in [references/RUNS.md](./references/RUNS.md).

### state.md skeleton

```markdown
# Agent Team State
team-version: <skill git sha | unknown>
project: <name>
run: V<NNN>-<name>
kind: greenfield | brownfield
workspace: <absolute path>
team-root: <absolute path>
baseline-commit: <brownfield: sha | –>
run-branch: <brownfield: branch | –>
size: small | standard | large
mode: stepwise | checkpoint | yolo
quality-bar: prototype | internal | production
max-parallel: <1–4>
stage: S0-brief | S0.5-discovery | S1-product | S2-plan | S3-build | S4-accept | done
status: in-progress | awaiting-human | blocked | done | abandoned
halt: <kind: evidence, only while blocked | –>
next-action: <one line a fresh session can execute>
session-dispatches: <count this session>
<!-- keep one field per line: scripts/run.sh reads them -->

## Gates
| Gate | Artifacts | Status | Round | Commit | Notes |
|---|---|---|---|---|---|
| brief | brief.md | pending | – | – | |

Gates: brief · baseline (brownfield) · product (01, 02) · plan (03, 04) · MS-n · accept.
Status: pending | in-review | approved | approved (auto-<mode>) | approved (override) | n/a
Commit: the `.agent-team/` commit made at approval. Drift is checked against it.

## Build
current-milestone: –
consecutive-escalations: 0
| Phase | Milestone | Status | Workdir | Base | Revise rounds | Stale | Notes |
|---|---|---|---|---|---|---|---|

Phase status: pending | in-progress | in-review | done | stale | escalated | blocked
Fix phases (`PHASE-F##`) go here too; Notes gives the findings, the owning phase, and `touches:`.

## Open items (shown at the next human stop)
```

## Brief

```markdown
# Brief: <project>
## Problem · Users · Outcome that matters most
## Target state (what the human can see and do when this run is done)
## Success measures (max 3, measurable)
## In scope · Out of scope (min 3)
## Kind: greenfield | brownfield (the change, the parts it touches, re-architect yes/no)
## Constraints (platform, required/forbidden tech, repo standards files)
## Reference material — dirty room (analyst only)
## Existing specs (human-owned; references/ADOPTION.md)
## Size: small | standard | large · Quality bar: prototype | internal | production
## Run: mode <stepwise | checkpoint | yolo> · max-parallel <n> · time/budget ceiling
```

## IDs and traceability

Every claim downstream of the brief cites an ID. Something you can't trace is out of scope.

| Prefix | Meaning | Defined in |
|---|---|---|
| `REQ-###` / `REQ-###.n` · `NFR-###` | Requirement / its acceptance criterion · measurable quality | 01 |
| `FLOW-###` / `SCR-###` | Flow / screen (or command, for a CLI or library) | 02, or 01 §UX notes when there is no 02 |
| `ADR-###` · `COMP-###` · `DATA-###` · `API-###` | Decision record · component · entity · contract | 03 |
| `ASM-###` | Assumption someone decided to rely on | any spec or report |
| `MS-#` / `PHASE-###` | Milestone / build phase (`PHASE-F##` for fix phases) | 04 |
| `Q-###` · `UXF-#` · `D-###` · `CR-###` · `H-###` | Question · designer feedback on 01 · decision · change request · handoff | run files |

- **Global and run-local.** `REQ`, `NFR`, `FLOW`, `SCR`, `ADR`, `COMP`, `DATA`, `API`, and `ASM` are global: a run numbers them after the highest in `system/` and every `runs/*/specs/`. The rest restart each run and are cited from other runs as `V002/D-014`.
- **Never reuse or renumber.** A removed item stays as `~~REQ-007~~ removed per D-012`.
- **IDs in code.** A test for an item under a phase's `acceptance tests:` writes the ID with `-` and `.` as `_`: `REQ-004.2` → `REQ_004_2_rejects_duplicate_email`, `DATA-003` → `DATA_003_…`.
- **Change tags (brownfield).** Each item in a brownfield run's specs is tagged `existing`, `new`, `changed`, or `removed` ([references/BROWNFIELD.md](./references/BROWNFIELD.md)).

**Decisions.** Each `D-###` in `decisions.md`:

```markdown
## D-012 <title>
source: human | auto-<mode> | builder · kind: answer | gate | clarification | override | out-of-scope
affects: <spec paths + IDs | none> · supersedes: <D-### | –>
decision: <one or two sentences>
```

## Handoff

The Lead writes `handoffs/H-###.md` before every dispatch:

```markdown
# H-###: <agent> — <mode> — <target>
mode: discover | requirements | ux | design | phase | precheck | spec-review | milestone-review | phase-review | acceptance | consolidate
tier: deep | standard | light · effort: low | medium | high · round: <n>
run-mode: <mode> · size: <size> · quality-bar: <bar>
workspace: <absolute> · team-root: <absolute> · workdir: <absolute> · base: <sha | –>
## Task
## Inputs (read only these)
## Outputs (write only these)
## Done when
## Context from the human (≤10 lines, cite D-###)
```

### Return

The agent appends this to the handoff and replies with only this block:

```markdown
## Return
status: done | needs-human | blocked
outputs: <paths> · trace: <IDs created or covered>
summary: <≤5 lines>
assumptions: <ASM ids | none>
decisions: <each decision you made without the human: Q or ambiguity · what you chose · affects | none>
questions: <batch per §Questions | none>
change-requests: <proposed CR text with class | none>
blocked-by: <only if blocked: spec-gap | test-red | env | dependency — evidence>
ux-feedback: <designer: open UXF IDs | none>
verify: <command · exit · one-line summary | n/a>
```

| blocked-by | Meaning | The Lead routes it to |
|---|---|---|
| `spec-gap` | the specs contradict each other, or building as written would change scope or a shared contract | a change request |
| `test-red` | a test won't go green after 3 genuine attempts | one deep retry, then escalation |
| `env` | a tool, runtime, or permission is missing | a `blocked` stop |
| `dependency` | a package not on the allowlist is needed | a change request (hard stop) |

## Questions

Ask only what changes the artifact and what the brief, `decisions.md`, or an approved spec doesn't already answer. Return **one batch** of at most 7, most important first:

```markdown
Q-012 [blocking] <question>
  recommended: <answer> — <one-line reason> · options: <a> | <b> · affects: <spec sections + IDs>
```

The Lead presents the batch in one message ("accept all" is a valid reply) and logs each answer as a `D-###`, copying `affects:`. In `yolo`, agents don't ask: they adopt their recommended answer and list it under `decisions:`.

## Change requests

Agents settle small things themselves. An ambiguity two reasonable readers would resolve the same way, or that changes nothing outside your own work, is yours to decide: record the choice as an `ASM` and under `decisions:`. Propose a **CR** only when a fix would change an approved spec's scope, a shared contract (`API`, `DATA`, 03 §6 conventions), another phase's behaviour, or the allowlist. Fix a defect in the spec where it starts. The Lead writes `changes/CR-###.md`:

```markdown
# CR-###: <title>
raised-by: <agent> in H-### · class: clarification | scope | contract | dependency
affects: <spec paths + IDs> · status: proposed | approved | rejected · decision: D-###
problem: · proposal: <the smallest change> · impact: <specs, phases, code>
```

`clarification` adds, removes, or widens no `REQ`, `NFR`, `API`, or dependency. When in doubt, it isn't one. Once approved, the Lead dispatches each affected spec's owner with "apply CR-### only", then one `spec-review` of the changed specs, and marks every phase tracing to a changed ID `stale`.

## Gate presentation

```
<Gate> — <artifacts> · reviewer: PASS (round <k>) — reviews/<file>
What this decides: <2–3 lines>
Key choices: <bullets with IDs>
Assumptions to confirm: <ASM list or none>
Decided without you since the last stop: <auto and builder D-### or none>
Risks: <top 3>
Options: Approve · Request changes · Switch mode · Stop · Abandon run
```

An escalation stop also offers **Override (give a reason)**.

## Command output

1. Redirect everything: `<cmd> > <workspace>/logs/<id>-<what>.log 2>&1; echo "exit=$?"`.
2. Read only the exit code, the last 30 lines, and the failing tests' names and first assertion line (`grep` the log).
3. Quote at most 10 lines anywhere.
4. Never re-run a failed command unchanged hoping it passes. Different results on the same tree mean a flaky test: report it.

## Phase diff

A builder doesn't commit, so new files are untracked. In the phase's `workdir:`: `git add --all --intent-to-add && git diff <base>` (add `--stat` for the file list).

## Run log and metrics

`log.md` gets one row per dispatch, written when its Return arrives, with `When` from `date -u +%FT%TZ`:

```markdown
| When | Stage | H-### | Agent | Mode | Tier | Effort | Round | Result | Tokens | Notes |
```

`retro.md` reports: dispatches and tokens per stage, first-pass PASS rate per agent, REVISE rounds, escalations and their reasons, human stops, CRs, auto decisions later overridden, and test count and verify duration.

## Clean room

1. **Local only.** Work only inside the project root and this skill's folder: no web, no remote tools. The package manager may install packages on the 03 §11 allowlist; anything else needs a CR.
2. **Dirty room.** Only `dm-at-analyst` may read the brief's *Reference material*, and it turns it into behaviour statements, never copied code or text. *Existing specs* in the brief are the human's own documents: the agents they're mapped to may read them and cite them like a `D-###` ([references/ADOPTION.md](./references/ADOPTION.md)). In brownfield, the project's own code is input every agent may read, cited by `path:line`.
3. **Spec-derived code.** The builder implements from the approved specs and its own decisions on small gaps, never from memory of a specific named project. Phase reports list the sources consulted (spec IDs and project files only).

## Direct invocation

If a human invokes a `dm-at-*` agent directly: if `.agent-team/active` names a run, read its `state.md`, refuse to edit an approved spec without an approved CR, do the task, and tell the human to resume with `/dm-agent-team`. If there is no run, offer `/dm-agent-team` (recommended) or a solo run: write only your own files, ask the human your question batch directly, and say there is no independent review.

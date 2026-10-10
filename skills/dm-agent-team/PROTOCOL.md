# Agent Team Protocol

The shared contract for the Lead, the builder, and the reviewer; it wins over the agent files.

## Workspace

All team state lives under `.agent-team/` at the project root (the **team root**) and is committed to git as the project's history. Source code lives where 03 §8 puts it.

```
.agent-team/                 # team root
├── active                   # the active run's folder name, or `none`
├── models.md                # tier → model mapping for this host (ROUTING.md)
├── lessons.md               # the team's memory across runs: one lesson per entry, one-line summary first
├── system/                  # living specs of the whole system, updated at the end of each run
└── runs/V002-csv-export/    # one folder per run: the run's **workspace**
    ├── state.md  brief.md  decisions.md  costs.tsv   # Lead-owned (costs.tsv is written by run.sh)
    ├── specs/               # 01-requirements, 02-ux (standard and large), 03-architecture (with the build plan)
    ├── build/               # builder: PHASE-###-report.md
    ├── reviews/             # reviewer and precheck.sh
    ├── baseline.md  discovery-scope.md            # brownfield only
    ├── retro.md
    ├── logs/                # git-ignored: full command output, never read whole
    └── worktrees/           # git-ignored: only when phases build in parallel (references/PARALLEL.md)
```

- **Paths are absolute.** Every dispatch names `workspace:` (the run folder) and `team-root:`. `.agent-team/...` in this skill means `<workspace>/...`, except `active`, `models.md`, `lessons.md`, and `system/`, which are in the team root. A builder in a worktree never reads or writes team files through the worktree's stale copy.
- **Git** ignores only `.agent-team/runs/*/worktrees/` and `.agent-team/runs/*/logs/`. The Lead commits the rest. Project tooling must ignore `.agent-team/`.
- **Runs** (starting, closing, abandoning, folding into `system/`): [references/RUNS.md](./references/RUNS.md).

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
stage: S0-brief | S0.5-discovery | S1-spec | S2-build | S3-accept | done
status: in-progress | awaiting-human | blocked | done | abandoned
halt: <kind: evidence, only while blocked | –>
next-action: <one line a fresh session can execute>
<!-- one field per line: scripts/run.sh reads them -->

## Gates
| Gate | Artifacts | Status | Round | Commit | Notes |
|---|---|---|---|---|---|
| brief | brief.md | pending | – | – | |

Gates: brief · baseline (brownfield: baseline.md) · spec (01, 02, 03) · MS-n · accept.
Status: pending | in-review | approved | approved (auto-<mode>) | approved (override) | n/a
Commit: the `.agent-team/` commit made at approval.

## Build
current-milestone: –
consecutive-escalations: 0
| Phase | Milestone | Status | Lane | Base | Revise rounds | Notes |
|---|---|---|---|---|---|---|

Phase status: pending | in-progress | in-review | done | stale | escalated | blocked
Fix phases (`PHASE-F##`) go here too; Notes gives the findings, the owning phase, and `touches:`.

## Log (one row per dispatch or resume, when its Return arrives)
| When (date -u) | Stage | Agent · mode | Tier · effort | Round | Result | Notes |

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
## Direction (what the interview settled: users and rules, UX direction, stack preferences, quality tools) — each as D-###
## Reference material — dirty room (the Lead reads it only while writing 01; never copied)
## Existing specs (human-owned; references/ADOPTION.md)
## Size: small | standard | large · Quality bar: prototype | internal | production
## Run: mode <stepwise | checkpoint | yolo> · max-parallel <n> · time/budget ceiling
```

## IDs and traceability

Every claim downstream of the brief cites an ID; what can't be traced is out of scope.

| Prefix | Meaning | Defined in |
|---|---|---|
| `REQ-###` / `REQ-###.n` · `NFR-###` | Requirement / its acceptance criterion · measurable quality | 01 |
| `FLOW-###` / `SCR-###` | Flow / screen (or command, for a CLI or library) | 02, or 01 §UX notes |
| `ADR-###` · `COMP-###` · `DATA-###` · `API-###` | Decision record · component · entity · contract | 03 |
| `ASM-###` | Assumption someone decided to rely on | any spec or report |
| `MS-#` / `PHASE-###` | Milestone / build phase (`PHASE-F##` for fix phases) | 03 §13 |
| `D-###` | Decision | decisions.md |

- **Global and run-local.** Spec items (`REQ`, `NFR`, `FLOW`, `SCR`, `ADR`, `COMP`, `DATA`, `API`, `ASM`) are global: a run numbers them after the highest in `system/` and every `runs/*/specs/`. `MS`, `PHASE`, and `D` restart each run and are cited from other runs as `V002/D-014`.
- **Never reuse or renumber.** A removed item stays as `~~REQ-007~~ removed per D-012`.
- **IDs in code.** A test for an item under a phase's `acceptance tests:` writes the ID with `-` and `.` as `_`: `REQ-004.2` → `REQ_004_2_rejects_duplicate_email`.
- **Change tags (brownfield).** Each item in a brownfield run's specs is tagged `existing`, `new`, `changed`, or `removed` ([references/BROWNFIELD.md](./references/BROWNFIELD.md)).

**Decisions.** Each `D-###` in `decisions.md`:

```markdown
## D-012 <title>
source: human | auto-<mode> | lead | builder · kind: answer | gate | change | override | out-of-scope
affects: <spec paths + IDs | none> · supersedes: <D-### | –>
decision: <one or two sentences, with the reason>
```

## Dispatch

The Lead dispatches an agent with one prompt; there is no handoff file. The prompt carries:

```
Effort: <level>. You are <dm-at-builder | dm-at-reviewer>; read <absolute SKILL.md> and <absolute PROTOCOL.md>, then follow them.
Why: <the brief's outcome in one line, and what this piece contributes>.
Mode: <phase | precheck | spec-review | milestone-review | phase-review | acceptance> · round <n> · run-mode <mode> · size <size> · quality-bar <bar>
workspace: <absolute> · team-root: <absolute> · workdir: <absolute> · base: <sha | –>
Task: <one or two sentences>
Inputs (read only these): <paths, with section or ID lists>
Outputs (write only these): <paths>
Done when: <checkable criteria>
Context: <≤10 lines; cite D-###>
Reply with only your Return block.
```

A **resume** (the same agent continued) carries only what changed: the verdict or review path, the next phase, and anything the Lead decided meanwhile.

### Return

The agent replies with only this block:

```markdown
## Return
status: done | blocked
outputs: <paths> · trace: <IDs covered>
summary: <≤5 lines; only what a tool result from this session shows>
assumptions: <ASM ids with one line each | none>
blocked-by: <only if blocked: spec-gap | test-red | env | dependency — evidence>
verify: <command · exit · one-line summary | n/a>
```

Agents never ask the human. A gap two reasonable people would settle the same way, or that affects only your own work, is yours to decide: record it as an `ASM` and in `assumptions:`. `blocked` is for what you can't settle:

| blocked-by | Meaning | The Lead's route |
|---|---|---|
| `spec-gap` | the specs contradict each other, or building as written would change scope or a shared contract | a spec change (§Spec changes) |
| `test-red` | a test won't go green after 3 genuine attempts | one resume at `high`, then escalation |
| `env` | a tool, runtime, or permission is missing | a `blocked` stop |
| `dependency` | a package not on the allowlist is needed | a spec change, and a hard stop in every mode |

## Spec changes after the spec gate

Only the Lead edits a frozen spec, and only through a `D-###` with `kind: change` naming the IDs edited and why. A clarification (adds, removes, or widens no `REQ`, `NFR`, `API`, or dependency) the Lead decides itself; a change of scope or of a shared contract goes to the human per the mode table. After the edit, every phase tracing to a changed ID is `stale`, and acceptance lists every post-gate change for the reviewer to re-check. An edit to a gated artifact without a `D-###` is drift ([references/EXCEPTIONS.md](./references/EXCEPTIONS.md)).

## Stops

Present a stop outcome first: what this decides, the key choices with their IDs, assumptions to confirm, decisions made since the last stop, risks, and the options (approve · request changes · switch mode · stop · abandon run; an escalation also offers override with a reason). Use the host's structured question tool if it has one.

## Command output

1. Redirect: `<cmd> > <workspace>/logs/<id>-<what>.log 2>&1; echo "exit=$?"`.
2. Read only the exit code, the last 30 lines, and each failing test's name and first assertion.
3. Quote at most 10 lines anywhere.
4. Never re-run a failed command unchanged; different results on the same tree are a flaky test to report.

## Phase diff

Builders don't commit, so new files are untracked. In the `workdir:`: `git add --all --intent-to-add && git diff <base>` (add `--stat` for the file list).

## Clean room

1. **Local only.** Only the project root and this skill's folder: no web, no remote tools. The package manager may install packages on the 03 §11 allowlist; anything else is a `dependency` block.
2. **Dirty room.** Only the Lead, while writing 01, reads the brief's *Reference material*, and turns it into behaviour statements, never copied code or text. *Existing specs* in the brief are the human's own documents, cited like a `D-###` ([references/ADOPTION.md](./references/ADOPTION.md)). In brownfield, the project's own code is input everyone may read, cited by `path:line`.
3. **Spec-derived code.** The builder implements from the approved specs and its own recorded assumptions, never from memory of a specific named project. Phase reports list the sources consulted.

## Direct invocation

If a human invokes `dm-at-builder` or `dm-at-reviewer` directly: if `.agent-team/active` names a run, read its `state.md`, do the task, and tell the human to resume with `/dm-agent-team`. With no run, do the task on what the human gives you, write only your own files, and say there was no independent review.

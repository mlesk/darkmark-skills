# Agent Team Protocol

This file defines the shared contract for the Lead and every `dm-at-*` agent. When an agent file and this file disagree, this file wins.

## Workspace

All team state lives under `.agent-team/` at the project root (the **team root**), and it is **committed** to git as the project's history of runs. Source code lives where `specs/03-architecture.md` puts it.

```
.agent-team/                 # the team root
├── active                   # control file: the active run's folder name, or `none`
├── models.md                # Lead-owned; human may edit overrides. Tier → model mapping for this host
├── system/                  # living specs: the whole system as built so far, consolidated after each run
│   ├── 01-requirements.md
│   ├── 02-ux.md
│   └── 03-architecture.md
└── runs/
    └── V002-csv-export/     # one folder per run: the run's **workspace**
        ├── state.md         # Lead-owned. The current truth: kind, mode, stage, gates, phases, counters
        ├── brief.md         # Lead-owned. G0 artifact
        ├── decisions.md     # Lead-owned. Append-only D-### log of this run's decisions
        ├── log.md           # Lead-owned. Append-only run log, one row per dispatch
        ├── specs/           # this run's 01-requirements, 02-ux, 03-architecture, 04-build-plan
        ├── ux/prototypes/   # dm-at-designer. Self-contained HTML, no external URLs
        ├── build/           # dm-at-builder. PHASE-###-report.md per phase
        ├── reviews/         # dm-at-reviewer. One file per review round
        ├── baseline.md      # Lead-owned, brownfield only. Test and quality baseline at baseline-commit
        ├── discovery-scope.md # Lead-owned, brownfield only. What discovery starts from and must re-check
        ├── approved/        # Lead-owned. Copy of each artifact as approved at its gate, for drift diffs
        ├── changes/         # Lead-owned. CR-###.md change requests
        ├── handoffs/        # Lead-owned. H-###.md; the agent appends only ## Return
        ├── retro.md         # Lead-owned. Written at the end
        ├── logs/            # git-ignored. Full command output, never read whole
        └── worktrees/       # git-ignored. One git worktree per phase being built
```

**Runs.** Each run of the team (the first greenfield build, then each brownfield change) gets its own folder `runs/V<NNN>-<name>/`: a three-digit sequence number and a short kebab-case name. `active` names the run in progress, or says `none` between runs. Exactly one run is active at a time. A run ends `done` (after G6) or `abandoned` (the human chose to abandon it at a stop); either way the Lead sets `active` to `none`.

**Workspace paths are absolute.** Builders and phase reviewers work inside a git worktree, whose checkout holds only a committed snapshot of `.agent-team/`, not the live files. So every handoff gives the run folder's absolute path as `workspace:` and the team root's as `team-root:`. Every path written as `.agent-team/...` in this protocol, in SKILL.md, and in the agent files means `<workspace>/...`, except `active`, `models.md`, and `system/`, which mean `<team-root>/...`. Never read or write team files through a path relative to your working directory: an edit to a worktree's snapshot is outside your phase's `touches:` and fails the precheck.

**What git ignores.** `.gitignore` lists `.agent-team/runs/*/worktrees/` (nested checkouts git can't track) and `.agent-team/runs/*/logs/` (raw command output). Everything else under `.agent-team/` is committed by the Lead (see SKILL.md §Lead rules).

**System specs.** `system/` holds the current specification of the whole system: every requirement, screen, component, contract, and ADR that exists, without change tags. It is written at the end of each run by the consolidation step (SKILL.md §Consolidate) and is the starting point for the next run's discovery. Each `system/` spec starts with a `coverage:` line: `full`, or `partial: <areas>` when the system came from a `--brownfield` discovery that recovered only the areas its change touched. Later runs widen it as they recover more.

**Global and run-local IDs.** Spec items are **global**: `REQ`, `NFR`, `ASM`, `FLOW`, `SCR`, `ADR`, `COMP`, `DATA`, and `API` keep their ID across runs, and a run numbers each of these prefixes after the highest ID in `system/` and in every `runs/*/specs/`, abandoned runs included (their phases may already be in the code). Everything else is **run-local** and restarts in each run: `Q`, `UXF`, `MS`, `PHASE`, `D`, `CR`, and `H`. Outside its own run, cite a run-local ID with its run's sequence number: `V002/D-014`.

Project test, lint, and build tooling must ignore `.agent-team/`.

### state.md skeleton

```markdown
# Agent Team State
team-version: <skill git sha | unknown>
project: <name>
run: V<NNN>-<name>
workspace: <absolute path to this run's folder>
team-root: <absolute path to .agent-team/>
kind: greenfield | brownfield
baseline-commit: <brownfield only: sha the run started from | –>
run-branch: <brownfield only: branch the team integrates into | –>
mode: stepwise | checkpoint | yolo
quality-bar: prototype | internal | production
max-parallel: <1–4>
stage: S0-kickoff | S0.5-discovery | S1-requirements | S2-ux | S3-architecture | S4-plan | S5-build | S6-acceptance | done
alignment-round: <0 until S2 needs one; counts requirements ⇄ UX rounds>
status: in-progress | awaiting-human | blocked | done | abandoned
halt: <kind: evidence, only while status is blocked | –>
next-action: <one line a fresh session can execute>
session-dispatches: <count since this session started>

## Gates
| Gate | Artifact | Status | Round | Approved | Hash | Reopens | Notes |
|---|---|---|---|---|---|---|---|
| G0 | brief.md | pending | – | – | – | 0 | |

Hash is `git hash-object <artifact>` recorded at approval (see SKILL.md §Spec integrity). It works on untracked files.
Gate status: pending | in-review | approved | approved (auto-<mode>) | approved (override) | aligning | reopened (CR-###) | recheck (CR-###)
`aligning` is used only on G1, while S2's alignment rounds edit 01; G2's approval sets it to G2's own approval status.

## Build
current-milestone: –
current-wave: –
consecutive-escalations: 0
| Phase | Milestone | Status | Workdir | Base | Revise rounds | Stale | Last review | Notes |
|---|---|---|---|---|---|---|---|---|

Phase status: pending | in-progress | in-review | done | stale | escalated | blocked
Fix phases (`PHASE-F##`) also go in this table; Notes gives the finding IDs, the owning phase, `touches:`, and in brownfield any `behaviour-changes:` and `deletes:`.

## Open items (shown at the next human stop)
- <CR / Q / escalation ids awaiting the human>
- <auto-approved gates and auto-answered questions since the last human stop, with D-###>
- <open ASM ids>
```

## Brief

```markdown
# Brief: <project>
## Problem
## Users
## Outcome that matters most
## Target state (what you can see and do when v1 is done)
## Success measures (max 3, measurable)
## In scope (v1)
## Out of scope (min 3)
## Kind: greenfield | brownfield (brownfield: the change, the parts of the system it touches, re-architect yes/no)
## Constraints (platform, required/forbidden tech, repo standards files)
## Reference material — dirty room (dm-at-analyst only)
- <path> — <what it is>
## Existing specs (human-owned; see references/ADOPTION.md)
- <path> → 01 | 02 | 03 — <what it is>
## Quality bar: prototype | internal | production
## Time / budget ceiling
## Run: mode <stepwise | checkpoint | yolo> · max-parallel <n>
```

## IDs and traceability

Every claim downstream of the brief cites an ID. If you cannot trace something, it is not in scope.

**Change tags (brownfield).** In a brownfield run, every item in 01, 02, and 03 carries one of `existing`, `new`, `changed`, or `removed` after its ID, for example `### REQ-002 Export totals — Must · changed`. A `changed` item keeps the ID of the `existing` item it changes and restates it in full; where the baseline version is also listed (01 §0, the baseline parts of 03), it stays as recorded, marked `→ changed`. A `removed` item keeps its ID and cites the `D-###` or `REQ` that removes it. An item that takes another's place under a different meaning is a `removed` item plus a `new` one. Only `new`, `changed`, and `removed` items are work; `existing` items are context the change must not break, and they cite the code they were recovered from. `existing` items are exempt from phase ownership, coverage tables, the acceptance trace matrix, and the Requirements ⇄ UX alignment checks, and a `path:line` (or test) citation counts as a source in every trace and hallucination check.

**Stages and phases.** A **stage** (`S0`–`S6`) is a step of the team's process: kickoff, requirements, UX, architecture, plan, build, acceptance. A **phase** (`PHASE-###`) is one unit of build work in `04-build-plan.md`, built by one builder in one worktree. Phases are planned inside out: horizontal layers first, UI phases last.

| Prefix | Meaning | Defined in |
|---|---|---|
| `REQ-###` / `REQ-###.n` | Functional requirement / its acceptance criterion | 01 |
| `NFR-###` | Measurable non-functional requirement | 01 |
| `ASM-###` | Assumption: an unconfirmed fact that someone decided to rely on | any spec |
| `Q-###` | Open question for the human | any spec |
| `FLOW-###` / `SCR-###` | User flow / screen (or CLI command, for developer-facing products) | 02 |
| `UXF-#` | Requirements feedback item raised by the designer | 02 §12 |
| `ADR-###` | Architecture decision record | 03 |
| `COMP-###` / `DATA-###` / `API-###` | Component / entity / contract | 03 |
| `MS-#` / `PHASE-###` | Milestone / build phase (`PHASE-F##` for fix phases) | 04 |
| `D-###` | Decision (human, or `auto-<mode>`) | decisions.md |
| `CR-###` | Change request | changes/ |
| `H-###` | Handoff | handoffs/ |

IDs are never reused or renumbered. A removed item stays in the file as `~~REQ-007~~ removed per D-012`.

**IDs in code.** Most languages don't allow `-` or `.` in identifiers, so a test for any item under a phase's `acceptance tests:` writes its ID with both replaced by `_`: `REQ-004.2` becomes `REQ_004_2` (for example `REQ_004_2_rejects_duplicate_email`), and `DATA-003` becomes `DATA_003`. Anyone searching for an item's test searches for that form.

Each `D-###` in `decisions.md` is an entry in this form. An auto decision is binding until a human overrides it. A decision that replaces an earlier one names it in `supersedes:`; the earlier entry is never edited.

```markdown
## D-012 <title>
source: human | auto-checkpoint | auto-yolo
kind: answer | gate | deviation | override | out-of-scope
affects: <spec paths + IDs this decision must show up in | none>
supersedes: <D-### | –>
decision: <what was decided, in one or two sentences>
```

**Assumptions** use the same table in every spec: `| ASM | Default | Risk if wrong | Confirm by |`.

## Handoff

The Lead writes `handoffs/H-###.md` before every dispatch:

```markdown
# H-###: <agent> — <mode> — <target>
from: lead
to: at-<agent>
mode: discover | consolidate | requirements | design | ux-language | ux | plan | phase | precheck | spec-review | phase-review | milestone-review | acceptance
tier: deep | standard | light
effort: low | medium | high
round: <n>
run-mode: stepwise | checkpoint | yolo
quality-bar: prototype | internal | production
workspace: <absolute path to this run's folder>
team-root: <absolute path to .agent-team/>
workdir: <absolute path: project root or worktree>
base: <commit sha the work starts from | –>
alignment-round: <n, only in an S2 alignment round | –>
work-list: <UXF IDs and D-### to apply in this alignment round | –>

## Task
<one or two sentences>

## Inputs (read only these)
- <path>[#section or ID list]

## Outputs (write only these)
- <path>

## Done when
- <checkable criterion>

## Context from the human (≤10 lines, cite D-###)
```

### Return

The agent appends this section to the same file, writes nothing else into it, and replies with only this block:

```markdown
## Return
status: done | needs-human | blocked
outputs: <paths written>
summary: <≤5 lines>
trace: <IDs created or covered>
assumptions: <ASM ids | none>
questions: <question batch per §Questions | none>
auto-decisions: <yolo only: each as Q-### · answer adopted · affects: <spec IDs> | none>
change-requests: <proposed CR text with class | none>
blocked-by: <only when status is blocked: spec-gap | test-red | env | dependency — evidence (spec ID, or test · command · exit · log path)>
ux-feedback: <designer only: open UXF IDs in 02 §12 | none>
verify: <command · exit · one-line summary | n/a>
```

`needs-human` means the agent needs answers before it can finish. `blocked` means the agent cannot proceed without changing something it does not own, and `blocked-by:` says which kind:

| blocked-by | Meaning | The Lead routes it to |
|---|---|---|
| `spec-gap` | a spec is missing, ambiguous, or contradictory | a change request |
| `test-red` | a test will not go green after 3 genuine attempts | the escalation ladder's deep retry, then escalation |
| `env` | a tool, runtime, or permission is missing on this machine | a `blocked` stop for the human |
| `dependency` | a package that is not on the allowlist is needed | a change request (a hard stop in every mode) |

## Questions

Agents never talk to the human directly when dispatched. They return **one batch** of at most 7 questions, most important first:

```markdown
Q-012 [blocking] <question>
  recommended: <answer> — <one-line reason>
  options: <a> | <b> | <c>
  affects: <the spec sections and IDs the answer changes>
```

The Lead copies `affects:` into the `D-###` that records the answer, so the reviewer can check that the decision reached the spec without the Lead reading specs.

The Lead presents the whole batch in one message (use the host's structured question tool if it has one) and tells the human they can reply "accept all" or answer only the ones they disagree with. Each answer becomes a `D-###`.

In `yolo` mode nobody asks. When the handoff says `run-mode: yolo`, the agent does not return `needs-human` for questions: it adopts each recommended answer, continues, and lists them under `auto-decisions:` in its Return. The Lead records each one as a `D-###` with `source: auto-yolo`. If an agent still returns a batch in yolo mode, the Lead accepts the recommended answers the same way and re-dispatches.

Ask only what changes the artifact. Never ask what the brief, `decisions.md`, or an approved spec already answers.

## Change requests

A change request (CR) is opened when an agent finds a defect in an approved or frozen spec, or needs something outside its ownership. Fix a defect in the spec where it starts, not in the spec where it was noticed. **Exception:** before G2, a problem with 01 found during S2 goes to 02 §12 as a `UXF` row and is settled in an alignment round (SKILL.md §Requirements ⇄ UX alignment), not through a CR. Agents only *propose* CR text in their Return. The Lead writes `changes/CR-###.md`:

```markdown
# CR-###: <title>
raised-by: <agent> in H-###
class: clarification | scope | dependency | contract
affects: <spec paths + IDs>
problem: <what is wrong or missing>
proposal: <the smallest change that fixes it>
impact: <downstream specs, phases, and code that must change>
status: proposed | approved | rejected
decision: D-###
```

`clarification` means the change resolves an ambiguity without adding, removing, or widening a `REQ`, `NFR`, `API`, or dependency. Anything else is not a clarification. When in doubt, it is not.

Once a CR is approved, the Lead applies it in this order:

1. Dispatch the owner of the edited spec to apply it, set that spec's gate row to `reopened (CR-###)`, and add 1 to its Reopens count.
2. Dispatch the reviewer in `spec-review` mode on the edited spec.
3. For every downstream spec named in the CR's `impact:` whose gate is **already approved**, set the row to `recheck (CR-###)`, then dispatch its owner to bring it in line, followed by a `spec-review`, in spec order (01 → 04). An owner that finds nothing to change says so in its Return's `summary:`, and a clean review returns the row to the status it had before, without a stop. A downstream spec that is not approved yet simply gets the CR file as an input on its next author round.
4. A spec whose content changed is approved again per the mode table (its gate stops or auto-approves as it did originally), and its hash and copy are re-recorded.
5. Mark every phase listed in `impact:`, or tracing to a changed ID, as `stale`. Those phases are rebuilt.

Each of these author dispatches uses the author's usual mode, lists `changes/CR-###.md` as an input, and has the task "apply CR-### only". **A CR round changes only what the CR names**, the same way a revision round fixes only the review findings.

A spec reaching Reopens 3 in one run is a stop in every mode: the spec keeps being wrong, so the human should look at it.

## Gate presentation

```
Gate G<n> — <artifact>
Reviewer verdict: PASS (round <k>) — reviews/<file>
What this decides: <2–3 lines>
Key choices: <bullets, each with its ID>
Assumptions needing your confirmation: <ASM list or none>
Decided without you since the last stop: <auto D-### list or none>
Risks: <top 3>
Your options: Approve · Request changes (say what) · Switch mode · Stop · Abandon run
```

An **escalation** stop (the author or builder ran out of REVISE rounds) also offers **Override (give a reason)**: the human accepts the work despite the open findings. See SKILL.md §Human override.

In `checkpoint` mode, G4 presents G1–G4 as one stop with one block per spec. If the host has a structured question tool, use it for the options.

## Command output

Build, test, and verify output can be thousands of lines. Never read it whole.

1. Redirect everything to a file in the workspace: `<cmd> > <workspace>/logs/<id>-<what>.log 2>&1; echo "exit=$?"`.
2. Read only the exit code and the summary: the last 30 lines, plus the names and first assertion line of each failing test (use `grep` on the log).
3. Quote at most 10 lines of output in any report or review.
4. Never re-run a failed command unchanged in the hope that it passes. Re-run only after a change, and say what changed. If the same command gives different results on the same tree, that is a flaky test: report it, don't retry it away.

## Phase diff

A builder never commits, so a phase's new files are untracked, and plain `git diff` does not show them. To see a phase's whole change, run this in its `workdir:`:

```bash
git add --all --intent-to-add && git diff <base>          # full diff, new files included
git add --all --intent-to-add && git diff --stat <base>   # file list
```

`git status --porcelain --untracked-files=all` in the worktree lists the same files one by one (without the flag, a new folder shows as a single entry). Reports and reviews are written to the live workspace, not the worktree, so they never appear.

## Run log

`log.md` is append-only. Write exactly one row per dispatch, when its Return or verdict arrives, with `When` taken from `date -u +%FT%TZ` (never estimated):

```markdown
| When | Stage | Wave | H-### | Agent | Mode | Tier | Effort | Round | Result | Tokens | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
```

`Result` is the Return status for authors, or the verdict for reviews. `Tokens` is the dispatch's token count if the host reports it, otherwise `–`. Note any escalation as `ladder-<rule number>`.

## Metrics

Compute these from `log.md` and `state.md` for `retro.md`:

- **First-pass PASS rate** for each author: reviews that passed in round 1, divided by all first-round reviews.
- **Average REVISE rounds** for each stage and for phases.
- **Escalations to the human**, and the reason for each.
- **Human stops**, and how many were gates versus question batches.
- **Gate edits:** the number of gates where the human requested changes.
- **Auto decisions** that a human later overrode.
- **Escaped defects:** findings in acceptance that a phase review should have caught.
- **Phase cycle:** dispatches per phase.
- **Parallelism:** average wave size, and the number of stale rebuilds caused by merge conflicts.
- **Routing:** dispatches and tokens per tier; first-pass PASS rate per route; ladder escalations per rule; precheck FAILs that saved a deep review.
- **Sessions:** the number of sessions, and dispatches per session.
- **Test health:** total tests, pass rate, and the verify command's duration.

## Clean room

1. **Local only.** Read and write only inside the project root and this skill's folder. No web search, no URL fetching, no MCP or remote tools, no issue trackers. Use the local filesystem, local git, and local build and test commands.
2. **One network exception.** The package manager may install dependencies that appear in the **dependency allowlist** in `specs/03-architecture.md`. Anything else needs a CR.
3. **Dirty room.** Only `dm-at-analyst` may read the paths listed under *Reference material* in `brief.md`. In a brownfield run, the project's own existing code is not the dirty room: it is human-owned input every agent may read, cited by path and line (see references/BROWNFIELD.md). *Existing specs* are different: they are the human's own documents for this project, and the agents the brief maps them to may read them. An author treats an existing spec in its handoff inputs as settled unless it contradicts the brief, a `D-###`, or another existing spec; each contradiction or gap becomes a `Q` with the existing text as the recommended answer. Anything taken from one cites it as its source (`from <path> §<section>`), and the reviewer accepts that citation like a `D-###`. The analyst describes behaviour in requirements and never copies code or exact text. Every other agent must not open those paths.
4. **Spec-derived code.** `dm-at-builder` writes code only from approved specs. It does not reproduce code from memory of a specific named project. If a spec is too thin to implement without inventing behaviour, the builder returns `blocked` and proposes a CR.
5. **Provenance.** Every phase report lists the sources consulted, which must be spec IDs and project files only. `dm-at-reviewer` audits this, and also checks dependencies against the allowlist and its recorded licenses.

## Direct invocation

When a human invokes a `dm-at-*` skill directly instead of through the Lead:

1. If `.agent-team/active` names a run, read that run's `state.md`. Refuse to edit a frozen spec unless the human names an approved CR. Otherwise do the task, then tell the human to run `/dm-agent-team` to resume, so that state and gates stay consistent.
2. If no workspace exists, ask whether to start with `/dm-agent-team` (recommended) or run solo. In solo mode, create only your own output files. You talk to the human directly: ask your questions as one batch per §Questions and wait for the answers. Write your Return as your final message instead of into a handoff. End by asking the human to approve the result. There is no reviewer in solo mode, so say so.

# Agent Team Protocol

This file defines the shared contract for the Lead and every `dm-at-*` agent. When an agent file and this file disagree, this file wins.

## Workspace

All team state lives in `.agent-team/` at the project root. Source code lives where `specs/02-architecture.md` puts it.

**The workspace is git-ignored and addressed by absolute path.** `.agent-team/` is listed in `.gitignore` and never committed. Builders and slice reviewers work inside a git worktree, which has no copy of it. So every handoff gives the workspace's absolute path as `workspace:`, and every path written as `.agent-team/...` in this protocol and in the agent files means `<workspace>/...`, never a path relative to your working directory. Source code and tests go in the handoff's `workdir:`; reports, reviews, and logs go in the workspace.

```
.agent-team/
├── state.md            # Lead-owned. The current truth: mode, phase, gates, slices, counters
├── models.md           # Lead-owned; human may edit overrides. Tier → model mapping for this host
├── brief.md            # Lead-owned. G0 artifact
├── decisions.md        # Lead-owned. Append-only D-### log of decisions
├── log.md              # Lead-owned. Append-only run log, one row per dispatch
├── specs/
│   ├── 01-requirements.md   # dm-at-analyst
│   ├── 02-architecture.md   # dm-at-architect (design)
│   ├── 03-ux.md             # dm-at-designer
│   └── 04-build-plan.md     # dm-at-architect (plan)
├── ux/prototypes/      # dm-at-designer. Self-contained HTML, no external URLs
├── build/              # dm-at-builder. SLICE-###-report.md per slice
├── reviews/            # dm-at-reviewer. One file per review round
├── logs/               # Whoever ran the command. Full command output, never read whole
├── approved/           # Lead-owned. Copy of each artifact as approved at its gate, for drift diffs
├── changes/            # Lead-owned. CR-###.md change requests
├── handoffs/           # Lead-owned. H-###.md; the agent appends only ## Return
├── worktrees/          # Lead-owned. One git worktree per slice being built
└── retro.md            # Lead-owned. Written at the end
```

Project test, lint, and build tooling must ignore `.agent-team/`.

### state.md skeleton

```markdown
# Agent Team State
team-version: <skill git sha | unknown>
project: <name>
workspace: <absolute path to .agent-team/>
mode: stepwise | checkpoint | yolo
quality-bar: prototype | internal | production
max-parallel: <1–4>
phase: P0-kickoff | P1-requirements | P2-architecture | P3-ux | P4-plan | P5-build | P6-acceptance | done
status: in-progress | awaiting-human | blocked
halt: <kind: evidence, only while status is blocked | –>
next-action: <one line a fresh session can execute>
session-dispatches: <count since this session started>

## Gates
| Gate | Artifact | Status | Round | Approved | Hash | Notes |
|---|---|---|---|---|---|---|
| G0 | brief.md | pending | – | – | – | |

Hash is `git hash-object <artifact>` recorded at approval (see SKILL.md §Spec integrity). It works on untracked files.

## Build
current-milestone: –
current-wave: –
consecutive-escalations: 0
| Slice | Milestone | Status | Workdir | Base | Revise rounds | Stale | Last review | Notes |
|---|---|---|---|---|---|---|---|---|

Slice status: pending | in-progress | in-review | done | stale | escalated | blocked
Fix slices (`SLICE-F##`) also go in this table; Notes gives the finding IDs, the owning slice, and `touches:`.

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
## Success measures (max 3, measurable)
## In scope (v1)
## Out of scope (min 3)
## Constraints (platform, required/forbidden tech, repo standards files)
## Reference material — dirty room (dm-at-analyst only)
- <path> — <what it is>
## Quality bar: prototype | internal | production
## Time / budget ceiling
## Run: mode <stepwise | checkpoint | yolo> · max-parallel <n>
```

## IDs and traceability

Every claim downstream of the brief cites an ID. If you cannot trace something, it is not in scope.

| Prefix | Meaning | Defined in |
|---|---|---|
| `REQ-###` / `REQ-###.n` | Functional requirement / its acceptance criterion | 01 |
| `NFR-###` | Measurable non-functional requirement | 01 |
| `ASM-###` | Assumption: an unconfirmed fact that someone decided to rely on | any spec |
| `Q-###` | Open question for the human | any spec |
| `ADR-###` | Architecture decision record | 02 |
| `COMP-###` / `DATA-###` / `API-###` | Component / entity / contract | 02 |
| `FLOW-###` / `SCR-###` | User flow / screen (or CLI command, for developer-facing products) | 03 |
| `MS-#` / `SLICE-###` | Milestone / build slice (`SLICE-F##` for fix slices) | 04 |
| `D-###` | Decision (human, or `auto-<mode>`) | decisions.md |
| `CR-###` | Change request | changes/ |
| `H-###` | Handoff | handoffs/ |

IDs are never reused or renumbered. A removed item stays in the file as `~~REQ-007~~ removed per D-012`.

**IDs in code.** Most languages don't allow `-` or `.` in identifiers, so a test for an acceptance criterion writes its ID with both replaced by `_`: `REQ-004.2` becomes `REQ_004_2` (for example `REQ_004_2_rejects_duplicate_email`). Anyone searching for a criterion's test searches for that form.

Each `D-###` in `decisions.md` records `source: human | auto-checkpoint | auto-yolo`. An auto decision is binding until a human overrides it.

## Handoff

The Lead writes `handoffs/H-###.md` before every dispatch:

```markdown
# H-###: <agent> — <mode> — <target>
from: lead
to: at-<agent>
mode: requirements | design | ux-language | ux | plan | slice | precheck | spec-review | slice-review | milestone-review | acceptance
tier: deep | standard | light
effort: low | medium | high
round: <n>
run-mode: stepwise | checkpoint | yolo
quality-bar: prototype | internal | production
workspace: <absolute path to .agent-team/>
workdir: <absolute path: project root or worktree>
base: <commit sha the work starts from | –>

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
auto-decisions: <yolo only: each question you settled yourself, with the answer adopted | none>
change-requests: <proposed CR text with class | none>
blocked-by: <only when status is blocked: spec-gap | test-red | env | dependency — evidence (spec ID, or test · command · exit · log path)>
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
```

The Lead presents the whole batch in one message (use the host's structured question tool if it has one) and tells the human they can reply "accept all" or answer only the ones they disagree with. Each answer becomes a `D-###`.

In `yolo` mode nobody asks. When the handoff says `run-mode: yolo`, the agent does not return `needs-human` for questions: it adopts each recommended answer, continues, and lists them under `auto-decisions:` in its Return. The Lead records each one as a `D-###` with `source: auto-yolo`. If an agent still returns a batch in yolo mode, the Lead accepts the recommended answers the same way and re-dispatches.

Ask only what changes the artifact. Never ask what the brief, `decisions.md`, or an approved spec already answers.

## Change requests

A change request (CR) is opened when an agent finds a defect in a frozen spec, or needs something outside its ownership. Agents only *propose* CR text in their Return. The Lead writes `changes/CR-###.md`:

```markdown
# CR-###: <title>
raised-by: <agent> in H-###
class: clarification | scope | dependency | contract
affects: <spec paths + IDs>
problem: <what is wrong or missing>
proposal: <the smallest change that fixes it>
impact: <downstream specs, slices, and code that must change>
status: proposed | approved | rejected
decision: D-###
```

`clarification` means the change resolves an ambiguity without adding, removing, or widening a `REQ`, `NFR`, `API`, or dependency. Anything else is not a clarification. When in doubt, it is not.

Once a CR is approved, the Lead dispatches the owning author to apply it and the reviewer checks the edited spec. Every slice it touches is marked `stale` in `state.md` and rebuilt.

## Gate presentation

```
Gate G<n> — <artifact>
Reviewer verdict: PASS (round <k>) — reviews/<file>
What this decides: <2–3 lines>
Key choices: <bullets, each with its ID>
Assumptions needing your confirmation: <ASM list or none>
Decided without you since the last stop: <auto D-### list or none>
Risks: <top 3>
Your options: Approve · Request changes (say what) · Switch mode · Stop
```

In `checkpoint` mode, G4 presents G1–G4 as one stop with one block per spec. If the host has a structured question tool, use it for the options.

## Command output

Build, test, and verify output can be thousands of lines. Never read it whole.

1. Redirect everything to a file in the workspace: `<cmd> > <workspace>/logs/<id>-<what>.log 2>&1; echo "exit=$?"`.
2. Read only the exit code and the summary: the last 30 lines, plus the names and first assertion line of each failing test (use `grep` on the log).
3. Quote at most 10 lines of output in any report or review.

## Slice diff

A builder never commits, so a slice's new files are untracked, and plain `git diff` does not show them. To see a slice's whole change, run this in its `workdir:`:

```bash
git add --all --intent-to-add && git diff <base>          # full diff, new files included
git add --all --intent-to-add && git diff --stat <base>   # file list
```

`git status --porcelain --untracked-files=all` in the worktree lists the same files one by one (without the flag, a new folder shows as a single entry). The workspace is git-ignored, so reports and logs never appear.

## Run log

`log.md` is append-only. Write one row per dispatch:

```markdown
| When | Phase | Wave | H-### | Agent | Mode | Tier | Effort | Round | Result | Tokens | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|
```

`Result` is the Return status for authors, or the verdict for reviews. `Tokens` is the dispatch's token count if the host reports it, otherwise `–`. Note any escalation as `ladder-<rule number>`.

## Metrics

Compute these from `log.md` and `state.md` for `retro.md`:

- **First-pass PASS rate** for each author: reviews that passed in round 1, divided by all first-round reviews.
- **Average REVISE rounds** for each phase and for slices.
- **Escalations to the human**, and the reason for each.
- **Human stops**, and how many were gates versus question batches.
- **Gate edits:** the number of gates where the human requested changes.
- **Auto decisions** that a human later overrode.
- **Escaped defects:** findings in acceptance that a slice review should have caught.
- **Slice cycle:** dispatches per slice.
- **Parallelism:** average wave size, and the number of stale rebuilds caused by merge conflicts.
- **Routing:** dispatches and tokens per tier; first-pass PASS rate per route; ladder escalations per rule; precheck FAILs that saved a deep review.
- **Sessions:** the number of sessions, and dispatches per session.
- **Test health:** total tests, pass rate, and the verify command's duration.

## Clean room

1. **Local only.** Read and write only inside the project root and this skill's folder. No web search, no URL fetching, no MCP or remote tools, no issue trackers. Use the local filesystem, local git, and local build and test commands.
2. **One network exception.** The package manager may install dependencies that appear in the **dependency allowlist** in `specs/02-architecture.md`. Anything else needs a CR.
3. **Dirty room.** Only `dm-at-analyst` may read the paths listed under *Reference material* in `brief.md`. The analyst describes behaviour in requirements and never copies code or exact text. Every other agent must not open those paths.
4. **Spec-derived code.** `dm-at-builder` writes code only from approved specs. It does not reproduce code from memory of a specific named project. If a spec is too thin to implement without inventing behaviour, the builder returns `blocked` and proposes a CR.
5. **Provenance.** Every slice report lists the sources consulted, which must be spec IDs and project files only. `dm-at-reviewer` audits this, and also checks dependencies against the allowlist and its recorded licenses.

## Direct invocation

When a human invokes a `dm-at-*` skill directly instead of through the Lead:

1. If `.agent-team/state.md` exists, read it. Refuse to edit a frozen spec unless the human names an approved CR. Otherwise do the task, then tell the human to run `/dm-agent-team` to resume, so that state and gates stay consistent.
2. If no workspace exists, ask whether to start with `/dm-agent-team` (recommended) or run solo. In solo mode, create only your own output files. You talk to the human directly: ask your questions as one batch per §Questions and wait for the answers. Write your Return as your final message instead of into a handoff. End by asking the human to approve the result. There is no reviewer in solo mode, so say so.

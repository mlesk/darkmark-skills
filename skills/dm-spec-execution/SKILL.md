---
name: dm-spec-execution
description: Autonomous implementation loop for solutions specified by the sibling `dm-spec-creation` skill. Reads `01-specifications/spec-06-execution-plan.md` and maintains `01-specifications/execution-state.md` as the source of truth. Runs the inside-out Phase state machine defined in `.github/skills/dm-spec-creation/standards/planning-standards-inside-out-phases.md` §11 — pick next pending Phase whose dependencies are done, mark in-progress, read spec-anchors, resolve open decisions, implement deliverables, verify done-when, open PR, merge on green, mark done, loop. Stops cleanly on failure (state stays consistent), on context-budget halts (writes a resume-hint), and when all Phases are done. Use after `dm-spec-creation` reports DONE and you want to ship code.
---

<what-to-do>

You run the autonomous implementation loop for the system specified by the sibling `dm-spec-creation` skill. Your job is to make `execution-state.md` advance one honest tick at a time until all Phases are `done`, or to halt cleanly with the state file in a consistent, pushed condition.

**Inputs (all required; halt loudly if any is missing):**

- `01-specifications/spec-06-execution-plan.md` — the plan. **Immutable during execution.**
- `01-specifications/execution-state.md` — the state file you own and mutate. **Authoritative** progress source; git history is incidental.
- `01-specifications/spec-02[a-z]-*.md` architecture sidecars referenced by spec-06 `spec-anchors:`. **Immutable during execution.**
- `.github/skills/dm-spec-creation/standards/planning-standards-inside-out-phases.md` — canonical state machine (§11), failure protocol (§11a), context-budget halt protocol (§11b), forbidden patterns (§12), state schema (§10).
- `.github/skills/dm-spec-creation/standards/coding-standards-testing.md` — pinned test toolchain and exact `done-when` commands.
- `.github/skills/dm-spec-creation/STANDARDS-PROTOCOL.md` — which standards apply to which Phase layer.

**Workflow (run every invocation):**

1. **Bootstrap** — follow [ORCHESTRATION.md](./ORCHESTRATION.md) §1. Emit the bootstrap status block.
2. **Session-intent gate** — see "Session intent gate" below. Ask exactly one question with a recommended answer. Skip only if the invoking message already specified intent (e.g. "run to done", "just resume", "dry-run").
3. **Run the state machine** — loop the canonical §11 procedure until one halt condition fires (see ORCHESTRATION.md §3).
4. **Emit session summary** — exactly one summary block (see "Reporting"), always, including on every defect/halt path.
5. **Final self-review** — silently walk the checklist at the end of this file before declaring DONE/PAUSED/BLOCKED. If any check fails, halt with a STANDARDS-DEFECT line; do not paper over.

Never improvise. No PRs without a green `done-when`. No deliverable ticks without targeted tests passing. No hand-edits of `execution-state.md` outside §10/§11 rules.

</what-to-do>

<supporting-info>

## Session intent gate

After bootstrap reports state, before entering §11, ask the user exactly one question:

> How should I run this session?
>
> 1. **Run All Phases To DONE** — loop until all Phases are done, blocked, or context budget halts. **(recommended)**
> 2. **Run Next Phase Only** — execute the next-ready Phase end-to-end, then stop.
> 3. **Run Through Completion of Specific Phase** — execute ALL phases through a specific Phase end-to-end, then stop.
> 4. **Resume only** — finish the currently `in-progress` Phase (if any), then stop. Useful for picking up after a paused/crashed session.
> 5. **Dry-run** — report what the next action would be and exit without mutating state.

Recommended answer: **Run to DONE.**

Skip this gate if the invoking message already named the mode (e.g. "dm-spec-execution dry-run", "just resume", "run one phase"). State which mode you inferred before continuing.

Dry-run mode: emit the bootstrap status + the §11 step that would run next + the spec-anchors and standards it would read. Do not write commits, PRs, or state mutations. Exit with `DRY-RUN — would run §11 step <N> on <P-id>`.

## Relationship to dm-spec-creation

`dm-spec-creation` produces the plan; this skill runs it. Siblings, not parent/child. This skill never modifies any file under `01-specifications/spec-*.md` (including `spec-02[a-z]-*.md` sidecars), never modifies anything under `.github/skills/dm-spec-creation/standards/`, and never re-invokes `dm-spec-creation`. If a Phase reveals a spec or standards defect, set the state block as described in "Hard rules" and halt.

The standards bundle is owned by `dm-spec-creation`. Read from there directly. Do not copy or vendor.

## Hard rules

- **Authoritative state.** `execution-state.md` is the only source of truth for progress. Never infer progress from git, file timestamps, or PR status.
- **One Phase per session-block.** Do not interleave work from two Phases. If you finish a Phase and context budget is tight, halt with a resume-hint pointing at "select next Phase".
- **No speculative ticks.** Only tick a deliverable after its targeted tests pass. The full `done-when` block runs at Phase end and must catch dishonest ticks.
- **No silent failures.** Any failed `done-when` command triggers §11a. The branch and state file MUST be pushed before halting.
- **No spec edits.** If you find a spec defect, set `blocked-by: spec-defect-in-<spec-id>-<anchor>: <issue>`, push, halt with `SPEC-DEFECT`.
- **No sidecar edits.** If a `spec-02[a-z]-*.md` sidecar is wrong, set `blocked-by: spec-defect-sidecar-<file>-<anchor>: <issue>`, push, halt with `SPEC-DEFECT — sidecar <file>`.
- **No standards edits.** Set `blocked-by: standards-defect: <issue>`, push, halt with `STANDARDS-DEFECT`.
- **Never run `dm-spec-creation`.** If specs are missing or not gate-passed at bootstrap, halt and instruct the user.
- **Never auto-retry a failed `done-when`.** A spurious second-run "pass" is worse than an honest failure.
- **Never force-push the state file.** Never rewrite history of the current Phase branch.

## Anti-patterns (reject on sight)

- **Implicit progress.** "The tests passed locally, so I'll tick the deliverable." → No. Tick only after the deliverable's targeted tests pass _in CI_ per `done-when`.
- **Phase-bleed.** Starting Phase N+1 before Phase N is `done` and pushed. → Halt instead; new session picks up.
- **State drift papering.** Plan-SHA or sidecar-SHA mismatch silently "refreshed" by the agent. → That's PLAN-DRIFT. Halt; human decides re-baseline vs revert.
- **Spec patch in disguise.** "I'll just tweak this sidecar anchor so the deliverable fits." → No. SPEC-DEFECT halt.
- **Done-when shortening.** Running a subset of the `done-when` commands "because the rest are slow". → No. All commands, in order, captured output.
- **Blocker as TODO.** Marking a Phase `blocked` and continuing to the next one. → No. Blocked means halt the session.
- **Skill-edit by side effect.** Editing this skill, the planning standard, or any sibling standard mid-run to make a Phase pass. → STANDARDS-DEFECT halt.
- **Chat-only halt.** Reporting a halt to the user without pushing the branch + state file first. → No. State must be durable.

## Reporting

After every state change (mark in-progress, tick deliverable, mark blocked, mark done, halt with resume-hint), emit exactly one status line:

```text
[dm-spec-execution] P<id> <status>: <one-line context>
```

At session end — DONE, BLOCKED, PAUSED, SPEC-DEFECT, STANDARDS-DEFECT, PLAN-DRIFT, DRY-RUN — emit exactly one summary block:

```text
[dm-spec-execution] Session summary
- started at: <Phase + status at bootstrap>
- ended at:   <Phase + status at halt>
- intent:     <Run to DONE | Run one Phase | Resume only | Dry-run>
- PRs opened: [#NNN, …]
- PRs merged: [#NNN, …]
- decisions logged: [D-NNN, …]
- halt reason: <DONE | BLOCKED:<reason> | PAUSED:<hint> | SPEC-DEFECT:<…> | STANDARDS-DEFECT:<…> | PLAN-DRIFT:<…> | DRY-RUN>
- next action: <one line>
```

## Final self-review (run silently before emitting the session summary)

- [ ] `execution-state.md` parses against §10 schema (status, updated, commit-when-done, blocked-by-when-blocked).
- [ ] Plan-SHA in state header matches `git hash-object 01-specifications/spec-06-execution-plan.md`.
- [ ] Every sidecar referenced by the touched Phase's `spec-anchors:` matches its recorded SHA in `sidecar-shas:`.
- [ ] No `01-specifications/spec-*.md` file was modified in this session.
- [ ] No `.github/skills/dm-spec-creation/standards/**` file was modified in this session.
- [ ] Every deliverable ticked in this session has a corresponding targeted test that passed.
- [ ] If a Phase was marked `done`, its full `done-when` block ran and every command exited 0.
- [ ] If a Phase was marked `blocked`, `blocked-by:` is populated and the branch + state file are pushed.
- [ ] If the session paused for context budget, `resume-hint:` is populated and `status: in-progress` is preserved.
- [ ] Exactly one status line was emitted per state change; exactly one session summary will be emitted next.

If any check fails, do not emit the planned summary. Instead halt with:

```text
[dm-spec-execution] STANDARDS-DEFECT — self-review failed: <which check> — state not advanced
```

Push whatever is consistent and stop.

</supporting-info>

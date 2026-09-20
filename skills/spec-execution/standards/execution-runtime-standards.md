# Execution Runtime Standards

This is the **consumer-side** wrapper that `spec-execution-pocockified` follows when interpreting and mutating state. The **authoritative** state machine, schema, failure protocol, and context-budget halt protocol live in the sibling `spec-creation` skill:

- `.github/skills/spec-creation/standards/planning-standards-inside-out-phases.md` §10 — execution state schema (canonical).
- §11 — agent execution protocol (canonical state machine).
- §11a — failure protocol (canonical).
- §11b — context-budget halt protocol (canonical).
- §12 — forbidden patterns (canonical).
- `.github/skills/spec-creation/standards/coding-standards-testing.md` — pinned test toolchain and exact `done-when` commands.

Cite those sections when in doubt. This file only adds runtime-specific clarifications that would clutter the planning standard.

## 1. State file is untrusted input

Even though `spec-execution-pocockified` is the sole author of `execution-state.md`, treat every read as untrusted:

- **Schema.** Validate every Phase block against §10 (status, updated, `commit:` when done, `blocked-by:` when blocked). On violation, halt with `STANDARDS-DEFECT — execution-state.md violates §10 schema at P<id>`. Do NOT auto-repair.
- **Commit SHAs.** Every `commit:` SHA must resolve in the local git repository. If not, halt — corrupted history is a human-investigation condition.
- **Plan SHA.** The state file header MUST carry `plan-sha: <git hash-object 01-specifications/spec-06-execution-plan.md at bootstrap>`. On every read, recompute and compare. Mismatch → halt with `PLAN-DRIFT — spec-06 was modified after execution started; expected <old> got <new>`. Recovery is a human decision (re-baseline vs revert).
- **Sidecar SHAs.** The state file header MUST carry `sidecar-shas:` — a map listing the `git hash-object` of every `01-specifications/spec-02[a-z]-*.md` file referenced by spec-06 anchors at bootstrap. On every read, recompute and compare. Any mismatch → halt with `PLAN-DRIFT — sidecar <file> was modified after execution started; expected <old> got <new>`.

## 2. Recovery posture

For every recoverable error class, the response is **always**: set state, push, halt. Never:

- retry a failed `done-when` automatically (the agent's "fix" may pass spuriously);
- mutate a deliverable tick that was set by a previous agent;
- delete or rewrite history of the current Phase branch;
- force-push the state file;
- skip the self-review checklist before emitting a session summary.

## 3. Reading order on bootstrap

1. `ORCHESTRATION.md` §1 of this skill.
2. Sibling planning standard §10 + §11 + §11a + §11b + §12.
3. Sibling `coding-standards-testing.md` §1 (pinned tools) + §5 (required commands).
4. `01-specifications/spec-06-execution-plan.md` — lazily; only the current Phase's section is needed for §11 step 4 onward.
5. Any `01-specifications/spec-02[a-z]-*.md` sidecar cited by the current Phase's `spec-anchors:` — read the cited sections in full. Sidecar constraints are inherited literally; the agent does not paraphrase or re-derive them.
6. Bundled standards cited by the current Phase's layer per `.github/skills/spec-creation/STANDARDS-PROTOCOL.md` (including the `spec-02x` row when a sidecar is in play).

## 4. What this skill does NOT decide

- It does NOT pick test frameworks (pinned in `coding-standards-testing.md`).
- It does NOT pick stack components (pinned in `STACK-DEFAULTS.md` of the sibling skill).
- It does NOT pick architecture (`design-standards-clean-architecture.md` + `design-standards-domain-model.md` + `design-standards-problem-domain-implementation.md`).
- It does NOT decide ordering (planning standard §3).
- It does NOT decide `done-when` (planning standard §7 + the Phase block in spec-06).
- It does NOT decide whether to ship (the user's session-intent gate answer governs that).

It only **executes** what the plan and the bundled standards say.

## 5. Reporting contract

Every state change emits exactly one status line per SKILL.md "Reporting" section. The session summary block is emitted exactly once, at session end (DONE, BLOCKED, PAUSED, SPEC-DEFECT, STANDARDS-DEFECT, PLAN-DRIFT, DRY-RUN, STOPPED). Before that summary, the self-review checklist in SKILL.md MUST be walked silently; if any check fails, the planned summary is replaced by a `STANDARDS-DEFECT — self-review failed` halt line.

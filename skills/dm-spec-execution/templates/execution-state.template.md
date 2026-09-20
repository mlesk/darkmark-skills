# Execution State File Template

> Canonical schema lives in `.github/skills/dm-spec-creation/standards/planning-standards-inside-out-phases.md` §10. This template is the **initial** file content the agent writes during planning standard §11 step 0. Fill `<plan-sha>`, `<sidecar-shas>`, and the per-Phase blocks from `spec-06-execution-plan.md`.

```markdown
# Execution State

<!--
generated:    <ISO-8601 UTC>
last-updated: <ISO-8601 UTC>
plan-sha:     <git hash-object 01-specifications/spec-06-execution-plan.md>
sidecar-shas:
  spec-02a-<name>.md: <git hash-object output>
  spec-02b-<name>.md: <git hash-object output>
  # … one line per spec-02[a-z]-*.md referenced by spec-06 spec-anchors
-->

## P0 Preflight

- status: pending
- updated: <ISO-8601 UTC>

### Deliverables

- [ ] P0.1 <copied from spec-06 §4>
- [ ] P0.2 <copied from spec-06 §4>

## P1 <title from spec-06>

- status: pending
- updated: <ISO-8601 UTC>

### Deliverables

- [ ] P1.1 <copied from spec-06 §4>
- [ ] P1.2 <copied from spec-06 §4>

<!-- … one ## block per Phase or sub-phase in spec-06 §4, in plan order … -->
```

## Field rules (mirrored from planning standard §10)

- `status:` ∈ `{ pending, in-progress, done, blocked }`.
- `updated:` ISO-8601 UTC, refreshed on every status change.
- `commit:` required iff `status: done`; absent otherwise.
- `blocked-by:` required iff `status: blocked`; absent otherwise.
- `resume-hint:` optional; set by an agent before a clean context-budget halt; cleared by the resuming agent on next progress.
- Deliverables: `- [ ]` or `- [x]`. Tick only after the deliverable's targeted tests pass.

The file is written by `dm-spec-execution` only. Plan authors do not hand-edit it.

## Header field rules

- `plan-sha:` — captured at bootstrap. Validated on every read. Mismatch → `PLAN-DRIFT` halt.
- `sidecar-shas:` — captured at bootstrap for every sidecar referenced by spec-06 `spec-anchors:`. Validated on every read. Any mismatch → `PLAN-DRIFT — sidecar <file>` halt.

Both header fields are write-once at bootstrap. The runtime never refreshes them silently; drift is a human decision.

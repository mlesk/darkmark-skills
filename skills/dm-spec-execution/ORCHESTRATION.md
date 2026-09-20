# Orchestration Protocol — dm-spec-execution

The state machine lives in `.github/skills/dm-spec-creation/standards/planning-standards-inside-out-phases.md` §11. This file defines the **bootstrap** and the **error envelopes** around that loop. Do not duplicate the loop here.

## 1. Bootstrap (run every invocation)

1. **Verify the sibling skill exists.** The following paths MUST resolve:
   - `.github/skills/dm-spec-creation/standards/planning-standards-inside-out-phases.md`
   - `.github/skills/dm-spec-creation/standards/coding-standards-testing.md`
   - `.github/skills/dm-spec-creation/STANDARDS-PROTOCOL.md`

   If any are missing, halt: `sibling skill 'dm-spec-creation' is missing or corrupt; restore it before invoking dm-spec-execution.`

2. **Verify dm-spec-creation reported DONE.** Open `01-specifications/decisions.md` and confirm a `<!-- cross-spec-gate: PASS … -->` block exists at the top. If absent, halt: `cross-spec gate has not passed; run dm-spec-creation to completion before invoking dm-spec-execution.`

3. **Locate the plan.** Open `01-specifications/spec-06-execution-plan.md`. If missing or its gate-result block is not `PASS`, halt: `spec-06 has not passed its gate; run dm-spec-creation first.`

3a. **Verify referenced architecture sidecars.** Scan `spec-06-execution-plan.md` for every `spec-anchors:` value of the form `spec-02<letter>#<anchor-id>`. For each unique sidecar file referenced:

- the file `01-specifications/spec-02<letter>-*.md` MUST exist;
- it MUST end with `<!-- gate-result: PASS … reviewer=dm-spec-creation/spec-02x-sidecar-gate -->`;
- it MUST contain an inline `<a id="<anchor-id>"></a>` for every cited anchor.

  On any failure, halt: `SPEC-DEFECT — sidecar <file> missing, failed, or anchor <anchor-id> not present; run dm-spec-creation first.` Do not attempt to repair.

4. **Locate or initialize the state file.** If `01-specifications/execution-state.md` is missing, run planning standard §11 step 0: generate it from the plan with every Phase `pending` and every deliverable unticked, including the `plan-sha:` and `sidecar-shas:` header fields. Commit (`init: bootstrap execution-state.md from spec-06`) and push to `main` before doing anything else.

5. **Validate state file as untrusted input** (per `standards/execution-runtime-standards.md` §1):
   - Schema check (§10 fields).
   - `plan-sha:` matches current `git hash-object 01-specifications/spec-06-execution-plan.md` — else halt `PLAN-DRIFT`.
   - Every entry in `sidecar-shas:` matches the current `git hash-object` of the referenced sidecar — else halt `PLAN-DRIFT — sidecar <file>`.
   - Every `commit:` SHA resolves locally — else halt `STANDARDS-DEFECT — corrupted commit reference at P<id>`.

6. **Read the state file in full.** Identify:
   - any Phase with `status: in-progress` (a previous session was interrupted)
   - any Phase with `status: blocked` (human resolution required)
   - the lowest-numbered Phase with `status: pending` whose `depends-on` are all `done`

7. **Report state to the user.** Use this exact format:

   ```text
   [dm-spec-execution] bootstrap
   - plan: 01-specifications/spec-06-execution-plan.md (gate PASS)
   - sidecars referenced: <list of spec-02x file names, or "none">
   - state file: <created | found, last-updated <ts>>
   - in-progress: <P-id or none>
   - blocked:     <P-id: reason | none>
   - next ready:  <P-id or "all done">
   ```

8. **Run the session-intent gate** (see SKILL.md "Session intent gate"). Ask one question with a recommended answer, unless the invoking message already named the mode. Echo the chosen mode before proceeding.

9. **Decide the entry point** into planning standard §11:
   - If a Phase has `status: in-progress` AND a `resume-hint:` → enter at §11 step 5 (Implement) on that Phase, using the hint.
   - If a Phase has `status: in-progress` WITHOUT a `resume-hint:` → previous agent crashed. Re-read its spec-anchors and partially-ticked deliverables; resume at §11 step 6 from the first unticked deliverable.
   - If a Phase has `status: blocked` → halt with the blocker reason; do not attempt to override.
   - Otherwise → enter at §11 step 2 (Select).

   In **Dry-run** intent, do not enter §11. Emit `DRY-RUN — would run §11 step <N> on <P-id>` and the spec-anchors / standards that step would read, then exit.

## 2. Main loop

Run planning standard §11 verbatim. Do not deviate.

In **Run Next Phase Only** intent, exit after the next Phase reaches `done` or `blocked`.

In **Run Through Completion of Specific Phase** intent, loop until target phase is complete or a halt condition fires.

In **Resume only** intent, exit after the originally-`in-progress` Phase reaches `done` or `blocked`. If there was no in-progress Phase at bootstrap, exit immediately with `RESUME-ONLY — no in-progress Phase to resume`.

In **Run All Phases to DONE** intent, loop until a halt condition fires.

## 3. Halt conditions

The session ends cleanly when any of these occur. In every case, the state file is in a consistent state and pushed.

| Condition                         | State                                   | Reported as                                                 |
| --------------------------------- | --------------------------------------- | ----------------------------------------------------------- |
| All Phases `done`                 | unchanged                               | `DONE — all <N> Phases shipped`                             |
| Phase marked `blocked` (§11a)     | `blocked-by:` populated                 | `BLOCKED — <P-id>: <reason>`                                |
| Context-budget halt (§11b)        | `resume-hint:` populated, `in-progress` | `PAUSED — <P-id> at hint: <hint>`                           |
| Human-gate required               | `blocked-by: human-decision: <q>`       | `HUMAN-GATE — <P-id>: <question>`                           |
| Spec defect found                 | `blocked-by: spec-defect-...`           | `SPEC-DEFECT — <P-id>: <issue>` (run dm-spec-creation)         |
| Sidecar defect found              | `blocked-by: spec-defect-sidecar-...`   | `SPEC-DEFECT — sidecar <file>: <issue>` (run dm-spec-creation) |
| Standards defect found            | `blocked-by: standards-defect-...`      | `STANDARDS-DEFECT — <issue>`                                |
| Plan or sidecar SHA mismatch      | unchanged                               | `PLAN-DRIFT — <file>: expected <old> got <new>`             |
| One-Phase / Resume-only fulfilled | unchanged                               | `STOPPED — intent satisfied`                                |
| Dry-run                           | unchanged                               | `DRY-RUN — would run §11 step <N> on <P-id>`                |

## 4. Error envelopes

Any uncaught exception during deliverable work or `done-when` execution falls through to planning standard §11a. The state machine never crashes loudly — it always lands in a consistent halted state. The self-review checklist in SKILL.md runs before the session summary in every halt path.

## 5. Hard rules (mirrored from SKILL.md)

- `execution-state.md` is authoritative — never infer progress from git.
- No speculative deliverable ticks.
- No silent failures — every halt pushes the branch + state file.
- No spec edits. No sidecar edits. No standards edits. Halt and report instead.
- Never re-run `dm-spec-creation` from inside this skill.
- Never auto-retry a failed `done-when`.
- Never force-push the state file or rewrite Phase-branch history.

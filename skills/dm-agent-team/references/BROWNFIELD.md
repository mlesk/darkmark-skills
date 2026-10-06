# Brownfield mode

Read this only when `state.md` says `kind: brownfield`. The Lead lists it as an input on every handoff in a brownfield run, so every agent follows it. Where this file and an agent file disagree, this file wins for brownfield runs (PROTOCOL.md still wins over both).

A brownfield run **changes an existing system**. It follows the same stages, gates, reviews, and build loop as a greenfield run. What changes is what the team starts from (the existing code and its behaviour) and what it must not break.

## Starting a brownfield run

- A run is brownfield in two cases:
  - **After a finished run.** Once any run in `.agent-team/runs/` has ended `done`, every later run is brownfield automatically: the team is changing the system it built, and `.agent-team/system/` describes it.
  - **On a codebase the team didn't build.** The human invokes `/dm-agent-team --brownfield <description of the change>`. Without the flag (and with no finished run), a folder that already holds source code is a G0 stop asking the human to restart with `--brownfield`.
- The Lead records `kind: brownfield`, `baseline-commit:`, and `run-branch:` in `state.md`. Resumes and `scripts/run.sh` read the kind from there; the flag is not needed again.

### Boot, in this order

These run **before** the new run folder is created, so it can't make the tree look dirty:

1. **Clean tree.** `git status --porcelain` must be empty. If not, stop: the human commits or stashes first. The team never stashes or discards the human's work. (Earlier runs' `.agent-team/` history is committed, so it doesn't count as dirty.)
2. **Run branch.** Create `agent-team/<run>` (for example `agent-team/V002-csv-export`) from the current `HEAD` and switch the project root to it (`git switch -c`). That `HEAD` is the `baseline-commit`.
3. Then continue with the normal boot from *Ignore only what git can't hold* onward, and record `kind:`, `baseline-commit:`, and `run-branch:` in `state.md`. The run's `.agent-team/` commits go on the run branch.

**On every resume**, and before planning a wave or integrating, check that `git branch --show-current` equals `run-branch:`. If it doesn't (the human checked out another branch between sessions), stop with `status: blocked`, `halt: wrong-branch`, and ask the human to switch back. The team never merges into any other branch.

## Clean room in brownfield

The existing repository is **human-owned input**, not reference material: every agent may read it. Reference material listed in the brief (other systems, competitor products, external code) is still the dirty room, readable only by the analyst. Anything taken from the existing code cites it by `path:line` (or by the test that shows it); that citation counts as a source in every trace and hallucination check, the same way a `D-###` does.

**Deleting existing files** stays a hard stop, with one exception: a file that existed at `baseline-commit` may be deleted when a phase lists it under `deletes:` and each entry cites a `D-###` with `source: human`. An auto-approved G4 never counts, even in yolo.

## S0.5 Discovery and gate G0.5 (baseline)

Discovery records what exists before anything is designed. It runs after G0 and before S1.

**Two starting points:**

- **After a finished run** (`.agent-team/system/` exists): start from the living specs. Find the commit that last changed `system/` (`git log -1 --format=%H -- .agent-team/system`) and list the code changed since then (`git diff --name-only <that commit> <baseline-commit>`, excluding `.agent-team/`). The baseline 01 §0 and 03 are the relevant parts of `system/`, re-tagged `existing`, checked only against the changed files. If nothing changed, discovery confirms the living specs and goes straight to the regression floor (step 5). Changes made outside the team since the last run are recorded as `existing` and listed at G0.5.
- **On a codebase the team didn't build** (no `system/`): recover everything from the code, as below.

**Inputs** for both discover dispatches: the brief (including the parts of the system it names), `decisions.md`, this file, any existing specs or docs the brief lists ([ADOPTION.md](./ADOPTION.md)), and the repository itself.

1. **Architect, `discover` mode** → `specs/03-architecture.md`, every item tagged `existing` and citing its source files:
   - §3 the system as it is: components, boundaries, and data stores
   - §4–§6 the components, data, and contracts the change is likely to touch (not the whole system)
   - §7 the conventions the code actually follows (errors, logging, configuration, …), even where they're imperfect
   - §8 the folder layout and naming conventions in use
   - §9 the coding standards in use, from config files and the code
   - §10 the existing test command, test levels, and a `test files:` line of globs matching every test and test-support file (for example `tests/*, */conftest.py, **/*_test.go`), and whether the suite is **hermetic** (can it run twice in parallel from two worktrees without sharing ports, files, or databases?)
   - §10.1 the formatters, linters, type checkers, and CI checks already configured, with their commands
   - §11 the dependencies already in use (the starting allowlist) and the `list command:`
2. **Reviewer, `spec-review`** of the baseline 03 (the brownfield discover checks replace the greenfield 03 checks).
3. **Analyst, `discover` mode** → `specs/01-requirements.md` §0 *Baseline behaviour*: the current behaviour of the area the brief's change touches, as `REQ`s tagged `existing`, with acceptance criteria describing what the code does today, each citing `path:line` or the test that shows it. Unknown or surprising behaviour becomes a `Q`, not a guess. Its inputs add the baseline 03.
4. **Reviewer, `spec-review`** of baseline 01 §0.
5. **Lead: the baseline.** Using PROTOCOL §Command output, on `baseline-commit`:
   - run the existing test command from 03 §10;
   - run each existing §10.1 check and save its full output;
   - write `baseline.md`:

   ```markdown
   # Baseline
   commit: <sha> · test command: `<cmd>` · exit: <n> · log: logs/baseline-tests.log
   passing: <count> · failing: <count> · skipped: <count> · coverage: <% or not measured>
   hermetic: yes | no | unknown — <evidence>
   ## Failing at baseline
   | Test | Failure (one line) | Decision |
   ## Quality baseline
   | Check | Command | Log | Findings | Files with findings (path: count) |
   ```

6. **G0.5 Baseline gate** (stop in stepwise and checkpoint; in yolo, auto on reviewer PASS only if nothing below needs deciding). Present the baseline 03 summary, 01 §0, and `baseline.md`. The human decides, each as a `D-###` with `source: human`:
   - every test **failing at baseline**: **fix** it (a fix phase in the plan) or **quarantine** it. A quarantine `D-###` has `affects: 03 §10 known failures`.
   - every existing **quality check with findings**: keep it **ratcheted** (it blocks new and changed files only), fix the findings (phases in the plan), or drop it as a gate.
   - a **non-hermetic suite**: make it hermetic first (a phase), or run with `max-parallel: 1`.

   If any of these needs deciding, G0.5 stops in every mode, including yolo. Record G0.5's Hash and `approved/` copy for `baseline.md`; 01 and 03 are re-recorded at G1 and G3.

**Done when:** G0.5 is approved and every baseline test failure, quality finding set, and hermeticity problem has its `D-###`. (Verify doesn't exist yet: it is defined at S3–S4 and made green by `PHASE-001`.)

## Change-scoped specs (S1–S4)

Every item in 01, 02, and 03 carries a change tag (PROTOCOL §IDs and traceability): `existing`, `new`, `changed`, or `removed`. Only `new`, `changed`, and `removed` items are work. `existing` items are context the change must not break, and they are **exempt** from phase ownership, coverage, the acceptance trace matrix, and the Requirements ⇄ UX alignment checks.

- **01:** §0 holds the baseline behaviour. The change's `REQ`s describe what is added or different, and each `changed` or `removed` `REQ` names the `existing` `REQ` it replaces. S1's handoff includes the baseline 03 for context.
- **02:** existing screens and design language are the baseline. Skip the `ux-language` dispatch and the design-language questions unless the brief asks for a redesign: reuse the existing tokens and patterns, recorded in §1–§2 as `existing`. Design only `new` and `changed` screens and states; list `existing` screens the change affects indirectly.
- **03:** design **within** the existing architecture. §2.1–§2.2 read `Chosen: existing (baseline)` and the style-and-stack question batch is skipped, unless the human asked at G0 to re-architect. New components, contracts, and data follow the baseline §7–§9 conventions; deviating from one needs an ADR, as does adding a dependency, a layer, or a pattern the code doesn't already use. §10 lists the quarantined tests under `known failures:` (from the G0.5 decisions) and says how the verify command excludes them: by deselecting them in the test command (for example `--deselect`, `-k "not …"`, an exclude list), **never** by adding skip markers to the tests.
- **Quality gate (§10.1) ratchets.** Each ratcheted check's command runs only on files changed since the baseline, for example `ruff check $(git diff --name-only --diff-filter=ACMR <baseline-commit> -- '*.py')`, and §10.1 shows that exact command. A new or stricter check is always ratcheted. Findings in untouched files are recorded in `baseline.md` and are not blockers; new and changed files must be clean.
- **Hermetic verify:** if the suite is not hermetic and G0.5 chose `max-parallel: 1`, the hermetic requirement on verify is waived for this run.
- **Data changes:** any change to a persisted `existing` `DATA` entity needs a migration plan in §5: forward migration, compatibility with existing data, and a rollback.

## The build plan in brownfield (S4)

The inside-out layer order still applies to the change. Brownfield adds:

- **`PHASE-001` is the baseline harness**, not a new project skeleton: make the 04 `verify:` command run the existing suite minus the `known failures:` (by deselection) and the §10.1 checks with the ratchet, make the §11 `list command:` work, and add any characterisation-test support. Nothing else. **Done when** verify is green on the run branch. This is the regression floor.
- **Characterisation phases come first.** Before any phase changes `existing` behaviour, a phase in layer `characterisation` pins that behaviour with tests that **pass** on the unchanged code (they are not written red first). They are named after the `existing` item they pin (`REQ_007_2_…`, `API_003_…`). The phase that then changes the behaviour updates those tests only where a `changed` `REQ` or a `D-###` says so.
- **Behaviour changes are declared.** A phase that edits or deletes a file matching 03 §10 `test files:` that existed at `baseline-commit` lists it in `touches:` and names each allowing decision on a `behaviour-changes: D-###, …` line. A fix phase records the same in its Build row's Notes.
- **Deletions are declared.** A phase that deletes any other baseline file lists it under `deletes: <path> (D-###), …`, each with a human-sourced decision.

## No-regression gate (S5–S6)

- Verify runs the whole existing suite (minus quarantined tests) plus the change's tests. Any test that passed at baseline and now fails is a **blocker** in precheck and review, unless a `behaviour-changes:` `D-###` covers it.
- The Lead runs `scripts/precheck.sh` with `--brownfield --baseline <baseline-commit>` (and, for a fix phase, `--behaviour-changes "<D-### …>"` from its Build row). It adds check 6: no baseline test file (per 03 §10 `test files:`) was edited or deleted, and no baseline file was deleted, without the declarations above, and every cited `D-###` exists in `decisions.md`. If the script can't run, the reviewer's precheck applies the same check.
- **Acceptance** re-runs the full existing suite on a clean checkout and compares with `baseline.md`: every test that passed at baseline still passes, or its change or removal is covered by a `behaviour-changes:` `D-###`; every baseline failure is fixed or still quarantined. It re-runs the checks that existed at baseline over the whole repository and compares per file: findings in files the change didn't touch must not have grown.
- **G6** presents the run branch, the diff summary against `baseline-commit`, the behaviour changes and deletions with their decisions, and the regression comparison. Merging the run branch is the human's action.

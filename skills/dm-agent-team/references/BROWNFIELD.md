# Brownfield mode

Read this only when `state.md` says `kind: brownfield`. The Lead lists it as an input on every handoff in a brownfield run, so every agent follows it.

A brownfield run **changes an existing system**. It follows the same stages, gates, reviews, and build loop as a greenfield run. What changes is what the team starts from (the existing code and its behaviour) and what it must not break.

## Starting a brownfield run

- The human invokes `/dm-agent-team --brownfield <description of the change>`. The flag is required; the Lead never switches into brownfield on its own. Without it, a folder that already holds source code is a G0 stop asking the human to restart with `--brownfield`.
- The Lead records `kind: brownfield`, `baseline-commit:`, and `run-branch:` in `state.md`. Resumes and `scripts/run.sh` read the kind from there; the flag is not needed again.

### Boot additions

1. **Clean tree.** `git status` must be clean. If not, stop: the human commits or stashes first. The team never stashes or discards the human's work.
2. **Run branch.** Create `agent-team/<project>` from the current `HEAD` and switch the project root to it (`git switch -c`). Record it as `run-branch:`, with that commit as `baseline-commit:`. All phase worktrees branch from the run branch, and integration merges into it. The human's branch is never touched; they merge the run branch through their usual process after G6.
3. **Ignore the workspace** as in greenfield: add `.agent-team/` to `.gitignore` in a commit on the run branch.

## Clean room in brownfield

The existing repository is **human-owned input**, not reference material: every agent may read it. Reference material listed in the brief (other systems, competitor products, external code) is still the dirty room, readable only by the analyst. Anything taken from the existing code cites it by path and line as its source, the same way a spec item cites a `D-###`.

## S0.5 Discovery and gate G0.5 (baseline)

Discovery records what exists before anything is designed. It runs after G0 and before S1.

1. **Architect, `discover` mode** → `specs/03-architecture.md`, every item tagged `existing`:
   - §3 the system as it is: components, boundaries, and data stores, recovered from the code
   - §4–§6 the components, data, and contracts the change is likely to touch (not the whole system), each citing its source files
   - §7 the conventions the code actually follows (errors, logging, configuration, …), even where they're imperfect
   - §8 the folder layout and naming conventions in use
   - §9 the coding standards in use, from config files and the code
   - §10 the existing test command and test levels; §10.1 the formatters, linters, type checkers, and CI checks already configured, with their commands
   - §11 the dependencies already in use (they are the starting allowlist) and the `list command:`
2. **Reviewer, `spec-review`** of the baseline 03: does each claim match the code it cites?
3. **Analyst, `discover` mode** → `specs/01-requirements.md` §0 *Baseline behaviour*: the current behaviour of the area the brief's change touches, as `REQ`s tagged `existing`, with acceptance criteria describing what the code does today (cite file and line, or the test that shows it). Unknown or surprising behaviour becomes a `Q`, not a guess.
4. **Reviewer, `spec-review`** of baseline 01.
5. **Lead: regression floor.** Run the existing test command from 03 §10 on `baseline-commit`, per PROTOCOL §Command output, and write `baseline.md` in the workspace:

   ```markdown
   # Baseline
   commit: <sha> · test command: `<cmd>` · exit: <n> · log: logs/baseline-tests.log
   passing: <count> · failing: <count> · skipped: <count> · coverage: <% or not measured>
   ## Failing at baseline
   | Test | Failure (one line) | Decision |
   ```

   Run each existing §10.1 quality check the same way and record its finding count: that is the quality baseline.
6. **G0.5 Baseline gate** (stop in stepwise and checkpoint; auto on reviewer PASS in yolo, except as below). Present the baseline 03 summary, the baseline behaviour in 01 §0, and `baseline.md`. For every test failing at baseline, the human decides by `D-###`: **fix** it (a fix phase in the plan), or **quarantine** it (03 §10 `known failures:` lists it, and verify excludes it). A failing test can never be quarantined automatically, even in yolo: if any fail, G0.5 stops in every mode.

After G0.5, verify must be green on the baseline (with quarantined tests excluded). That is the regression floor.

## Change-scoped specs (S1–S4)

Every item in 01, 02, and 03 carries a change tag: `existing`, `new`, `changed`, or `removed`. Only `new`, `changed`, and `removed` items are work; `existing` items are context the work must not break.

- **01:** §0 holds the baseline behaviour. The change's `REQ`s describe what is added or different, and each `changed` or `removed` `REQ` names the `existing` `REQ` it replaces. The coverage table maps the brief to change `REQ`s.
- **02:** existing screens and design language are the baseline. Skip the design-language questions unless the brief asks for a redesign: reuse the existing tokens and patterns, recorded in §1–§2 as `existing`. Design only `new` and `changed` screens and states; list `existing` screens that the change affects indirectly.
- **03:** design **within** the existing architecture. Skip the style-and-stack evaluation (§2.1–§2.2 read `Chosen: existing (baseline)`) unless the human asked at G0 to re-architect. New components, contracts, and data follow the baseline §7–§9 conventions; deviating from one needs an ADR, as does adding a dependency, a layer, or a pattern the code doesn't already use.
- **Quality gate (§10.1) ratchets.** Keep the existing checks. A new check, or a stricter rule, applies to `new` and `changed` files only, not to untouched legacy files, so the change doesn't inherit a backlog. Existing findings in untouched files are recorded in the quality baseline and are not blockers. New and changed files must be clean.
- **Data changes:** any change to a persisted `existing` `DATA` entity needs a migration plan in §5: forward migration, compatibility with existing data, and a rollback.

## The build plan in brownfield (S4)

The inside-out layer order still applies to the change. Two things are added:

- **`PHASE-001` is the baseline harness**, not a new project skeleton: make verify run the existing tests (minus quarantined ones) and the §10.1 checks with the ratchet, make the §11 `list command:` work, add any characterisation-test support, and fix nothing else. Verify must be green at the end of it.
- **Characterisation phases come first.** Before any phase changes `existing` behaviour, a phase in layer `characterisation` pins that behaviour with tests that pass on the unchanged code. They are named after the `existing` item they pin (`REQ_007_2_…`, `API_003_…`). The phase that then changes the behaviour updates those tests only for the parts a `changed` `REQ` or a `D-###` says should change.
- **Behaviour changes are declared.** A phase that changes, deletes, or rewrites a test that existed at `baseline-commit` lists those test files in `touches:` and names the decision in a `behaviour-changes: D-###, …` line. Deleting any file that existed at baseline is also listed in `touches:` and approved at G4 with the plan.

## No-regression gate (S5–S6)

- Verify runs the whole existing suite (minus quarantined tests) plus the change's tests. Any test that passed at baseline and now fails is a **blocker** in precheck and review, unless the phase's `behaviour-changes:` cites a `D-###` accepting that behaviour change.
- The Lead runs `scripts/precheck.sh` with `--brownfield --baseline <baseline-commit>`. It adds check 6: no file that is a test at `baseline-commit` was modified or deleted unless the phase entry has a `behaviour-changes:` line and lists the file in `touches:`.
- Acceptance re-runs the full existing suite on a clean checkout and compares it with `baseline.md`: the passing count may only go up; every baseline failure is fixed or still quarantined by its `D-###`. It also re-runs the §10.1 checks: findings in untouched files must not have grown.
- **G6** presents the run branch, the diff summary against `baseline-commit`, the behaviour changes and their decisions, and the regression comparison. Merging the run branch is the human's action.

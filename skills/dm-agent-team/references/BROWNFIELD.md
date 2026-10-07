# Brownfield mode

Read this only when `state.md` says `kind: brownfield`. The Lead lists it on every handoff of a brownfield run, and where it adds to an agent file, it wins. A brownfield run **changes an existing system**: same stages, gates, and build loop, but it starts from the code as it is and must not break it.

A run is brownfield when an earlier run has finished (`.agent-team/system/` describes the system) or when invoked with `/dm-agent-team --brownfield <change>` on a codebase the team didn't build.

## Boot

After the run is named and before its folder is created:

1. **Clean tree.** `git status --porcelain` must be empty, or stop: the human commits or stashes. Never stash or discard the human's work.
2. **Run branch.** `git switch -c agent-team/<run>` from the current `HEAD`, which is the `baseline-commit`. Record `kind:`, `baseline-commit:`, and `run-branch:` in `state.md`. All the run's commits go on this branch; the human merges it when the run is done.

On every resume and before each wave, `git branch --show-current` must equal `run-branch:`, or stop (`blocked`, `halt: wrong-branch`).

## Rules that change

- **The existing code is input**, readable by every agent and cited as `path:line` (or the test that shows it). A citation counts as a source in every review. External reference material is still analyst-only.
- **Change tags.** Every item in the run's 01, 02, and 03 is `existing`, `new`, `changed`, or `removed`. A `changed` item keeps the ID of the item it changes and restates it in full; the baseline version stays where it was recorded, marked `→ changed`. A `removed` item keeps its ID and cites the decision. A different item taking an old one's place is `removed` plus `new`. Only `new`, `changed`, and `removed` items are work; `existing` items are context the change must not break, exempt from phase ownership and coverage.
- **Deleting a baseline file** is allowed only under a phase's `deletes:`, each entry citing a `D-###` with `source: human`. An auto-approved plan never counts.

## Discovery and the baseline gate

Discovery (S0.5) records what exists before anything is designed. It runs after the brief gate.

**Scope.** The Lead first writes `discovery-scope.md`:

```markdown
# Discovery scope
system-commit: <git log -1 --format=%H -- .agent-team/system, or –>
system-coverage: full | partial: <areas> | none
changed since system-commit: <git diff --name-only <system-commit> <baseline-commit> -- . ':!.agent-team'>
```

After a finished run, discovery starts from `system/`: the baseline is the part of it the change touches, re-checked against the code only where a changed file implements it, plus any area the change touches that `system/` doesn't cover. On a codebase the team didn't build, it recovers the area the change touches from the code. An item taken unchanged from `system/` cites its ID there.

**Dispatches** (inputs: the brief, `decisions.md`, `discovery-scope.md`, the `system/` specs if any, existing docs the brief lists, this file, and the repository):

1. **Architect, `discover`** → `specs/03-architecture.md`, every item `existing` and cited: components and boundaries; the data and contracts the change will likely touch; the conventions, structure, and coding standards in use; the test command, a `test files:` line of globs matching every test and test-support file, and whether the suite is hermetic (can two copies run at once from two worktrees?); the quality tools already configured, with commands; the dependencies in use and a `list command:`. Describe, don't judge.
2. **Analyst, `discover`** → `specs/01-requirements.md` §0 *Baseline behaviour*: the current behaviour of the area the change touches, as `existing` `REQ`s whose criteria describe what the code does today, each cited. Surprises become `Q`s, not guesses.
3. **Reviewer, `spec-review`** of both: spot-check at least 5 claims against the code; an unsupported claim is a major. Nothing in a baseline spec proposes a change.
4. **The Lead records the baseline** on `baseline-commit`: run the test command and each existing quality check per PROTOCOL §Command output, and write `baseline.md`:

   ```markdown
   # Baseline
   commit: <sha> · test command: `<cmd>` · exit: <n> · log: logs/baseline-tests.log
   passing: <n> · failing: <n> · skipped: <n> · hermetic: yes | no | unknown — <evidence>
   ## Failing at baseline
   | Test | Failure (one line) | Decision |
   ## Quality baseline
   | Check | Command | Findings | Files with findings (path: count) |
   ```

5. **Baseline gate.** Present the baseline 03 and 01 §0 and `baseline.md`. The human decides, each as a `D-###` with `source: human`: for each test failing at baseline, **fix** it (a phase) or **quarantine** it; for each existing quality check with findings, **ratchet** it (new and changed files only), fix the findings, or drop it; for a non-hermetic suite, make it hermetic (a phase) or set `max-parallel: 1`. If any of these is needed, the gate stops in every mode.

## Designing the change

- **01** describes only the change, with change tags; 02 reuses the existing design language and designs only `new` and `changed` screens.
- **03** designs within the existing architecture: §1 reads `Chosen: existing (baseline)` unless the human asked to re-architect. A deviation from the baseline conventions, a new dependency, layer, or pattern needs an ADR. A change to persisted `existing` data needs a migration, compatibility with existing data, and a rollback in §4.
- **§10** lists `known failures:` (the quarantined tests) and excludes them from verify by deselection in the test command, never by skip markers.
- **§10.1 ratchets**: each ratcheted check runs only on files changed since the baseline, for example `ruff check $(git diff --name-only --diff-filter=ACMR <baseline-commit> -- '*.py' ':!.agent-team')`, and shows that exact command. New checks are always ratcheted.

## Planning the change

- **`PHASE-001` is the baseline harness:** verify runs the existing suite minus `known failures:`, plus the ratcheted checks, and the `list command:` works. Nothing else. Verify green on the run branch is the regression floor.
- **Characterisation first.** Before a phase changes `existing` behaviour, a `characterisation` phase pins it with tests that **pass** on the unchanged code, named after the item they pin.
- **Declared changes.** A phase that edits or deletes a baseline test (matching 03 §10 `test files:`) lists it in `touches:` and names the allowing decisions on `behaviour-changes: D-###, …`. A phase that deletes any other baseline file lists it under `deletes: <path> (D-###)`.

## No regression

- Any test that passed at baseline and now fails is a blocker unless a `behaviour-changes:` decision covers it. The Lead runs `precheck.sh` with `--brownfield --baseline <baseline-commit>`; it checks the declarations above and that every cited `D-###` exists.
- **Acceptance** re-runs the full existing suite on a clean tree and compares with `baseline.md`: every baseline pass still passes or its change is covered by a decision, and every baseline failure is fixed or still quarantined. It re-runs the baseline quality checks over the whole repository: findings in files the change didn't touch must not have grown.
- **The accept gate** shows the run branch, `git diff --stat <baseline-commit> -- . ':!.agent-team'`, the behaviour changes and deletions with their decisions, and the regression comparison. Merging the run branch is the human's action.

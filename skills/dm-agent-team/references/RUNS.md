# Runs

Only the Lead reads this file. A project is built over a sequence of **runs**, each in its own folder `.agent-team/runs/V<NNN>-<name>/` (a three-digit sequence number and a short kebab-case name). `.agent-team/active` names the run in progress, or says `none`. One run is active at a time. A run ends `done` (after the accept gate) or `abandoned`.

## New run

Start one when `active` is missing or says `none`. If it names a run that ended `done` or `abandoned`, write `none`, commit, and continue here. If it names a folder that doesn't exist on this branch, look for it on the run branches (step 1); if none explains it, stop (`blocked`, `halt: active-missing`).

**Old layout.** If `.agent-team/state.md` sits directly in the team root (an earlier version of this skill), stop and offer to migrate. On approval: remove its phase worktrees (`git worktree remove --force`, `git worktree prune`), delete their `at/` branches, and mark those phases `stale`; move everything except `models.md` and `worktrees/` into `runs/V001-<project>/`; add `run:` and `team-root:` to `state.md` and rewrite every absolute path under the old folder; write `active`; fix `.gitignore` (step 4); commit. Never re-dispatch a handoff written before the migration.

1. **Other branches.** A brownfield run commits on its own branch, so look there too: for each branch in `git branch --list 'agent-team/*'`, read `git show <branch>:.agent-team/active` and that run's status. Stop (`blocked`, `halt: wrong-branch`) if a run is active on another branch, or a `done` run's branch isn't merged into `HEAD` (`git merge-base --is-ancestor <branch> HEAD` fails). The human switches to it, merges it, or deletes it. Branches of abandoned runs are ignored.
2. **Kind and name.** If any run in `runs/` ended `done`, this run is brownfield. Otherwise it is greenfield unless invoked with `--brownfield`; without the flag, if the folder already holds source code, ask at the brief gate whether to restart with `--brownfield`. The name is the next number after the highest in `runs/` here and on every `agent-team/*` branch (`git ls-tree --name-only <branch> .agent-team/runs/`), plus a name drawn from the request, for example `V002-csv-export`.
3. **Git.** If the folder isn't a git repo, ask whether to `git init`. Without git, the run can produce specs, but the build is a `blocked` stop. Brownfield: run the boot steps in [BROWNFIELD.md](./BROWNFIELD.md) now (clean tree, run branch `agent-team/<run>`).
4. **`.gitignore`.** It must list `.agent-team/runs/*/worktrees/` and `.agent-team/runs/*/logs/`, and must not ignore `.agent-team/` itself. If it changed, or the repo has no commits yet, commit it as `chore: agent-team workspace`.
5. **Run folder.** Create `runs/<name>/` per [PROTOCOL.md §Workspace](../PROTOCOL.md#workspace), write the name to `active`, and fill `state.md`: `run:`, `workspace:`, `team-root:`, `kind:`, and `team-version:` (`git -C <skill dir> rev-parse --short HEAD`, or `unknown`).
6. **Routing.** Write `models.md` in the team root per [ROUTING.md](../ROUTING.md), or reuse it.
7. **Guardrails.** Read [host-guardrails.md](./host-guardrails.md). If the host config lacks its rules, add a question to the brief batch: install them (recommended) or not.

**Renaming** is allowed until the brief gate is approved: move the folder (`git mv` if committed), update `active`, `run:`, `workspace:`, and every path under it in `state.md`, and in brownfield rename the branch (`git branch -m`) and `run-branch:`.

## Consolidate

After the acceptance review passes, fold the run into `.agent-team/system/`, so the next run starts from the whole system as built.

1. Dispatch, in parallel, the owners of the run's specs in `consolidate` mode: analyst (01), designer (02, if the run has one or `system/02-ux.md` exists), architect (03). Inputs: the run's specs, `decisions.md`, and the current `system/` spec each owns (absent the first time). Outputs: `<team-root>/system/<spec>`.
2. Dispatch the reviewer (`spec-review`) once over the `system/` specs written, with the run's specs and the previous `system/` specs as inputs. Its file is `reviews/system-r<round>.md`. Route as any spec review.

**The consolidation rules** (each owner follows them for its spec):

- The `system/` spec describes the **whole current system**: start from the current `system/` spec, or an empty one.
- Add `existing` items that `system/` lacks or describes differently, add `new` items, replace `changed` items under the same ID, and strike `removed` ones as `~~REQ-007~~ removed in V002 per V002/D-014`. Drop the change tags.
- Qualify run-local IDs you copy (`D`, `CR`, `PHASE`, `Q`) with the run: `V002/D-014`. Never renumber a global ID.
- Leave out run-only content: question history, UX notes about the change process, option evaluations (keep only the chosen style and stack and the ADRs), and the build plan.
- The first line after the title is `coverage: full` after a greenfield run; after a `--brownfield` run, `coverage: partial: <areas recovered so far>`, widened by each later run.
- Change nothing else, and don't rewrite existing text. Return the IDs added, changed, and struck.

The accept gate approves the `system/` specs together with the run.

## Closing a run

After the retro: remove any leftover worktrees and `at/` branches of the run, set `stage: done` and `status: done`, write `none` to `active`, and commit `.agent-team/` as `agent-team(<run>): done`. In brownfield, the commit is on the run branch: tell the human to merge it (or delete it to discard the run) before the next run.

## Abandoning a run

At any stop the human may choose **Abandon run**. Log a `D-###`, set `status: abandoned`, remove the run's worktrees and `at/` branches, write `none` to `active`, and commit. The folder stays as history. Phases already merged stay in the code: list their merge commits so the human can decide. In greenfield they can revert them; in brownfield they can delete the run branch (dropping the run's folder with it) or merge it. Never revert merges or delete the run branch yourself. Whatever code remains, the next run's discovery records as `existing`.

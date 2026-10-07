# Exceptions

Only the Lead reads this file, and only when one of these situations happens.

## Drift

Approved specs must not change behind the team's back. At every gate approval, the Lead commits `.agent-team/` and writes that commit's sha in the gate's `Commit` column.

- **Check** at boot, before each wave, and before presenting a gate: `git diff --quiet <commit> -- <workspace>/<artifact>` for every artifact in an approved gate's Artifacts column (the baseline gate covers only `baseline.md`). Skip a spec while a CR is being applied to it.
- **Drift** (the diff isn't empty): a `blocked` stop in every mode, `halt: drift: <file> changed since the <gate> gate`. Show the changed hunks' headers and at most 10 lines from `git diff <commit> -- <file>`, written to a log. The human either **adopts** the edit, which you run as a CR (reviewed, and the affected phases go stale), or **reverts** it (`git checkout <commit> -- <file>`).
- After a CR or an adopted edit, the gate is approved again and records the new commit.

## Recover

On resume, before planning a wave:

1. In brownfield, the project root must be on `run-branch:`; otherwise stop (`blocked`, `halt: wrong-branch`).
2. If the project root has an unfinished merge (`git rev-parse -q --verify MERGE_HEAD`), run `git merge --abort` and integrate that phase again.
3. For each phase that is `in-progress` or `in-review`: if its latest handoff has a Return, route it. Otherwise re-dispatch: a builder rebuilds in a fresh worktree (`git worktree remove --force`, `git branch -D`, then step 5.1), and a precheck or review is simply re-run.

## Escalation

A phase escalates when it has one more non-PASS than its size allows, `test-red` persists after the deep retry, or it goes stale a second time (two phases keep colliding: the `touches:` are probably wrong). Per the mode table, stop, or mark it `escalated` and keep building the phases that don't depend on it. Spec stages and consolidation escalate after their REVISE rounds, always as a stop.

**Human override.** At an escalation stop the human may accept the work despite REVISE findings, giving a reason in words. Log a `D-###` with `kind: override`, the reason, and the finding IDs it waives. For a phase, commit and integrate it as a PASS and write `override D-###` in its Notes; for a gate, write `approved (override)`. An override is never automatic, and never covers a hard stop, a builder `blocked`, or a red verify. Acceptance lists every override.

## Stalled build

No phase is ready and not every phase is `done`: what remains is `escalated` or `blocked`, or waits on one. Stop in every mode (`blocked`, `halt: stalled`) and show the escalated phases with the phases waiting on each.

## Circuit breaker

Three escalations in a row (`consecutive-escalations`, reset by any PASS) stop the build in every mode. The plan is probably wrong: recommend sending it back to the architect.

## Blocked phases

When a builder's `blocked` cause is resolved (the human fixed the environment, or the CR was decided), remove its worktree and branch and mark it `stale`, so it rebuilds from the new `HEAD`. If the CR was rejected and the phase can't be built as specified, mark it `escalated`.

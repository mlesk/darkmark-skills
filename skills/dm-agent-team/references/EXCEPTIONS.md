# Exceptions

Only the Lead reads this file, and only when one of these situations happens.

## Drift

Gated artifacts change only through a `D-###` with `kind: change`. At every gate approval the Lead commits `.agent-team/` and writes that commit's sha in the gate's `Commit` column.

- **Check** at boot, before each milestone gate, and before acceptance: `git diff --quiet <commit> -- <workspace>/<artifact>` for every artifact in an approved gate's Artifacts column (the baseline gate covers only `baseline.md`), ignoring hunks a logged `kind: change` decision accounts for.
- **Drift** (an unaccounted edit, usually a hand edit by the human): a `blocked` stop in every mode, `halt: drift: <file> changed since the <gate> gate`. Show the changed hunks' headers and at most 10 lines, written to a log. The human either **adopts** the edit (log it as a `kind: change` decision; phases tracing to the changed IDs go `stale`; acceptance re-checks it) or **reverts** it (`git checkout <commit> -- <file>`).

## Recover

On resume, before building:

1. In brownfield, the project root must be on `run-branch:`; otherwise stop (`blocked`, `halt: wrong-branch`).
2. If the project root has an unfinished merge (`git rev-parse -q --verify MERGE_HEAD`), `git merge --abort` and integrate that lane again (PARALLEL.md step 3).
3. A phase `in-progress` or `in-review` was interrupted. With one builder in the project root, discard the partial work back to the last phase commit (`git reset -q && git checkout -- . && git clean -fd -- . ':!.agent-team'`, after checking the tree holds nothing but that phase's files) and start a fresh builder on the phase. In a lane, remove the worktree and branch and open a new lane. An interrupted precheck or review is simply re-run.

## Escalation

A phase escalates when it has one more non-PASS than its size allows, `test-red` persists after the `high`-effort resume, or (lanes) it goes stale a second time. Per the mode table, stop, or mark it `escalated` and keep building the phases that don't depend on it. The spec stage escalates after its REVISE rounds, always as a stop.

**Human override.** At an escalation stop the human may accept the work despite REVISE findings, giving a reason in words. Log a `D-###` with `kind: override`, the reason, and the finding IDs it waives. For a phase, commit it as a PASS and write `override D-###` in its Notes; for a gate, write `approved (override)`. An override is never automatic, and never covers a hard stop, a builder `blocked`, or a red verify. Acceptance lists every override.

## Stalled build

No phase is ready and not every phase is `done`: what remains is `escalated` or `blocked`, or waits on one. Stop in every mode (`blocked`, `halt: stalled`) and show the escalated phases with the phases waiting on each.

## Circuit breaker

Three escalations in a row (`consecutive-escalations`, reset by any PASS) stop the build in every mode. The plan is probably wrong: recommend revising 03 §13 at a spec change.

## Blocked phases

When a builder's `blocked` cause is resolved (the human fixed the environment, or the spec change is made), resume the builder on the phase from the current `HEAD` (a lane first discards its partial work: `git reset -q && git checkout -- . && git clean -fd` in the worktree). If a scope change was refused and the phase can't be built as specified, mark it `escalated`.

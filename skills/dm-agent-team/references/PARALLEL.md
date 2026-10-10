# Parallel lanes

Read this only when `max-parallel` is above 1 (large runs whose plan has independent phases). Below that, one builder works in the project root and none of this applies.

A **lane** is one persistent builder with its own git worktree. Lanes run at most `max-parallel` at a time and persist across waves, so each keeps its context.

1. **Plan a wave.** A phase is ready when it is `pending` or `stale` and every phase in `depends-on:` is `done`. Pick ready phases, in plan order, whose `touches:` don't overlap each other or a hotspot another in-flight phase owns. A wave of one is normal.
2. **Open a lane** for a phase that has none: `git worktree add <workspace>/worktrees/lane-<n> -b at/lane-<n>` from the current `HEAD`; that `HEAD` is the phase's `base:`. Dispatch the lane's builder with the worktree as `workdir:`. Stagger dispatches by a few seconds, so the later ones read the cache the first one wrote instead of all writing it.
3. **Check** each `done` with the precheck in the lane's worktree (SKILL.md step 4.2), then **integrate** passed phases one at a time in plan order, in the project root: `git merge --no-ff --no-commit at/lane-<n>`, run verify (and `verify-full` if 03 names one), and commit only if green. A conflict or a red verify: `git merge --abort`, mark the phase `stale` with the reason (a second stale is an escalation: two phases keep colliding, so the `touches:` are probably wrong).
4. **Continue the lane:** after its phase is integrated, `git -C <worktree> merge <project HEAD>` (fast-forward or merge) so the lane sees the integrated tree, then **resume** its builder with the next ready phase and the new `base:`. A stale phase is rebuilt by its lane from the new base.
5. **Close lanes** at a milestone gate, at a session break, and at the end of the build: `git worktree remove <path>` and `git branch -d at/lane-<n>` (`--force` and `-D` for an abandoned one). A new session opens fresh lanes.

The builder's rules don't change: it never commits, never reads team files through the worktree's stale `.agent-team/`, and its verify must stay fast. The Lead's `state.md` Build table records each phase's lane and base.

---
name: dm-sweep
description: Run the nightly maintenance lane for one project or all configured projects. Performs deterministic health checks (git state, tests, TODOs, doc drift, dependency audit, committed secrets, large files, agent-run status), writes a digest capped at five decisions, and leaves code untouched. Use when the user asks for a morning brief, "sweep", "nightly", "what needs attention", "what happened overnight", or wants work to continue while they sleep. Do NOT use to fix what it finds, to review a diff, or to replace the test suite.
---

# Sweep

The maintenance lane. It observes and reports; it never edits. The output is one file a human can read in two minutes and act on with at most five decisions.

**Why it exists:** a build lane is idle at every human gate. A sweep lane turns that idle time into a morning list, without giving an agent permission to change code unattended.

## Run

```bash
# One project, full checks
scripts/sweep.sh --project /path/to/repo

# All configured projects, one digest
scripts/sweep-all.sh

# Fast check while you work (no tests, no audit)
scripts/sweep.sh --project . --dry-run
```

Config: `~/.config/dm-sweep/projects`, one absolute path per line, `#` for comments.
Digest: `~/.local/share/dm-sweep/latest.md` (dated copy alongside).
Per-project detail: `<project>/.agent/inbox/YYYY-MM-DD.md`.

Each run prints one machine line: `SWEEP <GREEN|AMBER|RED> <decisions> <file>`.
Exit: `0` green/amber, `2` red, `3` usage or config. A red sweep is a signal, not a failure of the lane.

## What it checks

| Check | Signal | Red when |
|---|---|---|
| git | branch, dirty files, unpushed commits, last commit age | never (amber only) |
| tests | detected `npm test` / `pytest` / `cargo test` / `go test` | non-zero exit |
| todos | tracked `TODO/FIXME/HACK/XXX` | >25 (amber) |
| docs | README age vs last commit | >30 days behind (amber) |
| deps | `npm audit` critical/high/moderate | critical or high >0 (amber) |
| secrets | key patterns and tracked `.env` | any hit |
| size | tracked files over 2MB | amber |
| agent runs | `.agent-team/runs/*/state.md` stage/status/next-action | awaiting-human or blocked (amber) |
| rtk | token savings, when installed | never |

Deliberately not checked: code quality, architecture, whether the tests are meaningful, performance, live URLs. Those belong to review and QA, not a nightly script.

## The digest

`latest.md` has three parts:

1. a project table with health and decision count;
2. the decisions, grouped by project, already capped at five per project;
3. links to each project's full detail file.

The five-decision cap is the point. If a project produces more than five, the sweep picks by priority (secrets/tests/agent-blocked first) and the rest stay in the detail file. Do not raise the cap; split the project instead.

## Acting on it

Route each decision; do not fix it in the sweep session.

| Finding | Route |
|---|---|
| failing tests | `dm-debug` (reproduce first), then a fix |
| committed secret | `gstack-cso`; rotate before removing |
| dependency advisory | a small `dm-agent-team` brownfield change, or a direct bump with a test |
| agent run awaiting human | answer its gate in an interactive session; do not auto-approve |
| doc drift, TODOs, size | batch into one housekeeping change, never urgent |
| red for three days | escalate: the lane is telling you the project is stuck |

## Scheduling

Installed as a launchd job at `~/Library/LaunchAgents/dev.darkmark.dm-sweep.plist`, daily at 02:00.

```bash
scripts/install-scheduler.sh                 # install or update, default 02:00
scripts/install-scheduler.sh --hour 3        # change the time
scripts/install-scheduler.sh --uninstall
launchctl kickstart -k gui/$(id -u)/dev.darkmark.dm-sweep   # run now
```

The installer copies the runner to `~/.local/share/dm-sweep/bin/` because launchd cannot execute scripts from an external volume under macOS TCC. If the projects themselves live on an external volume and the digest shows `MISSING`, grant Full Disk Access to `/bin/bash` in System Settings → Privacy & Security.

Logs: `~/Library/Logs/dm-sweep.log`. The job runs under `caffeinate` so a sleeping laptop finishes the checks it started.

## Anti-patterns

- **Letting the sweep write code.** It reports; the build lane changes.
- **Per-item notifications.** One digest, twice a day.
- **Running the full suite on a busy machine.** Use `--dry-run` while working; the nightly run has the machine to itself.
- **Treating amber as failure.** Amber is a queue, not an alarm.
- **Adding a check with no owner.** If nobody acts on a signal, delete the check.

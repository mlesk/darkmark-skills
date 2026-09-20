# darkmark-skills

A set of useful skills that I use day to day.

These skills are designed to be small, easy to adapt, and composable. They work with any AI coding agent — Claude Code, Codex, GitHub Copilot, and others. Hack around with them. Make them your own. Enjoy.

Inspired by Matt Pocock's [skills](https://github.com/mattpocock/skills)

All user-invocable skills use the `dm-` prefix to avoid conflicts with other plugins and to show they are part of one set. For example, the `loopify` skill is `dm-loopify` in the agent. The `spec-*` sub-skills bundled inside `dm-spec-creation` are agent-only (`user-invocable: false`) and are not linked as standalone skills.

## Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/mlesk/skills.git ~/darkmark-skills

# 2. Link the skills into the central agent skills directory
cd ~/darkmark-skills
./scripts/link-skills.sh
```

That's it. Your skills are now available as slash commands in every agent that reads `~/.agents/skills/`.

**Preview what will happen without making changes:**

```bash
./scripts/link-skills.sh --dry-run
```

**Overwrite existing skill links:**

```bash
./scripts/link-skills.sh --force
```

**Remove links pointing into this repo:**

```bash
./scripts/unlink-skills.sh
```

## Registration

All skills are registered in one central directory: `~/.agents/skills/`. Every supported agent (Claude Code, Codex, GitHub Copilot, and others) reads from there.

Each skill is symlinked into that directory, so pulling the repo updates the skills everywhere automatically.

## Available Skills

- [`dm-decide`](skills/dm-decide/SKILL.md) - Structured decision-making process. Grills the decision across seven mental models, builds a weighted rubric, scores the options, iterates to refine guidance, and delivers the options, the process used, and a final recommended decision.
- [`dm-loopify`](skills/dm-loopify/SKILL.md) - Generalized rubric optimization loop for a goal, single artifact, related artifact set, or codebase. Clarifies the goal, builds the rubric, scores the baseline, and iterates until it reaches a target score or plateaus.
- [`dm-pocockify`](skills/dm-pocockify/SKILL.md) - Purpose-first workflow for creating, reviewing, or improving agent skills. Inspired by Matt Pocock's prompt engineering approach. Four modes: create from scratch, pocockify existing, review only, or update in place.
- [`dm-write`](skills/dm-write/SKILL.md) - Improve any non-fiction prose using Williams' Style: Lessons in Clarity and Grace. Diagnoses against ten rules, then delivers a revised version with scorecard and change log.
- [`dm-spec-creation`](skills/dm-spec-creation/SKILL.md) - Gate-driven specification workflow for C# / ASP.NET Core / .NET Aspire / EF Core + TypeScript / React (Vite + shadcn), Clean Architecture, and inside-out phased planning. Bundles standards, templates, gates, and orchestration docs.
  - [`spec-00-prd`](skills/dm-spec-creation/specs/spec-00-prd/SKILL.md) (agent-only)
  - [`spec-01-domain-model`](skills/dm-spec-creation/specs/spec-01-domain-model/SKILL.md) (agent-only)
  - [`spec-02-architecture`](skills/dm-spec-creation/specs/spec-02-architecture/SKILL.md) (agent-only)
  - [`spec-03-implementation-guidance`](skills/dm-spec-creation/specs/spec-03-implementation-guidance/SKILL.md) (agent-only)
  - [`spec-04-user-interface`](skills/dm-spec-creation/specs/spec-04-user-interface/SKILL.md) (agent-only)
  - [`spec-05-app-use-cases`](skills/dm-spec-creation/specs/spec-05-app-use-cases/SKILL.md) (agent-only)
  - [`spec-06-execution-plan`](skills/dm-spec-creation/specs/spec-06-execution-plan/SKILL.md) (agent-only)
- [`dm-spec-execution`](skills/dm-spec-execution/SKILL.md) - Autonomous implementation loop that executes the Phase state machine from `spec-06-execution-plan.md`, tracking progress in `execution-state.md`.

## How It Works

The `scripts/link-skills.sh` script finds every user-invocable `SKILL.md` in the repo (skipping `deprecated/` and the agent-only sub-skills under `skills/dm-spec-creation/specs/`, which carry `user-invocable: false`) and creates a symlink in `~/.agents/skills/`. For example:

```
~/.agents/skills/dm-loopify → ~/darkmark-skills/skills/dm-loopify
~/.agents/skills/dm-spec-creation → ~/darkmark-skills/skills/dm-spec-creation
```

Because these are symlinks, running `git pull` in the repo updates every agent's skills at once. No reinstalling, no copying.

## Contributing

1. Create a new folder directly under `skills/` (for example `skills/my-skill/`)
2. Add a `SKILL.md` following the existing conventions
3. List it in the table above
4. Run `./scripts/link-skills.sh` to make it available locally

## FAQ

**How do I remove a skill?**
Delete the symlink from `~/.agents/skills/`, run `./scripts/unlink-skills.sh`, or move the skill folder to `skills/deprecated/` and re-run `link-skills.sh`.

**What if I only want a subset of skills?**
Move the skills you don't want into a different directory, or put them in `skills/deprecated/`. The script skips `deprecated/` automatically.

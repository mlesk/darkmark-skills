# darkmark-skills

A set of useful skills that I use day to day.

These skills are designed to be small, easy to adapt, and composable. They work with any AI coding agent — Claude Code, Codex, GitHub Copilot, and others. Hack around with them. Make them your own. Enjoy.

Inspired by Matt Pocock's [skills](https://github.com/mattpocock/skills)

All user-invocable skills use the `dm-` prefix to avoid conflicts with other plugins and to show they are part of one set. For example, the `loopify` skill is `dm-loopify` in the agent. The `spec-*` sub-skills bundled inside `dm-spec-creation` are agent-only (`user-invocable: false`) and are not linked as standalone skills.

## Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/mlesk/darkmark-skills.git ~/darkmark-skills

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

### Thinking and improving

- [`dm-grill`](skills/dm-grill/SKILL.md) - Interviews you one question at a time, each with a recommended answer, until a plan, decision, or requirement is sharp enough to act on. Leaves a grill record. The other skills use it for their intake.
- [`dm-loopify`](skills/dm-loopify/SKILL.md) - Rubric-driven optimization loop for a file, document set, workflow, skill, subsystem, codebase, or goal. Agrees a rubric and threshold, scores a baseline, runs judged improvement rounds to a stop rule, and closes with a `dm-critic` review. Also the engine `dm-write` and `dm-decide` run on.
- [`dm-critic`](skills/dm-critic/SKILL.md) - Independent adversarial review by two fresh-context reviewers (a critic hunting defects and an explorer proposing higher-ceiling alternatives), verified and merged into one table of next-step options.
- [`dm-decide`](skills/dm-decide/SKILL.md) - Structured decision-making on the `dm-loopify` engine. Grills the decision through mental-model lenses scaled to reversibility, vetoes options that fail must-pass constraints, scores the rest including the status quo, stress-tests the leader, and delivers a decision record.
- [`dm-write`](skills/dm-write/SKILL.md) - Improves non-fiction prose with Williams' _Style: Lessons in Clarity and Grace_ on the `dm-loopify` engine. Diagnoses against ten rules, revises in scored rounds, checks with a cold reader, and delivers revised text with a change log.

### Building

- [`dm-agent-team`](skills/dm-agent-team/SKILL.md) - A Lead plus five sub-agents (analyst, architect, designer, builder, reviewer) that take a product idea through requirements and UX design (iterated until they agree and reach your target state), then architecture and a build plan, to a clean-room, test-driven implementation in local files. Three run modes (stepwise, checkpoint, yolo), build phases planned inside out (horizontal layers first, UI phases last) and built in parallel git worktrees, a `--brownfield` mode for changing existing systems (discovery, characterisation tests, a no-regression gate), an independent reviewer after every author turn, and a driver script for unattended runs. The successor to `dm-spec-creation` + `dm-spec-execution`. Its agent-only sub-agents are dispatched by the Lead and are not linked as skills:
  - [`dm-at-analyst`](skills/dm-agent-team/agents/dm-at-analyst/SKILL.md) (agent-only)
  - [`dm-at-architect`](skills/dm-agent-team/agents/dm-at-architect/SKILL.md) (agent-only)
  - [`dm-at-designer`](skills/dm-agent-team/agents/dm-at-designer/SKILL.md) (agent-only)
  - [`dm-at-builder`](skills/dm-agent-team/agents/dm-at-builder/SKILL.md) (agent-only)
  - [`dm-at-reviewer`](skills/dm-agent-team/agents/dm-at-reviewer/SKILL.md) (agent-only)
- [`dm-debug`](skills/dm-debug/SKILL.md) - Hypothesis-driven debugging: reproduce, shrink, rank hypotheses, run experiments that tell them apart, and fix the root cause with a regression test seen failing first. Keeps a debug log.

### Being replaced by `dm-agent-team`

These still work, but new projects should use `dm-agent-team`. See [GUIDE.md §Migrating from the spec skills](skills/dm-agent-team/GUIDE.md#migrating-from-the-spec-skills).

- [`dm-spec-creation`](skills/dm-spec-creation/SKILL.md) - Gate-driven specification workflow for C# / ASP.NET Core / .NET Aspire / EF Core + TypeScript / React (Vite + shadcn), Clean Architecture, and inside-out phased planning. Bundles standards, templates, gates, and orchestration docs.
  - [`spec-00-prd`](skills/dm-spec-creation/specs/spec-00-prd/SKILL.md) (agent-only)
  - [`spec-01-domain-model`](skills/dm-spec-creation/specs/spec-01-domain-model/SKILL.md) (agent-only)
  - [`spec-02-architecture`](skills/dm-spec-creation/specs/spec-02-architecture/SKILL.md) (agent-only)
  - [`spec-03-implementation-guidance`](skills/dm-spec-creation/specs/spec-03-implementation-guidance/SKILL.md) (agent-only)
  - [`spec-04-user-interface`](skills/dm-spec-creation/specs/spec-04-user-interface/SKILL.md) (agent-only)
  - [`spec-05-app-use-cases`](skills/dm-spec-creation/specs/spec-05-app-use-cases/SKILL.md) (agent-only)
  - [`spec-06-execution-plan`](skills/dm-spec-creation/specs/spec-06-execution-plan/SKILL.md) (agent-only)
- [`dm-spec-execution`](skills/dm-spec-execution/SKILL.md) - Autonomous implementation loop that executes the Phase state machine from `spec-06-execution-plan.md`, tracking progress in `execution-state.md`. Needs `dm-spec-creation` installed alongside it.

### Skills about skills

- [`dm-pocockify`](skills/dm-pocockify/SKILL.md) - Purpose-first workflow for creating, reviewing, or improving agent skills. Inspired by Matt Pocock's prompt engineering approach. Four modes: create from scratch, pocockify existing, review only, or update in place.
- [`dm-skill-eval`](skills/dm-skill-eval/SKILL.md) - Tests a skill: static lint (`scripts/lint-skill.py`), trigger evals with near misses, and behavior scenarios run by fresh sub-agents with a separate judge. Saves a pass-rate report next to the skill.
- [`dm-learn`](skills/dm-learn/SKILL.md) - Turns a session's corrections and failures into small, approved edits to `AGENTS.md`, `CLAUDE.md`, or a skill, so the next session doesn't repeat them.

### How the skills compose

Skills call siblings by relative path (`../dm-grill/SKILL.md`), so install the whole set with `link-skills.sh`.

```
dm-decide ─┐                ┌─> dm-grill   (intake interview)
dm-write  ─┴─> dm-loopify ──┴─> dm-critic  (final independent review)
dm-pocockify ─> dm-grill, dm-skill-eval
dm-debug, dm-learn          (standalone; dm-debug may hand off to dm-learn)
dm-agent-team ──> dm-at-* sub-agents (nested, dispatched by the Lead)
dm-spec-creation ─> dm-spec-execution   (being replaced by dm-agent-team)
```

## How It Works

The `scripts/link-skills.sh` script links every top-level skill (`skills/<name>/SKILL.md`) into `~/.agents/skills/`. Anything nested deeper is skipped: the agent-only `dm-at-*` sub-agents under `skills/dm-agent-team/agents/`, the `spec-*` sub-skills under `skills/dm-spec-creation/specs/`, and everything in `skills/experimental/` and `skills/deprecated/`. For example:

```
~/.agents/skills/dm-loopify → ~/darkmark-skills/skills/dm-loopify
~/.agents/skills/dm-agent-team → ~/darkmark-skills/skills/dm-agent-team
```

Because these are symlinks, running `git pull` in the repo updates every agent's skills at once. No reinstalling, no copying.

## Contributing

1. Create a new folder directly under `skills/` (for example `skills/dm-my-skill/`), or under `skills/experimental/` while it is a work in progress
2. Add a `SKILL.md` following the existing conventions (`dm-pocockify` can draft it)
3. List it in the README under Available Skills
4. Lint it: `python3 skills/dm-skill-eval/scripts/lint-skill.py --all skills` (this also checks that every skill is linked from this README and that its links resolve)
5. Run `./scripts/link-skills.sh` to make it available locally

## FAQ

**How do I remove a skill?**
Move the skill folder to `skills/deprecated/`, then run `./scripts/unlink-skills.sh` followed by `./scripts/link-skills.sh`. `link-skills.sh` never removes old links, so without the unlink step the moved skill leaves a dangling symlink in `~/.agents/skills/`.

**What if I only want a subset of skills?**
Move the skills you don't want into `skills/deprecated/`, then unlink and re-link as above. The script only links top-level skills, so anything there is skipped. Note that `dm-write` and `dm-decide` need `dm-loopify`, `dm-grill`, and `dm-critic`.

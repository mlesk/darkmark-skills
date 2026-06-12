# darkmark-skills

A set of useful skills that I use day to day.

These skills are designed to be small, easy to adapt, and composable. They work with any AI coding agent — Claude Code, Codex, GitHub Copilot, and others. Hack around with them. Make them your own. Enjoy.

Inspired by Matt Pocock's [skills](https://github.com/mattpocock/skills)

All skills are prefixed with dm- to avoid conflicts with other plugins. For example, the `loopify` skill is `dm-loopify` in the agent.

## Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/mlesk/skills.git ~/darkmark-skills

# 2. Link the skills into your agents (auto-detects which you have)
cd ~/darkmark-skills
./scripts/link-skills.sh
```

That's it. Your skills are now available as slash commands in every detected agent.

**Want to pick specific agents?**

```bash
./scripts/link-skills.sh --agents claude,codex,copilot
```

**Preview what will happen without making changes:**

```bash
./scripts/link-skills.sh --dry-run
```

**Overwrite existing skill links:**

```bash
./scripts/link-skills.sh --force
```

## Supported Agents

| Agent          | Skills directory     |
| -------------- | -------------------- |
| Claude Code    | `~/.claude/skills/`  |
| Codex (OpenAI) | `~/.codex/skills/`   |
| GitHub Copilot | `~/.copilot/skills/` |

Each skill is symlinked into the agent's skills directory, so pulling the repo updates the skills everywhere automatically.

## Available Skills

### Productivity

- [`dm-loopify`](skills/productivity/dm-loopify/SKILL.md) - Generalized rubric optimization loop for a goal, single artifact, related artifact set, or codebase. Clarifies the goal, builds the rubric, scores the baseline, and iterates until it reaches a target score or plateaus.
- [`dm-pocockify`](skills/productivity/dm-pocockify/SKILL.md) - Purpose-first workflow for creating, reviewing, or improving agent skills. Inspired by Matt Pocock's prompt engineering approach. Four modes: create from scratch, pocockify existing, review only, or update in place.

### Engineering

_No skills yet. Add yours to `skills/engineering/`._

## How It Works

The `scripts/link-skills.sh` script finds every `SKILL.md` in the repo (skipping `deprecated/`) and creates a symlink in each agent's skills directory. For example:

```
~/.claude/skills/loopify → ~/darkmark-skills/skills/productivity/dm-loopify
~/.codex/skills/loopify  → ~/darkmark-skills/skills/productivity/dm-loopify
~/.copilot/skills/loopify → ~/darkmark-skills/skills/productivity/dm-loopify
```

Because these are symlinks, running `git pull` in the repo updates every agent's skills at once. No reinstalling, no copying.

## Contributing

1. Create a new folder under the right bucket (`skills/engineering/`, `skills/productivity/`, etc.)
2. Add a `SKILL.md` following the existing conventions
3. Add it to the plugin manifest (`.claude-plugin/plugin.json` for Claude, or equivalent for other agents)
4. List it in the table above
5. Run `./scripts/link-skills.sh` to make it available locally

## FAQ

**How do I remove a skill?**
Delete the symlink from the agent's skills directory, or just move the skill folder to `skills/deprecated/` and re-run `link-skills.sh`.

**How do I add a new agent?**
Edit the `agent_dir()` function and `KNOWN_AGENTS` array in `scripts/link-skills.sh`. Pull requests welcome.

**What if I only want a subset of skills?**
Move the skills you don't want into a different directory, or put them in `skills/deprecated/`. The script skips `deprecated/` automatically.

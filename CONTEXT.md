# Dark Mark Skills

A collection of agent skills loaded from the central `~/.agents/skills/` directory by Claude Code, Codex, GitHub Copilot, and other agents.

Skills live in a flat list under `skills/`: `dm-grill`, `dm-loopify`, `dm-critic`, `dm-decide`, `dm-write`, `dm-agent-team` (a Lead with two nested agent-only `agents/dm-at-*` sub-agents, builder and reviewer), `dm-debug`, `dm-pocockify`, `dm-skill-eval`, `dm-learn`, and the legacy `dm-spec-creation` (with seven agent-only `specs/spec-*` sub-skills) and `dm-spec-execution`, which `dm-agent-team` is replacing. The top-level `README.md` is the index and lists every skill with a link to its `SKILL.md`.

`scripts/link-skills.sh` symlinks each top-level skill into `~/.agents/skills/`. `scripts/unlink-skills.sh` removes those links. Nested sub-agents and skills under `skills/experimental/` and `skills/deprecated/` are skipped.

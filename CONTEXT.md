# Dark Mark Skills

A collection of agent skills loaded from the central `~/.agents/skills/` directory by Claude Code, Codex, GitHub Copilot, and other agents.

Skills live in a flat list under `skills/`: `dm-grill`, `dm-loopify`, `dm-critic`, `dm-decide`, `dm-write`, `dm-debug`, `dm-spec-creation` (with seven agent-only `specs/spec-*` sub-skills), `dm-spec-execution`, `dm-pocockify`, `dm-skill-eval`, and `dm-learn`. `skills/experimental/dm-agent-team` is a work in progress meant to replace the spec skills. The top-level `README.md` is the index and lists every skill with a link to its `SKILL.md`.

`scripts/link-skills.sh` symlinks each top-level skill into `~/.agents/skills/`. `scripts/unlink-skills.sh` removes those links. Skills under `skills/experimental/` and `skills/deprecated/` are skipped.

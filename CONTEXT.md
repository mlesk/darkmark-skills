# Dark Mark Skills

A collection of agent skills loaded from the central `~/.agents/skills/` directory by Claude Code, Codex, GitHub Copilot, and other agents.

Skills live in a flat list under `skills/`: `dm-decide`, `dm-loopify`, `dm-pocockify`, `dm-write`, `dm-spec-creation` (with seven agent-only `specs/spec-*` sub-skills), and `dm-spec-execution`. The top-level `README.md` is the index and lists every skill with a link to its `SKILL.md`.

`scripts/link-skills.sh` symlinks each skill into `~/.agents/skills/`. `scripts/unlink-skills.sh` removes those links. Skills under `skills/deprecated/` are disabled and skipped.

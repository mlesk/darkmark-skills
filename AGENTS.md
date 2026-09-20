# AGENTS

Skills live in a flat list under `skills/`. Each skill is a directory containing a `SKILL.md`.

- Every skill must have a reference in the top-level `README.md`.
- Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.
- `skills/spec-creation` bundles standards, templates, gates, orchestration docs, and the seven `specs/spec-*` sub-skills. Each sub-skill has its own `SKILL.md` and its own entry in the top-level `README.md`.
- `skills/deprecated/` holds disabled skills. The link scripts skip it.
- Registration is symlink-based: `scripts/link-skills.sh` links every `SKILL.md` under `skills/` (except `deprecated/`) into `~/.agents/skills/`. `scripts/unlink-skills.sh` removes links that point into this repo.
- `dm-*` skills use the `dm-` prefix to avoid collisions with other plugins. `spec-*` skills use the `spec-` prefix.

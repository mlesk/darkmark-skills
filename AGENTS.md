# AGENTS

Skills live in a flat list under `skills/`. Each skill is a directory containing a `SKILL.md`.

- Every skill must have a reference in the top-level `README.md`.
- Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.
- All user-invocable skills use the `dm-` prefix to avoid collisions with other plugins and mark the set. The `spec-*` sub-skills are agent-only and keep the `spec-` prefix.
- `skills/dm-spec-creation` bundles standards, templates, gates, orchestration docs, and the seven `specs/spec-*` sub-skills. Each sub-skill has its own `SKILL.md` (marked `user-invocable: false`, agent-only) and its own entry in the top-level `README.md`.
- `skills/experimental/` holds work-in-progress skills. `dm-agent-team` lives there and is intended to eventually replace `dm-spec-creation` + `dm-spec-execution`.
- `skills/deprecated/` holds disabled skills.
- Registration is symlink-based: `scripts/link-skills.sh` links only top-level `skills/<name>/SKILL.md` into `~/.agents/skills/`. Nested sub-skills, `experimental/`, and `deprecated/` are never linked. `scripts/unlink-skills.sh` removes links that point into this repo.
- Skills compose by calling siblings through relative paths (`../dm-grill/SKILL.md`). `dm-write` and `dm-decide` are domain packs on the `dm-loopify` engine; `dm-loopify` uses `dm-grill` and `dm-critic`. Keep shared mechanics in the engine, not copied into callers.
- Keep each `SKILL.md` short; move templates, long rule lists, and examples into `references/` and link them from the step that needs them.
- Before committing, run `python3 skills/dm-skill-eval/scripts/lint-skill.py --all skills` and fix every error.

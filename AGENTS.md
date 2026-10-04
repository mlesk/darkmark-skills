# AGENTS

Skills live in a flat list under `skills/`. Each skill is a directory containing a `SKILL.md`.

- Every skill must have a reference in the top-level `README.md`.
- Each skill entry in the top-level `README.md` must link the skill name to its `SKILL.md`.
- All skills use the `dm-` prefix to avoid collisions with other plugins and mark the set. Agent-only sub-agents nested inside a skill (the `dm-at-*` agents in `dm-agent-team`) also use it; the legacy `spec-*` sub-skills keep the `spec-` prefix.
- `skills/dm-spec-creation` bundles standards, templates, gates, orchestration docs, and the seven `specs/spec-*` sub-skills. Each sub-skill has its own `SKILL.md` (marked `user-invocable: false`, agent-only) and its own entry in the top-level `README.md`.
- `skills/dm-agent-team` is a Lead skill with five nested agent-only sub-agents under `agents/dm-at-*/`. Each has its own `SKILL.md` and its own README entry. The Lead dispatches them by path; they are never linked.
- `dm-agent-team` supersedes `dm-spec-creation` + `dm-spec-execution`. Put new spec and execution features into `dm-agent-team`, not the spec skills. When the spec skills are retired, move both to `skills/deprecated/` in one commit, because `dm-spec-execution` reads `../dm-spec-creation/`.
- `skills/experimental/` holds work-in-progress skills.
- `skills/deprecated/` holds disabled skills.
- Registration is symlink-based: `scripts/link-skills.sh` links only top-level `skills/<name>/SKILL.md` into `~/.agents/skills/`. Nested sub-skills, `experimental/`, and `deprecated/` are never linked. `scripts/unlink-skills.sh` removes links that point into this repo.
- Skills compose by calling siblings through relative paths (`../dm-grill/SKILL.md`). `dm-write` and `dm-decide` are domain packs on the `dm-loopify` engine; `dm-loopify` uses `dm-grill` and `dm-critic`. Keep shared mechanics in the engine, not copied into callers.
- Keep each `SKILL.md` short; move templates, long rule lists, and examples into `references/` and link them from the step that needs them.
- Before committing, run `python3 skills/dm-skill-eval/scripts/lint-skill.py --all skills` and fix every error. It also checks the README.

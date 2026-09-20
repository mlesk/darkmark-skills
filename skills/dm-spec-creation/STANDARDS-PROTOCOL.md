# Standards Protocol

This skill is opinionated and self-contained. Each spec phase loads a fixed set of standards from the bundle under [`./standards/`](./standards/) inside the skill folder. The orchestrator MUST read these files in full before running the sub-skill's grilling loop and MUST cite specific `[MUST]`/`[SHOULD]` rules when recommending answers.

If any listed standard file is missing from `standards/`, the skill is corrupt — halt and ask the user to restore the skill. Do not fall back to repo-level standards.

## Standards-to-spec mapping (paths relative to the skill root)

| Spec                            | Required standards (read in full)                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| spec-00 PRD                     | `standards/coding-standards-general.md`                                                                                                                                                                                                                                                                                                                                                                                                                            |
| spec-01 Domain Model            | `standards/design-standards-domain-model.md`, `standards/design-standards-problem-domain-implementation.md`, `standards/design-standards-clean-architecture.md`                                                                                                                                                                                                                                                                                                    |
| spec-02 Architecture            | `standards/design-standards-clean-architecture.md`, `standards/design-standards-problem-domain-implementation.md`, `standards/coding-standards-csharp.md`, `standards/coding-standards-aspnet.md`, `standards/coding-standards-aspire.md`, `standards/coding-standards-efcore.md`, `standards/coding-standards-sql.md`, `standards/coding-standards-rest-api.md`, `standards/coding-standards-typescript.md`, `standards/coding-standards-react.md`                |
| spec-02x Architecture Sidecar   | base `standards/design-standards-clean-architecture.md` + `standards/design-standards-problem-domain-implementation.md`; PLUS the subset of `coding-standards-*.md` that governs the sidecar's technical slice (e.g. `coding-standards-efcore.md` + `coding-standards-sql.md` for a persistence sidecar; `coding-standards-aspnet.md` + `coding-standards-rest-api.md` for a transport sidecar). The sidecar's front-matter MUST enumerate the standards it loads. |
| spec-03 Implementation Guidance | all `standards/coding-standards-*.md` (general, csharp, aspnet, aspire, efcore, sql, rest-api, typescript, react, testing)                                                                                                                                                                                                                                                                                                                                         |
| spec-04 User Interface          | `standards/coding-standards-react.md`, `standards/coding-standards-typescript.md`                                                                                                                                                                                                                                                                                                                                                                                  |
| spec-05 App Use Cases           | `standards/coding-standards-rest-api.md`, `standards/coding-standards-aspnet.md`, `standards/coding-standards-aspire.md`                                                                                                                                                                                                                                                                                                                                           |
| spec-06 Execution Plan          | `standards/planning-standards-inside-out-phases.md`, `standards/design-standards-clean-architecture.md`, `standards/coding-standards-testing.md`                                                                                                                                                                                                                                                                                                                   |

## Citation format

When grilling, cite standards inline:

> Recommendation: model `ResearchRun` as a pink moment-interval.
> Rationale: `design-standards-domain-model.md` §4 [MUST] classify remembered business activity as pink before considering yellow or green archetypes.

## Standards drift

If during a later spec phase you discover the standards contradict a decision logged in an earlier spec, stop. Surface the contradiction. Resolve by either:

- amending the earlier spec (re-runs its gate + cross-spec gate), or
- logging a `standards-deviation` entry in `decisions.md` with explicit rationale.

Never silently override a standard.

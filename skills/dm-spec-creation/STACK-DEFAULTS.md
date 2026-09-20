# Canonical Stack Defaults

This skill is **opinionated**. It accelerates spec creation for one specific solution shape — the one defined by the standards bundle below. All sub-skills and gates assume these defaults. They are NOT choices for the user to make. The user may **deviate** from any default, but every deviation costs a `standards-deviation` entry in `decisions.md` and is interrogated by the gate.

## The standards bundle (bundled with the skill)

Every standard the skill cites lives under [`./standards/`](./standards/) inside the skill folder. The skill is self-contained: it does not read from `02-standards/` or any other repo location. Paths below are relative to the skill root.

### Design standards

- [standards/design-standards-domain-model.md](./standards/design-standards-domain-model.md) — Object Modeling in Color (Pink Moment-Interval / Yellow Role / Blue Description / Green Party-Place-Thing), Law of Demeter, Domain-Neutral Component
- [standards/design-standards-problem-domain-implementation.md](./standards/design-standards-problem-domain-implementation.md) — rich-domain-model implementation discipline
- [standards/design-standards-clean-architecture.md](./standards/design-standards-clean-architecture.md) — clean architecture layering

### Coding standards

- [standards/coding-standards-general.md](./standards/coding-standards-general.md)
- [standards/coding-standards-csharp.md](./standards/coding-standards-csharp.md)
- [standards/coding-standards-aspnet.md](./standards/coding-standards-aspnet.md)
- [standards/coding-standards-aspire.md](./standards/coding-standards-aspire.md)
- [standards/coding-standards-efcore.md](./standards/coding-standards-efcore.md)
- [standards/coding-standards-sql.md](./standards/coding-standards-sql.md)
- [standards/coding-standards-rest-api.md](./standards/coding-standards-rest-api.md)
- [standards/coding-standards-typescript.md](./standards/coding-standards-typescript.md)
- [standards/coding-standards-react.md](./standards/coding-standards-react.md)
- [standards/coding-standards-testing.md](./standards/coding-standards-testing.md) — pinned test-runtime stack (xUnit, NetArchTest, Vitest, Playwright) and required test-execution commands

### Planning standard

- [standards/planning-standards-inside-out-phases.md](./standards/planning-standards-inside-out-phases.md) — inside-out phased execution plan format consumed by the autonomous implementation agent

## The default stack (encoded as decisions, not questions)

| Layer                    | Default                                                                                                                | Governed by                                             |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Backend language         | C# (latest LTS) with nullable reference types enabled solution-wide                                                    | `coding-standards-csharp.md`                            |
| Web framework            | ASP.NET Core Minimal APIs                                                                                              | `coding-standards-aspnet.md`                            |
| App orchestration        | .NET Aspire (AppHost + ServiceDefaults)                                                                                | `coding-standards-aspire.md`                            |
| Persistence              | EF Core with relational store; migrations in code                                                                      | `coding-standards-efcore.md`, `coding-standards-sql.md` |
| API style                | REST (resource-oriented), JSON                                                                                         | `coding-standards-rest-api.md`                          |
| Frontend language        | TypeScript (strict)                                                                                                    | `coding-standards-typescript.md`                        |
| Frontend framework       | React + Vite                                                                                                           | `coding-standards-react.md`                             |
| UI component system      | shadcn/ui + Tailwind (matching `01-specifications/screen-mockups/` pattern)                                            | `coding-standards-react.md`                             |
| Frontend package manager | pnpm (workspace-aware; `pnpm-lock.yaml` checked in)                                                                    | `coding-standards-testing.md` §5                        |
| Test runtime             | xUnit (.NET unit/integration), NetArchTest (architecture), Vitest + RTL (FE component), Playwright (FE e2e + visual)   | `coding-standards-testing.md`                           |
| Domain modeling          | Object Modeling in Color (no aggregates)                                                                               | `design-standards-domain-model.md`                      |
| Architecture             | Clean Architecture                                                                                                     | `design-standards-clean-architecture.md`                |
| Build planning           | Inside-out phased execution plan for autonomous agent delivery                                                         | `planning-standards-inside-out-phases.md`               |
| Solution layout          | `src/` for runtime projects; `tests/` peer; Aspire AppHost composes; mockups under `01-specifications/screen-mockups/` | inferred from this repo                                 |
| Spec output folder       | `01-specifications/` with `decisions.md` and `implementation-decisions.md` alongside                                   | this skill                                              |

## How defaults change the workflow

Sub-skills that previously asked the user to **choose** a stack now ask the user only to:

1. **Confirm** each default applies, OR
2. **Deviate** — name the deviation, justify it, log a `standards-deviation` decision entry, and accept that the deviating spec/gate gets harder scrutiny.

The skill never asks "what frontend framework do you want?" — it asks "Confirm React + Vite + shadcn (default) or declare a deviation?"

## Standards integrity

The standards bundle is part of the skill. If a file under `standards/` is missing, the skill is corrupt — the orchestrator halts and asks the user to restore the skill (e.g. re-pull from source control). The skill does not improvise around missing standards and does not fall back to repo-level standards folders.

## Keeping standards in sync

If the project's own standards (under `02-standards/` or elsewhere) evolve, refresh the bundle by re-copying the updated files into `standards/`. The skill is intentionally a snapshot: a spec produced today is reproducible from the standards bundled at that time, independent of later changes to the repo's standards folder.

**Explicit non-goal: automated drift detection.** This skill does NOT detect, warn about, or reconcile drift between its bundled `standards/` and any project-canonical standards folder elsewhere in the repo. Bundle freshness is the user's responsibility, and snapshot semantics are deliberate — reproducibility of a spec from a fixed standards bundle outweighs the convenience of auto-sync. Do not add drift-detection logic to the skill; if drift matters, refresh the bundle manually before invoking the skill on a new spec set.

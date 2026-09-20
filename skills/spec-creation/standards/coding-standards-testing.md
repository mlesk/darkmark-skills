# Coding Standard: Testing

> Pins the test-runtime stack and conventions assumed by `standards/planning-standards-inside-out-phases.md` §6 and by every Phase's `done-when:` block in `spec-06-execution-plan.md`. Without this standard, "tests pass" is unenforceable.

## 1. Pinned tooling

| Test type                           | Framework                                                                                   | Notes                                                                                           |
| ----------------------------------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| .NET unit                           | xUnit                                                                                       | xUnit's built-in `Assert` is the default; teams MAY add Shouldly via a D-NNN.                   |
| .NET architecture                   | NetArchTest.Rules                                                                           | One project: `<Solution>.ArchitectureTests`. Tests tagged `[Trait("Category","Architecture")]`. |
| .NET integration (PD with faked SI) | xUnit + hand-rolled fakes implementing PD-owned SI contracts                                | Live in `<Project>.Tests` peer to the PD project.                                               |
| .NET integration (SI real adapter)  | xUnit + real SQLite (file or `:memory:`) for persistence; real file I/O for source adapters | Live in `<Project>.IntegrationTests`.                                                           |
| .NET integration (UC end-to-end)    | xUnit + `WebApplicationFactory<TProgram>` + real SI                                         | Live in `<UcProject>.IntegrationTests`.                                                         |
| .NET API integration (UI BFF)       | xUnit + `WebApplicationFactory<TProgram>` against the BFF host                              | Live in `MoneyMaker.WebApp.IntegrationTests` (or equivalent).                                   |
| FE component                        | Vitest + React Testing Library                                                              | Co-located `*.test.tsx` next to the component.                                                  |
| FE end-to-end                       | Playwright (`@playwright/test`)                                                             | `tests/e2e/` at the FE project root.                                                            |
| FE visual parity (mockup)           | Playwright `expect(page).toHaveScreenshot()` against approved mockup screen                 | Required for FE Phases per `planning-standards-inside-out-phases.md` §6 (or D-NNN deviation).   |

Deviating from any pinned framework requires a `standards-deviation` entry in `decisions.md` naming the alternative and the rationale.

## 2. Test-project naming

| Purpose                  | Project name                              | Location                           |
| ------------------------ | ----------------------------------------- | ---------------------------------- |
| Unit / faked-SI tests    | `<RuntimeProject>.Tests`                  | `tests/`                           |
| Real-adapter integration | `<RuntimeProject>.IntegrationTests`       | `tests/`                           |
| Architecture tests       | `<Solution>.ArchitectureTests`            | `tests/`                           |
| FE e2e tests             | (no separate project — Playwright config) | `src/MoneyMaker.WebApp/tests/e2e/` |

Test class names: `<TypeUnderTest>Tests`. Test method names: `Should_<expected behaviour>_when_<condition>` (snake-case allowed for readability).

## 3. Minimum architecture-test set

The `<Solution>.ArchitectureTests` project MUST contain at least these assertions (P1 of the execution plan scaffolds them; later Phases extend):

1. **PD has no reference to SI, ASP.NET, EF Core, or any infrastructure assembly.**
2. **UC has no reference to UI BFF or FE assemblies.**
3. **UI BFF has no reference to FE assemblies.**
4. **Domain projects (`MoneyMaker.PD.*`) have no transitive reference to `Microsoft.EntityFrameworkCore` or `Microsoft.AspNetCore.*`.**
5. **Project naming follows `MoneyMaker.<Layer>.<Module>` per `coding-standards-csharp.md` and the repo convention.**
6. **No class in PD depends on a type from an SI namespace.** (Contracts are PD-owned; SI implements them.)

Each assertion is one xUnit test method, traited `[Trait("Category","Architecture")]`, so `dotnet test --filter Category=Architecture` runs the set. P1's deliverables enumerate these tests by name; P10 (hardening) extends with project-specific assertions.

## 4. Test data & fixtures

- SI integration tests own their fixture data under `tests/<Project>.IntegrationTests/Fixtures/`. No shared global fixture store.
- UC and UI integration tests bootstrap a fresh SQLite database per test class (file: `Path.GetTempFileName()`, deleted on teardown).
- FE e2e fixtures live in `src/MoneyMaker.WebApp/tests/e2e/fixtures/`.
- Production data must never be loaded into a test fixture.

## 5. Required test execution commands

These commands MUST be the exact strings used in every `done-when:` block:

```text
dotnet build MoneyMaker.slnx                                    # zero warnings, whole solution
dotnet test MoneyMaker.slnx --filter Category=Architecture      # architecture-only fast pass
dotnet test MoneyMaker.slnx                                     # full backend test suite
pnpm --filter ./src/MoneyMaker.WebApp run typecheck             # FE type check
pnpm --filter ./src/MoneyMaker.WebApp run lint                  # FE lint
pnpm --filter ./src/MoneyMaker.WebApp run test                  # FE component tests (Vitest)
pnpm --filter ./src/MoneyMaker.WebApp run test:e2e              # FE e2e (Playwright)
```

The FE package manager is **pnpm** (per `STACK-DEFAULTS.md` testing-toolchain section). Use of `npm` or `yarn` requires a `standards-deviation`.

## 6. CI posture

A `.github/workflows/ci.yml` MUST run, at minimum, on every push and PR:

1. `dotnet build MoneyMaker.slnx -warnaserror`
2. `dotnet test MoneyMaker.slnx`
3. `pnpm install --frozen-lockfile` + the four `pnpm` commands above.
4. Architecture tests run as a separate job (faster failure surface).

Phase P1's deliverables include creating this workflow. Phase P10 extends it (coverage thresholds, etc.) if any are agreed.

## 7. What this standard does NOT cover

- Coverage targets (decide per project; log as D-NNN if any).
- Mutation testing (out of scope by default).
- Performance / load tests (specify in P10 if required by spec-00 NFRs).

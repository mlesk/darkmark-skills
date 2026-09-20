---
name: clean-architecture-standards
description: Standards for implementing Clean Architecture with the canonical FE -> UI -> UC -> PD <- SI model, enforcing a problem-domain-centered architecture where the Problem Domain owns business rules and external service contracts.
scope: Projects adopting Clean Architecture with clearly separated Front-End, User Interface API, Use Case, Problem Domain, and System Integration layers.
---

# Clean Architecture Standards

> **Sources:**
>
> - [Clean Architecture Simplified — DrunknCode](https://medium.com/@DrunknCode/clean-architecture-simplified-and-in-depth-guide-026333c54454)
> - [Next Level Clean Architecture Boilerplate — Microsoft ISE](https://devblogs.microsoft.com/ise/next-level-clean-architecture-boilerplate/)
> - [Building Maintainable Clean Architecture — Red Hat](https://developers.redhat.com/articles/2023/04/17/my-advice-building-maintainable-clean-architecture)
> - Robert C. Martin, "Clean Architecture: A Craftsman's Guide to Software Structure and Design"
> - Heavily influenced by Color Modeling by COAD, Feature Driven Development process by DeLuca.
>
> **Canonical Layer Model:**
>
> ```text
> FE ──→ UI ──→ UC ──→ PD ←── SI
> ```
>
> - **FE** is the Front-End Layer, such as a React SPA. It is a deployable actor.
> - **UI** is the User Interface API Layer, such as a BFF API. It is a deployable actor and the backend composition root.
> - **UC** is the Application Use Case Layer. It exposes commands and queries and is the only backend surface invoked by UI.
> - **PD** is the Problem Domain Layer. It owns business rules, business invariants, lifecycle state, domain orchestration, and all external service contracts it requires.
> - **SI** is the System Integration Layer. It implements PD-owned contracts and encapsulates persistence, transport, SDK, filesystem, process, and external system details.
>
> The dependency arrow always points inward toward PD. SI's dependency on PD is **inverted** — PD defines the contracts, SI fulfills them.

---

## 1. Layer Taxonomy

- `[MUST]` Treat `FE` and `UI` as deployable actors.
- `[MUST]` Treat `UC`, `PD`, and `SI` as backend logical layers.
- `[MUST]` Use the short monikers `FE`, `UI`, `UC`, `PD`, and `SI` as the default folder and namespace terminology unless a tech spec explicitly overrides them.
- `[MUST]` Treat `UI` as the backend composition root.
- `[MUST]` Treat `UC` as the exclusive command and query facade used by `UI`.

## 2. The Dependency Rule

### 2.1 Compile-Time Dependency Rules

- `[MUST]` Compile-time dependencies point inward toward `PD`.
- `[MUST]` `PD` has zero references to `UC`, `UI`, `FE`, or `SI` projects.
- `[MUST]` `UC` references `PD` only.
- `[MUST]` `SI` references `PD` only.
- `[MUST]` `UI` may reference `UC` and `SI` because `UI` is the backend composition root.
- `[MUST]` `FE` does not reference backend code projects directly; it communicates with `UI` over the network boundary.
- `[MUST-NOT]` Allow `UC` to reference `SI` types, namespaces, packages, or assemblies directly.
- `[MUST-NOT]` Allow any inner backend layer to reference an outer backend layer's assembly, package, or module.

### 2.2 Runtime Invocation Rules

- `[MUST]` Runtime flow follows `FE -> UI -> UC -> PD <- SI`.
- `[MUST]` `FE` calls `UI` only.
- `[MUST]` `UI` invokes `UC` only for business use cases.
- `[MUST]` `UC` invokes `PD` behavior for all commands.
- `[MUST]` `UC` may use PD-owned interfaces resolved through the PD ServiceLocator for efficient query execution when full domain behavior is not required.
- `[MUST]` `PD` may use PD-owned interfaces resolved through the PD ServiceLocator for domain-relevant orchestration that requires external interaction.
- `[MUST]` `SI` fulfills the PD-owned interfaces used by `UC` and `PD`.

### 2.3 Dependency Matrix

```text
FE -> network only -> UI
UI -> UC, SI
UC -> PD
PD -> nothing
SI -> PD
```

- `[MUST]` Interpret the matrix above as project-reference guidance.
- `[MUST-NOT]` Misread runtime access to PD-owned interfaces as permission for `UC` to reference `SI` types directly.

## 3. Problem Domain Layer (PD)

- `[MUST]` All business rules, business constraints, invariants, lifecycle state management, and domain-relevant orchestration live inside `PD`.
- `[MUST]` `PD` defines all external service contracts, repository contracts, persistence contracts, and capability ports it requires.
- `[MUST]` `PD` owns the ServiceLocator abstraction used by `PD` and `UC` to resolve PD-owned interfaces.
- `[MUST]` Detailed PD coding rules for rich entities, value objects, controlled mutation, equality, XML documentation, and persistence isolation are governed by [design-standards-problem-domain-implementation.md](./design-standards-problem-domain-implementation.md).
- `[MUST]` `PD` entities are plain language objects with no dependencies on frameworks, ORMs, transport libraries, or SI packages.
- `[MUST]` `PD` entities encapsulate both data and behavior; they are not anemic data bags.
- `[MUST-NOT]` Import or reference ORM packages, HTTP frameworks, serialization libraries, SDKs, or SI-specific packages in `PD`.
- `[MUST-NOT]` Place business-rule validation in `UC`, `UI`, or `SI` when that validation represents problem-domain meaning.
- `[SHOULD]` Use value objects for concepts whose equality is defined by value.
- `[SHOULD]` Make PD entities immutable or controlled-mutation through explicit behavior methods.

## 4. Application Use Case Layer (UC)

- `[MUST]` `UC` is the exclusive command and query surface used by `UI`.
- `[MUST]` `UC` orchestrates use cases by coordinating `PD` entities and PD-owned interfaces.
- `[MUST]` `UC` contains no business rules.
- `[MUST]` Each use case is a single-responsibility unit that executes one user intent.
- `[MUST]` Commands invoke `PD` behavior.
- `[MUST]` Queries return `UC` DTOs only.
- `[MUST]` `UC` translates PD entities into UC DTOs for exposure upward to `UI` and `FE`.
- `[MUST]` `UC` may access the PD ServiceLocator and resolve PD-owned interfaces for efficient read paths, including direct persistence-backed queries that return PD entities.
- `[MUST]` Transaction boundaries and unit-of-work coordination live in `UC`.
- `[MUST]` `UC` logs execution at the use-case level for start, completion, and error.
- `[MUST]` `UC` enforces authorization.
- `[MUST-NOT]` Return PD entities directly to `UI` or `FE`.
- `[MUST-NOT]` Reference SI types, assemblies, namespaces, or packages directly.
- `[MUST-NOT]` Place use-case implementations or handlers in `SI` namespaces.
- `[SHOULD]` Use CQRS to separate commands from queries.
- `[SHOULD]` Cleanly split commands and queries, they should not be comingled in the same class.
- `[SHOULD]` Use a custom dispatcher or mediator pattern to decouple callers from UC handlers.
- `[SHOULD]` Perform input-shape and request-format validation in `UC`, distinct from PD business-rule validation.

## 5. Problem Domain Service Locator

- `[MUST]` The ServiceLocator abstraction is owned by `PD`.
- `[MUST]` `UI`, as composition root, wires the ServiceLocator with `SI` implementations of PD-owned interfaces.
- `[MUST]` `PD` may resolve PD-owned interfaces through the ServiceLocator when domain behavior requires external capabilities.
- `[MUST]` `UC` may resolve PD-owned interfaces through the same ServiceLocator for efficient query execution and orchestration.
- `[MUST-NOT]` Use the ServiceLocator to bypass `UC` from `UI`.
- `[MUST-NOT]` Use the ServiceLocator to resolve SI-defined interfaces, because `SI` does not own inward-facing contracts.
- `[SHOULD]` Keep ServiceLocator usage explicit and narrow so dependencies remain understandable and testable.

## 6. System Integration Layer (SI)

- `[MUST]` `SI` implements interfaces defined in `PD`.
- `[MUST]` `SI` depends on `PD` only.
- `[MUST]` All third-party dependencies such as ORMs, HTTP clients, cloud SDKs, filesystem APIs, process execution APIs, broker clients, and logging frameworks are confined to `SI`.
- `[MUST]` `SI` consumes and returns PD entities at its boundary.
- `[MUST]` `SI` may use internal DTOs, ORM models, SDK models, transport payloads, or process-specific shapes internally, but those types live and die within `SI`.
- `[MUST]` `SI` performs all mapping between external or persistence-specific models and PD entities.
- `[MUST-NOT]` Leak SI-specific types into `UC` or `PD`.
- `[MUST-NOT]` Define interfaces in `SI` that `UC` or `PD` consume inward.
- `[SHOULD]` Organize `SI` by integration or technical capability such as persistence, process execution, external APIs, email, or file storage.
- `[SHOULD]` Use adapter patterns at each external boundary.
- `[SHOULD]` Keep it cheap to swap SI implementations without changing `PD` or `UC`.

## 7. User Interface API Layer (UI)

- `[MUST]` `UI` is the backend deployable actor and the backend composition root.
- `[MUST]` `UI` is the BFF API boundary used by `FE`.
- `[MUST]` `UI` calls `UC` only for business use cases.
- `[MUST]` `UI` may reference `SI` for composition and bootstrap only, never as a business-use-case shortcut.
- `[MUST]` `UI` maps network request and response models to and from UC request and response DTOs.
- `[MUST]` `UI` handles cross-cutting API concerns such as authentication middleware, global exception handling, request logging, CORS, and rate limiting.
- `[MUST]` `UI` wires the PD ServiceLocator with SI implementations.
- `[MUST-NOT]` Bypass `UC` to call `PD` directly for business use cases.
- `[MUST-NOT]` Call `SI` directly for business use cases.
- `[MUST-NOT]` Place business rules in controllers, endpoints, or API modules.
- `[SHOULD]` Use a global exception handler to translate failures into structured responses.
- `[SHOULD]` Keep the bootstrap and registration code clean by delegating setup to per-layer registration methods.

## 8. Front-End Layer (FE)

- `[MUST]` `FE` is the front-end deployable actor, such as a React SPA.
- `[MUST]` `FE` communicates with `UI` only.
- `[MUST]` `FE` consumes UI-exposed contracts and never consumes PD entities or SI types.
- `[MUST-NOT]` Bypass `UI` to call `UC`, `PD`, or `SI` directly.

## 9. Dependency Injection & Composition Root

- `[MUST]` `UI` is the composition root.
- `[MUST]` All concrete SI implementations are selected and registered in `UI` startup and composition code.
- `[MUST]` `UI` configures the PD ServiceLocator with SI implementations of PD-owned interfaces.
- `[MUST]` Each layer should provide its own registration extension methods where appropriate.
- `[MUST]` Treat compile-time project references and runtime-wired availability as separate concerns.
- `[MUST-NOT]` Infer from runtime availability that `UC` may reference `SI` directly.
- `[SHOULD]` Use scoped lifetimes for per-request services, singleton for stateless services, and transient only when a new instance per resolution is genuinely required.

## 10. Data Mapping & Boundaries

- `[MUST]` There are exactly two primary sanctioned mapping seams in the backend architecture.
- `[MUST]` Boundary seam one is `PD -> UC DTOs` in `UC`.
- `[MUST]` Boundary seam two is `external or persistence-specific models -> PD entities` in `SI`.
- `[MUST]` `UC` maps PD entities to UC DTOs for exposure through `UI` to `FE`.
- `[MUST]` `SI` maps ORM entities, transport payloads, SDK models, external response objects, filesystem shapes, process outputs, and any other external representations to PD entities.
- `[MUST-NOT]` Share a single model class across `FE`, `UI`, `UC`, `PD`, and `SI`.
- `[MUST-NOT]` Expose SI-internal DTOs or models outside `SI`.
- `[SHOULD]` Use explicit mapping methods or lightweight mappers rather than hidden magic.

## 11. Testing Strategy

- `[MUST]` PD logic is testable in complete isolation with zero SI dependencies by by mocking or faking PD-owned SI interfaces.
- `[MUST]` UC use cases are testable by mocking or faking PD-owned interfaces.
- `[MUST]` SI implementations are tested with integration tests against real dependencies, not just mocks.
- `[SHOULD]` Primarily rely on integration tests that exercise the stack `UC -> PD <- SI` for critical workflows.
- `[SHOULD]` Use end-to-end tests that exercise the full stack `FE -> UI -> UC -> PD <- SI` for testing the FE to UI interactions.
- `[SHOULD]` Structure test projects to mirror the layer structure: `PD.Tests`, `UC.Tests`, `SI.Tests`, `E2E.Tests`.
- `[SHOULD-NOT]` Use actual test specific database instance or test container for database providers as the primary integration-test strategy.

## 12. Error Handling

- `[MUST]` `PD` communicates business rule violations via PD-specific exceptions or a Result/Either pattern.
- `[MUST]` `UC` catches PD failures and translates them into UC-level outcomes and DTOs.
- `[MUST]` `UI` translates UC outcomes into external API responses.
- `[SHOULD]` Prefer the Result pattern for expected business failures and reserve exceptions for unexpected conditions.
- `[SHOULD]` Use a global exception handler in `UI` as a safety net for unhandled exceptions.

## 13. Project Structure

- `[MUST]` Organize the solution into separate projects per layer with explicit dependency references enforcing the dependency rule:

  ```text
  Solution/
  ├── src/
  │   ├── FE/                  # Front-end deployable
  │   ├── UI/                  # BFF API / composition root, references UC and SI
  │   ├── UC/                  # References PD only
  │   ├── PD/                  # Zero external dependencies
  │   └── SI/                  # References PD only
  └── tests/
      ├── PD.Tests/
      ├── UC.Tests/
      ├── SI.Tests/
      └── E2E.Tests/
  ```

- `[MUST]` Enforce dependency rules via project references or equivalent boundary enforcement:
  - `PD` references no other project.
  - `UC` references `PD` only.
  - `SI` references `PD` only.
  - `UI` references `UC` and `SI`.
  - `FE` communicates with `UI` over the network boundary rather than backend project references.
- `[SHOULD]` Use module- or bounded-context folders within each layer as the system grows.
- `[SHOULD-NOT]` Create a catch-all `Common` or `Shared` utilities project that erodes the layer boundaries.

## 14. Forbidden Examples

- `[MUST-NOT]` Place UC handlers or command/query implementations inside `SI` namespaces.
- `[MUST-NOT]` Define inward-facing contracts in `SI`.
- `[MUST-NOT]` Return PD entities directly to `FE`.
- `[MUST-NOT]` Let `UI` bypass `UC` for normal business use cases.
- `[MUST-NOT]` Let SI-internal DTOs, ORM entities, SDK objects, or transport models cross into `UC` or `PD`.
- `[MUST-NOT]` Put unrelated service interfaces into request-contract files.

---

## Completion Checklist — Dependency Rule

- [ ] `PD` has zero references to `UC`, `UI`, `FE`, or `SI` ← COMMONLY MISSED
- [ ] `UC` references `PD` only ← COMMONLY MISSED
- [ ] `SI` references `PD` only
- [ ] `UI` is the composition root and references `UC` and `SI`
- [ ] Compile-time and runtime dependency rules are both documented and enforced
- [ ] No framework annotations on PD entities (`[Table]`, `[JsonProperty]`, `@Entity`, etc.) ← COMMONLY MISSED

## Completion Checklist — Domain Integrity

- [ ] All business rules, invariants, and lifecycle state management live in `PD` ← COMMONLY MISSED
- [ ] PD entities have behavior, not just properties
- [ ] Repository and service contracts are defined in `PD`, implemented in `SI`
- [ ] `PD` owns the ServiceLocator abstraction
- [ ] `PD` has no knowledge of how data is stored, serialized, transported, or integrated externally

## Completion Checklist — Layer Boundaries

- [ ] Mapping seam one is enforced: `PD -> UC DTOs` in `UC` ← COMMONLY MISSED
- [ ] Mapping seam two is enforced: `external or persistence models -> PD entities` in `SI` ← COMMONLY MISSED
- [ ] No ORM entities, transport models, SDK types, or SI DTOs leak across boundaries
- [ ] `UI` endpoints are thin and delegate to `UC`
- [ ] `UI` configures the PD ServiceLocator with SI implementations
- [ ] Global exception handling in `UI` translates UC failures to structured responses

## Completion Checklist — Testability

- [ ] PD logic testable as integration tests using SI mocks and Fakes but no direct dependency on concrete SI implemenations
- [ ] UC use cases testable with mocked or faked PD-owned interfaces
- [ ] SI tested with integration tests against real dependencies ← COMMONLY MISSED
- [ ] E2E tests cover critical FE to UI workflows through `FE -> UI -> UC -> PD <- SI`
- [ ] Result pattern or explicit error types are used for testable business outcomes

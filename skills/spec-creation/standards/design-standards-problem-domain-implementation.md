---
name: problem-domain-implementation-standards
description: Standards for implementing a rich, encapsulated Problem Domain that owns business behavior, invariants, lifecycle state, and domain-facing contracts without leaking persistence or framework concerns.
scope: Problem Domain, PD, Domain Entities, Value Objects, Rich Domain Model, Domain Implementation
---

# Problem Domain Implementation Standards

## Purpose

This document defines how `PD` code must be written once the domain has been discovered and the architecture boundaries have been established.

This standard complements, but does not replace:

- [design-standards-clean-architecture.md](./design-standards-clean-architecture.md) for layer ownership and dependency rules
- [design-standards-domain-model.md](./design-standards-domain-model.md) for domain discovery, archetypes, and model shape

If this document conflicts with those documents, resolve the conflict by keeping the layer boundaries from clean architecture and the discovery posture from the domain model standard, then fixing this document accordingly.

## Rich Problem Domain vs Anemic Problem Domain

- `[MUST]` treat `PD` types as business objects that own business meaning, state transitions, and business-rule enforcement.
- `[MUST-NOT]` treat `PD` entities as passive property bags whose rules are implemented primarily in `UC`, `UI`, or `SI`.
- `[MUST]` prefer intention-revealing business methods such as `Activate`, `Suspend`, `AddHolding`, `ReplaceAddress`, `RecordSnapshot`, or `ClosePosition` over broad public setters.
- `[MUST]` make illegal states hard to construct and hard to preserve.
- `[SHOULD]` reject designs where most domain behavior appears in handlers, services, repositories, or mappers while the domain classes only expose fields or trivial getters.

## Construction and Invariant Enforcement

- `[MUST]` enforce core invariants at construction time through constructors or named factories.
- `[MUST]` validate required values, range constraints, cross-field consistency, and lifecycle prerequisites at the point where state is created or changed.
- `[MUST-NOT]` allow partially initialized or semantically invalid domain objects to exist merely because later layers promise to fix them up.
- `[MUST]` use explicit factories when construction rules are complex, contextual, or need to communicate business intent better than an overloaded constructor would.
- `[SHOULD]` normalize values during construction when normalization is part of domain meaning, such as trimming codes, canonicalizing symbols, or ordering interval endpoints.

## Entity Rules

- `[MUST]` give each entity a stable identity and clear ownership of its lifecycle.
- `[MUST]` keep entity state private or privately settable and mutate it only through behavior methods that enforce invariants.
- `[MUST]` model lifecycle transitions explicitly through business methods rather than through arbitrary status assignment.
- `[MUST]` keep aggregate consistency rules inside the owning aggregate root or owning entity boundary.
- `[MUST]` let the owning entity control add, remove, reorder, activate, deactivate, and replace operations for its children.
- `[MUST-NOT]` expose mutable child collections for external callers to edit directly.
- `[MUST-NOT]` move entity lifecycle or consistency logic into repository implementations, endpoint handlers, or EF configuration classes.

## Value Object Rules

- `[MUST]` model concepts as value objects when equality is defined by value rather than durable identity.
- `[MUST]` keep value objects immutable once created.
- `[MUST]` place domain-specific arithmetic, comparison, interval logic, normalization, formatting rules, and compatibility checks on the value object when that behavior is part of the concept itself.
- `[MUST]` implement value equality and hash code semantics consistently.
- `[MUST-NOT]` leave rich value concepts as raw primitives when the domain depends on their rules, units, or comparisons.
- `[SHOULD]` prefer small, composable value objects over repeating primitive groups across the domain.

## Controlled Mutation and Encapsulation

- `[MUST]` make state-changing methods intention revealing and business meaningful.
- `[MUST]` validate mutation preconditions before modifying state.
- `[MUST]` protect internal collections with read-only views, snapshots, or purpose-built query methods.
- `[MUST]` keep derived values and cached calculations internally consistent with the source state they depend on.
- `[MUST-NOT]` expose public setters on business-critical state.
- `[MUST-NOT]` allow external callers to bypass business methods by mutating collections, timestamps, statuses, totals, or other invariant-bearing fields directly.
- `[SHOULD]` keep mutation APIs small enough that the allowed state transitions are obvious from the public surface.

## Equality, Hashing, and Identity

- `[MUST]` implement equality semantics deliberately instead of inheriting accidental defaults for important `PD` types.
- `[MUST]` use value equality for value objects.
- `[MUST]` use stable identity-based equality for entities unless a narrower documented rule is required.
- `[MUST]` keep `Equals` and `GetHashCode` consistent with each other.
- `[MUST-NOT]` base equality on mutable fields when doing so would make object identity unstable across its lifetime.
- `[SHOULD]` document any non-obvious equality behavior in XML docs on the type.

## Domain Errors and Failure Semantics

- `[MUST]` represent business-rule failures explicitly through typed domain exceptions or structured domain error results.
- `[MUST]` keep failure messages aligned with business meaning, not transport or persistence jargon.
- `[MUST]` distinguish expected business-rule violations from unexpected technical failures.
- `[MUST-NOT]` scatter opaque string-based rule checks across handlers and helper classes when a typed domain failure belongs in `PD`.
- `[SHOULD]` keep domain failure codes and messages stable enough for `UC` to map them predictably to UC results.

## Documentation Requirements

- `[MUST]` document public `PD` entities, value objects, policies, domain services, and public business methods with XML documentation.
- `[MUST]` describe business meaning, invariants, lifecycle assumptions, and failure conditions when they are not trivial from the signature alone.
- `[MUST]` use domain language from the specifications and model documents rather than technical shorthand.
- `[MUST-NOT]` rely on property names alone to explain important business semantics.
- `[SHOULD]` document why a method exists in business terms, not just what technical mutation it performs.

## Ports and External Capability Usage

- `[MUST]` define all inward-facing persistence, external-service, and capability contracts in `PD`.
- `[MUST]` keep those contracts shaped around domain meaning rather than provider APIs.
- `[MUST]` use the PD-owned ServiceLocator only for PD-owned interfaces and only where domain behavior or UC orchestration genuinely requires it.
- `[MUST-NOT]` use the ServiceLocator as a substitute for putting behavior on the correct domain object.
- `[MUST-NOT]` let `PD` code depend on provider models, SQL types, HTTP payloads, SDK response types, or filesystem/process APIs.
- `[SHOULD]` keep external capability usage narrow, explicit, and testable.

## Persistence and Framework Isolation

- `[MUST]` keep `PD` free of ORM attributes, EF configuration, transport annotations, serializer-driven shape decisions, and infrastructure base classes.
- `[MUST]` design entities and value objects around domain meaning first, then map them to persistence models in `SI`.
- `[MUST-NOT]` put static finders, repository lookups, lazy persistence access, or provider-driven lifecycle hooks directly on `PD` objects.
- `[MUST-NOT]` couple `PD` to framework inheritance hierarchies whose primary purpose is persistence, transport, or runtime plumbing.
- `[SHOULD]` accept persistence friction in `SI` rather than weakening the domain model to fit the persistence tool.

## Domain Services and Policies

- `[MUST]` introduce a domain service or policy only when behavior truly spans multiple domain objects or represents a standalone business rule that does not belong naturally on one entity or value object.
- `[MUST]` keep domain services expressed in business language.
- `[MUST-NOT]` create broad "manager" or "helper" classes that become dumping grounds for misplaced domain logic.
- `[SHOULD]` move behavior back onto entities or value objects when a service exists only because the model was initially too anemic.

## Testing Expectations

- `[MUST]` cover domain invariants, state transitions, equality rules, and failure cases with focused `PD` tests.
- `[MUST]` test domain behavior without real database, HTTP, filesystem, or process dependencies.
- `[MUST]` verify both successful transitions and rejected transitions.
- `[SHOULD]` organize tests around business scenarios and method intent rather than around private implementation details.

## Anti-Patterns and Review Smells

- `[MUST-NOT]` accept the following as normal `PD` implementation patterns:
  - entities with mostly public setters
  - handlers performing business-rule checks that should live on the domain object
  - mutable collections returned directly from entities
  - status fields changed freely from outside the owning object
  - primitive obsession for important money, quantity, interval, identifier, classification, or percentage concepts
  - duplicated invariant checks across multiple handlers or adapters
  - domain classes that know about EF, SQL, JSON, HTTP, SDKs, or file formats
- `[SHOULD]` treat these smells as a trigger to redesign the domain surface before adding more handlers or infrastructure code.

## Patterns To Emulate From Rich Domain Examples

- `[SHOULD]` emulate private state with explicit business methods.
- `[SHOULD]` emulate constructor or factory validation that blocks invalid objects early.
- `[SHOULD]` emulate rich value-object behavior with explicit comparison and domain operations.
- `[SHOULD]` emulate deliberate equality and hashing semantics.
- `[SHOULD]` emulate thorough documentation of business meaning and behavior.

---

## Completion Checklist

- [ ] Public PD types expose business behavior, not just data
- [ ] Construction and mutation enforce invariants at the point of change
- [ ] Entities do not expose mutable internal collections
- [ ] Value objects implement deliberate value semantics
- [ ] Equality and hashing rules are explicit and stable
- [ ] PD types are free of ORM, transport, and provider concerns
- [ ] Domain failures are explicit and meaningful
- [ ] XML docs explain business meaning and lifecycle assumptions
- [ ] Domain services exist only where behavior genuinely spans objects
- [ ] The resulting model is rich, encapsulated, and not anemic

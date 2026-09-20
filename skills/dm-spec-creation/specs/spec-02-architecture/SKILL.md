---
name: spec-02-architecture
description: Architecture grilling workflow for dm-spec-creation spec-02, including conditional spec-02x sidecars. Agent-only sub-skill invoked by the dm-spec-creation orchestrator to define layering, boundaries, persistence shape, and deployment on the canonical stack. Do not invoke directly; invoke dm-spec-creation instead.
user-invocable: false
---

# Sub-Skill: spec-02 Architecture

<standards-inputs>
- standards/design-standards-clean-architecture.md
- standards/design-standards-problem-domain-implementation.md
- standards/coding-standards-csharp.md
- standards/coding-standards-aspnet.md
- standards/coding-standards-aspire.md
- standards/coding-standards-efcore.md
- standards/coding-standards-sql.md
- standards/coding-standards-rest-api.md
- standards/coding-standards-typescript.md
- standards/coding-standards-react.md
</standards-inputs>

<inputs-from-prior-specs>
- spec-00-functional-prd.md
- spec-01-domain-model.md (immutable; reference, do not redefine)
</inputs-from-prior-specs>

<purpose>
Define the architectural shape — layering, slicing, boundary contracts, deployment topology, cross-cutting concerns — that realizes spec-01's domain model and satisfies spec-00's non-functional posture, anchored on the **canonical stack** in [../../STACK-DEFAULTS.md](../../STACK-DEFAULTS.md).
</purpose>

<grilling-sequence>

### Phase A — Stack confirmation (NOT stack selection)

For each row in [../../STACK-DEFAULTS.md](../../STACK-DEFAULTS.md) §"The default stack", ask: **"Confirm default or declare a deviation?"** One row at a time. The defaults are:

- Backend: C# + ASP.NET Core Minimal APIs + .NET Aspire (AppHost + ServiceDefaults)
- Persistence: EF Core on a relational store; code-first migrations
- API: REST + JSON
- Frontend: TypeScript (strict) + React + Vite + shadcn/ui + Tailwind
- Architecture: Clean Architecture, FE/UI/UC/PD/SI layering per `standards/design-standards-clean-architecture.md`
- Build planning: inside-out phased execution per `standards/planning-standards-inside-out-phases.md`
- Solution layout: `src/` runtime projects + peer `tests/`; Aspire AppHost composes; mockups under `01-specifications/screen-mockups/`

1. For each confirmed default, write a one-line statement in spec-02 §Stack citing the governing standards file. No decisions-log entry required (defaults are pre-decided).
2. For each deviation, log a `standards-deviation` entry in `decisions.md` with alternatives considered, the standard rule overridden, and the consequence. Then write the deviation into spec-02 §Stack with explicit rationale.
3. Reject deviations that have no rationale beyond preference.

### Phase B — Architectural style

4. Default: Clean Architecture with FE / UI / UC / PD / SI layering per `standards/design-standards-clean-architecture.md`. Confirm this realizes spec-01's module shape; if not, surface the mismatch and either re-shape spec-01 (re-run its gate) or deviate.
5. Define how spec-01 modules map to .NET projects under `src/`. Forbid any mapping that violates spec-01's dependency direction. Confirm the project naming follows `<Solution>.<Module>` per repo convention.

### Phase C — Boundary contracts

6. For every outgoing boundary (UI, external API, data store, message bus, file system, time), define the abstraction shape and which module owns it.
7. For every inbound boundary, define the contract surface (HTTP endpoints, CLI, scheduled jobs, etc.) at the **shape** level — not the field level (that's spec-05).

### Phase D — Cross-cutting concerns

8. Logging, telemetry, error handling, validation, authn/authz, configuration, secrets — for each, define ownership, mechanism class (e.g. "structured logging"), and where it crosses module boundaries.

### Phase E — Persistence shape

9. For each pink/green that spec-01 says is remembered, define the storage class (relational, document, blob, ephemeral). Forbid leaking persistence concerns into spec-01.
10. Define transactional boundaries in terms of pink moment-intervals, not technical aggregates.

### Phase F — Deployment topology

11. Define processes/services, their hosts, their communication shape, and their lifecycle.
12. Define environments (dev, test, prod) and how config differs.

### Phase G — Non-functional realization

13. For every NFR from spec-00 §non-functional posture, name the architectural mechanism that satisfies it.

### Phase H — Architecture sidecar identification (spec-02x family)

14. Walk the architecture once it is drafted. For each module from spec-01 and each significant technical slice (e.g. data download, data import, durable jobs, source-adapter contracts, projection pipelines), ask: **"Does this slice carry enough normative technical contract — lifecycle rules, idempotency, ordering, lineage, scope keys — to make base spec-02 too large or too implementation-shaping to stay coherent?"** Recommend a sidecar when any of these apply:
    - The slice has ≥3 distinct invariants the implementation agent must respect literally (not just architectural intent).
    - The slice owns a contract surface (e.g. `Schedule*`/`Execute*` ports) that downstream spec-06 Phases need to anchor against precisely.
    - Folding the slice into base spec-02 would push that document past coherent comprehension or would mix system-wide architecture with module-private detail.
15. For each recommended sidecar, capture: file name (`spec-02a-<slice>.md`, `spec-02b-<slice>.md`, … assigned in creation order), bounded scope (one or two sentences), authority boundary ("this sidecar narrows base spec-02 §… for the … slice; it MUST NOT contradict spec-01 or base spec-02 §…"), and the subset of standards it loads beyond the base spec-02 set.
16. Add a `Sidecar Index` section to base spec-02 listing every sidecar file, slice, authority boundary, and the spec-02 anchors it narrows. Sidecars referenced from base spec-02 MUST exist; sidecars existing on disk but missing from the index FAIL the spec-02 family gate.
17. For each sidecar:
    - draft from [../../templates/spec-02x-technical-spec.template.md](../../templates/spec-02x-technical-spec.template.md);
    - add inline HTML anchors (`<a id="kebab-slug"></a>`) on every `##` and `###` heading so spec-06 Phases can cite `spec-02a#anchor-id`, `spec-02b#anchor-id`, …;
    - run [../../gates/spec-02x-sidecar-gate.md](../../gates/spec-02x-sidecar-gate.md);
    - log any decisions in `decisions.md`; sidecar-introduced terms MUST already be in spec-01 §Glossary, or a glossary update is logged.
18. Sidecars are **conditional but formal**. A solution with no qualifying slices emits zero sidecars and proceeds to spec-03 with the spec-02 family equal to base spec-02 alone. A solution with sidecars MUST pass every sidecar gate before spec-03 may begin.

</grilling-sequence>

<writing-rules>
- No code. No file paths inside source projects. No method signatures.
- Every architectural choice cites a standards rule or a logged decision.
- Every spec-01 module must appear in the project map.
- Every spec-01 pink that is remembered must appear in the persistence shape.
</writing-rules>

<exit-checklist>
- [ ] Every default in STACK-DEFAULTS.md is either confirmed in spec-02 §Stack or has a `standards-deviation` entry in decisions.md.
- [ ] Project/package map honors spec-01 dependency direction.
- [ ] Every boundary has an abstraction shape and an owning module.
- [ ] Every NFR from spec-00 has a realization mechanism.
- [ ] Persistence shape covers every remembered concept from spec-01.
- [ ] Sidecar identification pass (Phase H) is complete; base spec-02 §Sidecar Index lists every emitted sidecar with file name, slice, and authority boundary.
- [ ] Every emitted sidecar is drafted from the sidecar template, anchored on every heading, and has passed [../../gates/spec-02x-sidecar-gate.md](../../gates/spec-02x-sidecar-gate.md).
- [ ] No sidecar contradicts spec-01 or base spec-02; any narrowing is explicit.
- [ ] decisions.md has entries only for deviations and genuine architectural trade-offs (including the rationale for each emitted sidecar); implementation-decisions.md is empty or only has stack-tactical entries.
</exit-checklist>

# Gate: spec-02 Architecture

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty.
2. Every default in [../STACK-DEFAULTS.md](../STACK-DEFAULTS.md) §"The default stack" is either confirmed in spec-02 §Stack OR has a corresponding `standards-deviation` entry in `decisions.md`.
3. Every spec-01 module appears in the project/package map.
4. Project/package map honors spec-01 dependency direction; no cycle.
5. Every outbound and inbound boundary has: abstraction shape, owning module.
6. Cross-cutting concerns section covers: logging, telemetry, error handling, validation, authn/authz, configuration, secrets.
7. Every spec-01 pink/green flagged as remembered appears in the persistence shape with a storage class.
8. Every spec-00 NFR is paired with an architectural realization mechanism.
9. Deployment topology section defines processes, hosts, comms, lifecycle, environments.
10. No method signatures, no source-file paths, no code blocks beyond high-level shape diagrams.
11. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).
12. §9 Sidecar Index is present. If any `01-specifications/spec-02[a-z]-*.md` files exist on disk they MUST be listed; every listed sidecar MUST exist on disk; every listed sidecar MUST have a passing `<!-- gate-result: PASS ... -->` block from [spec-02x-sidecar-gate.md](./spec-02x-sidecar-gate.md). Discrepancy in either direction FAILs this gate and re-opens the spec-02 family.
13. No sidecar listed in §9 contradicts spec-01 or any other section of base spec-02 (terms, dependency direction, persistence shape). Contradictions FAIL the gate.

## Rubric (1–5, pass bar ≥4)

- **Stack-domain fit** — chosen stack realistically supports spec-01's shape.
- **Boundary clarity** — every boundary is named, owned, shaped.
- **NFR realization** — every spec-00 NFR has a credible mechanism.
- **Standards alignment** — architecture cites `standards/design-standards-clean-architecture.md` and `standards/design-standards-problem-domain-implementation.md`; any deviation is logged.
- **Domain protection** — persistence and transport concerns do not leak into spec-01.
- **Topology completeness** — deployment, environments, and lifecycle are explicit.
- **Sidecar discipline** — sidecars are emitted only when justified by Phase H criteria; each has a clear authority boundary; none duplicates or fights base spec-02.

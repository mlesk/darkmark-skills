# Gate: spec-03 Implementation Guidance

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty.
2. §0 Upstream Architecture Sidecars Consumed is present. If any `01-specifications/spec-02[a-z]-*.md` files exist they MUST be listed, with the anchors spec-03 inherits from each (or the section MUST contain the literal text "none" if no sidecars exist).
3. No spec-03 convention contradicts a constraint or invariant from any active spec-02x sidecar. Contradictions FAIL the gate — the resolution is to re-open the spec-02 family, not patch spec-03.
4. Top-level folder structure maps every spec-02 project.
5. Every `coding-standards-*.md` matched to the stack has been walked rule-by-rule; for each `[MUST]` the spec captures its project-specific instantiation.
6. Every `[SHOULD]` from those standards is either adopted, elevated to `[MUST]` for this project, or rejected with rationale logged in `implementation-decisions.md`.
7. Error model section names exception classes vs. result types vs. validation results AND maps each to a boundary class.
8. Validation strategy specifies three layers: domain invariants, boundary validation, UI validation.
9. Testing section defines domain, integration, end-to-end, and architecture tests with framework, location, naming, assertion scope.
10. DI/composition section names composition root and lifetime rules.
11. Configuration section names sources, override order, secret storage, per-environment variation.
12. Persistence mapping section covers every spec-01-remembered concept identified in spec-02.
13. Async/concurrency posture explicitly stated.
14. Linter/formatter/analyzer policy named.
15. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).

## Rubric (1–5, pass bar ≥4)

- **Convention enforceability** — every convention is checkable by tooling or by a clear reviewer rubric.
- **Standards coverage** — every relevant standards file's rules are addressed.
- **Layering integrity** — conventions preserve spec-02 boundaries and spec-01 domain model.
- **Test rigor** — test pyramid is real, not nominal.
- **Operational readiness** — config, secrets, errors, observability are concrete enough to implement.
- **Decision provenance** — every tactical choice has an `implementation-decisions.md` entry.

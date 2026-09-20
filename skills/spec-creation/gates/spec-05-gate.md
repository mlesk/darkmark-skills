# Gate: spec-05 App Use Cases

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty.
2. Every use case is named in `Verb the Object` form.
3. Every use case has all 13 fields: trigger, inbound boundary, input shape, preconditions, steps, postconditions, output shape, error outcomes, authorization rule, idempotency posture, concurrency posture, observability, (and for API-exposed) contract shape.
4. Every spec-00 acceptance criterion is satisfied by at least one named use case.
5. Every spec-04 UI action maps to exactly one use case.
6. Every spec-01 pink with a lifecycle transition has a use case that performs it.
7. Every input/output field uses a spec-01 term or is an explicit primitive.
8. Every error outcome is named and mapped to spec-03's error model class AND a spec-04 UI feedback location.
9. No use case contains business rules that belong to spec-01 (orchestration only).
10. decisions.md / implementation-decisions.md have entries for authorization and idempotency/concurrency mechanisms.
11. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).

## Rubric (1–5, pass bar ≥4)

- **Coverage** — acceptance criteria, UI actions, lifecycle transitions all covered.
- **Orchestration purity** — use cases coordinate; they do not redefine domain rules.
- **Error explicitness** — no "something went wrong"; every error has a name and a handling location.
- **Concurrency honesty** — idempotency and concurrency posture stated, not hand-waved.
- **Contract fidelity** — API-exposed contracts align with spec-03 naming conventions.
- **Observability** — every use case names what is logged and metered.

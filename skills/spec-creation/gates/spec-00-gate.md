# Gate: spec-00 Functional PRD

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty (no `TBD`, no `TODO`).
2. ≥5 explicit out-of-scope items.
3. Every `core` capability has ≥2 acceptance criteria in `Given/When/Then` form.
4. Every objective traces to ≥1 acceptance criterion (verify by name match).
5. No forbidden technical term appears anywhere (literal deterministic word list, case-insensitive, whole-word where applicable): `database`, `API`, `ORM`, `framework`, `class`, `service`, `repository`, `endpoint`, `table`, `schema`, `library`, `EF`, `React`, `component` (React sense). (Open-ended "any named product/library" is enforced as a rubric dimension below, not here — see **Tech-neutrality**.)
6. Every workflow step is user-meaningful (no "the system serializes…").
7. decisions.md has entries for: scope split, single-vs-multi-user posture, audit posture, performance posture, freshness expectations.
8. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).

## Rubric (1–5, pass bar ≥4)

- **Clarity** — could a domain expert outside the conversation read this and agree it describes the product?
- **Completeness** — every capability has trigger, inputs, outputs, success criteria.
- **Measurability** — every objective is observable or measurable.
- **Tech-neutrality** — zero implementation leakage. Specifically: no named products, libraries, frameworks, vendors, protocols, file formats, or wire formats appear anywhere in the spec. A 5 means a reader cannot infer the implementation stack; a 1 means the spec reads like an architecture doc. Flag every named product/library/protocol/format as evidence at the score you assign.
- **Traceability** — acceptance criteria cover all objectives.
- **Scope discipline** — out-of-scope list is honest and specific.

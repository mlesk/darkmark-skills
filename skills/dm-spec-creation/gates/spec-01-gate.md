# Gate: spec-01 Domain Model

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty.
2. Modules listed with explicit dependency direction; graph is acyclic.
3. Every class has: archetype color, identity, responsibility, collaborators.
4. Every pink (moment-interval) has: lifecycle/status, start/finish semantics, mi-details list.
5. Every yellow (role) names both its role-status semantics AND the green it roles for.
6. Every blue (description) names what it describes and what consults it.
7. Glossary covers every term used anywhere in this spec AND every noun in spec-00 §user-visible object model.
8. Derived concepts are marked, with business-language derivation rules.
9. Coupling review section exists and identifies zero unjustified Law-of-Demeter violations (or justifies each).
10. Words `aggregate`, `aggregate root` do not appear (except possibly in a "we do not use this term" disambiguation note).
11. Words `database`, `repository`, `EF`, `DTO`, `JSON`, `HTTP`, `SQL`, `service` (in DI sense) do not appear.
12. decisions.md has entries for: module split, exclusions, any standards deviation.
13. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).

## Rubric (1–5, pass bar ≥4)

- **Archetype discipline** — colors correctly applied per `design-standards-domain-model.md`.
- **Business fidelity** — every pink, yellow, blue, green traces to spec-00 capability or workflow.
- **Coupling shape** — module dependencies and Demeter rules are explicit and respected.
- **Glossary precision** — definitions are crisp; disambiguations are present where terms overlap.
- **Implementation-neutrality** — zero leakage into persistence, transport, or hosting concerns.
- **Derived-concept honesty** — derived vs. remembered is consistent with spec-00.

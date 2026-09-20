# Gate: spec-04 User Interface

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure.

## Structural checklist

1. All template sections present and non-empty.
2. Every spec-00 `core` capability is reachable via at least one screen (or explicitly marked headless with rationale logged).
3. Every screen specifies: purpose, served capabilities, surfaced domain concepts, primary content blocks, user actions, empty state, loading state, partial-data state, error state, validation feedback locations, confirmation/destructive-action handling.
4. Navigation model and (if applicable) route shape defined.
5. Component vocabulary listed with design-system source named.
6. Accessibility target (WCAG level) and keyboard/focus contract stated.
7. Responsive breakpoints and per-screen behavior defined.
8. Every UI term maps to a spec-01 glossary entry (verify by lookup).
9. Mockup-scaffold decision logged in `decisions.md`.
10. No screen invents domain terms not present in spec-01.
11. Every `##` and `###` heading carries an inline HTML anchor of the form `<a id="kebab-slug"></a>` so downstream specs (esp. spec-06 `spec-anchors:`) can reference sections stably (per `standards/planning-standards-inside-out-phases.md` §4a).

## Rubric (1–5, pass bar ≥4)

- **Capability coverage** — capabilities map cleanly to screens.
- **State completeness** — every screen has all four interaction states explicitly.
- **Term consistency** — UI vocabulary equals spec-01 vocabulary.
- **Accessibility intent** — target and contract are concrete.
- **Design-system clarity** — component vocabulary is grounded in a named system.
- **Use-case readiness** — every action is shaped so spec-05 can define its use case.

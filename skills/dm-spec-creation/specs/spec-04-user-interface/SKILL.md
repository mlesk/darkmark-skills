---
name: spec-04-user-interface
description: User-interface grilling workflow for dm-spec-creation spec-04. Agent-only sub-skill invoked by the dm-spec-creation orchestrator to define screens, navigation, interaction states, and mockup scaffolding. Do not invoke directly; invoke dm-spec-creation instead.
user-invocable: false
---

# Sub-Skill: spec-04 User Interface

<standards-inputs>
- standards/coding-standards-react.md
- standards/coding-standards-typescript.md
</standards-inputs>

<stack-defaults>
Frontend stack is fixed per [../../STACK-DEFAULTS.md](../../STACK-DEFAULTS.md): TypeScript (strict) + React + Vite + shadcn/ui + Tailwind. Mockups live under `01-specifications/screen-mockups/` and follow the existing scaffold in this repo.
</stack-defaults>

<inputs-from-prior-specs>
- spec-00 (capabilities, workflows, acceptance criteria)
- spec-01 (domain glossary; terms used in UI must match)
- spec-02 (UI stack; boundary contracts UI consumes)
- spec-03 (UI implementation conventions)
</inputs-from-prior-specs>

<purpose>
Define the user interface: screens/views, navigation model, information architecture, interaction states, empty/loading/error states, key components, accessibility posture, and (optionally) a runnable Vite/shadcn mockup scaffold.
</purpose>

<grilling-sequence>

### Phase A — IA & navigation

1. List every screen/view. For each: purpose, the spec-00 capabilities it serves, the spec-01 concepts it surfaces.
2. Define the navigation model (top-level sections, modals, drawers, drill-downs).
3. Define route shape if applicable.

### Phase B — Per-screen specification

For each screen, capture: 4. Primary content blocks and their data shape (referencing spec-01 by canonical term). 5. User actions available and the spec-00 workflow step each advances. 6. Empty state, loading state, partial-data state, error state — all four for every screen. 7. Validation feedback locations. 8. Confirmation/destructive-action handling.

### Phase C — Component vocabulary

9. Default design-system source: shadcn/ui + Tailwind. Define the reusable component vocabulary (cards, tables, filters, status badges, etc.) drawn from that source. Any custom component requires a one-line justification.

### Phase D — Accessibility & responsiveness

10. Target WCAG level (default WCAG 2.2 AA — confirm or deviate). Keyboard navigation contract. Focus management rules.
11. Breakpoints and responsive behavior for each screen (default Tailwind breakpoints sm/md/lg/xl).

### Phase E — Mockup scaffolding (default ON)

12. Default: scaffold a runnable Vite + shadcn mockup app under `01-specifications/screen-mockups/` matching this repo's existing scaffold. Confirm which screens are mocked and at what fidelity (sketch / interactive / data-bound). Opting out requires a `standards-deviation` decision entry.

### Phase F — Cross-checks

13. Every spec-00 capability has at least one screen that exposes it (or is explicitly headless with rationale).
14. Every term shown in the UI maps to a spec-01 glossary entry.
15. Every UI action maps to a future spec-05 use case.

</grilling-sequence>

<writing-rules>
- UI terms = spec-01 terms. No drift.
- Every screen specifies all four interaction states (empty, loading, partial, error).
- No implementation code in the markdown — code lives in the mockup scaffold if elected.
</writing-rules>

<exit-checklist>
- [ ] Every spec-00 capability is reachable via the IA.
- [ ] Every screen has the four interaction states specified.
- [ ] Component vocabulary listed with design-system source.
- [ ] Accessibility target named.
- [ ] Glossary cross-check passes (no UI-only terms).
- [ ] Mockup scaffold decision logged.
</exit-checklist>

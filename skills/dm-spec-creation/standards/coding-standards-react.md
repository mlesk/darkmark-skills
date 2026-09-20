<!-- markdownlint-disable MD041 -->

> **Agent instruction:** These rules are MANDATORY for all React frontend code in this workspace. Any implementation involving React UI, TanStack Router, TanStack Query, TanStack Table, TanStack Form, TanStack Select, or shadcn/ui must follow this document. Rules marked `[MUST]` are hard requirements; `[PREFER]` indicates strong preference. When rules conflict, the more specific rule wins.

**Required skills:** `react-tanstack-router`, `react-best-practices`, `shadcn`

**Required libraries:** `TanStack Query`, `TanStack Table`, `TanStack Form`, `TanStack Select`

---

## 1. Skill And Library Dependency Contract

These standards depend on active use of the following skills and libraries. Do not treat them as optional references.

### Required Skills

1. `react-tanstack-router`
   - Use for route structure, file-based routing, loaders, route context, navigation, search params validation, preloading, and TanStack Query integration.
1. `react-best-practices`
   - Use for React performance, avoiding waterfalls, rerender control, bundle discipline, effect minimization, and correct translation of generic React guidance into this stack.
1. `shadcn`
   - Use for component selection, composition, styling rules, forms, icons, accessibility expectations, and CLI-based component workflows.

### Required Libraries

1. `TanStack Query`
   - Use for asynchronous server-state fetching, caching, mutations, invalidation, optimistic updates, and prefetching.
2. `TanStack Table`
   - Use for data-dense tables, ledgers, market grids, sortable/filterable lists, row selection, and column-management behavior.
3. `TanStack Form`
   - Use for validated multi-field form state, submission flow, reset behavior, and reusable field-level validation logic.
4. `TanStack Select`
   - Use for advanced select, multi-select, autocomplete, and searchable option-picking controls.

### Invocation Rules

- `[MUST]` Consult all three skills before implementing a non-trivial React frontend feature.
- `[MUST]` Use `react-tanstack-router` whenever a change touches routes, layouts, navigation, loaders, route guards, URL state, or route-level data fetching.
- `[MUST]` Use `react-best-practices` whenever building, reviewing, or refactoring React components, hooks, async flows, or client-side state management.
- `[MUST]` Use `shadcn` whenever adding, modifying, selecting, or composing UI components, forms, overlays, navigation elements, icons, or design tokens.
- `[MUST]` Use TanStack Query whenever a change touches async server reads or writes, cache lifecycles, optimistic updates, invalidation, or prefetching.
- `[MUST]` Use TanStack Table whenever a screen needs sortable, filterable, pinnable, selectable, grouped, or visibility-managed tabular state.
- `[MUST]` Use TanStack Form whenever a workflow involves coordinated multi-field validation, staged editing, or reusable field logic beyond trivial local inputs.
- `[MUST]` Use TanStack Select whenever a workflow needs searchable select, multi-select, autocomplete, or async option loading behavior.
- `[MUST]` When implementing TanStack Query flows inside routed pages, apply `react-tanstack-router` and `react-best-practices` together.
- `[MUST]` When building routed, data-dense screens, apply the required skills together with the relevant TanStack libraries instead of mixing in bespoke state pipelines.
- `[PREFER]` Cite the skill-derived pattern in your implementation notes or PR summary when a decision is non-obvious.

---

## 2. Core Stack Rules

- `[MUST]` Use TypeScript for all React frontend code.
- `[MUST]` Keep React code compatible with the project's chosen routing, data-fetching, and component-library stack rather than introducing parallel patterns.
- `[MUST]` Use TanStack Router for application routing. Do not introduce React Router or ad hoc client-side routing patterns.
- `[MUST]` Use TanStack Query for server-state fetching, caching, invalidation, and mutations. Do not replace it with bespoke fetch state management.
- `[MUST]` Use TanStack Table for data-intensive table and grid behavior. Do not hand-roll sorting, filtering, pagination, selection, or column-state plumbing when TanStack Table fits the screen.
- `[MUST]` Use TanStack Form for complex validated forms. Do not replace it with ad hoc reducer-driven form state plus manual validation maps when TanStack Form fits the workflow.
- `[MUST]` Use TanStack Select as the default advanced select/autocomplete primitive. Do not build custom searchable select controls from scratch when TanStack Select fits the interaction.
- `[MUST]` Use shadcn/ui components and composition patterns as the default UI building blocks.
- `[MUST]` Prefer extending or composing existing patterns over introducing new architectural conventions.
- `[PREFER]` Keep feature code cohesive: route definitions in route files, query definitions near feature data access, and presentational UI inside feature components.

---

## 3. React Component Standards

- `[MUST]` Keep components focused on a single responsibility.
- `[MUST]` Derive view state during render when it can be computed from props, loader data, query data, or existing state.
- `[MUST]` Avoid using `useEffect` for logic that belongs in event handlers, route loaders, or TanStack Query.
- `[MUST]` Avoid fetching server state inside `useEffect` when the data can be provided by a loader or TanStack Query.
- `[MUST]` Use semantic, descriptive names for components, hooks, handlers, and state.
- `[MUST]` Prefer controlled composition over deeply nested prop drilling when building reusable UI sections.
- `[PREFER]` Split large screens into route shell, data boundary, and presentational sections.
- `[PREFER]` Use `startTransition` or `useDeferredValue` for non-urgent UI updates when it improves responsiveness.
- `[PREFER]` Avoid blanket `useMemo` and `useCallback`; only introduce them when a measured rerender or identity problem exists.

### State Rules

- `[MUST]` Distinguish clearly between server state, route state, form state, and ephemeral UI state.
- `[MUST]` Store server state in TanStack Query, not local component state.
- `[MUST]` Store URL-driven filters, pagination, sorting, and view state in TanStack Router search params when they affect navigation, linking, or reloadability.
- `[MUST]` Store coordinated multi-field form state in TanStack Form rather than duplicating it across component-local state variables.
- `[MUST]` Keep transient UI-only state local unless multiple branches truly share it.
- `[PREFER]` Use functional state updates when the next value depends on the previous value.

---

## 4. TanStack Router Standards

- `[MUST]` Use file-based routing patterns provided by TanStack Router.
- `[MUST]` Register router types correctly and preserve end-to-end type safety.
- `[MUST]` Validate route search params with a schema-based validator such as Zod.
- `[MUST]` Use `Route.useLoaderData()`, `Route.useParams()`, and related route-scoped APIs instead of unscoped hook usage when route types are available.
- `[MUST]` Prefer loaders for route-critical data preparation, redirects, guards, and pre-render orchestration.
- `[MUST]` Implement auth and access control in route lifecycle boundaries such as `beforeLoad`, not as late client-side patches inside components.
- `[MUST]` Keep route files responsible for route concerns only: route declaration, validation, loader wiring, guards, and top-level screen composition.
- `[PREFER]` Use nested routes and layout routes to reflect the product information architecture instead of conditional mega-components.
- `[PREFER]` Use preloading and code-splitting for heavier route branches.

### URL State Rules

- `[MUST]` Put shareable, bookmarkable, or restorable screen state in the URL.
- `[MUST]` Validate and normalize URL state at the route boundary.
- `[MUST]` Avoid reading raw search params throughout leaf components; prefer a validated route contract.

---

## 5. TanStack Query Standards

- `[MUST]` Use TanStack Query for all asynchronous server-state reads and writes unless there is a clear documented exception.
- `[MUST]` Centralize query options, keys, and fetch functions in feature-level query modules or equivalent stable locations.
- `[MUST]` Use stable, explicit query keys that encode the actual cache identity.
- `[MUST]` Prefer route loaders that call `queryClient.ensureQueryData(...)` for route-entry data that should be ready before render.
- `[MUST]` Use mutations for writes and explicitly handle optimistic updates, invalidation, or cache updates where required.
- `[MUST]` Model loading, empty, error, and success states intentionally; do not leave server-state transitions implicit.
- `[MUST]` Avoid duplicate requests caused by component-level fetch orchestration when a shared query can own the data.
- `[PREFER]` Prefetch likely next-screen data when navigation intent is clear.
- `[PREFER]` Keep query select/transform logic close to the query definition when it improves reuse and consistency.

### Query Anti-Patterns

- `[MUST NOT]` Fetch data in both a route loader and a component for the same cache key unless the duplication is deliberate and documented.
- `[MUST NOT]` Use ad hoc `fetch` plus local `isLoading` or `error` state for server data that belongs in TanStack Query.
- `[MUST NOT]` Use overly broad invalidation when a targeted cache update is practical.

---

## 6. TanStack Table Standards

- `[MUST]` Define columns, headers, cell renderers, and table capabilities from TanStack Table column definitions as the single source of truth.
- `[MUST]` Drive sorting, filtering, column visibility, row selection, expansion, and pinning through TanStack Table state instead of parallel bespoke state objects.
- `[MUST]` Keep table state controlled when it must coordinate with route state, query state, or sibling panels.
- `[MUST]` Push shareable table state such as sorting, filters, pagination, or visible analytical modes into TanStack Router search params when the view must survive refresh, linking, or operator handoff.
- `[PREFER]` Keep domain mapping outside cell renderers; renderers should format prepared row data rather than reconstruct business objects.

### Table Anti-Patterns

- `[MUST NOT]` Re-implement generic row-model behaviors with ad hoc arrays and `useState` when TanStack Table already provides the capability.
- `[MUST NOT]` Scatter table state ownership across unrelated leaf components.

---

## 7. TanStack Form Standards

- `[MUST]` Use TanStack Form as the owner of values, dirty state, touched state, validation, and submit lifecycle for complex forms.
- `[MUST]` Keep field validation rules close to the form model so the validation contract is explicit and reusable.
- `[MUST]` Integrate TanStack Form with TanStack Query mutations by letting the form own input state and the mutation own the server write.
- `[MUST]` Adapt TanStack Form fields into shadcn form primitives through reusable field wrappers or adapters instead of re-wiring every field by hand.
- `[PREFER]` Use form-level defaults and reset behavior to support docked-editor and staged-edit workflows consistently.

### Form Anti-Patterns

- `[MUST NOT]` Mirror TanStack Form field values into separate component state unless a narrow, documented UI-only concern requires it.
- `[MUST NOT]` Mix unrelated manual validation maps, reducer state, and TanStack Form ownership in the same workflow.

---

## 8. TanStack Select Standards

- `[MUST]` Use TanStack Select for searchable selects, autocompletes, multi-selects, and async option pickers that need robust keyboard and focus behavior.
- `[MUST]` Keep option identity stable and type-safe; map domain entities into explicit option models instead of passing raw, ambiguous objects through the control.
- `[MUST]` Integrate TanStack Select with TanStack Form fields through shared adapters when the select participates in a form workflow.
- `[MUST]` Use shadcn styling and layout wrappers around TanStack Select where needed, but keep advanced selection semantics owned by the select library.
- `[PREFER]` Centralize repeated option formatting and filtering behavior for domain-specific pickers.

### Select Anti-Patterns

- `[MUST NOT]` Rebuild custom combobox or autocomplete controls for repeated workflows that TanStack Select can already handle.
- `[MUST NOT]` Store duplicate open-state, highlighted-option state, or selected-option state outside the select abstraction without a documented coordination need.

---

## 9. shadcn/ui Standards

- `[MUST]` Use existing shadcn/ui components before creating custom styled markup.
- `[MUST]` Compose UI from the library's intended primitives rather than partially re-implementing them.
- `[MUST]` Use built-in variants, semantic tokens, and project-defined theme tokens instead of raw color utility values for component styling.
- `[MUST]` Follow the library's accessibility composition requirements, including titles for dialogs, sheets, and drawers.
- `[MUST]` Utilize this preset as the basis for component styling `--preset aIRvSE`
- `[MUST]` Use `cn()` for conditional classes when the existing UI utilities expect it.
- `[MUST]` Use `gap-*` layout patterns instead of `space-x-*` or `space-y-*`.
- `[MUST]` Prefer `size-*` when width and height are equal.
- `[MUST]` Use library-provided components for alerts, empty states, badges, separators, skeletons, and toasts when available.
- `[MUST]` Follow the project's icon-library and import conventions instead of assuming default icon packages.
- `[PREFER]` Inspect installed components and shadcn docs before adding new components.

### Forms

- `[MUST]` Build forms using the shadcn form composition rules active in the project.
- `[MUST]` Represent validation and disabled states using the component library's expected attributes and structure.
- `[MUST]` Use the appropriate grouped form primitives for related controls rather than hand-rolled layout wrappers.

---

## 10. Performance And Rendering Rules

- `[MUST]` Eliminate avoidable waterfalls by starting independent async work early and awaiting it as late as correctness allows.
- `[MUST]` Prefer parallel fetching for independent data requirements.
- `[MUST]` Avoid rerenders caused by broad subscriptions when a derived boolean or narrower selected value is sufficient.
- `[MUST]` Avoid effect-driven derived state when the value can be computed during render.
- `[MUST]` Avoid duplicating state ownership across TanStack Router, Query, Table, Form, and Select; each concern should have one primary owner.
- `[MUST]` Use route-level code splitting, `React.lazy`, or equivalent lazy-loading patterns for heavy screens when it materially improves bundle cost.
- `[MUST]` Avoid barrel-import-heavy hot paths when direct imports are clearer and lighter.
- `[PREFER]` Defer non-critical third-party code until after the primary experience is interactive.
- `[PREFER]` Use skeletons, suspense boundaries, and intentional pending states instead of blank loading gaps.

---

## 11. Accessibility And UX Rules

- `[MUST]` Preserve semantic HTML even when composing through component abstractions.
- `[MUST]` Ensure keyboard navigation works for dialogs, menus, tabs, forms, and other interactive controls.
- `[MUST]` Provide accessible labels, descriptions, and error messaging for form controls.
- `[MUST]` Preserve keyboard, focus, and announcement behavior when composing TanStack Form and TanStack Select with shadcn wrappers.
- `[MUST]` Ensure loading and mutation states are visible and understandable.
- `[MUST]` Ensure destructive actions are clearly distinguished and confirmed when risk warrants it.
- `[PREFER]` Use consistent empty, loading, and error-state patterns across feature areas.

---

## 12. Implementation Workflow

### Before Coding

- `[MUST]` Identify whether the task affects routing, server state, tabular state, form state, advanced selection controls, UI composition, or multiple layers.
- `[MUST]` Read the relevant sections of `react-tanstack-router`, `react-best-practices`, and `shadcn` before coding, then apply the matching TanStack library standards for the feature slice.
- `[MUST]` Reuse established route, query, and UI patterns from the codebase where they exist.

### During Coding

- `[MUST]` Keep route concerns, query concerns, table concerns, form concerns, select concerns, and UI concerns separated even when implemented in the same feature.
- `[MUST]` Preserve type safety across route params, search params, loader data, query data, and component props.
- `[MUST]` Prefer the smallest change that aligns the implementation with the stack conventions.

### Before Completion

- `[MUST]` Verify the implementation follows the required skills rather than merely compiling.
- `[MUST]` Check for routing consistency, query cache correctness, table-state ownership, form validation and submission flow, select accessibility, loading and error-state completeness, and shadcn composition correctness.
- `[PREFER]` Note any deliberate deviations from these standards and justify them explicitly.

---

## 13. Review Checklist

Use this checklist when reviewing React frontend work:

- `[ ]` Were `react-tanstack-router`, `react-best-practices`, and `shadcn` all applied where relevant?
- `[ ]` Is routing implemented with TanStack Router patterns rather than ad hoc navigation?
- `[ ]` Is server state implemented with TanStack Query rather than `useEffect` fetch logic?
- `[ ]` Do data-dense tables and grids use TanStack Table rather than bespoke row-state plumbing?
- `[ ]` Do complex forms use TanStack Form with clear validation and submission ownership?
- `[ ]` Do advanced select and autocomplete controls use TanStack Select rather than custom combobox implementations?
- `[ ]` Are URL-driven filters and view state validated and routed through search params?
- `[ ]` Are shadcn components composed correctly and styled via variants/tokens rather than raw overrides?
- `[ ]` Are loading, error, empty, and success states explicit?
- `[ ]` Are accessibility requirements preserved for forms, overlays, and interactive components?
- `[ ]` Are avoidable waterfalls, duplicate requests, and unnecessary rerenders removed?

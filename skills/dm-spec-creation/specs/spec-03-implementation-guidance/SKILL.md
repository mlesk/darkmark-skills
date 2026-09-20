---
name: spec-03-implementation-guidance
description: Implementation-guidance grilling workflow for dm-spec-creation spec-03. Agent-only sub-skill invoked by the dm-spec-creation orchestrator to convert architecture into concrete coding conventions, error model, and test posture. Do not invoke directly; invoke dm-spec-creation instead.
user-invocable: false
---

# Sub-Skill: spec-03 Implementation Guidance

<standards-inputs>
- standards/coding-standards-general.md
- standards/coding-standards-csharp.md
- standards/coding-standards-aspnet.md
- standards/coding-standards-aspire.md
- standards/coding-standards-efcore.md
- standards/coding-standards-sql.md
- standards/coding-standards-rest-api.md
- standards/coding-standards-typescript.md
- standards/coding-standards-react.md
- standards/coding-standards-testing.md
</standards-inputs>

<inputs-from-prior-specs>
- spec-00, spec-01, spec-02 (all immutable)
- any active `spec-02a-*.md`, `spec-02b-*.md`, … architecture sidecars listed in base spec-02 §Sidecar Index (all immutable; treated as upstream architecture)
</inputs-from-prior-specs>

<purpose>
Convert spec-02's architecture into concrete implementation guidance for the **canonical stack** (see [../../STACK-DEFAULTS.md](../../STACK-DEFAULTS.md)): solution and folder conventions, naming, error model, validation strategy, testing strategy, DI/composition posture (Aspire-aware), configuration loading, EF Core mapping rules, async/threading posture, and per-stack patterns. Specific enough that an autonomous agent does not need to invent conventions.
</purpose>

<grilling-sequence>

### Phase 0 — Inventory upstream architecture sidecars

0. List every `spec-02[a-z]-*.md` file present under `01-specifications/` (each is a gate-passed architecture sidecar; see dm-spec-creation SKILL.md §"Architecture sidecar family"). For each, identify the technical contracts (§5 of the sidecar) that downstream implementation will realize. Sidecars are **upstream constraints**: spec-03 may reference them but MUST NOT redefine, weaken, or override them. If a sidecar mandates a convention (e.g. idempotency key shape, scope-key ordering), spec-03 carries that constraint forward verbatim or cites it directly.

### Phase A — Repository layout

1. Default layout: `src/` for runtime projects, `tests/` peer for test projects, Aspire `AppHost` composes, mockups under `01-specifications/screen-mockups/`. Confirm or deviate.
2. Confirm `Directory.Build.props` enables `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`, `<ImplicitUsings>enable</ImplicitUsings>`, and the project's chosen LangVersion.
3. Define naming conventions for files, classes, methods, tests (default: `<Solution>.<Module>` projects, `*Tests` test projects, `Should_*` test method names — confirm or deviate).

### Phase B — Per-stack conventions

4. For each loaded `coding-standards-*.md`, walk its `[MUST]` rules. For each, confirm it applies, then capture the project-specific instantiation (e.g. "[MUST] use nullable reference types" → "project-wide `<Nullable>enable</Nullable>` in Directory.Build.props").
5. Capture every `[SHOULD]` the project elects to enforce as a `[MUST]` here.
6. Capture every `[SHOULD]` the project elects to skip, with rationale logged.

### Phase C — Error model

6. Define exception classes vs. result types vs. validation results. Define which boundary uses which.
7. Define logging requirements per error kind.

### Phase D — Validation strategy

8. Where does input validation live? Domain invariants vs. boundary validation vs. UI validation — three layers, three rules.

### Phase E — Testing strategy

9. Define test pyramid: domain tests, integration tests, end-to-end tests, architecture tests. For each: framework, location, naming, what it asserts, what it never asserts.
10. Define test data strategy.

### Phase F — Dependency injection / composition

11. Define composition root location, registration conventions, lifetime rules.

### Phase G — Configuration & secrets

12. Define config sources, override order, secret storage, per-environment variation mechanism.

### Phase H — Persistence mapping

13. For each spec-01 concept that spec-02 marked persistent, define mapping rules: naming, key strategy, concurrency, migrations workflow.
14. Forbid mappings that leak into the domain model.

### Phase I — Async / concurrency

15. Define async posture (async-all-the-way vs. sync), cancellation handling, retry policy class, timeout defaults.

### Phase J — Code review automation

16. Define linters, formatters, analyzers, and the policy for treating their output (warning vs. error).

</grilling-sequence>

<writing-rules>
- This is the only spec where concrete coding conventions live.
- Every convention cites the standards rule it implements or extends.
- No business logic. No domain redefinitions.
- Every convention is enforceable — either by tooling or by a human reviewer with a clear rubric.
</writing-rules>

<exit-checklist>
- [ ] Every spec-02 project appears in the layout.
- [ ] Every active spec-02x sidecar is listed in spec-03 §0 (Upstream Architecture Sidecars Consumed) with the anchors this spec-03 references.
- [ ] No spec-03 convention contradicts a constraint or invariant from an active spec-02x sidecar; conflicts are escalated (re-open the spec-02 family) rather than worked around.
- [ ] Every loaded standards file has been walked rule-by-rule.
- [ ] Error, validation, testing, DI, config, persistence, async sections all complete.
- [ ] implementation-decisions.md has entries for every tactical choice with alternatives.
- [ ] No `[SHOULD]` from the standards is silently dropped — each is either adopted, elevated, or rejected with rationale.
</exit-checklist>

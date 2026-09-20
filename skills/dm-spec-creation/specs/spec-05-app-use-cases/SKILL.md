---
name: spec-05-app-use-cases
description: App use-case grilling workflow for dm-spec-creation spec-05. Agent-only sub-skill invoked by the dm-spec-creation orchestrator to define application-layer orchestrators with inputs, outputs, errors, and authorization rules. Do not invoke directly; invoke dm-spec-creation instead.
user-invocable: false
---

# Sub-Skill: spec-05 App Use Cases

<standards-inputs>
- standards/coding-standards-rest-api.md
- standards/coding-standards-aspnet.md
- standards/coding-standards-aspire.md
</standards-inputs>

<stack-defaults>
Inbound surface is fixed per [../../STACK-DEFAULTS.md](../../STACK-DEFAULTS.md): ASP.NET Core Minimal APIs (REST + JSON) hosted under .NET Aspire. Scheduled jobs run as Aspire-composed services. Authorization defaults to single-user (no auth) unless spec-00 says otherwise.
</stack-defaults>

<inputs-from-prior-specs>
- spec-00 (capabilities, acceptance criteria)
- spec-01 (domain terms; collaborators)
- spec-02 (boundary contracts; inbound surface)
- spec-03 (error model, validation, async posture)
- spec-04 (UI actions that trigger use cases)
</inputs-from-prior-specs>

<purpose>
Define the application use cases — the orchestrators that sit between inbound boundaries (UI actions, scheduled jobs, CLI, external triggers) and the domain model. Every use case is a named, parameterized operation with explicit inputs, outputs, preconditions, postconditions, error outcomes, and authorization rules.
</purpose>

<grilling-sequence>

### Phase A — Use case inventory

1. Enumerate every use case. Source candidates from:
   - spec-04 UI actions
   - spec-00 workflow steps
   - spec-02 inbound boundary surface (scheduled jobs, external triggers)
2. For each, name in `Verb the Object` form. Reject vague names.

### Phase B — Per-use-case specification

For each use case, capture: 3. Trigger(s) and inbound boundary. 4. Input shape (using spec-01 terms only). 5. Preconditions (system state required). 6. Steps in business language — calls to domain collaborators, not implementation method signatures. 7. Postconditions (what changed; which spec-01 pinks were created or transitioned). 8. Output shape. 9. Error outcomes — each named, each mapped to spec-03's error model class, each mapped to a UI feedback location from spec-04. 10. Authorization rule (even if "single user, always allowed" — say so). 11. Idempotency posture. 12. Concurrency posture (what happens if invoked twice in parallel). 13. Observability — what gets logged, what gets metered.

### Phase C — Contract shape (for API-exposed use cases)

14. Define request/response shape at field level, citing spec-03 naming conventions.
15. Define HTTP status mapping per error outcome.

### Phase D — Cross-checks

16. Every spec-00 acceptance criterion is satisfied by at least one use case.
17. Every spec-04 UI action maps to exactly one use case.
18. Every spec-01 pink that has a lifecycle transition has a use case that performs it.
19. No use case manipulates domain state outside its postconditions.

</grilling-sequence>

<writing-rules>
- Use cases are application-layer orchestrators. They MUST NOT contain business rules that belong in spec-01.
- Every input and output field uses a spec-01 term or is explicitly a primitive.
- Every error outcome is named — no "something went wrong".
</writing-rules>

<exit-checklist>
- [ ] Every UI action and every inbound trigger has a use case.
- [ ] Every use case has all 13 per-use-case fields.
- [ ] Coverage cross-checks (acceptance criteria, UI actions, pink lifecycle) all pass.
- [ ] decisions.md has entries for any authorization model choices.
- [ ] implementation-decisions.md has entries for idempotency/concurrency mechanism choices.
</exit-checklist>

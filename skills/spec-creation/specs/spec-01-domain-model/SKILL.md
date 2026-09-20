# Sub-Skill: spec-01 Domain Model

<standards-inputs>
- standards/design-standards-domain-model.md
- standards/design-standards-problem-domain-implementation.md
- standards/design-standards-clean-architecture.md
</standards-inputs>

<inputs-from-prior-specs>
- spec-00-functional-prd.md (sole product source)
</inputs-from-prior-specs>

<purpose>
Shape the business domain model using **Object Modeling in Color** (the Archetypal Domain Shape / Domain-Neutral Component) — Pink (Moment-Interval), Yellow (Role), Blue (Description), Green (Party-Place-Thing) — plus the Law of Demeter for coupling discipline. No persistence, no API, no aggregates.
</purpose>

<modeling-method>

The prescribed method is **Object Modeling in Color**. Classify in this order:

1. **Pink first.** What remembered business activity does the PRD demand? Each remembered activity is a moment-interval candidate.
2. **Yellow next.** For each pink, who/what participates _as a role_ (not as themselves)? Roles whose status itself matters become yellow.
3. **Blue.** What reusable descriptions, defaults, policies, classifications recur across many individuals?
4. **Green last.** What individually-tracked parties, places, things, and bounded containers underlie the roles?

Reject the term "aggregate root". It does not belong in this vocabulary.

Apply Law of Demeter: each class talks only to immediate collaborators. If a chain of `.foo.bar.baz` appears in the model's behavior, surface it as a coupling smell.

</modeling-method>

<grilling-sequence>

### Phase A — Modeling posture

1. Restate the posture rules from `design-standards-domain-model.md`. Confirm they apply.
2. Identify exclusions (multi-user, short-selling, etc.) directly from spec-00 §out-of-scope.

### Phase B — Module decomposition

3. Propose 2–4 modules derived from business areas (not technical layers). Define dependency direction. Reject any cycle.

### Phase C — Pink discovery (per module)

4. Walk every workflow in spec-00. For each remembered activity, propose a pink class: name, identity, start/finish semantics, status lifecycle, what it remembers.
5. For each pink, list its mi-details (the dependent line-item shape).

### Phase D — Yellow discovery

6. For each pink, ask: who/what participates _as a role_? Capture role status, role-specific responsibilities, role-status invariants.
7. Distinguish role (yellow) from underlying party-place-thing (green). Force this distinction.

### Phase E — Blue discovery

8. Identify recurring descriptions/defaults/classifications/policies. Each is blue.
9. For each blue, name what it describes and what consults it.

### Phase F — Green discovery

10. For each yellow, identify the green it roles for. For each pink that references a thing, identify the green.
11. Reject greens invented for technical convenience.

### Phase G — Derived concepts

12. Identify concepts the business reasons about but does not independently persist (e.g. current position derived from trades). Mark as derived. Capture derivation rule in business language.

### Phase H — Glossary

13. For every term used in this spec, capture: canonical name, color, one-sentence definition, what it is NOT (disambiguation).
14. Cross-check: every noun from spec-00 §user-visible object model appears here, mapped to a color.

### Phase I — Coupling review

15. For every behavior method on every class, name the immediate collaborators it touches. Flag any Demeter violation.
16. For every cross-module reference, confirm it follows the declared dependency direction.

</grilling-sequence>

<writing-rules>
- No mention of: persistence, EF, repositories, DI, application services, DTOs, HTTP, JSON, SQL.
- No "aggregate" or "aggregate root".
- Every class has an archetype color.
- Every class has identity, responsibility, collaborators, and (for pink) lifecycle.
- Glossary is exhaustive.
</writing-rules>

<exit-checklist>
- [ ] Modules + dependency direction declared, acyclic.
- [ ] Every pink has lifecycle + mi-details.
- [ ] Every yellow distinguishes from its green.
- [ ] Glossary covers every term used anywhere in the spec.
- [ ] Derived concepts are explicitly marked and have business-language derivation rules.
- [ ] Coupling review identifies zero unjustified Demeter violations.
- [ ] decisions.md has entries for module split, exclusion choices, and any standards deviation.
</exit-checklist>

# Sub-Skill: spec-00 Functional PRD

<standards-inputs>
- standards/coding-standards-general.md
</standards-inputs>

<inputs-from-prior-specs>
None. This is the root spec.
</inputs-from-prior-specs>

<purpose>
Produce a functional PRD that defines product behavior, business scope, workflows, user-visible object model, required calculations, decision rules, and acceptance criteria — with zero implementation detail.
</purpose>

<grilling-sequence>

Walk the user through the template in [../../templates/spec-00-prd.template.md](../../templates/spec-00-prd.template.md), section by section. One question at a time. Always offer a recommendation.

### Phase A — Framing

1. Who is the user, in one sentence? (single user? team? roles?)
2. What is the single most important outcome the product must produce?
3. What is explicitly **out of scope** at v1? Push hard for at least five out-of-scope items.
4. What does "done" look like for the product — what would make the user say "this works"?

### Phase B — Objectives & Vision

5. Restate phase A as 5–9 measurable product objectives.
6. Draft the product vision in 2–3 paragraphs. Read it back. Refine.

### Phase C — Capability inventory

7. Enumerate every distinct business capability. For each, capture: name, one-sentence purpose, trigger, inputs, outputs, success criteria.
8. For each capability, classify: `core` (required v1), `supporting` (required v1 but not differentiating), `deferred` (out of v1).
9. Reject any capability that cannot be stated without naming a technology, library, or database.

### Phase D — Workflows

10. For each `core` capability, sketch the end-to-end workflow as a numbered sequence of user-meaningful steps.
11. Identify the cross-capability workflows (workflows that traverse two or more capabilities).

### Phase E — User-visible object model

12. List the nouns the user thinks about. Define each in one sentence. Do not model relationships yet — that's spec-01.
13. For each noun, mark whether the product **remembers** it (persistent business meaning) or **derives** it (computed view).

### Phase F — Required calculations & decision rules

14. For each calculation the product performs, capture: inputs, formula or rule in business language, output, when it runs.
15. For each decision rule (e.g. "Monitor vs Trade"), capture the inputs, the rule, and the resulting action.

### Phase G — Acceptance criteria

16. For each `core` capability, write 2–4 acceptance criteria in `Given/When/Then` form using only business language.
17. Cross-check: every objective in Phase B traces to ≥1 acceptance criterion.

### Phase H — Non-functional posture

18. Single-user or multi-user? Concurrent edits possible?
19. Data freshness expectations (per data class)?
20. Failure tolerance — what must never be lost, what can be re-derived?
21. Performance posture — interactive, batch, both?
22. Audit posture — what history must be preserved?

</grilling-sequence>

<writing-rules>
- Forbidden words in this spec: `database`, `API`, `ORM`, `framework`, `class`, `service`, `repository`, `endpoint`, `table`, `schema`, `library`, `EF`, `React`, `component` (in the React sense), any specific product/library name.
- Allowed: business nouns, capabilities, workflows, decision rules, acceptance criteria.
- Every objective must be measurable or observable.
- Every capability must have an acceptance criterion.
</writing-rules>

<exit-checklist>
Before invoking the gate, confirm:
- [ ] Every section of the template is filled.
- [ ] No forbidden technical terms appear.
- [ ] Every `core` capability has acceptance criteria.
- [ ] Every objective traces to ≥1 acceptance criterion.
- [ ] Out-of-scope list has ≥5 explicit items.
- [ ] decisions.md has entries for every scope and posture choice.
</exit-checklist>

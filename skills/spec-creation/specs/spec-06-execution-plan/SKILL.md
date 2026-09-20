# Sub-Skill: spec-06 Execution Plan

<standards-inputs>
- standards/planning-standards-inside-out-phases.md
- standards/design-standards-clean-architecture.md
- standards/coding-standards-testing.md
</standards-inputs>

<inputs-from-prior-specs>
- spec-00 through spec-05 (all immutable; all gate-passed)
- any active `01-specifications/spec-02[a-z]-*.md` architecture sidecars (all immutable; all sidecar-gate-passed)
</inputs-from-prior-specs>

<purpose>
Produce an **agent-executable** execution plan: an ordered, dependency-respecting sequence of inside-out Phases (and sub-phases) that an autonomous implementation agent can pick up, ship as a PR, verify mechanically, and continue across sessions. The plan adds no new vocabulary — it sequences the contracts already pinned in spec-01/02/04/05.

Outcome: `spec-06-execution-plan.md` and `01-specifications/execution-state.md` together form the state machine the implementation agent executes per `planning-standards-inside-out-phases.md` §11.
</purpose>

<grilling-sequence>

### Phase A — Plan posture

1. Confirm the plan target: this skill produces a plan for **autonomous agent execution**. Every Phase MUST satisfy `planning-standards-inside-out-phases.md` §4 anatomy and §7 done-when bar. Soft-pass is forbidden.
2. Confirm the layer vocabulary: FE / UI / UC / PD / SI (planning standard §2). Reject any candidate Phase whose scope cannot be expressed in these layers.
3. Confirm sub-phase PR policy (planning standard §9): one PR per Phase or sub-phase.

### Phase B — Phase backbone

4. Draft the Phase list anchored to planning standard §3 (inside-out ordering). For this stack the default backbone is:
   - **P0 Preflight** — toolchain version assertions (`global.json`, `.tool-manifest`, `package.json`, `pnpm-workspace.yaml`), `.github/workflows/ci.yml`. Mandatory — every later `done-when` depends on this.
   - P1 Scaffold canonical projects, namespaces, and the minimum architecture-test set from `coding-standards-testing.md` §3 for FE / UI / UC / PD / SI.
   - P2 PD business concepts + PD-owned contracts, decomposed by module from spec-01 (e.g. P2a Core, P2b Research, P2c Portfolio).
   - P3 SI persistence baseline (provider registration, mappings, migrations, WAL/tuning where applicable).
   - P4 PD durable-job contracts + SI job storage + worker-host execution of UC flows.
   - P5 SI source adapters per accepted spec-04 data source (sub-phases per provider).
   - P6 UC layer covering every spec-05 use case the UI BFF must expose.
   - P7 UI BFF endpoints fulfilling everything the FE will need (per spec-05 contract shapes).
   - P8 FE screens against the stable UI surface, ordered by spec-04 dependency. Each FE Phase MUST include a Playwright visual-parity check against the corresponding `01-specifications/screen-mockups/` screen (or log a D-NNN deviation).
   - P9 End-to-end vertical proof (e.g. Research vertical: UC → PD ← SI from research run through candidates and signals).
   - P10 Hardening — observability, failure handling, deployment packaging, architecture-test extension.
5. Adjust the backbone only when justified by spec-00..05; log any reordering or omission as a `decisions.md` `standards-deviation` entry citing planning standard §3. P0 may not be skipped.

### Phase C — Per-phase anatomy

For every Phase / sub-phase, capture all fields from planning standard §4:

6. `layer(s)` — ⊆ { FE, UI, UC, PD, SI, cross-cutting }.
7. `depends-on` — list of earlier phase-ids; reject any forward dependency.
8. `scope` — 1–3 sentences in repo terms (spec-01/02/04/05 nouns only).
9. `spec-anchors` — explicit `spec-NN#kebab-anchor-id` or `spec-NN<letter>#kebab-anchor-id` references (per planning standard §4a); the latter form targets an active `spec-02x` architecture sidecar. Plain `spec-NN §X.Y` is forbidden; ≥1 required. Anchors targeting a sidecar that does not exist or that has not passed its sidecar gate FAIL the gate.
10. `deliverables` — numbered checklist per planning standard §5; each deliverable self-contained, verifiable, repo-anchored.
11. `files (touch budget)` — repo-relative directories / file patterns to add or change.
12. `tests to add` — typed per layer per planning standard §6 (test frameworks pinned in `coding-standards-testing.md` — the plan never re-chooses them).
13. `done-when` — mechanical pass/fail commands per planning standard §7 baseline (solution-wide `dotnet build`/`dotnet test`); no opinion words.
14. `human-gate` — default `none`; if present, must state the human decision required.
15. `decisions inherited` AND `decisions to make` — split per planning standard §4: inherited lists existing D-NNN constraints; to-make lists open questions the agent MUST resolve + log a fresh D-NNN for before marking the Phase done.

### Phase D — Coverage matrices

Build all four matrices required by planning standard §8:

16. **Acceptance criteria coverage** — spec-00 ACs → Phase-ids. Every AC ≥1.
17. **Use case coverage** — spec-05 UCs → Phase-ids. Every UC appears in the relevant UC Phase AND in the UI/FE Phases that surface it.
18. **Screen coverage** — spec-04 screens → Phase-ids. Every screen lands in a FE Phase.
19. **Behaviour coverage** — spec-01 classes with behaviour → Phase-ids. Every such class lands in a PD Phase.
    19a. **Sidecar coverage (conditional).** If any `spec-02[a-z]-*.md` sidecars exist, build a fifth matrix in template §5.5 mapping each sidecar artifact (contract / invariant / RUA rule, identified by its anchor) to the implementing Phase-ids. Every sidecar contract / invariant MUST land in at least one Phase. Orphan sidecar artifacts FAIL the gate; sidecars that have zero Phase coverage are either un-needed (delete the sidecar and re-open spec-02) or a planning hole.

Any empty row fails the gate.

### Phase E — Execution state companion

20. Reference the canonical execution-state schema in planning standard §10 (do not duplicate it). State that the file lives at `01-specifications/execution-state.md` and is created on first execution by the sibling `spec-execution` skill per planning standard §11 step 0.
21. State that the agent (not the plan author) creates and maintains the file; the plan only references the canonical schema.

### Phase F — Agent execution protocol

22. Reference planning standard §11 (and §11a failure protocol + §11b context-budget halt protocol) as the canonical state machine; do not duplicate. Note that the sibling `spec-execution` skill is the orchestration entry point.
23. Confirm branch/PR/commit policy per planning standard §9 and §9a.

### Phase G — Forbidden-pattern sweep (mandatory)

Before exit, scan the plan for every forbidden pattern in planning standard §12:

24. No IT-only Phases without a verifiable contract surface for the next layer.
25. No `done-when` containing opinion words.
26. No forward dependencies.
27. No vocabulary outside spec-01/02/04/05 (terms originating in active `spec-02x` sidecars are permitted because sidecars belong to the spec-02 family).
28. No Phase bundling multiple use cases or screens without sub-phase split.
29. `execution-state.md` companion specified.
30. All four coverage matrices present and complete.

</grilling-sequence>

<writing-rules>
- Phases are ordered inside-out (PD → SI of PD contracts → UC → UI → FE → vertical proof → hardening).
- One PR per Phase or sub-phase. Branch name = phase-id slug.
- Every `done-when` line is a command or a machine-checkable assertion.
- Plan reuses spec-01/02/04/05 nouns; introduces none.
- No estimates, no story points, no time durations.
- Test posture per Phase follows planning standard §6 — PD uses faked SI, SI uses real adapters, UC runs full stack without FE, FE adds e2e UI tests.
- Cross-cutting infrastructure work is named explicitly as a scaffolding or hardening Phase, never disguised as a feature Phase.
</writing-rules>

<exit-checklist>
- [ ] Every Phase has all 11 fields from planning standard §4 (layer(s), depends-on, scope, spec-anchors, deliverables, files, tests to add, done-when, human-gate, decisions inherited, decisions to make).
- [ ] Phase ordering matches planning standard §3 (P0 Preflight present and unskipped; or deviation logged in decisions.md).
- [ ] Every `spec-anchors:` value uses the `spec-NN#kebab-anchor-id` form (or `spec-NN<letter>#kebab-anchor-id` for sidecar references), NOT `spec-NN §X.Y`.
- [ ] Every sidecar-targeted anchor (`spec-02<letter>#…`) resolves to an existing, gate-passed sidecar file.
- [ ] Every Phase has ≥1 numbered deliverable.
- [ ] Every Phase's `done-when` includes the solution-wide baseline commands from planning standard §7.
- [ ] Every FE-touching Phase's `done-when` includes a Playwright visual-parity test OR cites a D-NNN deviation.
- [ ] All four coverage matrices (§8) complete with zero empty rows; if sidecars exist, the conditional fifth matrix (§5.5) is also complete with zero empty rows.
- [ ] `01-specifications/execution-state.md` referenced (not duplicated) per planning standard §10.
- [ ] Agent execution protocol referenced (§11, §11a, §11b) from planning standard — plan does not redefine.
- [ ] One-PR-per-Phase policy stated; branch naming + commit/PR conventions per §9/§9a stated.
- [ ] Forbidden-pattern sweep (Phase G) passes for every Phase.
- [ ] decisions.md has entries for any deviation from the default backbone.
</exit-checklist>

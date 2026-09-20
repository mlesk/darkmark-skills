# Cross-Spec Consistency Gate

Runs after every successful per-spec gate, using the set of specs that currently report PASS. This includes the canonical spine (spec-00…spec-06) and every emitted spec-02x sidecar as they become gate-passed. The gate therefore acts as an early warning system for terminology drift, traceability breaks, and cross-spec contradictions instead of deferring those discoveries until the end. Any failure invalidates the offending spec's PASS stamp and the orchestrator re-enters the main loop at the earliest failing spec.

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure mechanics.

## Layer 1 — Terminology consistency

For every distinct term used in spec-02 / any active spec-02x sidecar / spec-03 through spec-06:

1. Confirm the term appears in spec-01's glossary.
2. Confirm the usage matches the glossary definition (no semantic drift).
3. Flag any synonyms used for the same concept across specs (including sidecars).
4. Flag any term in spec-01 that no later spec or sidecar uses (potential dead concept — confirm or remove).

## Layer 2 — Forward traceability

1. Every `core` capability in spec-00 → ≥1 use case in spec-05 → ≥1 Phase (or sub-phase) in spec-06.
2. Every objective in spec-00 → ≥1 acceptance criterion in spec-00 → ≥1 Phase in spec-06 (covered by §5.1 Acceptance Criteria → Phases matrix).
3. Every non-functional posture in spec-00 → ≥1 architectural mechanism in spec-02 → ≥1 implementation convention in spec-03 → ≥1 hardening Phase in spec-06 (typically P10).

## Layer 3 — Backward traceability

1. Every Phase in spec-06 → ≥1 use case in spec-05 (or a behaviour-bearing class in spec-01 for PD Phases, or a scaffolding/cross-cutting justification) AND ≥1 acceptance criterion in spec-00 (transitively via the use case or behaviour it implements).
2. Every use case in spec-05 → ≥1 inbound boundary in spec-02 AND ≥1 capability in spec-00.
3. Every screen in spec-04 → ≥1 capability in spec-00.

## Layer 4 — Capability closure

1. Every concept in spec-01 is realized in spec-02 (or in a spec-02x sidecar that narrows the relevant base spec-02 section) — mapped to a module + persistence shape — OR is explicitly marked derived OR is explicitly marked out-of-scope with rationale.
2. Every spec-01 pink with a lifecycle transition has a spec-05 use case that performs it AND a spec-06 Phase (typically in the UC band) that builds it.
3. Every spec-01 module appears in spec-02's project map AND spec-03's folder layout AND a spec-06 PD Phase.
4. Every spec-02x sidecar listed in base spec-02 §Sidecar Index is referenced by at least one spec-06 Phase via `spec-anchors:` OR is explicitly marked as informational in `decisions.md`. Orphan sidecars FAIL the gate.

## Layer 5 — Dependency-direction integrity

1. spec-02's project dependency graph is a refinement of spec-01's module dependency graph (no edge in spec-02 contradicts spec-01).
2. Every spec-02x sidecar's technical contracts refine (do not contradict) base spec-02's boundaries and dependency direction.
3. spec-03's folder layout preserves spec-02's project structure.
4. spec-06's Phase ordering does not violate any spec-01 / spec-02 / spec-02x dependency edge, and respects the inside-out layer ordering `FE → UI → UC → PD ← SI` per `standards/planning-standards-inside-out-phases.md` §3.

## Layer 6 — Decision-log integrity

1. Every spec-level decision identified during grilling has a `decisions.md` or `implementation-decisions.md` entry.
2. No entry is `superseded` without a forward link to the superseding entry.
3. Every `standards-deviation` entry cites the rule and the rationale.
4. Every `gate-override` entry is cross-referenced from the overridden spec's gate-result block.

## Layer 7 — Standards alignment

1. Every `[MUST]` rule in every loaded standard is addressed in at least one spec.
2. No spec contradicts a `[MUST]` rule without a `standards-deviation` decision entry.

## Layer 8 — Execution-plan integrity

Reads `spec-06-execution-plan.md` as input. Every Phase entry MUST satisfy the following — any failure FAILs the gate and re-opens spec-06.

1. **Anchor resolution.** Every `spec-anchors:` reference resolves to an inline HTML anchor (`<a id="…"></a>`) that exists in the target spec file. This includes `spec-02<letter>#anchor-id` references targeting sidecars. Stale or shifted references FAIL — the agent cannot trust section-number drift. A sidecar referenced from spec-06 whose file is missing, whose anchor is missing, or whose gate has not passed is a hard FAIL.
2. **Touch-budget legality.** Every path in `files (touch budget):` lives under a directory permitted by spec-02's project map / any narrowing in an active spec-02x sidecar / spec-03's folder layout. No Phase writes outside the declared layout.
3. **Test-posture conformance.** Every `tests to add:` entry matches the layer(s) the Phase touches, per `standards/planning-standards-inside-out-phases.md` §6 table. PD-touching Phases include unit + faked-SI integration; SI-touching Phases include real-adapter integration; UC-touching Phases include UC→PD→real-SI integration; UI-touching Phases include BFF integration; FE-touching Phases include component tests + ≥1 e2e UI test per use-case screen.
4. **Dependency acyclicity.** The `depends-on` graph across all Phases/sub-phases is acyclic and references only earlier-numbered phase-ids.
5. **Decision-field hygiene.** Every Phase has both `decisions inherited:` and `decisions to make:` (per planning standard §4). Each `decisions inherited:` entry resolves to an existing D-NNN in `decisions.md` or `implementation-decisions.md`.
6. **Mockup parity (FE Phases only).** Every FE-touching Phase's `done-when:` either (a) names a Playwright visual-parity test against the corresponding `01-specifications/screen-mockups/` screen, OR (b) cites a D-NNN entry documenting an explicit deviation.

## Output

On PASS, prepend to `decisions.md`:

```markdown
<!-- cross-spec-gate: PASS date=YYYY-MM-DD reviewer=dm-spec-creation
specs: spec-00..spec-06 + emitted spec-02x sidecars
layers: terminology, forward-trace, backward-trace, closure, dependency, decision-log, standards, execution-plan-integrity
-->
```

On FAIL, for each failing layer, identify the **lowest-numbered** spec (treating sidecars as belonging to the spec-02 family) that must change. Invalidate that spec's gate-result block by rewriting it as FAIL with the cross-spec finding appended, then return control to the orchestrator's main loop.

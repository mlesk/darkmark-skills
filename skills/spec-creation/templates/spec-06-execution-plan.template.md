# Specification: Execution Plan (Inside-Out Phased)

> Format: `standards/planning-standards-inside-out-phases.md`. The plan is consumed by an autonomous implementation agent and MUST be sufficient for end-to-end delivery without further human steering.

## 1. Scope

<!-- 1–3 sentences. Anchor to spec-00..05 by reference. State that this plan is governed by `standards/planning-standards-inside-out-phases.md`. -->

## 2. Layer Vocabulary

The plan uses FE / UI / UC / PD / SI per planning standard §2. Dependency direction: `FE → UI → UC → PD ← SI`.

## 3. Phase Backbone (ordered)

<!-- Ordered list of Phase ids and titles only. The detail is in §4. Example:

- P1  Scaffold canonical projects + architecture-test fences
- P2a PD: Core concepts and contracts
- P2b PD: Research concepts and contracts
- P2c PD: Portfolio concepts and contracts
- P3  SI persistence baseline (SQLite + EF Core)
- P4  PD durable-job contracts + SI job storage + worker host
- P5a SI source adapter: <provider>
- …
- P6  UC layer
- P7  UI BFF endpoints
- P8a FE: <screen group>
- …
- P9  End-to-end vertical proof (Research)
- P10 Hardening
-->

## 4. Per-Phase Specifications

<!-- per Phase template, repeat for every Phase / sub-phase:

### P<N>[<a|b|c>] <Phase title>
- layer(s):
- depends-on:
- scope:
- spec-anchors:                 # spec-NN#kebab-anchor-id OR spec-NN<letter>#kebab-anchor-id (sidecar) form ONLY (per planning standard §4a); never `spec-NN §X.Y`. Example: `spec-01#research-run, spec-02a#contract-schedule-port`.
- deliverables:
    1. …
    2. …
- files (touch budget):
- tests to add:
    - <layer>: <type> — <target>
- done-when:
    - `<command>` — <assertion>      # FE-touching Phases MUST include the Playwright visual-parity test OR cite a D-NNN deviation
    - …
- human-gate:        none
- decisions inherited: none           # OR [ D-NNN, … ] — existing decisions this Phase must respect
- decisions to make:   none           # OR [ "<open question>", … ] — each resolved + logged as a fresh D-NNN before the Phase can be marked done

-->

## 5. Coverage Matrices

### 5.1 Acceptance Criteria → Phases

<!-- table: spec-00 AC id | AC summary | Phase-ids -->

### 5.2 Use Cases → Phases

<!-- table: spec-05 UC | UC Phase (P6 sub-phase) | UI BFF Phase | FE Phase -->

### 5.3 Screens → Phases

<!-- table: spec-04 screen | FE Phase id -->

### 5.4 Domain Classes with Behaviour → Phases

<!-- table: spec-01 class | PD Phase id -->

### 5.5 Architecture Sidecar Coverage (conditional)

<!--
Required iff one or more `spec-02[a-z]-*.md` sidecars exist. Omit (write "not applicable — no sidecars") otherwise.

List each normative artifact from each sidecar (contracts from §5, invariants from §6, RUA rules from §7) by its anchor, and the implementing Phase-ids. Every artifact MUST land in at least one Phase. Orphan rows fail spec-06.

| Sidecar artifact (anchor)                          | Kind        | Implementing Phase-ids |
| -------------------------------------------------- | ----------- | ---------------------- |
| `spec-02a#contract-schedule-port`                  | contract    | P5a, P6b               |
| `spec-02a#constraint-idempotency-under-retry`      | invariant   | P5a                    |
| `spec-02b#rua-rules`                               | rua-rule    | P5b                    |
-->

## 6. Execution State Companion

A sibling file `01-specifications/execution-state.md` is the authoritative source of truth for progress, per `standards/planning-standards-inside-out-phases.md` §10. The schema is canonical — the implementation agent (under the sibling `spec-execution` skill) creates and maintains the file; the plan only references it. See planning standard §10 for the exact format and §11 for the state machine.

## 7. Agent Execution Protocol

The state machine the implementation agent runs is defined verbatim in `standards/planning-standards-inside-out-phases.md` §11 (with failure protocol in §11a and context-budget halt protocol in §11b). This plan does not duplicate it. The sibling `spec-execution` skill is the orchestration entry point; this plan is its input.

## 8. Branch & PR Policy

- One PR per Phase or sub-phase.
- Branch name = phase-id slugified (e.g. `P2a-pd-core-concepts`).
- No squash-merge across phases; no multi-phase PRs.
- Commit + PR conventions per planning standard §9a.

## 9. Plan-Level Decisions Index

<!-- table: D-NNN | type | summary | links — pulled from decisions.md / implementation-decisions.md for any deviation from the default backbone or done-when bar. -->

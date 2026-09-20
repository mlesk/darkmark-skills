# Gate: spec-02x Architecture Sidecar

Reusable gate. Runs once per emitted sidecar file matching `01-specifications/spec-02[a-z]-*.md`. Invoked by the spec-creation orchestrator inside the spec-02 family loop, before the cross-spec consistency gate.

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure mechanics.

## Inputs

- The sidecar file under review (`<sidecar-path>`).
- Base `01-specifications/spec-02-architecture.md` (for authority-boundary check).
- `01-specifications/spec-01-domain-model.md` (for terminology check).
- `decisions.md` (for D-NNN traceability).

## Structural checklist (all MUST pass)

1. **File name** matches the regex `^spec-02[a-z]-[a-z0-9-]+\.md$` and lives in `01-specifications/`.
2. **Listed in base spec-02 §Sidecar Index** with file name, slice, and authority boundary. A sidecar on disk but missing from the index FAILs the gate (and FAILs `spec-02-gate.md` item 12).
3. **Anchored headings.** Every `##` and `###` heading in the sidecar carries an inline `<a id="kebab-slug"></a>` (per `standards/planning-standards-inside-out-phases.md` §4a).
4. **Required sections present** per [templates/spec-02x-technical-spec.template.md](../templates/spec-02x-technical-spec.template.md): Purpose, Bounded Scope, Upstream Inputs, Module Ownership, Technical Contracts, Constraints & Invariants, and either Replace/Update/Append rules or an explicit "not applicable" note, plus Decisions and References. No `TBD` / `TODO` / empty required section.
5. **Authority boundary** is explicit: the sidecar names the base spec-02 section(s) it narrows AND contains the literal sentence (or a faithful paraphrase) "This sidecar MUST NOT contradict spec-01 or base spec-02 §…".
6. **No contradiction with spec-01.** Every domain term used appears in spec-01's glossary with identical meaning. New terms are forbidden unless spec-01 has been updated and re-gated.
7. **No contradiction with base spec-02.** No statement in this sidecar reverses, broadens, or fights a rule in base spec-02. Refinements (narrowing) are allowed and expected.
8. **No implementation-guidance overreach.** The sidecar does not redefine shared coding conventions, error model, test posture, DI, configuration, persistence-mapping rules, or analyzer policy — those belong to spec-03.
9. **Dependency direction.** The allowed inbound/outbound directions in §4 are a strict refinement of base spec-02's project dependency graph.
10. **Decisions logged.** Every architectural choice unique to this sidecar has a D-NNN entry in `decisions.md` referenced in §8.
11. **Standards loaded.** The sidecar's §3 enumerates the standards it loads beyond the base spec-02 set, matching the spec-02x row in [STANDARDS-PROTOCOL.md](../STANDARDS-PROTOCOL.md).

## Rubric (1–5, pass bar ≥4)

- **Scope boundedness** — the slice is genuinely narrow; the sidecar resists scope creep.
- **Contract clarity** — every contract in §5 is shaped precisely enough for a spec-06 Phase to assert against without further interpretation.
- **Invariant enforceability** — every item in §6 is literally checkable by a `done-when:` command or a test.
- **Anchor coverage** — every heading a downstream Phase might cite has a stable anchor; no orphan anchors.
- **Traceability** — every term, contract, and constraint maps cleanly back to spec-01 and base spec-02.
- **Standards alignment** — loaded standards are the right subset for the slice; nothing material is omitted.

## Output

On PASS, stamp the bottom of the sidecar file:

```markdown
<!-- gate-result: PASS date=YYYY-MM-DD reviewer=spec-creation/spec-02x-sidecar-gate -->
```

On FAIL, stamp:

```markdown
<!-- gate-result: FAIL date=YYYY-MM-DD reviewer=spec-creation/spec-02x-sidecar-gate
findings:
  - <one finding per failed item, citing structural item # or rubric dimension>
-->
```

A FAIL on any sidecar blocks the spec-02 family from passing, and therefore blocks the orchestrator from advancing to spec-03.

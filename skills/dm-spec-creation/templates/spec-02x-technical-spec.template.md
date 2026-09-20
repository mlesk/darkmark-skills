# Specification: Architecture Sidecar — `<slice-name>`

<!--
This is a `spec-02x` architecture sidecar. It is a conditional formal member of the spec-02 family — see `.github/skills/dm-spec-creation/SKILL.md` §"Architecture sidecar family" and the spec-02 sub-skill Phase H.

A sidecar narrows base spec-02 for one bounded module or technical slice. It is **architecture**, not implementation guidance:
- It MAY introduce normative technical contracts (lifecycle rules, idempotency, ordering, scope keys, lineage) downstream spec-06 Phases will cite literally via `spec-anchors: spec-02<letter>#anchor-id`.
- It MUST NOT contradict spec-01 (domain model) or base spec-02.
- It MUST NOT redefine shared coding conventions, error model, test posture, DI, configuration, or analyzer policy — those live in spec-03.

File naming: `01-specifications/spec-02a-<slice>.md`, `spec-02b-<slice>.md`, … assigned in creation order.

Every `##` and `###` heading below MUST carry an inline anchor of the form `<a id="kebab-slug"></a>` so spec-06 can reference sections stably. The sidecar gate FAILs any heading without one.
-->

## 1. Purpose <a id="purpose"></a>

<!-- 2–4 sentences. What slice is this sidecar narrowing? Why does it warrant its own document instead of living in base spec-02? -->

## 2. Bounded Scope <a id="bounded-scope"></a>

<!--
- IN scope (modules, capabilities, contract surfaces this sidecar owns).
- OUT of scope (adjacent surfaces this sidecar explicitly does NOT cover).
- Authority boundary: state which base spec-02 section(s) this sidecar narrows, and the literal sentence: "This sidecar MUST NOT contradict spec-01 or base spec-02 §<sections>."
-->

## 3. Upstream Inputs <a id="upstream-inputs"></a>

<!--
- spec-01 anchors consumed (e.g. `spec-01#research-run`).
- base spec-02 anchors narrowed (e.g. `spec-02#persistence`, `spec-02#worker-host`).
- Any spec-04 / spec-05 anchors that constrain this slice.
- Standards loaded beyond the base spec-02 set (per STANDARDS-PROTOCOL.md spec-02x row; e.g. `coding-standards-efcore.md`, `coding-standards-sql.md`).
-->

## 4. Module / Slice Ownership <a id="module-ownership"></a>

<!--
- Owning module(s) from spec-01.
- Owning project(s) / package(s) from base spec-02 §Project map.
- Who calls into this slice (allowed inbound directions) and who this slice calls (allowed outbound directions) — MUST be a refinement of base spec-02 dependency direction.
-->

## 5. Technical Contracts <a id="technical-contracts"></a>

<!--
The normative contract surface. For each contract:

### 5.1 <Contract name> <a id="contract-<kebab>"></a>

- Shape (port name, conceptual signature; no source paths, no method bodies).
- Lifecycle (when called; ordering; concurrency posture).
- Inputs / outputs in spec-01 vocabulary.
- Failure modes the implementation MUST handle distinctly.
-->

## 6. Constraints & Invariants <a id="constraints-invariants"></a>

<!--
Numbered, literally enforceable. Each item is something a spec-06 Phase will assert via a done-when. Examples:

1. Every <X> persisted MUST carry a (source, scope-key, as-of) triple.
2. <Operation> MUST be idempotent under retry: repeating with identical (scope-key, as-of) yields zero new rows.
3. <Pipeline> MUST process partitions in lexicographic scope-key order; out-of-order arrivals are quarantined, not dropped.
-->

## 7. Replace / Update / Append Rules <a id="rua-rules"></a>

<!-- For slices with mutating data flow (e.g. import, projection). Omit this section if not applicable.

For each entity touched by this slice, state:
- Replace: keys whose presence wipes prior rows for the same scope.
- Update: keys whose presence overwrites matching rows.
- Append: keys that are insert-only (history-preserving).
-->

## 8. Open Questions Resolved <a id="decisions"></a>

<!--
Each entry mirrors a decisions.md entry (D-NNN) that pertains specifically to this sidecar. Format:

- D-NNN — <one-line summary> — <link to decisions.md entry>
-->

## 9. References <a id="references"></a>

<!--
- Cross-links to spec-01 / base spec-02 / sibling sidecars.
- External specifications (RFCs, vendor docs) consulted.
-->

<!--
gate-result: (filled by gates/spec-02x-sidecar-gate.md on PASS)
-->

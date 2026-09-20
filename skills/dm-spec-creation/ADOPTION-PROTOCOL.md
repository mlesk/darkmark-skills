# Adoption Protocol

How `dm-spec-creation` picks up a set of **pre-existing specs** that were not authored through this skill, evaluates them, fills gaps, and runs them through the same gates as freshly-authored specs.

The bar is identical: an adopted spec passes the exact same per-spec gate and cross-spec gate as one drafted from scratch. Adoption is an entry path, not a relaxed standard.

## 1. When this protocol applies

The bootstrap (see [ORCHESTRATION.md](./ORCHESTRATION.md) §1 step 4) classifies each `spec-NN-*.md` and each `spec-02[a-z]-*.md` sidecar into one of five resumption states:

| State           | File present | Has `<!-- gate-result: ... -->` | Other signals                                                                                                                                                                                                                                                                                              |
| --------------- | ------------ | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `missing`       | no           | n/a                             | —                                                                                                                                                                                                                                                                                                          |
| `adopt-pending` | yes          | no                              | EITHER (a) size ≥ 500 bytes AND ≥ 2 `##` headings AND NO characteristic skill scaffolding markers (`<!-- 1–3 sentences -->`, `<!-- per spec-01 remembered concept -->`, `<!-- for each NFR -->`, `<!-- TBD -->`, etc.), OR (b) the file contains an `<!-- adoption: deferred ... -->` marker (see §2 Step C) |
| `draft`         | yes          | no                              | template scaffolding markers present OR `TBD` / `TODO` / empty required section markers AND no `<!-- adoption: deferred ... -->` marker — i.e. the file was being authored through this skill and was interrupted. MAY carry a `<!-- last-resolved-question: PhaseX.N -->` marker for grilling resumption  |
| `gate-failed`   | yes          | `FAIL` block                    | —                                                                                                                                                                                                                                                                                                          |
| `gate-passed`   | yes          | `PASS` block                    | —                                                                                                                                                                                                                                                                                                          |

`adopt-pending` is the foreign-content state (or a deferred-adoption state). The remainder of this document defines what to do when a spec is `adopt-pending`.

## 2. Adoption pass (per spec)

The orchestrator runs this procedure for each `adopt-pending` spec, in the canonical order (00 → 01 → 02 → all `spec-02x` sidecars → 03 → 04 → 05 → 06), **before** invoking the corresponding sub-skill's normal grilling loop.

### Step A — Read

1. Read the existing spec file in full.
2. Read the corresponding template under [templates/](./templates/).
3. Read the corresponding sub-skill under [specs/](./specs/) to obtain its `<exit-checklist>` and `<grilling-sequence>`.
4. Read every earlier spec already marked `gate-passed` (these are immutable constraints).
5. Read `decisions.md` and `implementation-decisions.md` for prior entries tagged with this spec's number.

### Step B — Assess

Produce an **Adoption Assessment** for the user — one compact block per spec, no narrative:

```text
Adoption assessment — spec-NN-<slug>.md
- size: <bytes>
- ##/### headings: <count> (<count-without-anchors> missing inline <a id="…"></a> anchors)
- template sections present:   [§1, §3, §4.1, §4.2, …]
- template sections missing:   [§2, §4.3, §7]
- template sections extra:     [§<heading> — not in template; user must justify keep/drop]
- terminology not in spec-01 glossary: [<term>, …]      (only if spec-01 is gate-passed)
- decisions referenced but absent from decisions.md / implementation-decisions.md: [<ref>, …]
- structural-checklist preview (without rubric scoring yet):
    item 1 — pass | fail (<one-line reason>)
    item 2 — pass | fail (<one-line reason>)
    …
```

Mapping rules for "section present / missing / extra":

- Match by **template § number AND heading slug** (case-insensitive). A heading present under any name carrying the right §-number bullet from the template counts as present.
- A template section whose body in the existing spec is only a comment or a placeholder counts as **missing**.
- A spec heading that does not match any template entry is **extra**.

### Step C — Choose adoption mode

Ask the user exactly once per spec which adoption mode to use:

| Mode        | Behaviour                                                                                                                                                                                                                                                                                                                                                            |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `adopt`     | Proceed to Step D. Existing content is preserved; missing sections are added; the sub-skill grills only on items the existing content does not already answer.                                                                                                                                                                                                       |
| `re-author` | Discard adoption. Rename the existing file to `01-specifications/spec-NN-<slug>.pre-adoption-YYYYMMDD.md` for reference, then enter the sub-skill's normal grilling loop from scratch as if the spec were `missing`.                                                                                                                                                  |
| `skip`      | Insert an `<!-- adoption: deferred date=YYYY-MM-DD -->` HTML comment as the first line of the file (above any existing content). This re-classifies the file as `adopt-pending` on every subsequent bootstrap (per §1 table row (b)), so the next invocation returns to Step C instead of falling through to normal grilling. Halt the main loop with a one-line note. No other edits are made. |

Mode is captured as a `decisions.md` entry tagged `adoption-mode` for traceability. The `skip` mode is intentionally non-destructive: it does NOT lose adoption context, and the next invocation will re-offer all three modes.

### Step D — Mechanical normalisation (only on `adopt`)

These edits are deterministic and require no user input. Apply in order:

1. **Anchor injection.** For every `##` and `###` heading lacking an inline `<a id="…"></a>` anchor, insert one. Slug derivation:
   - Strip leading section numbers (`1.`, `2.3`, `10.10`, etc.) and Markdown markup.
   - Lowercase; non-alphanumerics → `-`; collapse repeats; trim.
   - On collision within the file, append `-2`, `-3`, … in first-seen order.
     Fenced code blocks are skipped. Headings that already have an anchor are left alone.
2. **Template scaffolding for missing sections.** For each template § marked missing in Step B, insert the template's heading and its placeholder comment at the position the template dictates. Surrounding existing content is untouched.
3. **Decisions log triage.** For any `D-NNN` referenced in the spec but absent from `decisions.md` / `implementation-decisions.md`, insert a stub entry with `status: needs-content` so the gate's decision-log checks have something to bind to. The user fills the stub during Step E.
4. **Spec-01 glossary stubs (only when adopting spec-02 or later, and spec-01 is gate-passed).** For each terminology gap surfaced in Step B, add a `needs-definition` stub to `01-specifications/spec-01-domain-model.md` §Glossary and mark spec-01's `gate-result` as `FAIL` with finding "Adoption of spec-NN introduced N un-glossaried terms" — spec-01 must be re-gated before this spec can pass.

### Step E — Adoption-mode grilling

Invoke the sub-skill's normal `<grilling-sequence>` but in **adoption mode**:

- For each Phase / step in the grilling sequence:
  - If the existing content already satisfies the step (judged against the matching `<exit-checklist>` item), **skip** the question; do not re-ask the user.
  - If the existing content partially satisfies the step, present the existing content verbatim to the user, then ask only what is missing.
  - If the existing content does not satisfy the step, run the question normally (with the standard's recommended answer + rationale, as in fresh authoring).
- Apply edits inline per the sub-skill's writing rules.
- Log every non-trivial decision per [DECISIONS-PROTOCOL.md](./DECISIONS-PROTOCOL.md).

The user never gets re-grilled on content that was already there and already valid.

### Step F — Exit-checklist + gate

1. Run the sub-skill's `<exit-checklist>` literally; every item must pass.
2. Run the per-spec gate per [gates/GATE-PROTOCOL.md](./gates/GATE-PROTOCOL.md). On PASS, stamp the spec exactly as a fresh authoring pass would; on FAIL, re-enter Step E for the failed items.

## 3. Cascading effects

Adoption of a later spec can reveal defects in an earlier one (a missing glossary term, an unrealized concept, an unanchored reference). The orchestrator handles cascades the same way it handles cross-spec gate failures:

- The earlier spec's `gate-result` block is rewritten to `FAIL` with the cascading finding appended.
- Its state reverts to `gate-failed`, re-entering the main loop.
- The currently-being-adopted spec halts mid-Step E until the earlier spec re-passes.

`spec-02` sidecars are part of the `spec-02` family for cascade purposes: adopting any sidecar can re-open the base `spec-02`, and adopting base `spec-02` can re-open any sidecar.

## 4. Hard rules

- Adoption **never** silently rewrites user-authored content. Only mechanical normalisations (anchors, missing-section scaffolding, decision-log stubs, glossary stubs) are applied without prompting.
- Adoption **never** lowers the gate bar. Same checklist, same rubric ≥4 per dimension.
- Adoption mode is decided **per spec**, not globally. The user may `adopt` spec-00..03 and `re-author` spec-04, for instance.
- Adoption order strictly follows the canonical order. The orchestrator does not skip ahead to a later spec because it looks cleaner.
- A `re-author` choice **moves** (does not delete) the existing file with the `.pre-adoption-YYYYMMDD.md` suffix so the user retains the original.
- The cross-spec consistency gate runs unchanged after every per-spec gate passes — including the final pass that closes adoption.

## 5. Reporting

The resumption report format is **canonical in [SKILL.md](./SKILL.md) §Resumption** — do not duplicate it here. `adopt-pending` artifacts MUST appear in the report with their Step B assessment block inlined under the artifact's bullet so the user sees adoption context before being asked to choose a mode in the main loop. Deferred-adoption files (those carrying `<!-- adoption: deferred ... -->`) appear as `adopt-pending` with the assessment block plus a `deferred-since: YYYY-MM-DD` line so the user can see the choice has been re-offered before.

Each adoption-mode session emits a one-line completion status:

```text
[dm-spec-creation] spec-NN adopted: <X anchors injected> | <Y missing sections scaffolded> | <Z gate questions asked> | gate PASS
```

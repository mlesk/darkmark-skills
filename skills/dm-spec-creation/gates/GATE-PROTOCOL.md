# Gate Protocol

Every per-spec gate file has the same shape:

1. **Structural checklist** — literal pass/fail items.
2. **Rubric** — 1–5 scored dimensions with `4` as the pass bar.
3. **Run procedure** — what to do, in order.
4. **Output template** — exact text to append to the spec file.

## Run procedure (applies to every gate)

1. Read the spec file in full.
2. Read every standard listed in the spec's sub-skill `<standards-inputs>`.
3. Read the decisions logs and confirm every entry tagged with this spec's number is referenced from the spec, and every spec-level claim that resolves a trade-off has a backing entry.
4. Walk the **structural checklist**. Mark each item PASS or FAIL with evidence (section reference).
5. Walk the **rubric**. Score each dimension 1–5. Justify each score with one sentence citing evidence.
6. Compute result:
   - **PASS** iff every checklist item passes AND every rubric dimension scores ≥4.
   - **FAIL** otherwise.
7. Append the result block to the spec file (format below).
8. If FAIL, surface findings to the user and re-enter the sub-skill's grilling loop for the failed sections only.

## Output block — PASS

Both `checklist:` and `rubric:` blocks are REQUIRED on PASS. `checklist:` enumerates every structural-checklist item with `PASS` plus the §-anchor or evidence that satisfies it; this persists the gate walk on disk so a later reader (or an audit) can see the gate was actually run rather than rubber-stamped.

```markdown
---

<!-- gate-result: PASS date=YYYY-MM-DD reviewer=dm-spec-creation
checklist:
  1: PASS — §<section-or-evidence>
  2: PASS — §<section-or-evidence>
  ...
rubric:
  <dimension-1>: 5
  <dimension-2>: 4
  ...
-->
```

## Output block — FAIL

On FAIL, `checklist:` enumerates every item with `PASS` or `FAIL` plus evidence; `findings:` lists only the FAIL items with a remediation; `rubric:` records all scored dimensions (any dimension <4 is itself a finding).

```markdown
---

<!-- gate-result: FAIL date=YYYY-MM-DD reviewer=dm-spec-creation
checklist:
  1: PASS — §<section>
  2: FAIL — <one-line evidence>
  3: PASS — §<section>
  ...
findings:
  1. §<section> — <issue>. Fix: <remediation>.
  2. ...
rubric:
  <dimension-1>: 3
  ...
-->
```

## Honesty rule

If you have not actually walked every checklist item and scored every rubric dimension, you have not run the gate. Stating PASS without doing the work — including omitting the `checklist:` block or filling it without inspecting each item — is a critical failure of this skill. The `checklist:` block is the on-disk artifact that distinguishes a real gate walk from a rubber stamp.

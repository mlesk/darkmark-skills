# Orchestration Protocol

This file defines the deterministic state machine the orchestrator runs. Do not deviate.

## 1. Bootstrap (run every invocation)

1. **Verify the bundled standards exist.** This skill is self-contained — every standard lives under `standards/` inside the skill folder. The authoritative list of required standards is the mapping table in [STANDARDS-PROTOCOL.md](./STANDARDS-PROTOCOL.md), plus the `<standards-inputs>` block of every sub-skill under [specs/](./specs/). Verify every file referenced from those two sources exists under `standards/`. If any are missing, the skill is corrupt. Halt and ask the user to restore the skill. Do not fall back to repo-level standards folders. Do not maintain a parallel list here — `STANDARDS-PROTOCOL.md` is the single source of truth.

2. **Locate (or create) the specs folder.**
   - Default: `01-specifications/` at the repo root.
   - Before defaulting, scan the repo root for `CLAUDE.md`, `AGENTS.md`, `CONTEXT.md`, and `README.md` for an existing specs-folder convention. If one of those files names a different specs folder, propose it as the default in the confirmation question (with a one-line citation of where the convention was found).
   - If the chosen folder is absent, ask before creating it.

3. **Locate (or create) the decisions logs.**
   - `01-specifications/decisions.md`
   - `01-specifications/implementation-decisions.md`
   - If missing, create from the templates in [templates/](./templates/) at the moment the first decision is recorded — not before.

4. **Detect resumption state.** For each of spec-00 … spec-06, classify into one of five states (see [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md) §1 for the full decision table):
   - `missing` — file does not exist.
   - `adopt-pending` — file exists with substantive foreign content (≥ 500 bytes AND ≥ 2 `##` headings) AND NO `<!-- gate-result: ... -->` block AND NO characteristic skill scaffolding markers (`<!-- 1–3 sentences -->`, `<!-- per spec-01 remembered concept -->`, etc.). **Also classified as `adopt-pending`:** any file containing an `<!-- adoption: deferred ... -->` marker (set by a prior `skip` choice — see [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md) §2 Step C), regardless of scaffolding markers. This is a spec that was authored outside this skill (or whose adoption was deferred) and needs the adoption protocol before it can be gated.
   - `draft` — file exists, was clearly being authored through this skill (template scaffolding markers present OR `TBD`/`TODO`/empty required section), has no gate-result block, AND has no `<!-- adoption: deferred ... -->` marker. A draft file MAY carry a `<!-- last-resolved-question: PhaseX.N -->` marker (see §3 step 5a); sub-skills resume from the question after that marker.
   - `gate-failed` — file exists with a `<!-- gate-result: FAIL ... -->` block at the bottom.
   - `gate-passed` — file ends with `<!-- gate-result: PASS date=YYYY-MM-DD reviewer=spec-creation -->`.

5. **Detect spec-02 sidecars.** Glob `01-specifications/spec-02[a-z]-*.md` AND scan base `spec-02-architecture.md` §Sidecar Index for referenced sidecar filenames. Compute the **set symmetry** between disk and index:
   - Files on disk but not in the index → classify as `orphan-sidecar`. The spec-02 family is **not** gate-passed; surface this to the user in the resumption report and require either a base spec-02 amendment (re-gates spec-02) or deletion of the orphan.
   - Files in the index but not on disk → classify as `missing`. The spec-02 family is **not** gate-passed.
   - For each sidecar that exists on disk, compute the same five-state status as in step 4. If any sidecar is `adopt-pending`, `draft`, or `gate-failed`, the spec-02 family is **not** gate-passed regardless of the base spec-02 status.

6. **Produce adoption assessment** for every `adopt-pending` artifact (per [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md) §2 Step B). The assessment block is part of the resumption report; the user sees it before choosing adopt / re-author / skip in the main loop.

7. **Report state to the user.** Use the format shown in [SKILL.md](./SKILL.md) §Resumption — include detected sidecars as nested entries under spec-02, and include the adoption-assessment block for each `adopt-pending` artifact.

## 2. Main loop

```text
while any spec or spec-02 sidecar is not gate-passed:
    next = first non-passing artifact in this priority order:
        1. lowest-numbered base spec in {00..06} that is not gate-passed,
           BUT if `next` would be spec-03 and any spec-02 sidecar exists
           that is missing, adopt-pending, draft, or gate-failed,
           jump to that sidecar first.

    if next.state == adopt-pending:
        run ADOPTION-PROTOCOL.md §2 (Step C → Step F) on `next`
           - user chooses mode: adopt | re-author | skip
           - on `adopt`:    mechanical normalisation (Step D),
                            adoption-mode grilling (Step E),
                            exit-checklist + gate (Step F)
           - on `re-author`: rename file to <name>.pre-adoption-YYYYMMDD.md;
                            set state = missing; continue loop (next iteration
                            will fall through to the standard branch below)
           - on `skip`:     mark file state = draft; halt main loop with note
        (the protocol still ends in the per-spec gate; on PASS, stamp normally)
    else if next is a base spec (00..06):
        run sub-skill for `next`           # grilling from scratch / from draft
        run per-spec gate for `next`
    else if next is a spec-02 sidecar (spec-02[a-z]-*.md):
        run spec-02 sub-skill in sidecar mode for `next`
           (drafts from templates/spec-02x-technical-spec.template.md,
            cites base spec-02 anchors, logs decisions)
        run gates/spec-02x-sidecar-gate.md for `next`

    if gate FAIL:
        fix the spec (loop with user)
        re-run gate
    else:
        stamp `<!-- gate-result: PASS ... -->` at end of spec file

   run cross-spec consistency gate
   if FAIL:
      open the lowest-numbered offending spec
      set its gate-result block to FAIL with the cross-spec finding
      re-enter main loop
   else if any spec or spec-02 sidecar is still not gate-passed:
      continue loop
   else:
      stamp `<!-- cross-spec-gate: PASS date=YYYY-MM-DD -->` at top of decisions.md
      declare DONE to user, AND hand off:
         "All specs and the cross-spec gate report PASS.
          Implementation is owned by the sibling `spec-execution` skill,
          which runs the autonomous state machine in
          `standards/planning-standards-inside-out-phases.md` §11
          against `01-specifications/spec-06-execution-plan.md`
          and `01-specifications/execution-state.md`.
          Invoke `spec-execution` to begin implementation."
```

## 3. Per-spec sub-skill contract

Every sub-skill in [specs/](./specs/) follows the same contract:

1. **Load inputs.** Read all earlier passed specs + the standards files listed in the sub-skill's `<standards-inputs>` section.
2. **Detect carryover.** Read `decisions.md` and `implementation-decisions.md` for entries tagged with this spec's number.
3. **Detect adoption mode.** If the orchestrator invoked this sub-skill on an `adopt-pending` artifact, follow [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md) §2 Step E (adoption-mode grilling) instead of step 4 below — skip questions whose answers are already in the existing content, ask only what is missing.
4. **Grill the user** through every section of the corresponding template in [templates/](./templates/), in order. One question at a time. Always offer a recommended answer with rationale citing a standard rule (e.g. "design-domain-model-standards.md §3 [MUST] …").
5. **Write inline** to the spec file as each section is resolved.
   5a. **Mark grilling progress.** Each time a grilling-sequence question is fully answered AND its content is written to the spec, update (or insert at the top of the spec, just below the H1) a single HTML comment of the form `<!-- last-resolved-question: PhaseX.N -->` where `PhaseX.N` matches the sub-skill's `<grilling-sequence>` numbering. This makes mid-session interruption recoverable: on resumption, a `draft` spec carrying this marker resumes from question `PhaseX.N+1`, not from the top. On gate PASS, the marker is removed before the `<!-- gate-result: PASS ... -->` stamp is appended.
6. **Log every non-trivial decision** to the appropriate decisions log immediately. See [DECISIONS-PROTOCOL.md](./DECISIONS-PROTOCOL.md).
7. **Self-check** with the sub-skill's `<exit-checklist>` before handing off to the gate.

## 4. Per-spec gate contract

1. Run the gate's **structural checklist** as a literal pass/fail.
2. Run the gate's **rubric** by scoring each dimension 1–5 with one-sentence evidence.
3. Compute result:
   - `PASS` iff every structural item passes AND every rubric dimension scores ≥4.
   - `FAIL` otherwise. Emit a numbered finding list. Each finding cites a section and a remediation.
4. Append the result block to the bottom of the spec file:

   ```markdown
   <!-- gate-result: PASS date=2026-05-31 reviewer=spec-creation -->
   ```

   or:

   ```markdown
   <!-- gate-result: FAIL date=2026-05-31 reviewer=spec-creation
   findings:
     1. §4.2 — Term "Universe" used but missing from glossary. Fix: add to spec-01 §Glossary.
     2. ...
   -->
   ```

## 5. Cross-spec gate contract

Runs after every successful per-spec gate (including spec-02x sidecars), not only at the end. See [gates/cross-spec-consistency.md](./gates/cross-spec-consistency.md). Failures invalidate the offending spec's PASS stamp.

## 6. Hard rules

- **Never** mark a gate PASS to make progress. The user can force-override only by explicitly saying "override gate: <reason>" — log this to `decisions.md` with tag `gate-override` and proceed.
- **Never** edit a passed spec without re-running its gate AND the cross-spec gate.
- **Never** skip the decisions-log update step. Specs without decision-log backing fail the gate.
- **Never** generate content the user did not confirm. Drafts are written from confirmed answers, not from invention.

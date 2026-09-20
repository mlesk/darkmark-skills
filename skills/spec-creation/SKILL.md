---
name: spec-creation
description: Opinionated, gate-driven workflow that rapidly produces a complete, ruthlessly consistent set of system specifications and an inside-out phased execution plan for solutions built on this repo's canonical stack — C# / ASP.NET Core / .NET Aspire / EF Core + TypeScript / React (Vite + shadcn), Object Modeling in Color, and Clean Architecture. The execution plan is engineered for autonomous implementation-agent delivery. Bundles the full standards set inside the skill's `standards/` folder; the user only confirms or deviates. Use when starting a new solution on this stack, hardening an existing spec set (adopting foreign `01-specifications/` content), or producing execution-ready plans. Do not use to implement code from a passed spec set (hand off to `spec-execution`), to draft a single PRD without architecture or plan (use `to-prd`), to break a passed plan into trackable issues (use `to-issues`), or for exploratory ideation before any spec exists (use a brainstorming skill, then return).
---

<what-to-do>

You are running an opinionated, gate-driven specification workflow. The acceptable outcome is a complete, internally consistent spec set that an autonomous agent could implement without ambiguity, using this repo's canonical stack and standards (see [STACK-DEFAULTS.md](./STACK-DEFAULTS.md)).

This is a **multi-session workflow**. Expect 7 canonical specs (plus any conditional architecture sidecars), iterative one-question-at-a-time grilling per spec, and a hard pass/fail gate before each advance. Do not invoke for a quick sketch or a one-shot PRD — see the `Do not use when` boundary in the skill description.

The skill is built for **acceleration**. Stack, architecture, and planning method are not open questions — they are pre-decided defaults backed by the standards bundle. The user's job is to **confirm or deviate**, not to choose from scratch.

You will:

1. **Bootstrap** the workspace (locate standards, specs folder, decisions logs) — see [ORCHESTRATION.md](./ORCHESTRATION.md).
2. **Detect resumption state** — for each spec, determine whether it is `missing`, `adopt-pending` (foreign content authored outside this skill — see [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md)), `draft`, `gate-failed`, or `gate-passed`.
3. **Drive specs in strict order** (00 → 06). Do not skip. Do not parallelize.
4. **Run the per-spec sub-skill** for the next non-passing spec. Each sub-skill grills the user one question at a time, drafts inline, and updates the decisions logs as decisions crystallise.
5. **Run the per-spec gate** before advancing. A gate failure stops the workflow; you fix the spec, then re-run the gate. **Never advance on a soft pass.**
6. **After every successful per-spec gate, run the cross-spec consistency gate** ([gates/cross-spec-consistency.md](./gates/cross-spec-consistency.md)). Any failure sends you back to the offending spec immediately; do not wait until spec-06 to discover terminology drift or traceability breakage.
7. **Declare done** only when every per-spec gate is currently `PASS` and the most recent cross-spec gate run also reports `PASS`.

Work the orchestration loop in [ORCHESTRATION.md](./ORCHESTRATION.md) exactly. Do not improvise the order. Do not invent your own gates. Do not soften gate criteria to make progress.

</what-to-do>

<supporting-info>

## Canonical stack & standards

This skill is opinionated. Stack, architecture, and planning are pre-decided per [STACK-DEFAULTS.md](./STACK-DEFAULTS.md) and backed by the standards bundle declared in [STANDARDS-PROTOCOL.md](./STANDARDS-PROTOCOL.md). Sub-skills ask the user to **confirm or deviate** — they never ask the user to invent the stack.

If any standards-bundle file is missing from `./standards/`, the skill is corrupt and the orchestrator halts.

## Canonical spec set

This skill produces a **canonical spine** of seven documents under `01-specifications/`, plus an optional **architecture sidecar family** when one or more architecture slices need deeper normative treatment than fits in base `spec-02`.

### Canonical spine (always required)

| #   | File                                 | Sub-skill                                                                                          | Gate                                             |
| --- | ------------------------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| 00  | `spec-00-functional-prd.md`          | [specs/spec-00-prd/SKILL.md](./specs/spec-00-prd/SKILL.md)                                         | [gates/spec-00-gate.md](./gates/spec-00-gate.md) |
| 01  | `spec-01-domain-model.md`            | [specs/spec-01-domain-model/SKILL.md](./specs/spec-01-domain-model/SKILL.md)                       | [gates/spec-01-gate.md](./gates/spec-01-gate.md) |
| 02  | `spec-02-architecture.md`            | [specs/spec-02-architecture/SKILL.md](./specs/spec-02-architecture/SKILL.md)                       | [gates/spec-02-gate.md](./gates/spec-02-gate.md) |
| 03  | `spec-03-implementation-guidance.md` | [specs/spec-03-implementation-guidance/SKILL.md](./specs/spec-03-implementation-guidance/SKILL.md) | [gates/spec-03-gate.md](./gates/spec-03-gate.md) |
| 04  | `spec-04-user-interface.md`          | [specs/spec-04-user-interface/SKILL.md](./specs/spec-04-user-interface/SKILL.md)                   | [gates/spec-04-gate.md](./gates/spec-04-gate.md) |
| 05  | `spec-05-app-use-cases.md`           | [specs/spec-05-app-use-cases/SKILL.md](./specs/spec-05-app-use-cases/SKILL.md)                     | [gates/spec-05-gate.md](./gates/spec-05-gate.md) |
| 06  | `spec-06-execution-plan.md`          | [specs/spec-06-execution-plan/SKILL.md](./specs/spec-06-execution-plan/SKILL.md)                   | [gates/spec-06-gate.md](./gates/spec-06-gate.md) |

### Architecture sidecar family (conditional, formal when present)

When base `spec-02-architecture.md` would become too large, too implementation-shaping, or too module-specific to keep coherent, the `spec-02` sub-skill MAY emit one or more **architecture sidecars** named:

```text
01-specifications/spec-02a-<slice>.md
01-specifications/spec-02b-<slice>.md
01-specifications/spec-02c-<slice>.md
…
```

A sidecar is a **module-scoped or technical-slice-scoped architecture contract**. It is deeper and more normative than base `spec-02`, but narrower in surface. It MAY introduce technical contracts (e.g. download orchestration, import lineage, durable-job execution) that downstream `spec-06` Phases cite directly via `spec-anchors:`.

Sidecars are **conditional but formal**:

- Optional overall — a small solution may have zero sidecars.
- First-class when present — gated, anchorable from `spec-06`, and consumed by the sibling `spec-execution` skill as immutable inputs.
- Authority-bounded — a sidecar **narrows** base `spec-02` for its slice; it MUST NOT contradict `spec-01` or base `spec-02`. Contradictions FAIL the `spec-02` family gate.
- Created as part of the `spec-02` stage — after the base architecture passes its structural checklist, the sub-skill identifies any required sidecars, drafts them, anchors them, and gates them. Only when the full `spec-02` family passes does the workflow advance to `spec-03`.

Sidecars are **architecture**, not implementation guidance. `spec-03` remains the home for shared coding conventions, error model, test posture, DI, configuration, persistence-mapping rules, and analyzer policy. `spec-03` consumes active sidecars as upstream constraints when relevant.

Gate, template, and standards plumbing:

- Each sidecar uses [gates/spec-02x-sidecar-gate.md](./gates/spec-02x-sidecar-gate.md) as its gate.
- Each sidecar is drafted from [templates/spec-02x-technical-spec.template.md](./templates/spec-02x-technical-spec.template.md).
- Required standards inputs per sidecar follow the `spec-02x` row in [STANDARDS-PROTOCOL.md](./STANDARDS-PROTOCOL.md), with optional slice-specific additions documented in the sidecar's front-matter.

Plus two living artifacts maintained continuously across all phases:

- `decisions.md` — architectural / strategic decisions (template: [templates/decisions.template.md](./templates/decisions.template.md))
- `implementation-decisions.md` — tactical / implementation decisions (template: [templates/implementation-decisions.template.md](./templates/implementation-decisions.template.md))

## Standards are the substrate

The skill treats the bundled standards under [`./standards/`](./standards/) as **the** authoritative basis — `standards/coding-standards-*.md`, `standards/design-standards-*.md`, and `standards/planning-standards-inside-out-phases.md`. Read every applicable standard file before running its corresponding sub-skill. Sub-skills cite standards by `[MUST]`/`[SHOULD]` rule when recommending answers. See [STANDARDS-PROTOCOL.md](./STANDARDS-PROTOCOL.md) for the spec-to-standards mapping.

## Interaction style

- **One question at a time.** Wait for the answer before the next.
- **Always offer a recommended answer** with a one-line rationale tied to a standard or a prior spec.
- **Cross-check every claim** against earlier specs and the decisions logs. If you find a contradiction, surface it before writing.
- **Write inline.** Update the spec, `decisions.md`, or `implementation-decisions.md` the moment a decision lands. Never batch.
- **Refuse vague answers.** If the user says "we'll figure it out later", push back: name the decision, classify it, log it, or defer it explicitly with an owner and trigger.

## Gate discipline

Per-spec gates have two layers:

1. **Structural checklist** — required sections present, required cross-references present, no `TBD`/`TODO` markers, decisions log entries exist for every spec-level decision.
2. **Rubric score** — an LLM-as-judge pass scoring 1–5 across the dimensions listed in each gate file. Any dimension <4 fails the gate.

Cross-spec gate adds eight layers (see [gates/cross-spec-consistency.md](./gates/cross-spec-consistency.md)). Examples:

3. **Terminology consistency** — every domain term used in spec-02 / spec-02x sidecars / spec-03..06 appears in spec-01's glossary with identical meaning.
4. **Reference integrity** — every requirement in spec-00 traces forward to at least one use case in spec-05 and at least one Phase in spec-06.
5. **Capability closure** — every concept in spec-01 is either realized in spec-02 (or a spec-02x sidecar) / spec-03 / spec-06 or explicitly marked out-of-scope with rationale.
6. **Execution-plan integrity** — every `spec-anchors:` reference in spec-06 resolves to an inline HTML anchor in the target spec (including any referenced `spec-02x` sidecar); every Phase's `tests to add` matches its layer per the planning standard's test-posture table.

See [gates/GATE-PROTOCOL.md](./gates/GATE-PROTOCOL.md) for the exact run procedure.

## Failure modes to avoid

- **Skipping ahead** because a later spec "feels more concrete". The order encodes dependency direction. Earlier specs constrain later ones.
- **Letting the user dictate scope creep** mid-spec. Capture the new idea as a decision-log entry tagged `deferred` or `out-of-scope` and continue.
- **Treating a gate as a formality.** A gate exists to surface drift. If it never fails, you are not running it honestly.
- **Inventing new sections** not present in the template. Templates are the contract.
- **Writing implementation detail in spec-00 or spec-01.** Both are about meaning, not mechanism.

## Resumption

On every invocation, run the bootstrap in [ORCHESTRATION.md](./ORCHESTRATION.md) §1 to detect existing artifacts and prior gate results. Each artifact is classified into one of five states: `missing`, `adopt-pending` (foreign content authored outside this skill), `draft`, `gate-failed`, `gate-passed`. See [ADOPTION-PROTOCOL.md](./ADOPTION-PROTOCOL.md) for the full classification table and the adoption flow used when a spec is `adopt-pending`.

Report the resumption state to the user before doing anything else. If any artifact is `adopt-pending`, include its adoption-assessment block. Example with mixed states (some foreign specs being adopted, one sidecar already passed):

```text
Resumption report
- spec-00: gate-passed (2026-05-29)
- spec-01: adopt-pending
    - foreign content, 9 sections, 31 headings, 0 anchors, no gate-result
    - template sections present:  [§1, §2, §3, §4, §6, §7]
    - template sections missing:  [§5 Glossary, §8 Out-of-scope]
    - structural-checklist preview: 6/12 items pass
- spec-02: adopt-pending
    - foreign content, 10 sections, 42 headings, 0 anchors, no gate-result
    - template sections missing:  [§8 Non-Functional Realization, §9 Sidecar Index]
- spec-02 sidecars:
    - spec-02a-data-download.md: adopt-pending (33 anchors present, no gate-result)
    - spec-02b-data-import.md:   gate-passed (2026-05-31)
- spec-03..06: missing
- decisions.md: 7 entries
- implementation-decisions.md: 2 entries
Next action: run adoption pass on spec-01 (lowest-numbered adopt-pending). Will ask mode (adopt | re-author | skip), then proceed.
```

Then proceed.

## After this skill completes

This skill terminates when every per-spec gate and the cross-spec gate report `PASS`. It does **not** implement the system. Hand off to the sibling `spec-execution` skill, which runs the autonomous implementation loop defined in `standards/planning-standards-inside-out-phases.md` §11 against `spec-06-execution-plan.md` and `01-specifications/execution-state.md`.

Do not attempt to implement from inside this skill. Implementation is a different responsibility with a different state machine and a different rhythm.

</supporting-info>

# Planning Standard: Inside-Out Phased Execution

> Authored by this skill. Governs the structure of `spec-06-execution-plan.md` so that the plan is sufficient for an autonomous implementation agent (running under the sibling `dm-spec-execution` skill) to execute the solution end-to-end without further human steering.

## 1. Purpose

The execution plan exists to drive an autonomous implementation agent. It MUST be a deterministic, ordered, dependency-respecting sequence of work the agent can pick up Phase-by-Phase, ship as a PR, verify mechanically, and continue from across sessions.

The plan describes WHAT and IN WHAT ORDER. The HOW is fully constrained by specs 00–05 and the bundled coding/design/testing standards. The plan adds zero new vocabulary.

## 2. Layered architecture vocabulary

Plans MUST use the canonical layer abbreviations from `design-standards-clean-architecture.md`:

| Code | Layer            | Responsibility                                      |
| ---- | ---------------- | --------------------------------------------------- |
| FE   | Front-End        | React app (Vite + shadcn + Tailwind)                |
| UI   | UI BFF API       | ASP.NET Core Minimal API surface serving the FE     |
| UC   | Use Case         | Application orchestrators (spec-05)                 |
| PD   | Problem Domain   | Domain model + PD-owned contracts (spec-01)         |
| SI   | System Interface | Infrastructure adapters: persistence, sources, jobs |

Dependency direction is strict: `FE → UI → UC → PD ← SI`. PD owns the contracts SI implements; PD never depends on SI.

## 3. Inside-out phase ordering

Phases MUST be ordered inside-out:

0. **Preflight** — toolchain version assertions, repo-level config files (`global.json`, `.tool-manifest`, `package.json`, `pnpm-workspace.yaml`), `.github/workflows/ci.yml`. Establishes that all subsequent Phases can mechanically run their `done-when` commands.
1. **Scaffold** — projects, namespaces, architecture-test fences for FE/UI/UC/PD/SI per `coding-standards-testing.md` §3.
2. **PD** — business concepts + PD-owned contracts, grown module-by-module.
3. **SI persistence baseline** — provider registration, mappings, migrations, tuning.
4. **PD durable-job contracts + SI job storage + worker-host execution of UC flows**.
5. **SI source adapters** — provider-specific import/persistence paths behind PD contracts.
6. **UC** — use case layer fulfilling everything the UI BFF will need.
7. **UI BFF** — endpoints fulfilling everything the FE will need.
8. **FE** — screens against the stable UI surface, in dependency order.
9. **End-to-end vertical(s)** — exercise the full stack confirming inter-layer composition.
10. **Hardening** — observability, failure handling, deployment packaging, architecture-test coverage extension.

A plan MAY collapse or split these depending on the solution, but ordering MUST remain inside-out. Any deviation requires a `decisions.md` entry of type `standards-deviation`. Phase P0 MAY NOT be skipped — preflight is what makes every later `done-when` runnable.

## 4. Phase anatomy

Every Phase entry in `spec-06-execution-plan.md` MUST carry these fields. Missing any field fails the gate.

```text
### P<N>[<a|b|c>] <Phase title>
- layer(s):              ⊆ { FE, UI, UC, PD, SI, cross-cutting }
- depends-on:            [ <phase-id>, … ]                # acyclic; only earlier phases
- scope:                 1–3 sentences in repo terms (spec-01/02/04/05 nouns only)
- spec-anchors:          spec-NN#<anchor-id>, …           # at least one; anchor form per §4a
- deliverables:          ordered checklist (see §5)
- files (touch budget):  directories / file patterns to add or change (repo-relative)
- tests to add:          typed per layer (see §6)
- done-when:             pass/fail commands + assertions (see §7)
- human-gate:            none | <one-line description>
- decisions inherited:   [ D-NNN, … ] OR "none"           # existing D-NNNs this Phase must respect
- decisions to make:     [ "<open question>", … ] OR "none"  # the agent MUST log a fresh D-NNN for each before marking done
```

### 4a. Anchor form for `spec-anchors:`

`spec-anchors:` MUST use the form `spec-NN#kebab-anchor-id` or `spec-NN<letter>#kebab-anchor-id`, where:

- `spec-NN` targets a canonical-spine spec (`spec-00` … `spec-06`); the on-disk file matches `01-specifications/spec-NN-*.md`.
- `spec-NN<letter>` targets a sidecar (currently only `spec-02a`, `spec-02b`, … are valid); the on-disk file matches `01-specifications/spec-NN<letter>-*.md`.
- The anchor-id is an inline HTML anchor (`<a id="kebab-anchor-id"></a>`) placed at the start of the target heading in the target spec file.

Plain section-number references (`spec-NN §3.2`) are forbidden — section numbers shift silently and rot every plan that references them. The cross-spec gate (Layer 8) verifies every anchor resolves, including sidecar anchors.

## 5. Deliverables checklist

Each Phase contains a numbered checklist of deliverables. A deliverable is the smallest unit of work the agent ticks off in `execution-state.md`. Properties:

- **Numbered** within the Phase (`P2a.1`, `P2a.2`, …).
- **Self-contained**: one ticked deliverable leaves the build green.
- **Verifiable**: ties to a test or an architecture-test assertion or a successful command.
- **Repo-anchored**: names directories/types/migrations/endpoints already present in specs.

A Phase with zero deliverables fails the gate.

## 6. Test posture by layer

The plan MUST specify tests per Phase using these typed buckets. Frameworks and project naming are pinned in `coding-standards-testing.md` — the plan never re-chooses them.

| Layer touched | Required test types                                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| PD            | xUnit unit (pure) + xUnit integration against PD with SI **faked** behind PD contracts                                                            |
| SI            | xUnit direct integration tests against real adapters (real SQLite, real file I/O, etc.)                                                           |
| UC            | xUnit full integration tests covering UC → PD → real SI (no FE)                                                                                   |
| UI BFF        | xUnit integration tests against BFF endpoints via `WebApplicationFactory<TProgram>`                                                               |
| FE            | Vitest + RTL component tests + ≥1 Playwright e2e test per use-case screen + Playwright visual-parity test against the corresponding mockup screen |
| cross-cutting | NetArchTest architecture tests + smoke (`dotnet run --project AppHost` boots clean)                                                               |

The minimum architecture-test set is enumerated in `coding-standards-testing.md` §3. P1's deliverables MUST scaffold each named assertion; later Phases MAY extend.

For FE Phases the visual-parity test compares against `01-specifications/screen-mockups/` and is mandatory unless the Phase logs a `D-NNN` documenting the divergence.

## 7. Done-when bar

Every Phase MUST end with a `done-when` block enumerating commands or assertions the agent can run mechanically. The Phase is `done` only if every line passes. Forbidden:

- "Looks good" / "reviewed" / "approved by X" (unless behind `human-gate:`).
- "Tests added" without naming the test class or assertion target.
- Open-ended judgement.

The baseline `done-when` for every Phase (regardless of layer) MUST use these exact commands (per `coding-standards-testing.md` §5):

```text
- `dotnet build MoneyMaker.slnx`             — solution-wide build clean, zero warnings (whole solution, not just touched projects)
- `dotnet test MoneyMaker.slnx --filter Category=Architecture`  — architecture tests pass
- `dotnet test MoneyMaker.slnx`              — full backend test suite passes (incl. new tests for this Phase)
- lint/format clean on touched files
```

Phases touching FE additionally require:

```text
- `pnpm --filter ./src/MoneyMaker.WebApp run typecheck`  — clean
- `pnpm --filter ./src/MoneyMaker.WebApp run lint`       — clean
- `pnpm --filter ./src/MoneyMaker.WebApp run test`       — component tests pass
- `pnpm --filter ./src/MoneyMaker.WebApp run test:e2e`   — e2e tests pass, including the visual-parity test for in-scope screens
```

Building the whole solution (not just "touched projects") is mandatory — incremental builds hide downstream breakage.

## 8. Coverage matrices

`spec-06-execution-plan.md` MUST include four coverage matrices. Each row demands ≥1 Phase coverage; gaps fail the gate.

1. **spec-00 acceptance criteria → Phase-ids** (every AC covered by ≥1 Phase).
2. **spec-05 use cases → Phase-ids** (every UC lands in UC layer in some Phase, and again in UI/FE phases).
3. **spec-04 screens → Phase-ids** (every screen lands in a FE Phase).
4. **spec-01 classes with behavior → Phase-ids** (every class lands in a PD Phase).

## 9. Sub-phases and PR policy

- A Phase MAY decompose into ordered sub-phases (`P2a`, `P2b`, `P2c`).
- Each Phase **or** sub-phase ships as **one PR**.
- Branch name = phase-id slugified (e.g. `P2a-pd-core-concepts`).
- Merge to `main` only on green `done-when`.
- No squash-merge across phases; no multi-phase PRs.

### 9a. Commit & PR conventions

- **Commit message format:** `<phase-id>.<deliverable-n>: <one-line description>` (e.g. `P2a.3: add Research pink with status lifecycle`).
- **PR title:** `<phase-id>: <Phase title>` exactly.
- **PR body MUST include:**
  1. The Phase's `spec-anchors:` as clickable repo-relative links.
  2. The ticked deliverables list copied from `execution-state.md`.
  3. The captured stdout of every `done-when:` command (collapsed `<details>` block is acceptable).
  4. A "Decisions logged" section listing every D-NNN created during this Phase.

## 10. Execution state schema

A sibling file `01-specifications/execution-state.md` is the **authoritative** source of truth for progress. Git history is incidental. The schema below is exact — `dm-spec-execution` parses this format and the cross-spec gate validates it.

```markdown
# Execution State

<!-- generated: <ISO-8601 UTC>; last-updated: <ISO-8601 UTC>; plan-sha: <git sha of spec-06 at generation> -->

## P<N>[<a|b|c>] <title>

- status: pending | in-progress | done | blocked
- updated: <ISO-8601 UTC>
- commit: <sha> # required when status=done; absent otherwise
- blocked-by: <one-line reason> # required when status=blocked; absent otherwise
- resume-hint: <one-line description> # OPTIONAL; set by an agent before a clean context-budget halt; cleared by the resuming agent on next progress

### Deliverables

- [ ] P<N>.1 <description>
- [ ] P<N>.2 <description>
- [x] P<N>.3 <description> # tick on green; do not tick speculatively
```

Rules:

- One `## P…` block per Phase or sub-phase in plan order.
- `status: done` requires `commit:` AND every deliverable ticked.
- `status: blocked` requires `blocked-by:`.
- `resume-hint:` is the single mechanism for crossing context boundaries safely; the next agent reads it first.
- The file is written by the implementation agent only. Plan authors never hand-edit it.

## 11. Agent execution protocol

The plan, the state file, and this standard define a state machine the `dm-spec-execution` sibling skill runs:

0. **Initialize state (first run only).** If `01-specifications/execution-state.md` is missing, generate it from `spec-06-execution-plan.md` with one `## P…` block per Phase/sub-phase, every status `pending`, every deliverable unticked. Commit and push the new file before doing anything else.
1. **Bootstrap.** Read `spec-06-execution-plan.md`, `execution-state.md`, this standard, and `coding-standards-testing.md`. If any `## P…` block has `status: in-progress` AND a `resume-hint:`, the resuming agent picks up at that hint and continues from step 5 on that Phase.
2. **Select.** Choose the lowest-numbered Phase/sub-phase that is `pending` and whose `depends-on` are all `done`. If none, halt and report DONE.
3. **Mark `in-progress`.** Update the Phase block in `execution-state.md` (set `status: in-progress`, `updated: <now>`). Commit and push on the new Phase branch.
4. **Read context.** Open every `spec-anchors:` target by anchor-id and read the surrounding section in full. Read the bundled standards cited by the Phase's layer scope per `STANDARDS-PROTOCOL.md`. For every entry in `decisions inherited:`, open the D-NNN and treat it as binding.
5. **Resolve `decisions to make:` BEFORE implementing.** For each open question, either (a) determine the answer from prior specs + standards and log a new D-NNN to `decisions.md` / `implementation-decisions.md`, OR (b) if a human is required, set `human-gate:` semantics: write `blocked-by: human-decision: <question>` to the Phase block, push, halt. Do not start implementation while open questions remain.
6. **Implement deliverables in numbered order.** After each deliverable: run the targeted tests; if green, tick the deliverable in `execution-state.md`; commit (`<phase-id>.<n>: <description>`); push. Do not tick speculatively.
7. **Verify `done-when`.** Run every command in the Phase's `done-when:` block. Capture stdout for the PR body. On any failure, apply the failure protocol in §11a — do not advance status.
8. **Open PR.** Per §9a. PR title `<phase-id>: <title>`, body includes spec-anchors, ticked deliverables, captured `done-when` output, decisions logged.
9. **Merge on green.** Mechanical-checks-only unless `human-gate:` is set on the Phase. On merge, mark `status: done` in `execution-state.md`, set `commit: <merge-sha>`, clear any `resume-hint:`, commit, push.
10. **Loop to step 2.**

### 11a. Failure protocol

On any failed `done-when:` command, OR on any unexpected exception during deliverable work:

1. Do **not** advance any deliverable status (do not tick deliverables that became `[x]` speculatively — only ticks earned by passing targeted tests survive).
2. Do **not** open the PR.
3. Do **not** delete the branch.
4. Append `blocked-by: <one-line reason citing the failed command or exception>` to the Phase block in `execution-state.md`. Set `status: blocked`.
5. Commit the state change and push the branch + state file.
6. Halt. The next agent invocation sees `status: blocked` and either retries (after the human resolves the cause) or hand-offs to a human via the `human-gate:` channel.

### 11b. Context-budget halt protocol

Before any action that may exceed the remaining context budget (large file reads, multi-step refactors, long test runs):

1. Append (or update) `resume-hint: <next concrete step in plain English>` on the current Phase block in `execution-state.md`.
2. Commit and push.
3. Halt cleanly. The next agent picks up at step 1 of §11 and uses the hint.

A missing `resume-hint:` on an `in-progress` Phase means the previous agent crashed; the resuming agent re-reads the spec-anchors and the partially-ticked deliverables, then resumes from the first unticked deliverable.

## 12. Forbidden patterns

These fail the gate immediately:

- IT-only Phases that produce no contract surface for the next layer (e.g. "set up logging" without telling the agent what it can verify).
- Phases whose `done-when` includes opinion words ("polished", "production-ready", "looks right").
- Phases that depend on a later-numbered Phase.
- Phases that introduce vocabulary not present in spec-01 / spec-02 / any active spec-02x sidecar / spec-04 / spec-05.
- Phases that bundle multiple use cases or multiple screens without sub-phase decomposition.
- Plans without an `execution-state.md` schema reference.
- Plans without all four coverage matrices.
- `spec-anchors:` written as `spec-NN §X.Y` instead of `spec-NN#anchor-id` or `spec-NN<letter>#anchor-id`.
- `spec-anchors:` targeting a `spec-02<letter>` sidecar file that does not exist or whose target anchor is not present.
- `done-when:` baseline missing the solution-wide `dotnet build` and `dotnet test` commands per §7.
- FE-touching Phases without a visual-parity check OR a D-NNN deviation.
- FE-touching Phases without a visual-parity check OR a D-NNN deviation.

## 13. Standards-deviation

If the solution legitimately requires breaking inside-out ordering or skipping a layer (e.g. a CLI-only tool with no FE), log a `decisions.md` entry of type `standards-deviation` referencing this standard's §3, naming the omitted/reordered Phases and the rationale.

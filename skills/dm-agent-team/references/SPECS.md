# Writing the specs

The Lead reads this once, at S1, after the probe, and writes 01, 02 (when the size table says), and 03 in one pass from the brief, `decisions.md`, and `specs/00-probe.md`. Write 01 before deciding anything in 03: requirements say *what*, the architecture says *how*. Where a question would have gone to the human, decide, record an `ASM` (default, risk if wrong, how to confirm), and continue. Skip sections the project doesn't need. **All specs together stay under about 10,000 words:** precision is exact values and worked examples, not prose.

## 00 Probe

What was run, on what device and versions, how long it took, at what load, and the date. Every number in 01 and 03 not in the brief or a `D-###` cites a probe row. Measure a setting's whole range before claiming anything about it. For a UI change, also walk every screen the change touches on the running product and record each visible label, control, state, and container width in `probe.json`. Every behavioural claim in 01, 02, or 03 cites a probe ID, the brief, or a `D-###`; a claim about the product the probe did not see is a reviewer's major.

## 01 Requirements

- Each `REQ` is one capability from the user's side, with a MoSCoW priority, traced to the brief or a `D-###`. Every *Must* `REQ` has a happy-path and a failure-path criterion; *Should* and *Could* items are one line each, without criteria.
- Each criterion is Given / When / Then with concrete values, specific enough that a builder could write a failing test from it alone.
- Each `NFR` has a metric, a threshold that cites the probe, and how it is measured. Business rules carry exact values. One concept, one word (the glossary).
- The brief's target state, success measures, and exclusions are all covered. No file paths or layout; the *how* belongs in 03.
- Ask what a reader would assume is in scope but isn't; who may do what; what must never be lost; what happens on a duplicate, a re-run, or two changes at once. Record only what matters.
- **§UX notes** (whenever 02 is not written): the interface the user meets (commands and their output, or screens) as `SCR` items with what each shows and takes, its error messages, and its empty and failure states, each with the `REQ` it serves.
- **Reference material** (the dirty room) is read only now, and only as behaviour statements: never copied code, identifiers, or text.

```markdown
# Requirements: <project>
## 1. Purpose, actors, and target state
## 2. Glossary
## 3. Journeys (J-1 <name> — actor, trigger, steps, end state)
## 4. Requirements
### REQ-001 <capability> — Must
- REQ-001.1 Given <state> When <action> Then <observable result>
- REQ-001.2 Given <failure> When … Then …
## 5. Business rules (exact values)
## 6. Non-functional requirements (| NFR | Quality | Metric and threshold (probe row) | How measured |)
## 7. Out of scope
## 8. Assumptions (| ASM | Default | Risk if wrong | Confirm by |)
## 9. UX notes (when 02 is not written: SCR-001 <command or screen> — shows · takes · errors and empty states · REQ)
```

## 02 UX (large runs, or when the human asked for a designed UI)

Decide whether the product is **UI** (screens) or **DX** (a CLI, library, or API: a "screen" is a command, an output format, or an error message). Design what a design-conscious user would enjoy, within the requirements, in the user's terms; the technical shape comes in 03.

- Every `FLOW` traces to a journey or `REQ`, every `SCR` to a `FLOW`, and the target state is reached by the flows you name.
- Every screen has every state it can be in (loading, empty, error, success; partial, disabled, or offline where they apply), with the exact copy. Every failure in a 01 criterion has a designed state; every destructive action has a confirmation or an undo.
- Each `SCR` lists what it **shows** and what the user **enters or does**, in glossary terms with the `REQ` each serves. No API, endpoint, or storage.
- Named design tokens (colour, type, spacing, radii, motion) instead of raw values, with every theme's values; WCAG 2.2 AA contrast, focus order, labels.
- A gap in 01 found while designing is fixed in 01 now (same pass, same author), not designed around.
- An HTML prototype (self-contained, no external URLs) only when the human asked, or for the key screen at the production bar.

```markdown
# UX: <project> · kind: UI | DX
## 1. Design language and tokens (| Token | Value | Use |)
## 2. Navigation (or command tree)
## 3. Flows (target state reached by: FLOW-…) — FLOW-001 <name> — traces J-1, REQ-… — steps, decisions, exits
## 4. Screens — SCR-001 <name> — traces FLOW-… · shows · takes · states (each with copy) · interactions
## 5. Accessibility and responsive rules
## 6. Assumptions
```

## 03 Architecture and build plan

Design the simplest system that meets every requirement and NFR, with boundaries clean enough that a builder can build one phase without understanding the whole.

- **Style and stack** from the drivers: the few `NFR`s, `REQ`s, and constraints that actually shape the design. Prefer a modular monolith and the standard library unless a driver demands otherwise; use what the brief's *Direction* or an existing spec fixed. Record the choice and the alternatives rejected in a few lines.
- **Design the interface from the UX** (02, or 01 §UX notes): everything a screen shows comes from an `API` output or is derived from one; every input or action is an `API` operation; every flow is a sequence of `API` calls; every failure state maps to an error the `API` returns. The data model holds exactly what those operations must remember.
- **Fewest moving parts.** Every component, dependency, and layer traces to a `REQ`, an `NFR`, or an ADR. No services, queues, caches, or AI components unless an `NFR` needs them. ADRs only for decisions a later reader would question.
- **Executable contracts (§5):** inputs, outputs, errors, and where they matter idempotency, atomicity, concurrency; each with **one worked example** (a concrete input, its output, one error) the owning phase turns into a contract smoke named `API_003_…`. A shared budget (LLM calls, fetches, money) gets one worked example at the largest normal input showing each consumer's share; no specified feature may get 0 on a normal day. `PHASE-001` ships the smoke runner (boots the product, checks the health contract).
- **Conventions (§6)** settle only what a builder would otherwise invent: error kinds and how they surface, configuration, logging, validation, anything else this product needs. One to three checkable lines each.
- **Abstractions (§7)** only where they materially simplify the design: the same concept changing for the same reason, never code that merely looks alike; real cases now; a benefit that clearly outweighs indirection and coupling; a condition for inlining it again. SOLID, DRY, and pattern names are vocabulary, not reasons. List deliberate duplication too. A function before a class, a module before a framework.
- **Structure (§8)** that extends by addition, with the shared files every feature must edit listed as hotspots.
- **Quality gate (§10.1)** from the stack's established practice: the standard formatter in check mode, the standard linter with a recognised preset (list only deviations, with reasons), type checking where the language supports it, warnings as errors where possible. More (dependency audit, coverage floor, secret scan) only where the quality bar or an `NFR` asks. Each tool pinned, on the allowlist, with its config file and exact command.
- **Verify (§10):** one `verify command:` that runs the quality gate and then the tests, hermetic (green from any directory, concurrently: no fixed ports or shared state outside the working directory) and **fast: target under 3 minutes**. If the full suite is slower, `verify` runs the fast subset and a `verify-full command:` runs everything, once per milestone and at acceptance; a builder's verify never runs past 5 minutes.
- **Harness rules (§10), built in `PHASE-001`, not after the first flake:** an e2e or integration harness starts one instance per worker on an ephemeral port, caps CPU threads for anything that computes, logs each instance's output, and asserts on state, never on how fast work finishes. Write them as the `harness:` line.
- **Allowlist (§11):** minimal; package, pinned version, licence, purpose.
- **Build plan (§13).** `PHASE-001` is the foundation (toolchain, structure, the quality gate, verify green on a smoke test, the harness rules, the smoke runner, `.gitignore`, the §11 `list command:`, hotspot files, shared §6 plumbing, a README with install, run, and test commands). Every later phase is a **vertical slice**: one capability from storage to the surface the user meets, finished and verified by one builder in one session; a milestone is one to three slices the human can run. Aim for the size's count (`small` 1–3, `standard` 3–6, `large` ≤ 8); never a phase shorter than the checks around it.
  - **Each acceptance criterion is owned once**, by the phase that can test it end to end; a phase that owns no criterion lists the contract items it tests (`DATA-003`, `API-002`, `SCR-004`) under `acceptance tests:`; `scripts/coverage.sh` reads these lines.
  - `depends-on:` lists only real dependencies; `touches:` lists exact files or narrow folders. In brownfield it also names every baseline test that pins text the phase changes or a list the phase adds to (table and column lists, the footer, the rail, a constant): grep the baseline tests for each such name when writing §13, and run `scripts/suggest-touches.sh` on the builder's diff. With `max-parallel` above 1, phases that can run together must not overlap, and a phase that edits a hotspot names it.
  - **Milestones** end with something a human can run; small runs usually have one. Mark `risk: high` for concurrency, security, a tricky algorithm, or a data migration.

Keep these section numbers and the backticked lines: `scripts/precheck.sh` and `scripts/coverage.sh` read §5, §9–§11 and §13. In brownfield, a run spec **copies** §11 verbatim from `system/03`; a pointer to it reads as an empty allowlist to the scripts. Note that `verified-by:` is read by neither script: an NFR measured by the Lead is a sentence in the owning phase's notes, not a field.

```markdown
# Architecture: <project>
## 1. Drivers, style, and stack (chosen; alternatives rejected and why)
## 2. ADRs (ADR-001: context · decision · consequences · D-### | ASM-###)
## 3. Components (COMP-001: responsibility · owns DATA · exposes API · depends on)
## 4. Data (DATA-001: fields, constraints, invariants)
## 5. Contracts (API-001: input · output · errors · example · traces REQ, SCR) and flows → API calls
## 6. Conventions
## 7. Abstractions (| Abstraction | Cases now (IDs) | Simplifies | Costs | Inline it again if |) · Deliberate duplication: …
## 8. Structure and hotspots
## 9. Coding standards (or the repo's standards file plus deviations)
suppression exceptions: `<globs where suppression comments are allowed | none>`
## 10. Tests
verify command: `<exact command: quality gate, then tests; under 3 minutes>`
verify-full command: `<the whole suite, when verify is a subset | omit>`
test files: `<globs matching every test and test-support file>`
harness: <one instance per worker on an ephemeral port · thread caps · per-instance logs · no timing assertions>
### 10.1 Quality gate
| Check | Tool and version | Preset and deviations | Config file | Command | Fails on |
## 11. Dependency allowlist
list command: `<prints the direct dependency names, one per line>`
| Package | Version | License | Purpose |
## 12. Risks and assumptions (| ASM | Default | Risk if wrong | Confirm by |)
## 13. Build plan
verify: `<the verify command from §10>`
hotspots: <files>
| MS | What the human can run | Phases |
### PHASE-001 Foundation — MS-1 · layer: foundation
goal: <one sentence>
traces: COMP-…, ADR-…
acceptance tests: none — verify green with a smoke test
touches: <exact files or narrow folders>
depends-on: none
### PHASE-002 <title> — MS-1 · slice: <capability> · risk: normal | high
goal: <one sentence>
traces: REQ-…, DATA-…, API-…
acceptance tests: REQ-001.1 → <test intent>, DATA-003 → <invariant>, API-002 → <contract smoke>
touches: <exact files or narrow folders>
depends-on: PHASE-001
behaviour-changes: <brownfield, when it edits a baseline test: D-### …>
deletes: <brownfield, baseline files it deletes: path (D-###), …>
```

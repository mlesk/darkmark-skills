# Writing the specs

The Lead reads this once, at S1, and writes 01, 02 (standard and large), and 03 in one pass from the brief and `decisions.md`. Write 01 before deciding anything in 03: requirements say *what*, the architecture says *how*, and technology in 01 is a review finding. Where a question would have gone to the human, decide, record an `ASM` (default, risk if wrong, how to confirm), and continue. Skip sections the project doesn't need.

## 01 Requirements

- Each `REQ` is one capability from the user's side, with a MoSCoW priority, traced to the brief or a `D-###`. Every *Must* `REQ` has a happy-path and a failure-path criterion.
- Each criterion is Given / When / Then with concrete values, specific enough that a builder could write a failing test from it alone.
- Each `NFR` has a metric, a threshold, and how it is measured. Business rules carry exact values. One concept, one word (the glossary).
- The brief's target state, success measures, and exclusions are all covered. No technology, file paths, or layout.
- Ask yourself what a reader would assume is in scope but isn't; who may do what; what must never be lost; what happens on a duplicate, a re-run, or two changes at once; how much data and how fast. Record only what matters.
- **Small runs:** add §UX notes: the interface the user meets (commands and their output, or screens) as `SCR` items with what each shows and takes, its error messages, and its empty and failure states, each with the `REQ` it serves.
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
## 6. Non-functional requirements (| NFR | Quality | Metric and threshold | How measured |)
## 7. Out of scope
## 8. Assumptions (| ASM | Default | Risk if wrong | Confirm by |)
## 9. UX notes (small runs: SCR-001 <command or screen> — shows · takes · errors and empty states · REQ)
```

## 02 UX (standard and large)

Decide whether the product is **UI** (screens) or **DX** (a CLI, library, or API: a "screen" is a command, an output format, or an error message). Design what a design-conscious user would enjoy, within the requirements, in the user's terms; the technical shape comes in 03.

- Every `FLOW` traces to a journey or `REQ`, every `SCR` to a `FLOW`, and the target state is reached by the flows you name.
- Every screen has every state it can be in (loading, empty, error, success; partial, disabled, or offline where they apply), with the exact copy. Every failure in a 01 criterion has a designed state; every destructive action has a confirmation or an undo.
- Each `SCR` lists what it **shows** and what the user **enters or does**, in glossary terms with the `REQ` each serves. No API, endpoint, or storage.
- Named design tokens (colour, type, spacing, radii, motion) used instead of raw values; WCAG 2.2 AA contrast, focus order, labels.
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
- **Precise contracts:** inputs, outputs, errors, and where they matter idempotency, atomicity across entities, concurrency. A builder can write a test against each.
- **Conventions (§6)** settle only what a builder would otherwise invent: error kinds and how they surface, configuration, logging, validation, anything else this product needs. One to three checkable lines each.
- **Abstractions (§7)** only where they materially simplify the design: the same concept changing for the same reason, never code that merely looks alike; real cases now; a benefit that clearly outweighs indirection and coupling; a condition for inlining it again. SOLID, DRY, and pattern names are vocabulary, not reasons. List deliberate duplication too. A function before a class, a module before a framework.
- **Structure (§8)** that extends by addition, with the shared files every feature must edit listed as hotspots.
- **Quality gate (§10.1)** from the stack's established practice: the standard formatter in check mode, the standard linter with a recognised preset (list only deviations, with reasons), type checking where the language supports it, warnings as errors where possible. More (dependency audit, coverage floor, secret scan) only where the quality bar or an `NFR` asks. Each tool pinned, on the allowlist, with its config file and exact command.
- **Verify (§10):** one `verify command:` that runs the quality gate and then the tests, hermetic (green from any directory, concurrently: no fixed ports or shared state outside the working directory) and **fast: target under 3 minutes**. If the full suite is slower, `verify` runs the fast subset and a `verify-full command:` runs everything; the Lead runs it at integration and acceptance. A builder's verify must never run past 5 minutes.
- **Allowlist (§11):** minimal; package, pinned version, licence, purpose.
- **Build plan (§13).** Build inside out: `foundation` (`PHASE-001`: toolchain, structure, the full quality gate, verify green on a smoke test, `.gitignore` for build output, the §11 `list command:` working, hotspot files, shared §6 plumbing, a README with install, run, and test commands) → `domain` → `persistence` → `application` → `ui` or the command surface. Skip layers that don't apply.
  - **Size phases large.** A phase is the largest coherent piece one builder can finish and verify in one session; in small and standard runs group adjacent layers into one phase where they're small. Aim for the size's count (`small` 1–4, `standard` 3–8). 
  - **Each acceptance criterion is owned once**, by the phase at the lowest layer that can test it; a phase that owns no criterion lists the contract items it tests (`DATA-003`, `API-002`, `SCR-004`) under `acceptance tests:`.
  - `depends-on:` lists only real dependencies; `touches:` lists exact files or narrow folders. With `max-parallel` above 1, phases that can run together must not overlap, and a phase that edits a hotspot names it.
  - **Milestones** end with something a human can run; small runs usually have one. Mark `risk: high` for concurrency, security, a tricky algorithm, or a data migration.

Keep these section numbers and the backticked lines: `scripts/precheck.sh` reads §9–§11 and §13.

```markdown
# Architecture: <project>
## 1. Drivers, style, and stack (chosen; alternatives rejected and why)
## 2. ADRs (ADR-001: context · decision · consequences · D-### | ASM-###)
## 3. Components (COMP-001: responsibility · owns DATA · exposes API · depends on)
## 4. Data (DATA-001: fields, constraints, invariants)
## 5. Contracts (API-001: input · output · errors · traces REQ, SCR) and flows → API calls
## 6. Conventions
## 7. Abstractions (| Abstraction | Cases now (IDs) | Simplifies | Costs | Inline it again if |) · Deliberate duplication: …
## 8. Structure and hotspots
## 9. Coding standards (or the repo's standards file plus deviations)
suppression exceptions: `<globs where suppression comments are allowed | none>`
## 10. Tests
verify command: `<exact command: quality gate, then tests; under 3 minutes>`
verify-full command: `<the whole suite, when verify is a subset | omit>`
test files: `<globs matching every test and test-support file>`
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
### PHASE-002 <title> — MS-1 · layer: domain+persistence · risk: normal | high
goal: <one sentence>
traces: REQ-…, DATA-…, API-…
acceptance tests: REQ-001.1 → <test intent>, DATA-003 → <invariant>
touches: <exact files or narrow folders>
depends-on: PHASE-001
behaviour-changes: <brownfield, when it edits a baseline test: D-### …>
deletes: <brownfield, baseline files it deletes: path (D-###), …>
```

# Gate: spec-06 Execution Plan

See [GATE-PROTOCOL.md](./GATE-PROTOCOL.md) for run procedure. Governing standard: [`standards/planning-standards-inside-out-phases.md`](../standards/planning-standards-inside-out-phases.md).

## Structural checklist

1. All template sections present and non-empty.
2. §3 Phase backbone lists Phases in inside-out order matching planning standard §3 (deviations logged in `decisions.md` as `standards-deviation` entries citing planning standard §3). **P0 Preflight is present and not skipped.**
3. Every Phase entry in §4 contains all 11 fields from planning standard §4: `layer(s)`, `depends-on`, `scope`, `spec-anchors`, `deliverables`, `files (touch budget)`, `tests to add`, `done-when`, `human-gate`, `decisions inherited`, `decisions to make`.
4. Every `layer(s)` value is ⊆ { FE, UI, UC, PD, SI, cross-cutting }.
5. `depends-on` references only earlier phase-ids (acyclic; no forward refs).
6. Every Phase has ≥1 numbered deliverable; each deliverable is self-contained, verifiable, and repo-anchored to spec-01/02/04/05 (or active spec-02x sidecar) nouns.
7. Every Phase has a `done-when` block of mechanical assertions only — no opinion words ("polished", "production-ready", "looks right", "reviewed").
8. Test posture per Phase matches planning standard §6; test frameworks are NOT re-chosen — they come from `coding-standards-testing.md`:
   - PD-touching: xUnit unit + xUnit integration with SI faked.
   - SI-touching: xUnit direct integration tests against real adapters.
   - UC-touching: xUnit full integration tests covering UC → PD → real SI.
   - UI-touching: xUnit integration via `WebApplicationFactory<TProgram>`.
   - FE-touching: Vitest+RTL component tests + ≥1 Playwright e2e per use-case screen + Playwright visual-parity test against the mockup (or D-NNN deviation).
   - cross-cutting: NetArchTest architecture tests + smoke.
9. Every Phase baseline `done-when` includes the exact commands from planning standard §7 (solution-wide `dotnet build MoneyMaker.slnx`, `dotnet test MoneyMaker.slnx --filter Category=Architecture`, `dotnet test MoneyMaker.slnx`, lint/format). FE-touching Phases additionally include the four `pnpm --filter ./src/MoneyMaker.WebApp run ...` commands.
10. Every `spec-anchors:` value uses the `spec-NN#kebab-anchor-id` form per planning standard §4a, OR the `spec-NN<letter>#kebab-anchor-id` form when targeting an active `spec-02x` sidecar; plain `spec-NN §X.Y` references FAIL. Every sidecar anchor MUST resolve to an existing, gate-passed sidecar file with the cited anchor present.
11. All four §5 coverage matrices are present and have zero empty rows: - 5.1 spec-00 AC → Phase-ids - 5.2 spec-05 UC → UC/UI/FE Phase-ids - 5.3 spec-04 screen → FE Phase-id - 5.4 spec-01 class with behaviour → PD Phase-id
    11a. If any `01-specifications/spec-02[a-z]-*.md` sidecars exist, the conditional §5.5 Architecture Sidecar Coverage matrix is present and has zero empty rows; every contract/invariant/RUA rule from every sidecar maps to ≥1 Phase. If no sidecars exist, §5.5 says "not applicable — no sidecars".
12. §6 Execution state companion: references planning standard §10 canonical schema (no duplication).
13. §7 Agent execution protocol: references planning standard §11/§11a/§11b (no duplication).
14. §8 Branch & PR policy stated: one PR per Phase/sub-phase, branch name = phase-id slug, commit message and PR title/body format per planning standard §9a.
15. §9 Plan-Level Decisions Index lists every `decisions.md` / `implementation-decisions.md` entry that affects the plan.
16. `decisions inherited` and `decisions to make` are present (and non-overlapping) on every Phase. Every `decisions inherited:` D-NNN resolves to an existing entry; every `decisions to make:` is a concrete question (not a vague "figure out X").
17. Forbidden-pattern sweep (planning standard §12) passes:
    - No IT-only Phases lacking a verifiable contract surface for the next layer.
    - No `done-when` opinion words.
    - No forward dependencies.
    - No vocabulary outside spec-01/02/04/05 (terms originating in active `spec-02x` sidecars are permitted because sidecars belong to the spec-02 family).
    - No Phase bundles multiple use cases or screens without sub-phase split.
    - No FE-touching Phase missing the visual-parity check or a D-NNN deviation.
    - No `spec-anchors:` targeting a sidecar that does not exist or has not gate-passed.

## Rubric (1–5, pass bar ≥4)

- **Autonomy-readiness** — a fresh agent given only this plan, the standards bundle, and the spec set could pick the next Phase and ship it without asking a human.
- **Inside-out discipline** — Phase ordering respects `FE → UI → UC → PD ← SI`; PD precedes SI implementations of PD contracts; UC precedes UI; UI precedes FE.
- **Size discipline** — every Phase or sub-phase fits one PR; large Phases are decomposed; no Phase smuggles more than one use case or screen.
- **Traceability** — every Phase has explicit `spec-anchors`; every spec-00 AC, spec-05 UC, spec-04 screen, and behaviour-bearing spec-01 class lands in the coverage matrices.
- **Verification rigor** — `done-when` lines are mechanical; test posture per planning standard §6 is honoured; baseline assertions present on every Phase.
- **Resumability** — `execution-state.md` shape is sufficient for an agent dropped mid-Phase to determine exact state and resume.

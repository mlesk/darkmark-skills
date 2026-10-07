# Plan: taking dm-agent-team to an enterprise SDLC

**Status: parked — food for thought, not scheduled.** Agents never load this file. It was written against the full version of the team (gates G0–G6, separate 03 sections such as §7 conventions); on the lean version, read G1–G2 as the product gate, G3–G4 as the plan gate, G5 as milestone gates, G6 as the accept gate, and §7 as 03 §6. An `enterprise` bar would map naturally to the `large` size plus stricter gates. It records what the team would need before an enterprise could trust it, where each change would go, and in what order.

## Context

The team already has a strong core: independent fresh-context review, `REQ → SCR → API → PHASE → test` traceability, a clean room with a dependency allowlist, human gates G0–G6, spec drift detection, the Requirements ⇄ UX alignment loop, inside-out build phases, and a §10.1 code-quality gate inside verify.

What it lacks, from an enterprise SDLC view, is mostly about **evidence, security, change control, existing systems, and operations**. Most of it should not burden toy runs, so the plan gates it behind a new quality bar.

## Approach: an `enterprise` quality bar

Add `enterprise` above `production` in SKILL.md §Process profile and the brief's *Quality bar*. It switches on items 1–5 below. `production` gets items 2 (security scans) and 5 (operations) in lighter form; `prototype` and `internal` stay as they are.

| | prototype | internal | production | enterprise |
|---|---|---|---|---|
| Evidence bundle | – | – | at G6 | at every gate |
| Named-role approvers | – | – | – | required |
| Threat model and security review | – | – | threat model | threat model + security-review mode |
| SAST, SCA, secrets scan, SBOM | – | SCA | all | all, blocking |
| CI config and PR-ready output | – | – | CI config | CI + PR per milestone |
| Ops and release readiness | – | – | observability, runbook | full release gate |

---

## Critical items

### 1. Evidence bundle and attributable approvals

**Partly done** (October 2026): `.agent-team/` is now committed, one folder per run, so decisions, reviews, gate approvals, and handoffs survive as history (logs stay ignored). Still open: approver identity, separation of duties, and per-dispatch model and cost.

**Problem (original).** `.agent-team/` was git-ignored, so decisions, reviews, gate approvals, handoffs, and logs disappeared with the workspace. Gate approval is "any human message", with no identity or role, and yolo auto-approves gates.

**Changes.**
- **Evidence bundle.** At each gate (enterprise) or at G6 (production), the Lead exports a committed bundle to `docs/agent-team/` (path set in 03 §8): approved specs (from `approved/`), the gate's review files, `decisions.md`, the run log, and a manifest with the skill version, models per tier, and the hash of every artifact.
- **Approver identity.** The Gates table gains `Approver` and `Role`. The brief gains an *Approvers* section mapping roles to gates (for example product owner → G1–G2, architect and security → G3, release owner → G6). The Lead asks for the approver's name and role at each stop and logs it in the `D-###`.
- **Separation of duties.** In `enterprise`, G3 and G6 need two different approvers, and yolo cannot auto-approve G2, G3, or G6.
- **Run log.** `log.md` gains `Model` and `Cost` columns, filled from the host when it reports them.

**Where.** SKILL.md (Boot, the gate step, §Spec integrity, Retro), PROTOCOL.md (Gates table, Brief, Run log, new §Evidence bundle), the mode table.

**Done when.** A completed run leaves a committed bundle from which an auditor can tell, for any line of code, which phase, review, spec IDs, decisions, and named approvals led to it.

### 2. Security engineering

**Problem.** Security is a few checks: the reviewer looks for secrets and network calls, the allowlist records licences, and security scanning is an optional extra in §10.1.

**Changes.**
- **01 Requirements:** a security section: actors and trust levels, authentication and authorisation per `REQ`, data classification for each information noun, and abuse cases written as failure-path criteria. New analyst probe: "what would a malicious user try?"
- **03 Architecture:** new §7.11 *Threat model*: trust boundaries from §3, STRIDE per boundary, a mitigation (`ADR` or §7 rule) for each threat, and residual risks as `ASM`s.
- **§10.1 quality gate:** in `production`/`enterprise`, SAST, dependency vulnerability audit (SCA), secret scanning, and SBOM generation become mandatory, with severity thresholds that fail verify.
- **Reviewer `security-review` mode:** on 03 at G3 and on the whole system at acceptance. It checks the threat model against the design and code, and looks for the usual AI-code failures: injection, missing authorisation on new operations, unsafe deserialisation, secrets in config, and hallucinated or typo-squatted package names.
- **Supply chain:** the builder installs only exact allowlisted versions from lockfiles; precheck verifies the lockfile matches the allowlist.

**Where.** Analyst probes and skeleton, architect §7 and §10.1, a reviewer mode and checks, ROUTING (security review at deep/high).

### 3. Delivery controls: CI and pull requests

**Problem.** The team commits locally and never pushes. That's right for the clean room, but the quality gate runs only on the developer machine, and there is no PR, branch protection, or human code review of AI-written code.

**Changes.**
- **CI as the authority.** The foundation phase generates the CI configuration for the chosen platform, running exactly verify (the §10.1 gate plus tests). Acceptance requires CI config that matches verify.
- **PR-ready output.** At each milestone (enterprise) the Lead prepares a branch and a PR description from the phase reports: traced IDs, review verdicts, verify evidence, decisions, and assumptions. Pushing and opening the PR remain human actions (a hard stop), or are done by the Lead only when the human allows it at G0.
- **Provenance.** Commits carry a trailer naming the phase, the handoff, and the model tier, so AI-written changes can be identified.
- **Human code review.** In `enterprise`, G5 includes a human review of the milestone PR, separate from the reviewer agent.

**Where.** Architect §10.1 and foundation phase, SKILL.md build step and G5, PROTOCOL (commit message format), GUIDE (host setup for push permissions).

### 4. Brownfield mode

> **Done** (October 2026): implemented as `--brownfield`; see [references/BROWNFIELD.md](./references/BROWNFIELD.md). Kept below for the record.

**Problem.** The team is greenfield only. Adoption covers existing *specs*, not existing *code*, and the clean room forbids reading prior code outside the dirty room. Most enterprise work changes existing systems.

**Changes.**
- **G0 choice:** greenfield or brownfield. Brownfield turns the existing repository into a human-owned input instead of dirty-room reference.
- **New S0.5 Discovery (architect + analyst):** recover the current architecture into a baseline 03, the conventions and quality tools in use into §9–§10.1, and the behaviour the change touches into a baseline 01. Record the current test baseline (pass/fail, coverage) as the regression floor.
- **Change-scoped specs:** 01 and 02 describe the change and its impact on existing behaviour. 03 designs within the existing architecture; the style-and-stack evaluation is skipped unless the human asks for it.
- **Characterisation tests first:** before a phase changes legacy behaviour, a phase pins the current behaviour with tests.
- **No-regression gate:** verify must keep the baseline green; any newly failing existing test is a blocker unless a `D-###` accepts the behaviour change.

**Where.** A new `references/BROWNFIELD.md` read only in brownfield runs, plus hooks in SKILL.md (Kickoff, a Discovery stage), PROTOCOL (clean room exception), architect and reviewer. Effectively a sibling path through the same stages.

### 5. Operations and release

**Problem.** The lifecycle ends at G6 acceptance. The only operational content is §7.10 runtime topology.

**Changes.**
- **03 Architecture:** new §15 *Operations*: environments and promotion path, infrastructure as code, deployment strategy and rollback, data-migration safety (expand/contract, backups), feature flags, and observability (structured logs, metrics, traces, health checks, and alerts tied to each `NFR`).
- **Build:** an `operations` layer after `application` (or alongside `ui`) for deployment config, dashboards, and alerts; runbooks in `docs/runbooks/`.
- **Release-readiness gate:** acceptance in `production`/`enterprise` checks deployability to a test environment, rollback rehearsal, alert coverage of the `NFR`s, and runbook completeness. G6 becomes "release" rather than "accept".

**Where.** Architect design and plan modes, reviewer acceptance mode, the layer table, GUIDE.

---

## Important, second tier

| Item | Change | Where |
|---|---|---|
| **Data and privacy compliance** | Data classification drives handling rules; retention and deletion requirements; audit logging as an explicit `NFR`; regulatory tags in the brief (GDPR, HIPAA, SOX, PCI) that pull in a checklist of controls | Brief, analyst probes, architect §7, reviewer |
| **AI governance and cost** | Enforce the brief's budget: track cost per dispatch, stop at a ceiling (`blocked`, `halt: budget`); a model policy per data class; a wall-clock limit in `run.sh` | SKILL.md, ROUTING.md, `run.sh` |
| **Non-functional testing** | A performance/load harness for `NFR`s with thresholds; automated accessibility checks (for example axe) to back the designer's WCAG 2.2 AA claim; end-to-end tests for the main `FLOW`s; contract tests between layers | Architect §10, plan layers, reviewer acceptance |
| **Multiple stakeholders** | Gates that collect several sign-offs (product, UX, security, architecture), each a `D-###` with role | Gates table, gate presentation |
| **After G6: v1.1 and beyond** | An intake flow for defects and enhancements against a delivered system, reusing brownfield discovery and the CR machinery | SKILL.md, depends on item 4 |
| **Documentation deliverables** | API reference, an operations guide, and the ADRs published with the code as product docs, not only in the run folders | Architect §8, foundation and final phases, evidence bundle |

---

## Suggested order

1. **Evidence bundle and approver identity** (item 1): small, and every audit depends on it.
2. **Security engineering** (item 2): the threat model, security requirements, and mandatory scans.
3. **CI and PR output** (item 3).
4. **Brownfield mode** (item 4): the largest, and a prerequisite for the v1.1 intake flow.
5. **Operations and release** (item 5).
6. Second-tier items as the projects using the team need them.

Validate each with a toy run at the `enterprise` bar, recorded as a `dm-skill-eval` report in `evals/results/`, before starting the next.

## Open questions

- Should the evidence bundle live in the product repo (`docs/agent-team/`) or in a separate audit store?
- Which CI platforms to support first, and is generating CI config acceptable inside the clean room (it names a remote system but doesn't contact it)?
- In brownfield mode, how far does the clean room still apply? Probably: existing code is a human-owned input, but external reference code stays in the dirty room.
- Does `enterprise` need its own reviewer roles (security, compliance), or is a `security-review` mode on the existing reviewer enough?

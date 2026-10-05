# Adopting existing specs

Read this only when `brief.md` lists **Existing specs**. It lets a project that already has requirements or design documents (including a `01-specifications/` folder from the older `dm-spec-creation` skill) enter the team without re-interviewing everything.

## What adoption means

- Existing specs are **human-owned input**, not the dirty room. The human wrote them, or approved them, for this project. Unlike reference material, every agent the brief maps them to may read them.
- They are **inputs, not outputs.** Agents still write the team's own `01`, `02`, and `03`, using the existing text as the first answer to every question. Nothing is copied over unread: the reviewer still checks every claim against its source, and every gate still runs.
- **Nothing in the existing folder is edited.** The team writes only in `.agent-team/`.

## At kickoff (S0)

1. Ask for the paths in the G0 batch, with the recommended answer "none" unless the human mentioned documents.
2. Map each path to the spec it feeds, and record the map in the brief:

   ```markdown
   ## Existing specs (human-owned; see references/ADOPTION.md)
   - <path> → 01 | 02 | 03 — <what it is>
   ```

3. Log the map as a `D-###` with `kind: answer` and `affects:` naming the target specs.

## Mapping from dm-spec-creation

| Old spec | Feeds | Notes |
|---|---|---|
| `spec-00` PRD | 01 | Capabilities become `REQ`s; acceptance criteria keep their Given/When/Then. |
| `spec-01` glossary and exclusions | 01 | §3 Glossary and §8 Out of scope. |
| `spec-04` user interface | 02 | Screens, states, and navigation. The S2 alignment rounds still check it against 01. |
| `spec-01` modules, entities, relationships | 03 | §4 Components and §5 Data model. |
| `spec-02`, `spec-02x` sidecars, `spec-03`, both decision logs | 03 | Style and stack in §2, conventions in §7, standards in §9, decisions as ADRs. |
| `spec-05` app use cases | 03 | §6 Contracts. Use cases are app design, so they can't go in 01. |
| `spec-06` execution plan | none | Re-plan in S4. The architect plans the team's own build phases (horizontal layers first, then UI phases), which use a different format. |
| `execution-state.md` | none | Finish the run with `dm-spec-execution`, or start this team fresh. |

Standards files the old specs cite live inside the old skill's folder, which the clean room does not allow agents to read. Copy any you want to keep into the project and list them under the brief's *Constraints*.

## During S1–S3

- The Lead adds every mapped path to the handoff **Inputs** of that spec's author and reviewer, on every dispatch, including S2 alignment rounds.
- How authors and the reviewer treat existing specs (settled unless contradicted, cited as `from <path> §<section>`) is in [PROTOCOL.md §Clean room](../PROTOCOL.md#clean-room), rule 3, so every agent has it.
- **Adopted architecture.** If an existing architecture document (mapped to 03) already fixes the architecture style and the tech stack, the architect skips the style-and-stack question batch, writes `Chosen: <option> (adopted, D-###)` in §2.1 and §2.2, and does not score alternatives. The reviewer's 3–5 option check does not apply.

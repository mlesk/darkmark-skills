# Adopting existing specs

Read this only when `brief.md` lists **Existing specs**: human-owned requirements or design documents for this project (including a `01-specifications/` folder from the older `dm-spec-creation` skill).

- **They are input, not the dirty room.** The Lead treats them as settled while writing the specs, unless they contradict the brief, a `D-###`, or each other; each contradiction or gap becomes an `ASM` with the existing text as the default. Anything taken from them cites `from <path> §<section>`, which the reviewer accepts like a `D-###`, and the reviewer may read them to check.
- **The team still writes its own specs**, using the existing text as the first answer to every question, and the review and gates still run. Nothing in the existing folder is edited.
- **At the interview**, ask for the paths (recommended: none, unless the human mentioned documents), map each to 01, 02, or 03 in the brief, and log the map as a `D-###`. In brownfield, they are also discovery inputs; where the code disagrees with a document, the code is the baseline and the disagreement is an `ASM` to confirm at the baseline gate.
- **Adopted architecture.** If a document mapped to 03 fixes the style and stack, 03 §1 records `Chosen: <option> (adopted, D-###)`.

## Mapping from dm-spec-creation

| Old spec | Feeds | Notes |
|---|---|---|
| `spec-00` PRD, `spec-01` glossary and exclusions | 01 | capabilities become `REQ`s; criteria keep their Given/When/Then |
| `spec-04` user interface | 02 (01 §UX notes in small runs) | screens, states, navigation |
| `spec-01` modules and entities, `spec-05` use cases | 03 | §3 Components, §4 Data, §5 Contracts |
| `spec-02`, `spec-02x`, `spec-03`, decision logs | 03 | style and stack in §1, ADRs in §2, conventions in §6, standards in §9 |
| `spec-06` execution plan, `execution-state.md` | none | the Lead re-plans in 03 §13; finish an old run with `dm-spec-execution` or start fresh |

Standards files the old specs cite live in the old skill's folder, which the clean room doesn't allow the team to read: copy any you want into the project and list them under the brief's *Constraints*.

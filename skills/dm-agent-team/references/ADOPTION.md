# Adopting existing specs

Read this only when `brief.md` lists **Existing specs**: human-owned requirements or design documents for this project (including a `01-specifications/` folder from the older `dm-spec-creation` skill).

- **They are input, not the dirty room.** The agents the brief maps them to may read them. Authors treat them as settled unless they contradict the brief, a `D-###`, or each other; each contradiction or gap becomes a `Q` with the existing text as the recommended answer. Anything taken from them cites `from <path> §<section>`, which the reviewer accepts like a `D-###`.
- **The team still writes its own specs**, using the existing text as the first answer to every question, and every review and gate still runs. Nothing in the existing folder is edited.
- **At the brief gate**, ask for the paths (recommended answer: none, unless the human mentioned documents), map each to 01, 02, or 03 in the brief, and log the map as a `D-###`. The Lead lists each mapped path as an input to that spec's author and reviewer on every dispatch, including discovery in brownfield (where the code wins over a document that disagrees, and the disagreement becomes a `Q`).
- **Adopted architecture.** If a document mapped to 03 fixes the style and stack, the architect records `Chosen: <option> (adopted, D-###)` in 03 §1 and asks no style-and-stack question.

## Mapping from dm-spec-creation

| Old spec | Feeds | Notes |
|---|---|---|
| `spec-00` PRD, `spec-01` glossary and exclusions | 01 | Capabilities become `REQ`s; criteria keep their Given/When/Then |
| `spec-04` user interface | 02 (01 §UX notes in small runs) | screens, states, navigation |
| `spec-01` modules and entities, `spec-05` use cases | 03 | §3 Components, §4 Data, §5 Contracts |
| `spec-02`, `spec-02x`, `spec-03`, decision logs | 03 | style and stack in §1, ADRs in §2, conventions in §6, standards in §9 |
| `spec-06` execution plan, `execution-state.md` | none | the architect re-plans; finish an old run with `dm-spec-execution` or start fresh |

Standards files the old specs cite live in the old skill's folder, which the clean room doesn't allow agents to read: copy any you want into the project and list them under the brief's *Constraints*.

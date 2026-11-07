---
name: dm-retro-apply
description: Close the learning loop after a run. Extract every proposed skill change and every costliest failure from a retro, turn each into a file-and-line tracked item, apply or explicitly reject it, add a regression check, and refuse to call the run closed while an item is unclassified. Use when the user says "apply the retro", "close the loop", "why do we keep fixing the same thing", after a dm-agent-team retro, or at the end of any run with a retro.md. Do NOT use to write the retro itself, to review code, or to make broad skill rewrites untethered from a retro item.
---

# Retro Apply

A retro that ends in "proposed changes (not edited)" is a diary. This skill turns it into diffs, evals, and a closure table.

**The rule:** a run is not closed until every retro item is `applied`, `deferred` (with an owner and a date), or `rejected` (with a reason). No silent leftovers.

## Step 1 - Extract

Run the extractor on the retro:

```bash
python3 scripts/retro-items.py <run>/retro.md
```

It returns one row per item with:

| Field | Meaning |
|---|---|
| `id` | `R1`, `R2`... in document order |
| `kind` | `proposal` (a named skill change) or `failure` (a costliest failure) |
| `text` | the item, with continuation lines joined |
| `file` | the first `path:line` or `path (line N)` named, if any |
| `line` | that line number, if any |

If the retro has no "Proposed changes" section, say so and stop. Do not invent items from the narrative.

## Step 2 - Classify (HARD GATE)

For each item, choose exactly one:

| Class | When | Evidence required |
|---|---|---|
| `applied` | the change is small, named, and does not contradict a later decision | the diff or commit |
| `deferred` | real, but needs a design choice or a larger change | an owner and a date in `retro-applied.md` |
| `rejected` | the proposal is wrong, already fixed, or contradicts a later `D-###` | one line of why |

Default to `applied` for any item that names a file and a line. Default to `deferred` for anything that needs a new script or a new phase. Never leave an item blank.

Show the table and ask one question:

> Apply the named line edits now, and defer the three that need new scripts?
>
> Recommended answer: yes.

## Step 3 - Apply

For each `applied` item:

1. Read the target file. If the named line has moved, find the current line by content, never by number alone.
2. Make the **smallest** edit that would have prevented the failure. Replace a line; do not append a paragraph.
3. If the target is a script, add or update a check that fails on the old behaviour. Run it both ways: red before, green after.
4. If the target is a `SKILL.md`, add the regression to its trigger or behaviour eval with `dm-skill-eval`. A rule no eval can test is prose, not a fix.
5. Record the diff hash or commit in the closure table.

A failure item (not a proposal) is applied by adding the missing check or rule that would have caught it earlier. Name the stage where it should have been caught.

## Step 4 - Write the closure table

`<run>/retro-applied.md`:

```markdown
# Retro applied: <run>

| ID | Kind | Item (one line) | Class | Change | Evidence |
|---|---|---|---|---|---|
| R1 | proposal | precheck strips trailing punctuation in touches: | applied | scripts/precheck.sh:100 | <commit> |
| R2 | failure | spec facts not probed on the running app | applied | references/SPECS.md §00 | <commit> |
| R3 | proposal | add a visual side-by-side check | deferred | — | owner: Mark · 2026-11-01 |

## Rejected
| ID | Why |
|---|---|

## Evals
| Skill | Eval added | Pass before | Pass after |
|---|---|---|---|
```

## Step 5 - Gate closure

Before marking the run `done`:

- every row has a class;
- every `applied` row has evidence;
- every `deferred` row has an owner and a date;
- every changed skill has an eval that failed before and passes after;
- the same defect class does not appear unaddressed in the previous run's retro. If it does, escalate: the previous fix did not work.

If any check fails, the run status stays `awaiting-human` with `next-action: close retro items R<n>`.

## Anti-patterns

- **Rewriting the skill** because one proposal was narrow. Edit the line.
- **Applying a proposal that a later decision overrode.** Check `decisions.md` first.
- **Adding prose no eval can test.** Either make it checkable or reject it.
- **Marking a run closed with an empty closure table.** That is the exact failure this skill exists to stop.
- **Deferring everything.** If more than a third is deferred, the retro was too abstract; rewrite the proposals as file-and-line edits.

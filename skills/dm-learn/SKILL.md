---
name: dm-learn
description: Turn what went wrong or right in a session into small, specific edits to durable agent instructions (AGENTS.md, CLAUDE.md, a skill's SKILL.md, or a project doc) so the next session doesn't repeat it. Collects evidence from the conversation, classifies each lesson, proposes exact diffs, and applies only what the user approves. Use when the user says "learn from this", "remember this for next time", "update AGENTS.md", "retro", "what should we change so this doesn't happen again", or at the end of a session with corrections or repeated failures. Do NOT use for saving personal facts or preferences to the assistant's memory, or for writing project documentation for humans.
---

# Learn

Agents don't remember between sessions; files do. This skill takes the corrections and failures from this session and turns them into the smallest instruction change that would have prevented them.

The output is a set of **approved diffs to instruction files**, not a summary of the session.

## Step 1 - Collect evidence

Read the session and list concrete moments only:

- **Corrections:** the user said "no", "not like that", "I told you", or redid your work.
- **Repeated failures:** the same command, test, or approach failed more than once.
- **Discoveries:** facts you had to dig for that the next agent will need (build command, odd convention, where config lives).
- **Wins worth keeping:** an approach the user explicitly praised or asked to repeat.

For each one, write: what happened, the evidence (quote or command), and what it cost (time, a wrong change, a retry). Skip anything you can't point to.

## Step 2 - Classify each lesson

| Class | Goes to | Example |
| --- | --- | --- |
| Project fact | `AGENTS.md` / `CLAUDE.md` in the repo | "Run tests with `pnpm test:unit`; `pnpm test` needs Docker." |
| Skill behavior | That skill's `SKILL.md` | "dm-write: don't touch code blocks inside docs." |
| Personal preference across projects | The user's global instructions file, if they keep one | "Prefer British spelling." |
| Already documented | Nowhere; note that the agent missed it | The rule exists but was ignored, so the fix is placement or emphasis, not a new line. |
| One-off | Nowhere | A flaky network call that won't recur. |

Read the target file first. Most lessons should **edit or sharpen an existing line**, not append a new one.

## Step 3 - Propose diffs (HARD GATE)

For each lesson that survives, propose the exact change:

```text
L1  Project fact · AGENTS.md
Evidence:  `pnpm test` failed 3 times without Docker (turns 12, 15, 19)
Change:
  - Run `pnpm test` before committing.
  + Run `pnpm test:unit` before committing. `pnpm test` also runs integration tests and needs Docker.
```

Rules for a good lesson:

- **Specific and actionable:** a command, path, name, or rule. Not "be more careful".
- **Says why** in a few words, so a future agent can judge edge cases.
- **Smallest change:** one line beats a paragraph. Replace beats append.
- **Doesn't restate the code:** if the agent could read it from the repo in one search, it doesn't belong in instructions.

Show all proposals and ask:

> Which of these should I apply?
>
> Recommended answer: apply the project facts and skill fixes; drop anything marked one-off.

## Step 4 - Apply and check

Apply only the approved diffs. Then:

- Re-read each changed file top to bottom. Remove anything the new line duplicates or contradicts.
- If an instruction file is now over about 200 lines, say so and suggest what to move into a linked doc.
- If a skill was changed, suggest running `dm-skill-eval` on it.

End with a list of files changed and the lessons that were dropped and why.

## Anti-patterns

- **Diary entries:** recording what happened instead of what to do next time.
- **Platitudes:** "Always double-check your work."
- **Lesson bloat:** appending forever until the file is too long to be followed.
- **Silent edits:** changing instruction files without the user's approval.
- **Blaming the model:** writing "the agent should have known" instead of putting the fact where it will be read.

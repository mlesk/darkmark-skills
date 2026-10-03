---
name: dm-grill
description: Interview the user one question at a time, each with a recommended answer, until a plan, decision, design, or requirement is sharp enough to act on, then leave a grill record. Use when the user says "grill me", "interview me", "poke holes in this", "ask me questions first", or brings a fuzzy idea that needs pinning down before work starts. Other dm- skills call it for their intake. Do NOT use for factual lookups, for reviewing finished work (use dm-critic), or when the user has asked you to just proceed.
---

# Grill

Turn a fuzzy intent into a sharp one by asking the single most useful question, with a recommended answer, until nothing important is left to guess.

The output is a **grill record**: what was asked, what was decided, and what is still open. It is the input for whatever comes next.

## Rules

1. **Look before asking.** Read the conversation, open files, the repo, and docs first. Never ask what the environment can answer. State what you found as assumptions the user can correct.
2. **One question per turn.** Pick the unresolved question whose answer would change the most downstream work. Ask it, then stop and wait.
3. **Always recommend.** Every question ends with `Recommended answer:` and your best guess, specific enough that "yes" is a complete reply.
4. **Make questions concrete.** Ask about this situation, not the topic in general. "Who reads this report on Monday?" beats "Who is the audience?"
5. **Reassess after every answer.** An answer can close several questions or open new ones. Do not work through a fixed list.
6. **Push on vague answers.** "It depends", "the usual", and "fast" are not answers. Ask for the case, the number, or an example.
7. **Stop when the exit test passes**, not when the menu runs out.

## Question format

```text
Q<n> (<lens>): <question>

Recommended answer: <your best guess, stated as the answer>
```

## Lenses

The caller may supply its own lens menu (`dm-decide` supplies seven mental models, `dm-pocockify` supplies skill-design lenses). Without one, choose from:

| Lens | Probe |
| --- | --- |
| Outcome | What is observably true when this is done? |
| User | Who uses or reads the result, and what are they in the middle of? |
| Scope | What is explicitly out? Name at least three things. |
| Constraints | Deadlines, budget, interfaces, standards, must-keep items |
| Failure | Pre-mortem: it failed six months from now. Why? |
| Edge cases | What input, actor, or timing breaks the obvious path? |
| Alternatives | What else could meet the outcome? Why not that? |
| Verification | How will we know it worked without trusting anyone's confidence? |

## Exit test

Stop grilling when all of these hold:

- [ ] The goal fits in one sentence with an observable success condition.
- [ ] Scope and non-goals are explicit.
- [ ] Every remaining open question either cannot change the next step or is logged as an assumption.
- [ ] The caller's own exit criteria, if any, are met.

Hard cap: 12 questions. If you reach the cap, show the record and ask whether to continue or proceed with the logged assumptions.

## Grill record

Show this when the exit test passes, and ask the user to confirm or correct it:

```text
Grill record: <topic>
Goal: <one sentence>
Decided:
- Q1 (<lens>): <answer>
- ...
Assumptions (not confirmed):
- ...
Open (does not block the next step):
- ...
Lenses skipped and why: ...
```

Save it where the caller says. Standalone, put it in the conversation and offer to save it to a file.

## Anti-patterns

- **Question barrage.** Several questions in one turn.
- **Naked question.** A question with no recommended answer.
- **Asking the repo's job.** Asking what `package.json`, the docs, or the code already say.
- **Interrogation theatre.** Working through every lens when two of them settled the matter.
- **Silent assumption.** Filling a gap with a guess and not putting it in the record.

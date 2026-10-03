---
name: dm-skill-eval
description: Test an agent skill instead of eyeballing it. Lints the skill statically, writes trigger evals (prompts that should and should not load it, including near misses that belong to sibling skills) and behavior scenarios (what the agent must and must not do), runs them through fresh sub-agents with a separate judge, and saves a pass-rate report. Use when the user says "eval this skill", "test this skill", "will this skill trigger", "does this skill work", or after creating or changing a skill with dm-pocockify. Do NOT use to write or redesign a skill (use dm-pocockify) or to test application code.
---

# Skill Eval

A skill is a prompt. Prompts regress silently. This skill turns "looks good to me" into a repeatable pass rate that you can re-run after every change.

Evals live with the skill they test, so they travel with it:

```text
<skill>/evals/
├── triggers.md          # should-load / should-skip prompts
├── scenarios.md         # behavior scenarios with must / must-not checks
└── results/<date>.md    # one report per run
```

## Step 1 - Lint

Run the static checks first; there is no point testing behavior if the skill cannot load.

```bash
python3 <this-skill>/scripts/lint-skill.py <skill-dir>
python3 <this-skill>/scripts/lint-skill.py --all <skills-root>   # whole repo
```

It checks frontmatter, that `name` matches the directory, description length (1024 max) and trigger clause, broken relative links (including references to sibling skills), oversized bodies, and repo-local or absolute paths. Fix every error before Step 2. Report warnings.

## Step 2 - Write trigger evals

If `evals/triggers.md` doesn't exist, draft it from the description, the body's trigger boundary, and the descriptions of every sibling skill. Aim for 8-12 rows:

```markdown
| # | Prompt | Expect | Competes with |
| --- | --- | --- | --- |
| T1 | "Tighten this proposal, it rambles" | load | - |
| T2 | "Just fix the commas, don't reword" | skip | (none) |
| T3 | "Should we rebuild or refactor billing?" | skip | dm-decide |
```

- At least 4 `load` rows written in different words from the description. Copying the description's own phrases tests nothing.
- At least 4 `skip` rows, mostly **near misses**: requests a sibling skill owns, or that sound similar but need no skill.
- Show the draft to the user and ask them to add a real prompt they've typed before. Recommended answer: "Add the last prompt where the wrong skill loaded."

## Step 3 - Run trigger evals

For each row, start a **fresh sub-agent** and give it only:

1. The `name` and `description` of every installed skill (read the frontmatter from the skills root, e.g. `~/.agents/skills/*/SKILL.md`), in shuffled order.
2. The prompt.
3. The instruction: "Which one skill, if any, would you load for this request? Answer with the skill name or `none`, then one line of reasoning."

Run each row 3 times. A row passes when at least 2 of the 3 runs match `Expect` (for `skip`, any answer other than this skill). Without sub-agents, answer each row yourself from the descriptions alone, without rereading the body, and label the run `self-judged`.

## Step 4 - Write behavior scenarios

If `evals/scenarios.md` doesn't exist, draft 2-4 scenarios that test what makes the skill worth loading: its gates, its required outputs, and the shortcuts it forbids.

```markdown
## S1: <name>
Setup:     <files or context to create in a scratch directory>
Prompt:    <the user's opening message>
User:      <how the simulated user answers questions, e.g. "accepts every recommended answer">
Must:      <observable behaviors, e.g. "asks exactly one question per turn", "shows rubric before scoring">
Must not:  <forbidden behaviors, e.g. "edits the file before approval">
```

Every Must and Must-not line should be checkable from a transcript or file diff. "Is helpful" is not checkable.

## Step 5 - Run behavior scenarios

For each scenario:

1. Create the setup in a scratch directory. Never run scenarios against real project files.
2. **Runner:** a fresh sub-agent loads the skill and handles the prompt. A second sub-agent plays the user according to the `User` line. Cap at 15 turns.
3. **Judge:** a third fresh sub-agent gets the transcript, the resulting files, and the Must/Must-not list, never the skill body. For each line it answers pass or fail with a quote as evidence.

Run each scenario twice if time allows; behavior varies between runs. Without sub-agents, label results `self-judged` and treat them as weak evidence.

## Step 6 - Report

Write `evals/results/<YYYY-MM-DD>.md`:

```text
Skill eval: <skill>  (<date>, judge: sub-agent | self-judged)
Lint:       ok | N errors, M warnings
Triggers:   9/10 rows pass   (T3 failed: loaded dm-write 2/3 runs)
Scenarios:  S1 5/5 · S2 3/4  (S2 must-not "edits before approval": failed run 2)
Top fixes:
1. <description change that would fix T3>
2. <body change that would fix S2>
```

Compare with the previous report if one exists and call out regressions first. Propose fixes, but don't apply them unless the user asks; editing the skill is `dm-pocockify`'s job.

## Anti-patterns

- **Echo evals:** trigger prompts that copy the description's wording.
- **No near misses:** only testing that the skill loads, never that it stays out of a sibling's way.
- **Author-judged:** the agent that wrote or ran the skill grading its own transcript.
- **Unfalsifiable checks:** Must lines like "does a good job".
- **Single run:** treating one pass as proof when behavior varies between runs.

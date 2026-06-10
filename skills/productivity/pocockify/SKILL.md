---
name: pocockify
description: Purpose-first workflow for creating, reviewing, or pocockifying agent skills. Use when the user wants to create a new skill, improve an existing skill, review a skill, or create a stronger `<original-skill-name>-pocockified` version from an existing skill.
---

# Pocockify

Create or improve one small, sharp, standalone skill. The work is not to make instructions longer. The work is to discover the behavior contract that makes the skill worth loading, then encode that contract so another agent can reliably act on it later.

This skill is inspired by Matt Pocock's approach to prompt engineering: start with a clear purpose, inspect the source material, ask targeted questions with recommended answers, and produce durable outputs that survive the conversation. The goal is to create skills that are not just better in theory, but actually load for the right reasons and produce the right results when used by future agents.

## Operating principles

- **Trigger contract first.** A skill lives or dies by its `description`. Draft the load boundary before writing the body.
- **Small composable skills beat broad vague skills.** If the purpose contains "and then also", split, cut, or name the second skill.
- **Inspect before asking.** Read the conversation, active files, existing skill files, bundled resources, nearby examples, docs, and registries before asking the user.
- **Grill before authoring.** Ask one question at a time until purpose, trigger boundary, workflow, outputs, and verification are sharp.
- **Recommend every time.** Every user-facing question includes a recommended answer.
- **Pocockify, do not decorate.** Preserve useful domain-specific behavior, but replace vague prose with phase gates, exit criteria, explicit outputs, and verification.
- **Durable outputs over chat residue.** Produce a `SKILL.md`, a patch, or a review report that survives the conversation.
- **Fail loudly.** If purpose, source skill, prerequisites, or target output mode are unclear, stop and ask the smallest blocking question.

## Mode selection

First decide which mode the user asked for. Use available context before asking.

1. **Create from scratch** - no source skill exists. Output a new skill with the user-approved name.
2. **Pocockify existing skill** - an existing skill is the starting point. Output a new skill named `<original-skill-name>-pocockified`.
3. **Review only** - the user wants critique without file edits. Output findings and a proposed skill contract.
4. **Update in place** - the user explicitly wants the existing skill changed. Edit the existing skill instead of creating a suffixed copy.

Default for an existing source skill: **Pocockify existing skill**. Do not overwrite the original unless the user explicitly asks for in-place updates.

If mode is unclear, ask:

> Should I create a new skill from scratch, review the existing skill, update it in place, or create a `-pocockified` copy?
>
> Recommended answer: "Create a `-pocockified` copy so we keep the original intact while producing a sharper version."

## Naming rule for existing skills

When creating from an existing skill, derive the original skill name from the source skill's frontmatter `name`. If frontmatter is missing, use the source directory name.

The new skill must be named:

```text
<original-skill-name>-pocockified
```

The new directory should use the same value. Example: `write-a-skill` becomes `write-a-skill-pocockified`.

If the source frontmatter name and directory name disagree, fail loudly and ask which name should be authoritative.

## Phase 0 - Inspect context

Before asking anything, inspect what is already available:

- Current conversation: goal, examples, corrections, desired output mode, non-goals.
- Source skill, if any: `SKILL.md`, frontmatter, bundled resources, scripts, references, examples, and assets.
- Workspace: existing skill naming conventions, registries, README entries, validation commands, and nearby skill style.
- Existing ecosystem: overlapping skills, competing trigger descriptions, and reusable patterns.

Do not ask a question if the answer is discoverable. State important assumptions briefly and keep moving.

Exit criteria:

- You know the mode.
- You know whether there is a source skill.
- For existing skills, you know the original skill name and target `-pocockified` name.
- You know which facts came from context and which still need user judgment.

## Phase 1 - Source skill audit

Skip this phase for pure from-scratch creation.

For an existing skill, read the source skill as an artifact, not as truth. Extract:

- **Current trigger contract:** what the description says should load it.
- **Actual job:** what the body makes the agent do.
- **Useful behavior to preserve:** domain knowledge, templates, scripts, output formats, hard-won constraints.
- **Weaknesses:** trigger mush, broad scope, no feedback loop, no exit criteria, chat-only output, missing verification, local dependency leaks.
- **Hidden prerequisites:** tools, files, credentials, commands, or project conventions the skill assumes.
- **Overlap:** nearby skills it competes with.

If you cannot read the source skill, ask:

> Where is the existing skill I should use as the starting point?
>
> Recommended answer: "Use `<path-to-existing-skill>/SKILL.md` as the source, then create `<original-name>-pocockified` beside it."

Exit criteria:

- You can summarize the existing skill's contract in one sentence.
- You can name what must be preserved and what must be fixed.
- You know whether the target is review-only, in-place update, or suffixed copy.

## Phase 2 - Purpose grill

Ask one question at a time. Choose only the single highest-leverage unresolved question, wait for the answer, then reassess. Do not ask the whole list.

Use these questions as a menu:

1. **Job:** What repeated task should this skill make easier, safer, or more reliable?
   - Recommended answer: "It should help agents create a clear [artifact/workflow] from [input] without drifting into [known failure mode]."
2. **Pain:** What goes wrong when an agent does this without the skill?
   - Recommended answer: "Agents usually [failure mode], so the skill should force [countermeasure]."
3. **Preservation:** If starting from an existing skill, what must survive the pocockification?
   - Recommended answer: "Preserve [domain-specific workflow/template/script], but sharpen the trigger, gates, outputs, and verification."
4. **User:** Who invokes it, and what are they probably in the middle of doing?
   - Recommended answer: "A user who has [situation] and wants [outcome] without [cost]."
5. **Moment of value:** What should be noticeably better after the skill loads?
   - Recommended answer: "The agent should [observable behavior] earlier and more consistently than a generic assistant would."

Exit criteria:

- The purpose fits in one sentence.
- The skill has one job, not a bundle of adjacent jobs.
- For existing skills, the preserve/fix boundary is explicit.

## Phase 3 - Trigger boundary grill

The trigger boundary is the most important design decision. Grill until it is crisp.

Ask one question at a time from this menu:

1. **Positive triggers:** What exact user phrases, file types, artifacts, or contexts should load this skill?
   - Recommended answer: "Use when the user says [phrases], references [artifact], or asks to [task]."
2. **Near misses:** What similar requests should not load this skill?
   - Recommended answer: "Do not use for [neighboring task]; use [other workflow] or answer directly instead."
3. **Overlap:** Which existing skills might compete with it?
   - Recommended answer: "This skill owns [narrow job]; [other skill] owns [neighbor job]."
4. **Review triggers:** If reviewing or updating an existing skill, what words should load this workflow?
   - Recommended answer: "Use when the user asks to review, improve, pocockify, sharpen, rewrite, or create a `-pocockified` version of a skill."

Exit criteria:

- The `description` can be drafted before the body.
- Positive triggers and non-triggers are explicit.
- A future agent can choose between this skill and nearby skills without guessing.

## Phase 4 - Workflow, output, and verification grill

Make the output durable and checkable.

Ask one question at a time from this menu:

1. **Workflow:** What sequence should the agent follow every time?
   - Recommended answer: "Inspect -> audit source if present -> grill -> present contract -> get approval -> author or review -> verify."
2. **Output mode:** What exact artifact should this run produce?
   - Recommended answer: "A complete `SKILL.md` in `<original-name>-pocockified/`, with optional supporting files only if they improve reliability."
3. **Feedback loop:** Where does the user see and correct the work before it hardens?
   - Recommended answer: "Before authoring, present the skill contract and wait for approval."
4. **Verification:** How should the agent know the result is good?
   - Recommended answer: "Self-review trigger precision, standalone usability, extraction safety, behavior gates, and three positive plus two near-miss trigger examples."

Exit criteria:

- The final artifact is defined.
- Optional supporting files are justified or rejected.
- Success can be checked without trusting the author's confidence.

## Phase 5 - Present the skill contract

Before writing files, present this contract and ask for approval:

```markdown
## Skill Contract

**Mode:** create from scratch / pocockify existing / review only / update in place
**Source skill:** <path or none>
**Output skill name:** <skill-name or original-name-pocockified>
**Purpose:** <one-sentence job>
**Use when:** <positive trigger list>
**Do not use when:** <near-miss list>
**Workflow:** <phase list with gates>
**Primary output:** <artifact or review report>
**Preserve from source:** <none, or source behaviors/files to keep>
**Change from source:** <trigger/workflow/output/verification changes>
**Optional support files:** <none, or justified list>
**Verification:** <checks or commands>
```

Ask for approval before authoring in every normal interactive session. Proceed without approval only when the user explicitly delegated creation or update without further confirmation; in that case, state the contract and assumptions before writing.

## Phase 6 - Author, review, or update

### Create from scratch

Write a complete `SKILL.md` with YAML frontmatter and a compact instruction body.

### Pocockify existing skill

Create a new skill directory named `<original-skill-name>-pocockified` and write its `SKILL.md` there. The new frontmatter `name` must also be `<original-skill-name>-pocockified`.

Preserve useful source behavior, but rewrite the skill around:

- trigger contract first
- one-question-at-a-time grilling where user judgment is needed
- recommended answers for every user-facing question
- context inspection before asking
- phase gates and exit criteria
- explicit anti-patterns
- durable outputs
- loud failure on unclear prerequisites
- final self-review

Copy supporting files only when they genuinely improve reliability. If a source support file is copied, update references so the new skill is extractable on its own.

### Review only

Produce findings in this order:

1. Blocking issues
2. Nonblocking improvements
3. Proposed skill contract
4. Suggested `-pocockified` name
5. Verification gaps

Do not edit files.

### Update in place

Edit the existing skill only when the user explicitly requested in-place update. Preserve source-specific knowledge and avoid unrelated rewrites.

## Required frontmatter

```yaml
---
name: skill-name
description: One sentence describing what the skill does. Use when the user says specific phrases, references specific artifacts, or enters specific contexts where this skill should load.
---
```

Description rules:

- Include the capability and trigger contexts.
- Use concrete words users actually say.
- Include review/update/pocockify triggers when the skill handles existing skills.
- Avoid generic descriptions like "helps with skills" or "improves workflows".
- Keep it standalone; do not depend on repo-local docs, private paths, or this conversation.

## Anti-patterns to reject

- **Trigger mush:** The description is broad enough to load for almost anything.
- **Essay skill:** The body explains a philosophy but does not tell the agent what to do next.
- **Mega-skill:** One skill tries to cover ideation, planning, coding, review, shipping, and docs.
- **Ask-before-looking:** The agent asks the user for facts available in the workspace or source skill.
- **Source worship:** The new skill preserves old structure even when it caused the failure.
- **Destructive pocockification:** The original skill is overwritten when the user expected a suffixed copy.
- **No gate:** The workflow proceeds while purpose, scope, output mode, or success remains fuzzy.
- **Chat-only output:** The skill produces advice that disappears instead of an artifact, decision, checklist, issue, test, or edited file.
- **Local dependency leak:** The skill references repo-specific files or private conventions without bundling them or making them optional.
- **Verification theater:** The checklist says "looks good" instead of checking concrete properties.

## Final self-review

Before declaring done, check:

- [ ] Mode is explicit: from scratch, pocockified copy, review only, or in-place update.
- [ ] Existing source skill, if any, was inspected before asking questions.
- [ ] `name` matches the directory name and is specific.
- [ ] Existing-skill copy is named `<original-skill-name>-pocockified`.
- [ ] `description` states both capability and trigger contexts.
- [ ] Positive triggers are concrete.
- [ ] Near misses are handled.
- [ ] The skill is small enough to compose with other skills.
- [ ] The workflow has phase gates and exit criteria.
- [ ] The skill inspects context before asking the user.
- [ ] Every user-facing question pattern includes a recommended answer.
- [ ] Outputs are durable and behavioral, not just conversational.
- [ ] Prerequisite uncertainty fails loudly.
- [ ] Optional support files are justified or omitted.
- [ ] The folder can be extracted and still works without repo-local materials.
- [ ] At least three positive trigger examples and two near-miss examples have been tested against the description.
- [ ] Extraction safety has been checked by reading the draft as if copied into an empty skills directory: no repo-local paths, private references, or prior-chat dependencies are required.

End by telling the user what was created or reviewed, what assumptions were made, and how the result was verified.

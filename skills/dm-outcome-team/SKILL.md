---
name: dm-outcome-team
description: Take a product idea, or a change to an existing codebase, to working software the human has accepted. The human's intent is captured once, every requirement is proven by a test, nothing is accepted on its author's word, and the project is left with a current description of the system for the next change. Invoke with the idea or the change; invoke again in the same project to resume an unfinished run.
disable-model-invocation: true
---

# Outcome Team

You own one result: **software the human asked for, shown to do what they asked, at a cost that fits its size, with no surprises for them.** How you get there is yours to decide. That covers the order of work, which documents you write, whether you use helpers and how, and how you split the build. This file says what must be true at the end, the limits you work within, and how good is good enough.

## Done means

The human has accepted the run, and all of these hold:

1. **It does what they asked.** The human can do what they said they wanted to do when this was finished. You have shown it working by running it, not by describing it.
2. **Every requirement is proven.** Each thing the software must do is written down precisely enough to test, including timing, limits, and how rules interact (what happens to one rule while another is in progress). It has a test that passes now and would fail if any part of that behaviour broke: every value, branch, and case the requirement names, not just the first one. A test that only touches part of its requirement doesn't count, and a check that only confirms a test exists doesn't prove it is strong enough. Nothing ships that no requirement asked for.
3. **Nothing was accepted on its author's word.** No design and no finished work passes on the judgment of the context that produced it. Whoever checks it sees the work and the intent, not the author's reasoning, and looks for what is wrong.
4. **It meets the chosen quality bar.** The human picks prototype, internal, or production. At every bar the code is formatted, linted, and type-checked where the language allows, and one fast, repeatable command proves it green. The standard rises with the bar. Measurable qualities, such as speed, size, or limits, are measured, or you say why they couldn't be.
5. **Someone else can pick it up.** The repo explains how to install, run, test, and configure the software. The project holds a current description of the system as it now is: what it does, its rules, its structure, and the decisions behind them. The next change starts from that, not from reading the code from scratch.
6. **Nothing was decided silently.** Every choice made without the human is recorded with its reason and what it would cost if it were wrong, and the human saw the list before accepting.
7. **The run leaves a lesson.** A short retrospective records what the run cost, where the effort went, what went wrong, and what would make the next run better. Anything a future run should know that the repo doesn't already record is kept where the next run will find it.

## The human's part

- **Ask once, and ask well.** At the start, learn in one round what you need to know about their intent: the problem, who it's for, what they want to be able to do when it's done, what's out of scope, the rules with exact values, how it should feel to use, technology preferences and constraints, the quality bar, how much autonomy they want, and where the work should live if the project isn't a repository yet. Give a recommended answer with each question so they can accept it as is. Ask a second round only if an answer opens a choice you can't make well yourself.
- **Then don't interrupt.** Between decision points, settle gaps yourself, record the assumption, and show it at the next stop. The one exception is a question only the human can answer that blocks all remaining work.
- **Decision points.** The human always approves the direction before design begins, and the result before the run closes. They also approve the design before building starts, unless they chose more autonomy in words. They may ask for more stops and may change the level of autonomy at any stop.
- **A stop is a real stop.** Lead with what is being decided, the choices that matter, the assumptions to confirm, and what was decided since the last stop. Say how to approve, change course, or end the run. Then end your turn. A stop is approved only by the human's words, or by the level of autonomy they chose.
- **An approved design is a promise.** A later change to what it promises, such as scope, a shared interface, or a dependency, goes back to the human unless their autonomy covers it. A clarification doesn't need approval, but you still record it.

## Hard limits

These hold at every level of autonomy. Only the human's explicit words lift one.

- Stay inside the project root. No push, publish, or deploy, and no network use beyond installing approved packages.
- Use no dependency the human hasn't approved, either directly or as part of an approved design.
- Put no secrets or real credentials anywhere.
- Delete only what this run created, or what the human approved deleting.
- **Clean room.** Reference material the human points to may shape the requirements, as statements of behaviour only. Never copy code, identifiers, or text from it, and keep it away from whoever writes the code. Code comes from the approved design.
- **Tests are evidence.** Never weaken, skip, delete, or rewrite a test to get green, and never hard-code a result. If a test is wrong, raise it as a finding instead of fixing it quietly.
- **Existing code.** Work on a branch from a clean tree, and never touch the human's uncommitted work. Break nothing that worked before unless the human approved the change, and pin current behaviour with tests before you change it.
- **Bounded effort.** Respect any time or cost ceiling the human set. When work stops converging, change something real, such as the approach, the effort, or who looks at it, or take it to the human with the evidence. Never loop.

## Surviving interruption

Any session can end at any moment, and the next one may start with nothing but the repository.

- At all times, the committed project tells a fresh session what this run is for, where it stands, what was decided and by whom, what waits on the human, and the exact next step.
- A fresh session checks that nothing it relies on changed behind its back before it trusts it. If something did change, it asks the human before it builds on it.
- An unattended session never asks the human anything. When it reaches a stop, it records the stop and ends.

## Spending well

- **Scale the process to the job.** A one-screen tool doesn't need the process of a multi-service system. Scale documents, reviews, and stops to the size and stakes, and tell the human at the first stop what scale you chose.
- **Fresh contexts are expensive, and warm ones are cheap.** Use a helper when independence or real parallelism earns its cost, not by default.
- **Make checks mechanical where you can.** Any check a script can do should be a script, run on every piece of work.

## Honest reporting

Every claim of progress or success rests on a tool result from this session. If something isn't verified, say so plainly. Helpers' guesses are not facts: they reach the human as assumptions to confirm.

## Contracts with the scripts

Two scripts ship with this skill. They work only if you keep these formats.

**Unattended runner (`scripts/run.sh`).** `.agent-team/active` names the current run folder under `.agent-team/runs/`, or holds `none`. That folder's `state.md` has these fields, each on its own line, `key: value`:
- `status:` one of `in-progress`, `awaiting-human`, `blocked`, `done`, `abandoned`
- `stage:`
- `mode:` (`stepwise` means the run never goes unattended)
- `next-action:`
- `halt:` while blocked

The runner treats any change to `state.md` as progress.

**Per-piece precheck (`scripts/precheck.sh`).** The precheck reads `specs/03-architecture.md` in the run folder:
- A `verify:` line.
- §9, with an optional `suppression exceptions:` line.
- §10, with a `test files:` line, and §10.1, a table whose 4th column lists the quality config files.
- §11, a table whose first column lists the allowed packages, plus a `list command:` line.
- A `### PHASE-###` entry for each piece of work, with `touches:` and `acceptance tests:` lines.

The precheck expects requirement IDs in the form `REQ-n.n` and test names that carry them, with `-` and `.` written as `_`.

Run it on every piece of work, and on exit 1 treat its findings as must-fix. Exit 2 means it couldn't run: do the same checks some other way.

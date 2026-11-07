---
name: dm-portfolio
description: Run the weekly portfolio review that turns evidence into a ranked backlog of the next bodies of work and exploratory opportunities. Reads every project's git state, agent runs, tests, deploy gaps, and goals; produces one file per opportunity plus an INDEX and a NEXT work order; claims and closes items. Use when the user asks "what should I work on", "plan my week", "where should I point the agents", "review the portfolio", "what is the next body of work", "find opportunities", or "make a backlog". Do NOT use to start the work it proposes, to review a diff, or to replace dm-sweep's nightly health check.
---

# Portfolio

The weekly planning loop. It answers one question: **given the assets that exist, the goals that matter, and the capacity available, what is the highest-value next body of work?**

The output is a ranked backlog an agent can pick up cold, not a brainstorming document.

## The two layers

| Layer | Runs | Produces |
|---|---|---|
| **Evidence** | Weekly, deterministic, no model | `inventory/latest.json` and `.md`: git state, unmerged branches, agent runs, next actions, test/sweep health, deploy signals, PRs, TODOs |
| **Judgment** | When the user has capacity | `seeds.json` additions, re-scores, `backlog/INDEX.md`, `backlog/NEXT.md`, `backlog/REVIEW.md` |

The evidence layer never depends on an agent. The judgment layer never invents facts the evidence does not contain.

## Modes

### `review` (default)

1. **Refresh the evidence.**
   ```bash
   scripts/weekly.sh --ops <ops>
   ```
   This runs `inventory.py` and `plan.py`. Read `inventory/latest.md`, `backlog/INDEX.md`, and the previous `backlog/REVIEW.md` if present.

2. **Reconcile last week.** For every item claimed or shipped since the last review, check the evidence: did the branch merge, did the URL appear, did the run close? Mark `done`, `dropped`, or `stale`; never carry a dead item silently.

3. **Find the next body of work per project.** Use the evidence, in this order:
   - a run whose `status` is `in-progress` or `awaiting-human` → its `next-action` is the item;
   - a run whose `status` is `done` on an unmerged branch → merge-and-archive is the item;
   - a red sweep → the first red check is the item;
   - a built product with no URL → deploy is the item;
   - a repo with no remote or no public artifact → publish is the item;
   - a dirty tree, stale branch, or large TODO count → maintenance, lowest priority.
   Do not invent a feature when one of these exists. Finishing beats starting.

4. **Add exploratory opportunities.** Apply the lenses below to the assets and goals. Add 3–5 to `seeds.json` as valid JSON objects; do not duplicate an existing key. An exploratory item is only valid if it produces an artifact someone else can see.

5. **Hard gate every item.** Drop or rewrite anything that fails:
   - a concrete artifact (file, URL, recording, post, repo, decision memo);
   - a done-when observable by someone other than the author;
   - a stated goal in `goals.md`;
   - starts from existing assets, no new spend;
   - one skill and one initiating prompt;
   - ≤ 2 agent-days, or explicitly labelled a bet with a checkpoint.

6. **Score.** Use `config.json` weights and the anchors below. A score without a one-line reason is invalid. Change a score only when the evidence changed.

7. **Regenerate and inspect.**
   ```bash
   python3 scripts/plan.py --ops <ops>
   ```
   Read `backlog/INDEX.md`. Fix titles that do not name a deliverable. Write `backlog/REVIEW.md` with:
   - the top five and why;
   - what changed since last week;
   - the single human decision that unlocks the most value;
   - anything that should be dropped.

8. **Stop.** Do not start any item in this session. The output is the backlog.

### `pick`

```bash
dm-portfolio pick            # highest-scoring open item
dm-portfolio pick OPP-...    # a specific item
```

Marks it `claimed`, writes `picked/<ID>.md`, and prints the initiating prompt. The prompt is a complete work order: goal, context, done-when, first action, constraints, failure modes. Hand it to `dm-router` (or straight to the named skill) in a fresh session.

### `status`

```bash
dm-portfolio status
```

Prints rank, ID, score, status, project, and title. Use it at the start of a capacity window: one glance, one choice.

### `close`

```bash
dm-portfolio close OPP-... --outcome shipped --note "deployed at ..."
```

Writes `archive/<ID>.md`. Outcomes: `shipped`, `dropped`, `parked`, `blocked`. The next review removes it from the index.

## The rubric

| Criterion | Weight | 2 | 5 | 8 | 10 |
|---|---|---|---|---|---|
| Goal impact | 30 | no stated goal | indirect | serves one goal | serves two, or the income floor |
| Leverage | 20 | one-off | reusable in one project | reusable across projects | a public artifact others adopt |
| Time to signal | 15 | > 8 weeks | 3–4 weeks | ~1 week | same day |
| Probability | 15 | speculative | plausible | evidence + clear path | already 80% done |
| Learning | 10 | repeats known work | deepens a skill | new capability with a test | changes how I work |
| Cost / risk (inverse) | 10 | new spend or high risk | moderate | existing assets, reversible | trivial |

Score = weighted mean, 1–10. Effort: **S** ≤ 0.5 agent-day, **M** 1–2, **L** 3–5. The top five should fit the week's capacity (`config.json`); everything else is a queue, not a commitment.

## Exploratory lenses

1. **Asset → audience.** What can be shown to whom by Friday? A demo, a recording, a write-up, a workshop.
2. **Claim → proof.** What do you need to be able to say in an interview, and what artifact would prove it?
3. **Reuse → leverage.** What did you build that someone else would adopt if it had a quickstart and a licence?
4. **Risk → cheapest test.** What is the riskiest assumption in the current plan, and what is the smallest test that could kill it?
5. **Deadline → reverse.** If the deadline were 14 days, what would you ship, and what would you cut?
6. **Gap → market.** What do the target roles ask for that the portfolio does not currently show?

## The files

```text
inventory/YYYY-MM-DD.json|md   deterministic snapshot
backlog/OPP-YYYYMMDD-NN.md     one opportunity, full work order and prompt
backlog/INDEX.md               the ranked table
backlog/NEXT.md                the top item, ready to paste
backlog/state.json             status, scores, claims (planner-owned)
backlog/REVIEW.md              the judgment: top five, changes, the one decision
picked/OPP-....md              a claimed work order
archive/OPP-....md             closed items
seeds.json                     exploratory candidates (agent- or human-edited)
```

`INDEX.md` columns: Rank · ID · Project · Category · Title · Score · Effort · Skill · Model · Status. `NEXT.md` contains the full initiating prompt for the top item.

## Categories

`ship` (deploy or get users) · `finish` (merge, archive, land a PR) · `fix` (red tests, sweep) · `next` (a run's next action) · `leverage` (public artifact, case study, packaging) · `explore` (new evidence, interview, demo) · `learn` (skill or domain) · `maintain` (cleanup).

## Anti-patterns

- **Feature generation.** A new feature is not a body of work unless a user asked for it or a goal requires it.
- **Infinite backlog.** More than the capacity is a queue; do not present it as a plan.
- **Unobservable outcomes.** "Improve the UI" is not done-when. "A stranger can complete the demo without help" is.
- **Score inflation.** Ten items at 9.0 means the rubric was not applied.
- **Starting the work.** This skill plans; `dm-router` executes.
- **Ignoring a red signal.** A red sweep or a blocked run outranks a new idea.
- **Duplicating a claimed item.** Check `backlog/state.json` first.

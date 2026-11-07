# dm-research — Usage Guide

**Start here.** How to run the `dm-research` skill. Agents never load this file. Why it is shaped this way: [DESIGN.md](./DESIGN.md). The runtime the Lead follows: [SKILL.md](./SKILL.md), [PROTOCOL.md](./PROTOCOL.md), [ROUTING.md](./ROUTING.md).

**Status: experimental.** It lives in `skills/dm-research/` as a top-level skill, so `link-skills.sh` links it. Invoke it by name, or by path (§3).

## 1. What it is

A Lead skill plus two sub-agents (**researcher, reviewer**). Together they turn an open question into evaluated options and a recommendation you can defend:

**scoping scan → one interview → parallel research waves → options (status quo + a bold one) → veto and score on criteria fixed up front → stress test → citation script + independent review → report.**

- **One interview, informed.** The Lead scans the landscape first, so its questions and recommended answers are informed ones. After the brief gate it doesn't ask you anything until the next gate.
- **Every claim sourced.** Researchers write claims with a kind (fact, estimate, inference, opinion), a source, an exact quote, and a confidence with its reason. `scripts/ledger.sh` rejects any row that is incomplete.
- **Criteria before evidence.** You approve the scoring criteria at the brief gate. If they change later, the change is shown with the evidence that forced it.
- **Wider option space.** The status quo is always scored, and so is at least one bold option you didn't name.
- **Independent check.** `scripts/cite-check.sh` proves every citation resolves. A reviewer with a fresh context then opens the sources behind the claims that matter and builds the strongest case against the leading option.
- **Gets leaner as models improve.** Each reviewer check names the failure it prevents. `scripts/retro.sh` counts which checks fire across runs, and lists those that haven't fired in five runs as candidates to retire.

## 2. Prerequisites

- An agent host that starts subagents. Without them the Lead researches alone and says the review is self-review.
- Web search and fetch. Connectors (Drive, mail, Slack…) are used only when you name them at the brief gate.
- `dm-decide` installed beside it in the same repo; its scoring rules and lenses are reused.
- Run the session on your strongest model. The Lead does the synthesis and writes the report.

## 3. Run it

```text
Read <repo>/skills/dm-research/SKILL.md and act as the dm-research Lead it defines.
Is there a business opportunity in scheduling software for independent physiotherapy clinics in Canada?
Kind: opportunity. Size: standard. Mode: stepwise.
```

1. **Brief gate.** Answer the interview; accept the recommended answers you agree with. Check the research questions and the draft rubric. Everything after this runs on what you approve here.
2. **Findings gate** (stepwise, after each wave). See what was learned and what surprised, and redirect if needed.
3. **Options gate.** Check the options, vetoes, and final rubric before anything is scored.
4. **Report gate.** Read the recommendation, what would change it, and the open questions. Then read `retro.md`.

Run it again in the same folder to resume after a break.

## 4. Size and modes

| | quick | standard | deep |
|---|---|---|---|
| For | a two-way-door decision, a first look | a business case, a vendor or hiring decision | a one-way door, a venture, a strategy |
| Questions · parallel · waves | 3–5 · 3 · 1 | 5–10 · 5 · 2 | ≤15 · 8 · 3 |
| Report | ≤1,500 words | ≤3,000 | ≤5,000, plus `dm-critic` on a one-way door |

| Gate | stepwise (default) | checkpoint | yolo |
|---|---|---|---|
| brief, report | stop | stop | stop |
| findings | stop | auto | auto |
| options | stop | stop | auto if the rubric is unchanged |

**Hard stops in every mode:** any outward action (sending, posting, contacting people, signing up, buying), credentials, a source you didn't allow, the budget ceiling.

## 5. Where everything lives

```
.research/                   # in the git root, else the current folder
├── active  models.md  lessons.md  rule-hits.tsv
└── runs/R001-physio-scheduling/
    ├── brief.md  plan.md  state.md  decisions.md
    ├── findings/RQ-###.md   ledger.md
    ├── options.md  report.md  reviews/  retro.md
    └── logs/                # git-ignored
```

## 6. Testing the skill

```bash
skills/dm-research/evals/test-scripts.sh       # ledger, cite-check, retro on a fixture and seeded defects
python3 skills/dm-skill-eval/scripts/lint-skill.py skills/dm-research
```

Two end-to-end runs remain before it graduates from experimental ([DESIGN.md §10–§11](./DESIGN.md#10-verification)).

# What good options, scores, and reports look like

Only the Lead reads this file, at the options step and before writing the report. It describes the target, not a template: a stronger report inside this frame is welcome. Scoring rules come from `dm-decide` (`../../dm-decide/SKILL.md` Steps 3–5); this file says how they apply to researched options.

## Options

`options.md` holds, in order:

1. **Option set.** Each `OPT-##` in one paragraph: what it is, how it would work in practice, what it costs, what must be true for it to work (its `ASM`s), and the claims behind each statement. `OPT-00` is the status quo. At least one option is **bold**: one the brief didn't name, usually more ambitious, combined, or reframed. An option set of near-duplicates is a weak set; options should differ on the criteria that carry the most weight. Score a combined option's blended criteria on its stated split of hours or profit, never an even blend.
2. **Vetoes.** `| OPT | Must-pass failed | Evidence |`. Never veto the status quo silently.
3. **Rubric.** `| K-# | Criterion | Weight | 2/10 anchor | 10/10 anchor | Changed since brief |`. Weights sum to 100. Anchors are observable ("10/10: paying customers within 90 days") not adjectives ("10/10: great fit"). A change since the brief names its `D-###`; a changed `K-1` scale after the options gate also gets a sensitivity row.
4. **Scores** (after the options gate). Under `## Scores`, per option, `| K-# | Score | Rationale | Claims |`; every row cites at least one claim, `L-C##`, or `ASM` (`cite-check.sh` C5). `K-1` is goal attainment: each `K-1` row cites an `L-C##` deriving it as volume reached × price × margin, stated as owner profit after acquisition, on one basis for every option (C8). Then, under `## Summary`: `| OPT | Weighted total | Confidence | One-line rationale |`.
5. **Sensitivity.** What flips the leader: the smallest weight change, or the single assumption or claim that, if wrong, makes the runner-up win. If the margin is under 10 points, say the result is close and what would separate the options.
6. **Stress test.** The leader's most likely way to fail (inversion) and what follows from choosing it (second-order effects), each with what the evidence says.

Scores change only when evidence changes. A score resting on low-confidence or `single-source` claims says so in its rationale.

## Report

`report.md` is for the decider, who may read only the first screen. Outcome first, then the support, within the size's word cap.

1. **Recommendation** (one paragraph): what to do, why it wins, and the confidence (`high | medium | low`, with the reason). If it's a tie or the evidence can't separate the options, say that: an honest "it depends on X; here's how to find out" beats false precision.
2. **The question** in one line, and the decision it serves.
3. **Options at a glance:** the summary table from `options.md`, vetoed options included with the reason.
4. **Why the leader wins:** the two or three claims that matter most, cited.
5. **What would change the call:** the sensitivity result, specific enough to monitor.
6. **Risks and guardrails:** the stress test's findings and what to watch after acting.
7. **Next steps:** the first concrete action, and the cheapest step that reduces the biggest remaining uncertainty.
8. **Kind sections** from [KINDS.md](./KINDS.md).
9. **Open questions:** what the research couldn't settle and what it would cost to settle it.
10. **Method:** size, waves, questions asked, sources by type, the reviewer's verdict, and links to `options.md` and `ledger.md`.

**Citations.** Every factual sentence ends with its claim IDs in brackets: `[RQ003-C01, RQ003-C04]`. Each citation of a low-confidence claim carries `(low)` right after the ID, and of a `single-source` claim `(single-source)`: `[RQ003-C02 (low), RQ003-C05]`. `(low)` covers a claim that is both. Before an inference sets the headline ("the only…", "took N months"), read its derivation and carry its exceptions and bounds into the sentence.

**Good reports** are short where the evidence is clear and careful where it is thin; separate what is known from what is estimated; name the person or source when citing an opinion; and leave the decider knowing exactly what to do Monday.

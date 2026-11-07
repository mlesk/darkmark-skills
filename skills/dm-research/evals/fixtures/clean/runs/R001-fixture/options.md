# Options
## Option set
- OPT-00 Status quo: keep the self-hosted database [RQ002-C01].
- OPT-01 Move to Provider A [RQ001-C01].
- OPT-02 Move to Provider B [RQ001-C02 (low)].
## Vetoes
| OPT | Must-pass failed | Evidence |
|---|---|---|
| OPT-02 | K-2 budget ceiling | RQ001-C02 |
## Rubric
| K-# | Criterion | Weight | 2/10 anchor | 10/10 anchor | Changed since brief |
|---|---|---|---|---|---|
| K-1 | Cost | 60 | over $8k/yr | under $3k/yr | no (D-002) |
| K-2 | Ops load | 40 | over 4 h/week | under 30 min/week | no |
## Scores
### OPT-00
| K-# | Score | Rationale | Claims |
|---|---|---|---|
| K-1 | 4 | ops time priced in | RQ002-C01, ASM-001, L-C02 |
| K-2 | 3 | 2–4 h/week | RQ002-C01 |
### OPT-01
| K-# | Score | Rationale | Claims |
|---|---|---|---|
| K-1 | 7 | $380/month | RQ001-C01, L-C02 |
| K-2 | 9 | managed | L-C01 |
## Summary
| OPT | Weighted total | Confidence | One-line rationale |
|---|---|---|---|
| OPT-01 | 78 | medium | cheaper and less ops |
| OPT-00 | 36 | medium | ops time dominates |

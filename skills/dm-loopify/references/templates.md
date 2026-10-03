# Loopify templates

Use these compact artifacts instead of narrating between rounds.

## Optimization contract

```text
Optimization contract
- Goal:
- Consumer:
- Target class:          single artifact | artifact set | subsystem | codebase | goal-only
- Iteration slice:
- Search posture:        focused refinement | diverge then converge
- Path:                  light | full
- Threshold:             XX/100
- Margin:                +N
- Round cap:             N
- Plateau fallback:      one best-of-2 escape round, then stop and report the gap
- Review:                on | opted out (reason)
- Domain pack:           none | dm-write | dm-decide | ...
```

## Rubric

```markdown
## Rubric: <target>

### <Dimension> (weight: X)
- 2/10: <concrete failure the user could point at>
- 10/10: <concrete excellence achievable in scope>

Threshold: XX/100
```

## Scorecard

```text
BASELINE SCORE: XX/100

Dimension              Weight  Score  Rationale
-----------------------------------------------
...                     ...     ...    ...
```

Score = `sum(weight × score) / sum(weights) × 10`.

## Round

```text
Round N  (judge: blind pairwise | self-judged)
- Critique:   <weakness> — <rule/dimension> — costs ~X
- Slice:
- Candidate:  <path or summary of the change>
- Verdict:    candidate preferred on <dims> | best preferred on <dims>
- Score:      XX (best was YY, margin +N)
- Decision:   accepted | rejected
```

## Blind pairwise judge prompt

```text
You are judging two versions of the same <target> against this rubric.
<rubric with anchors>
Version A:
<...>
Version B:
<...>
For each dimension, say which version is better (A, B, or tie) and why in one
line. Then give an overall preference and a 0-100 score for each version.
You do not know which version is newer. Judge only what is on the page.
```

Randomize which version is A. Record the mapping in the round log.

## Trajectory

```text
Baseline -> R1 -> R2 -> R3 -> Final
   62    -> 68 -> 68 -> 77 ->  77
```

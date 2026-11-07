---
name: dm-router
description: Route a request to the right skill, model tier, and first action before doing any work. Use when a request is broad or ambiguous ("help me with X", "build this", "figure out Y"), when more than one installed skill could apply, when the user asks "what should I use", or at the start of any multi-step task. Emits a three-line route and then hands off. Do NOT use for a single-file edit, a factual question, or a request that already names a skill.
---

# Route

One screen. Pick the work, the skill, the model tier, and the first action. Do not read the whole skill library and do not chain skills for the sake of it.

**The default is no skill.** Most requests are one edit or one answer. Use a skill only when its verb matches the request.

## Step 1 - Name the verb

| The user is asking to... | Verb |
|---|---|
| choose between options, "should I", "which one" | **decide** |
| learn a market/topic, compare the landscape, gather evidence | **research** |
| build or change a system across more than one file | **build** |
| find why something is broken | **debug** |
| review finished work, "tear this apart", "what am I missing" | **critique** |
| improve prose, "does this read clearly" | **write** |
| turn a fuzzy idea into a plan | **grill** |
| make an existing artifact measurably better against a rubric | **optimize** |
| understand a codebase, its architecture or relationships | **understand** |
| create or improve a skill | **skill** |
| check whether a skill triggers/works | **eval** |
| keep a run healthy overnight, morning digest | **sweep** |
| close a retro into applied changes | **retro-apply** |

If two verbs apply, pick the one that produces the artifact the user will judge. Do not run both.

## Step 2 - Route

| Verb | Skill | Model tier | First action | Gate |
|---|---|---|---|---|
| decide | `dm-decide` | deep | Write the decision contract, then grill it | The contract |
| research | `dm-research` | deep for synthesis, cheap for retrieval | Draft the brief and the question set | Brief, options |
| build, small (1–3 files) | none — do it directly | standard | State the done-when and the command | The command |
| build, multi-file or multi-phase | `dm-agent-team` | session deep; builders standard | Write the brief, then the probe | Brief, spec, milestone, accept |
| debug | `dm-debug` | standard | Reproduce, shrink, rank hypotheses | Repro |
| critique | `dm-critic` | deep | Name the artifact and the rubric | Findings table |
| write | `dm-write` | standard | Diagnose against the ten rules | Revised text |
| grill | `dm-grill` | standard | One question at a time, each with a recommended answer | The plan |
| optimize | `dm-loopify` | deep | Lock the rubric and score the baseline | Threshold |
| understand | `understand` or `graphify` | standard | Build or query the graph | The answer |
| skill | `dm-pocockify` | deep | Purpose first, then the smallest instructions | Eval |
| eval | `dm-skill-eval` | standard | Static lint, then trigger evals | Pass rate |
| sweep | `dm-sweep` | cheap | Run the deterministic checks | Digest |
| retro-apply | `dm-retro-apply` | standard | Extract items, classify, apply | Closure table |

**Model tiers.** `deep` = strongest reasoning model, `xhigh` where offered. `standard` = the cheapest model that passes the checks. `cheap` = summarization, retrieval, formatting. Never run exploration on a deep tier; never run a review on a cheap one.

## Step 3 - Emit the route

Three lines, then act:

```text
Route: <verb> -> <skill or "direct"> (<model tier>)
Done when: <the command or observable result>
First: <the one action you are taking now>
```

If the route is `direct`, skip the ceremony and do the work. If the user disagrees with the route, take theirs.

## Rules

- **One primary skill.** A second skill is allowed only when the first explicitly hands off (for example `dm-loopify` → `dm-critic`).
- **No skill for a one-liner.** A typo fix, a single-file edit, or a factual answer is direct work.
- **Named skill wins.** If the user writes `/dm-write` or "use dm-critic", route there without re-litigating.
- **Escalate on ambiguity, not on size.** If the done-when cannot be stated in one line, the request is not ready — use `dm-grill` before `dm-agent-team`.
- **Do not load the library.** Read only the routed skill's `SKILL.md`. Sibling skills are read when that skill tells you to.
- **Cost check.** If the task will exceed roughly 10 tool calls, say the tier and the expected budget before starting.

## Canonical set (ignore duplicates)

These are the live skills. If another installed skill overlaps, prefer the canonical one and do not read the duplicate.

`dm-router` · `dm-agent-team` (absorbs `dm-spec-creation`, `dm-spec-execution`, `to-spec`, `implement`) · `dm-research` (absorbs `research`) · `dm-decide` · `dm-grill` (absorbs `grilling`, `grill-me`, `batch-grill-me`) · `dm-critic` (artifact critique; for a diff review use `gstack-review`) · `dm-debug` (absorbs `diagnosing-bugs`) · `dm-write` · `dm-loopify` · `dm-pocockify` · `dm-skill-eval` · `dm-learn` · `dm-retro-apply` · `dm-sweep` · `graphify` / `understand-*` · `gstack-cso` (security), `gstack-qa` (live QA), `gstack-ship` (land/deploy).

## Anti-patterns

- Routing to `dm-agent-team` for a two-line change.
- Running `dm-grill` when the user already gave a complete spec.
- Chaining three skills because each one was interesting.
- Reading five `SKILL.md` files before choosing.
- Emitting the route and then asking permission to proceed.

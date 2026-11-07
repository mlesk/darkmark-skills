# Model Routing

Only the Lead reads this file. Agents see only the `Effort:` line of their dispatch.

**Spend reasoning where a mistake is expensive and hard to see; save it where a check will catch the mistake anyway.** On the current models, lower effort still does routine work well, so start lower and re-run only failures higher.

| Tier | Use for | Typical model |
|---|---|---|
| `deep` | review verdicts, `PHASE-001`, `risk: high` phases | the strongest reasoning model |
| `standard` | other phases | a cheaper strong coding model |

| Work | Tier | Effort |
|---|---|---|
| The Lead (interview, specs, integration) | the session model: run interactive sessions on the deep tier, since the Lead now writes the specs; driver build sessions may use `--lead-model` standard | – |
| Spec review, milestone review, phase review | deep | medium |
| Acceptance | deep | high |
| Builder (a fresh context per phase, resumed only for that phase's revisions) | deep for `PHASE-001` and `risk: high` phases, else standard | medium |
| Any REVISE resume, and the `test-red` retry | same tier | high |
| Precheck, coverage | `scripts/precheck.sh` run by the builder, `scripts/coverage.sh` run by the Lead (fallback: reviewer at standard, low) | – |

Never de-escalate during a run; the retro proposes route changes from `state.md` §Log and `costs.tsv`.

## Builder continuity

A fresh builder per phase is the cost rule; a persistent builder per milestone is the convention rule. When a milestone's phases share conventions, assumptions, or a data model, keep one builder across the milestone and resume it for its fix phases — V001-workbench kept three builders across four milestones and reported fewer convention drifts. Dispatch fresh when the next phase is independent or when context is the larger cost. Record the choice in `models.md`.

## Applying a route

At the first boot, write `.agent-team/models.md` in the team root and say so in one line at the brief gate:

1. **`dispatch-param`:** the subagent tool takes a model per call (Claude Code: deep → `opus`, standard → `sonnet`). If it also takes an effort, pass it; otherwise the `Effort:` line in the dispatch carries it.
2. **`named-agents`:** agent types `dm-agent-team-deep` and `dm-agent-team-standard` exist (in `.claude/agents/`, `~/.claude/agents/`, or the `agent` block of `opencode.json`); dispatch to the matching one.
3. **`prompt-hint`:** otherwise every dispatch uses the session model; write `session`.

Only write a model ID you have seen in the tool's schema, the host config, or the human's words.

```markdown
# Model routing
host: <host> · apply-by: dispatch-param | named-agents | prompt-hint
| Tier | Model | Host agent |
|---|---|---|
| deep | <model> | <agent or –> |
| standard | <model> | <agent or –> |
## Route overrides (human-edited; win over the defaults)
| Work | Tier | Effort | Reason |
```

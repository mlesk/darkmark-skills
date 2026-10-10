# Model Routing

Only the Lead reads this file. Agents see only `tier:` and `effort:` in their handoff.

**Spend reasoning where a mistake is expensive and hard to see; save it where a check will catch the mistake anyway.**

| Tier | Use for | Typical model |
|---|---|---|
| `deep` | specs, plans, review verdicts, hard code | the strongest reasoning model |
| `standard` | routine code, orchestration | a cheaper strong coding model |
| `light` | mechanical checks; never verdicts | a fast, cheap model |

Effort: `low` act directly · `medium` think, then act (default) · `high` consider alternatives and check your reasoning first.

## Default routes

| Work | Tier | Effort |
|---|---|---|
| Lead (orchestration, gates, retro) | standard | low |
| Discovery (brownfield) | deep | high |
| Requirements, UX | deep | medium |
| Architecture and build plan | deep | high |
| Spec review, milestone review, phase review, acceptance | deep | medium (acceptance: high) |
| `PHASE-001` and phases marked `risk: high` | deep | medium |
| Other phases and fix phases | standard | medium |
| Consolidation | standard | medium |
| Precheck | `scripts/precheck.sh` (fallback: reviewer at standard, low) | – |

## Escalation

- A REVISE round 2 runs at `deep`, one effort level higher.
- A builder's `test-red` gets one retry at `deep`/`high` before it counts as an escalation.
- Never de-escalate during a run. The retro proposes route changes.

## Applying a route

At the first boot, write `.agent-team/models.md` in the team root and tell the human in one line at the brief gate. Detect the mechanism; don't guess:

1. **`dispatch-param`:** the subagent tool takes a model per call. In Claude Code: deep → `opus`, standard → `sonnet`, light → `haiku`. If it also takes an effort, set `effort-by: dispatch-param`.
2. **`named-agents`:** agent types named `dm-agent-team-deep`, `-standard`, and `-light` exist (in `.claude/agents/`, `~/.claude/agents/`, or the `agent` block of `opencode.json`). Dispatch to the one that matches; copy each one's model into the table.
3. **`prompt-hint`:** otherwise every dispatch uses the session model; write `session` in the table.

Only write a model ID you have seen in the tool's schema, the host config, or the human's words. When effort can't be set through the host, the dispatch prompt's `Effort:` line carries it. Start interactive sessions with a standard-tier model, and pass `--lead-model` to [scripts/run.sh](./scripts/run.sh).

```markdown
# Model routing
host: <host> · apply-by: dispatch-param | named-agents | prompt-hint · effort-by: dispatch-param | prompt-hint
| Tier | Model | Host agent |
|---|---|---|
| deep | <model> | <agent or –> |
| standard | <model> | <agent or –> |
| light | <model> | <agent or –> |
## Route overrides (human-edited; win over the defaults)
| Work | Tier | Effort | Reason |
```

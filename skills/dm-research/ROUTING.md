# Model Routing

Only the Lead reads this file. Agents see only the `Effort:` line of their dispatch.

**Spend reasoning where a mistake is expensive and hard to see; save it where a check will catch the mistake anyway.** Start lower and re-run only weak results higher.

| Work | Tier | Effort |
|---|---|---|
| The Lead (scan, interview, synthesis, options, report) | the session model; run it on the strongest model | – |
| Researcher, ordinary question | standard | medium |
| Researcher, `load-bearing` question | deep | medium |
| Researcher resumed to deepen a `partial` question | same tier | high |
| Reviewer | deep | high |
| Ledger and citation checks | `scripts/ledger.sh`, `scripts/cite-check.sh` | – |

Never de-escalate during a run; the retro proposes route changes.

## Applying a route

At the first boot write `.research/models.md`:

1. **`dispatch-param`:** the subagent tool takes a model per call (Claude Code: deep → `opus`, standard → `sonnet`); pass effort if it takes one, else the `Effort:` line carries it.
2. **`named-agents`:** agent types `dm-research-deep` and `dm-research-standard` exist in the host config; dispatch to the matching one.
3. **`prompt-hint`:** otherwise every dispatch uses the session model; write `session`.

Only write a model ID seen in the tool's schema, the host config, or the human's words.

```markdown
# Model routing
host: <host> · apply-by: dispatch-param | named-agents | prompt-hint
| Tier | Model |
|---|---|
| deep | <model> |
| standard | <model> |
## Route overrides (human-edited; win over the defaults)
| Work | Tier | Effort | Reason |
```

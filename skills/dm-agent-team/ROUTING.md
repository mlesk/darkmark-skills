# Model Routing

Only the Lead reads this file. Agents see only the `tier:` and `effort:` lines in their handoff.

The rule: **spend reasoning where a mistake is expensive and hard to see, and save it where a check will catch the mistake anyway.** Decisions that shape everything downstream (architecture, plan, review verdicts) get the strongest model and the most thinking. Work that verify or a reviewer will check (routine phases, mechanical checks, bookkeeping) gets a cheaper model and less thinking.

## Tiers and effort

| Tier       | Use for                                                 | Typical model                 |
| ---------- | ------------------------------------------------------- | ----------------------------- |
| `deep`     | judgment: decisions, specs, review verdicts, hard code  | the strongest reasoning model |
| `standard` | routine code, orchestration, simple question batches    | a cheaper strong coding model |
| `light`    | mechanical checks, lookups, log digests; never verdicts | a fast, cheap model           |

| Effort   | Meaning                                                                 |
| -------- | ----------------------------------------------------------------------- |
| `low`    | Act directly. No exploration of alternatives.                           |
| `medium` | The default. Think through the task, then act.                          |
| `high`   | Consider alternatives and check your reasoning before writing anything. |

## Default routes

| Work                                    | Agent · mode                                    | Tier     | Effort |
| --------------------------------------- | ----------------------------------------------- | -------- | ------ |
| Orchestration, state, gate presentation | Lead                                            | standard | low    |
| Requirements                            | dm-at-analyst · requirements                    | deep     | medium |
| Design-language questions               | dm-at-designer · ux-language                    | standard | low    |
| Approach evaluation and architecture    | dm-at-architect · design                        | deep     | high   |
| UX spec                                 | dm-at-designer · ux                             | deep     | medium |
| Build plan                              | dm-at-architect · plan                          | deep     | high   |
| Spec review                             | dm-at-reviewer · spec-review                    | deep     | high   |
| Foundation phase (`PHASE-001`)          | dm-at-builder · phase                           | deep     | medium |
| Routine phase, fix phase                | dm-at-builder · phase                           | standard | medium |
| Phase tagged `tier: deep`               | dm-at-builder · phase                           | deep     | medium |
| Mechanical pre-check                    | dm-at-reviewer · precheck                       | light    | low    |
| Phase review, milestone review          | dm-at-reviewer · phase-review, milestone-review | deep     | medium |
| Acceptance                              | dm-at-reviewer · acceptance                     | deep     | high   |
| Retro                                   | Lead                                            | standard | medium |

Why these defaults:

- **The architect and planner get the most thinking.** A wrong style, stack, or phase plan costs every later dispatch. The extra thinking is cheap by comparison.
- **The foundation phase is deep.** It fixes the structure, the hotspot files, and the shared plumbing that every later phase builds on.
- **Routine phases are standard.** Verify, the pre-check, and the deep review catch their mistakes.
- **The pre-check is light.** Running verify, diffing `touches:`, and grepping for skipped tests needs no judgment. Failing phases go back to the builder without spending a deep review.
- **Verdicts never go below deep.** A cheap judge that passes bad work costs more than it saves.

## Escalation ladder

Start at the route, and escalate only on evidence:

1. **REVISE round 2:** re-dispatch at `deep`, and raise effort by one level (to at most `high`).
2. **Builder `blocked` after 3 failed test attempts** (not a spec gap): retry once at `deep`/`high` before treating it as an escalation. The retry counts as a REVISE round.
3. **Repeated failure in a milestone:** if two standard-tier phases in the same milestone need round 2, route the milestone's remaining phases at `deep`. Return to the default at the next milestone.
4. **Question rounds:** a third question round for the same author runs at `high` effort.

Never de-escalate during a run. The retro proposes route changes from the metrics.

## Applying a route

At boot, write `.agent-team/models.md` from the skeleton below, choosing the first mechanism the host supports. Tell the human at G0 in one line, for example `Routing: named agents (deep → opus, standard → sonnet, light → haiku)`.

**Detect the mechanism; don't guess.** Check in this order:

1. **Your subagent tool's parameters.** If it accepts a model per call, use `dispatch-param`. In Claude Code the subagent (Agent/Task) tool takes `model` with the aliases `opus`, `sonnet`, and `haiku`: map deep → `opus`, standard → `sonnet`, light → `haiku`. If it also takes an effort or reasoning parameter, set `effort-by: dispatch-param`.
2. **Named tier agents.** If the subagent tool lists agent types named `dm-agent-team-deep`, `dm-agent-team-standard`, and `dm-agent-team-light`, or they are defined in `.claude/agents/`, `~/.claude/agents/`, or the `agent` block of the project's `opencode.json` / `opencode.jsonc`, use `named-agents` and copy each one's model into the table.
3. **Otherwise** use `prompt-hint` and write `session` in every Model cell.

Only write a model ID you have seen in the tool's schema, the host's config, or the human's own words. If a tier has none, write `session` and say so at G0. The human can correct `models.md` at any stop.

1. **`dispatch-param`:** the subagent tool takes a model, and possibly an effort, per call. Pass the mapped model and effort on each dispatch.
2. **`named-agents`:** the host has agents preconfigured with a model each (for example `dm-agent-team-deep`, `dm-agent-team-standard`, `dm-agent-team-light`, plus optional effort variants such as `dm-agent-team-deep-high`). Dispatch to the agent that matches the route. See [GUIDE.md §6](./GUIDE.md#6-tools-and-stack) for host examples.
3. **`prompt-hint`:** the host cannot choose models. Every dispatch uses the session model; tiers are recorded but have no effect. Effort still applies as a prompt line.

When the effort cannot be set through the host, add this line to the top of the dispatch prompt: `Effort: <level> — <meaning from the table above>`.

The **Lead's own model** is the session model. The Lead is mostly bookkeeping, so start interactive sessions with a standard-tier model, and pass `--lead-model` to [scripts/run.sh](./scripts/run.sh) for driver sessions. Gate presentations are built from summaries, so they need no deep model.

### `.agent-team/models.md` skeleton

```markdown
# Model routing
host: opencode | copilot | claude-code | codex | other
apply-by: dispatch-param | named-agents | prompt-hint
effort-by: dispatch-param | variant-agents | prompt-hint
| Tier     | Model      | Host agent        |
| -------- | ---------- | ----------------- |
| deep     | <model id> | <agent name or –> |
| standard | <model id> | <agent name or –> |
| light    | <model id> | <agent name or –> |

## Route overrides (human-edited; take precedence over ROUTING.md defaults)
| Work | Tier | Effort | Reason |
| ---- | ---- | ------ | ------ |
```

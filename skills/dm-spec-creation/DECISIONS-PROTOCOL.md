# Decisions Protocol

Two living logs are maintained continuously throughout the workflow.

## decisions.md — strategic / architectural

Log here when a choice:

- shapes domain meaning, module boundaries, or dependency direction
- selects a stack, framework, or architectural pattern
- accepts or deviates from a `[MUST]` rule in the standards
- defines a non-functional posture (security, performance, multi-user, etc.)
- closes a debate between genuine alternatives

## implementation-decisions.md — tactical

Log here when a choice:

- picks a library, package, or specific API
- defines a coding convention narrower than the standards
- resolves an implementation ambiguity (naming, file layout, test strategy)
- selects a UI component library, validation library, ORM mapping approach, etc.

## Entry format

Both logs use the same entry shape:

```markdown
## D-NNN — <short title>

- **Date:** YYYY-MM-DD
- **Phase:** spec-NN (or `cross-spec`, `override`)
- **Status:** accepted | superseded-by-D-MMM | deferred | out-of-scope | gate-override | standards-deviation
- **Context:** one paragraph on why the decision was on the table
- **Decision:** one paragraph on what was chosen
- **Alternatives considered:** bullet list, each with a one-line rejection rationale
- **Consequences:** what this constrains downstream
- **Standards refs:** file:section + rule severity (e.g. `design-standards-domain-model.md §4 [MUST]`)
```

`D-NNN` is monotonically increasing across both logs combined.

## When to write

Write **the moment** the decision is taken in the grilling session. Do not batch. Every spec-level claim that resolves a real trade-off must have a backing decision entry. Gates verify this.

## Deferred decisions

A deferred decision still gets an entry. Status `deferred`. Include:

- **Trigger:** the event that forces the decision (e.g. "first user requests multi-portfolio support")
- **Default behavior until then:** what the system does in the interim

A spec MAY reference a deferred decision but MUST NOT depend on its eventual resolution for correctness.

## Out-of-scope items

When the user proposes scope that the current spec set rejects, log it with status `out-of-scope` and a one-line rationale. This prevents the same idea coming back as informal scope creep.

## Overrides

If the user forces a gate to pass against the gate's verdict ("override gate: <reason>"), log an entry with status `gate-override` and tag the spec number. The cross-spec gate will still inspect overridden specs and may itself fail.

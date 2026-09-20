---
name: general-standards
description: Cross-cutting standards that apply regardless of language or technology. These rules address failure modes that recur across stacks.
scope: All
---

# General Standards

These rules apply across all languages and technologies. They are the root rule set — more specific standards files may override individual rules.

---

## Configuration & Secrets

- `[MUST]` Never hardcode secrets (API keys, connection strings, passwords) in source code — use environment variables, secret managers, or parameter stores.
- `[MUST]` All environment-specific configuration must come from environment variables or configuration files, never from compiled constants.
- `[MUST-NOT]` Commit `.env` files, secrets, or credentials to version control.

## Logging & Observability

- `[MUST]` All service entry points (API endpoints, CLI commands, background job handlers, message consumers) must log entry, exit, and errors with structured logging.
- `[MUST]` Use structured logging with correlation IDs — every request must carry a trace/correlation ID that propagates across service boundaries.
- `[MUST]` Log at appropriate levels: `Error` for failures requiring attention, `Warning` for degraded but functional states, `Information` for significant business events, `Debug` for development-time detail.
- `[MUST-NOT]` Log secrets, tokens, passwords, or PII at any log level.

## Health Checks

- `[MUST]` All deployable services (APIs, workers, timers) must expose health check endpoints (`/health`, `/alive`).
- `[MUST]` Health checks must verify connectivity to critical dependencies (databases, caches, external APIs).

## Error Handling

- `[MUST]` All public API endpoints must return structured error responses — never raw exception messages or stack traces.
- `[MUST]` Unhandled exceptions must be caught at the application boundary, logged, and translated to a safe response.
- `[MUST-NOT]` Swallow exceptions silently — always log or rethrow.

## Security Defaults

- `[MUST]` Use HTTPS for all network communication.
- `[MUST]` Validate all external input at system boundaries — never trust data from clients, message queues, or external APIs.
- `[MUST]` Use parameterized queries for all database access — never concatenate user input into SQL strings.

## README & Developer Experience

- `[MUST]` The README must include instructions to build, run, and test the project from a clean checkout.
- `[SHOULD]` Include a single command that starts the full application stack for local development.

---
name: sql-standards
description: Standards for SQL query design, naming conventions, indexing strategy, transaction management, and schema design with PostgreSQL-specific best practices. Formatting and alignment rules are omitted — enforce those via SQL linters.
scope: All SQL code and database schema definitions, with additional rules specific to PostgreSQL.
---

# SQL & PostgreSQL Standards

> **Sources:**
> - [SQL Style Guide — Simon Holywell](https://www.sqlstyle.guide/)
> - PostgreSQL official documentation and community best practices

---

## 1. General Principles

- `[MUST]` Use consistent and descriptive identifiers and names throughout the codebase.
- `[MUST]` Store dates and times in ISO 8601 format (`YYYY-MM-DDTHH:MM:SS.SSSSS`) or use PostgreSQL `TIMESTAMPTZ` for timezone-aware storage.
- `[SHOULD]` Prefer standard ANSI SQL functions over vendor-specific functions for portability, except where PostgreSQL-specific features provide significant advantages (e.g., `JSONB` operators, array functions, `RETURNING`).

## 2. Naming Conventions

- `[MUST]` Use `snake_case` for all identifiers — tables, columns, functions, indexes, constraints. Never use `camelCase`.
- `[MUST]` Ensure names do not collide with reserved keywords. If unavoidable, choose a synonym rather than quoting.
- `[MUST]` Keep names to a maximum of 63 bytes (PostgreSQL identifier limit).
- `[MUST-NOT]` Use descriptive prefixes or Hungarian notation such as `tbl_`, `sp_`, `fn_`, or `vw_`.
- `[SHOULD]` Use collective or singular nouns for table names (e.g., `staff` not `staffs`, `order` not `orders`).
- `[SHOULD]` Avoid `id` as the sole primary key column name — prefer `{table}_id` (e.g., `user_id`, `order_id`) for unambiguous joins.
- `[SHOULD]` Use standard suffixes: `_id` (identifier), `_status` (flag/state), `_total` (sum), `_num` (number), `_name` (name), `_date` (date), `_at` (timestamp), `_count` (tally).

## 3. SELECT Statements

- `[MUST]` Never use `SELECT *` in production queries, views, or stored procedures. Always explicitly list the columns needed.
- `[MUST]` Qualify every column reference with its table alias, even in single-table queries — prevents ambiguity as queries evolve.
- `[MUST]` Give CTEs meaningful names that describe their data — never use generic names like `cte`, `tmp`, or `t1`.
- `[SHOULD]` Use CTEs to break complex queries into named, readable steps.
- `[SHOULD]` Prefer CTEs over deeply nested subqueries for readability.

## 4. JOINs

- `[MUST]` Use explicit `JOIN` syntax (`INNER JOIN`, `LEFT JOIN`) — never use implicit comma-separated joins in the `FROM` clause with join conditions in `WHERE`.
- `[SHOULD]` Prefer `JOIN` (inner) over `LEFT JOIN` when all matching rows are expected.
- `[SHOULD-NOT]` Use `RIGHT JOIN` — reorder tables and use `LEFT JOIN` instead for consistency.

## 5. Schema Design & Data Types

- `[MUST]` Every table must have a primary key.
- `[MUST]` Use the most appropriate and constrained data type — do not use `TEXT` where `VARCHAR(255)` suffices.
- `[MUST]` Use `NUMERIC` or `DECIMAL` for monetary/financial values — never `REAL` or `FLOAT` (floating-point rounding errors).
- `[MUST]` Specify `NOT NULL` on columns that should never be null — don't rely on application-level enforcement alone.
- `[SHOULD]` Define constraints with explicit names (`CONSTRAINT order_amount_positive CHECK (amount > 0)`).
- `[SHOULD-NOT]` Use Entity-Attribute-Value (EAV) table patterns — use PostgreSQL `JSONB` for truly dynamic attributes.

## 6. PostgreSQL-Specific: Data Types

- `[MUST]` Use `TIMESTAMPTZ` (not `TIMESTAMP`) for any time data that could span time zones.
- `[MUST]` Use `UUID` type (not `VARCHAR(36)`) for UUID columns — smaller storage, native indexing, and `gen_random_uuid()` for generation.
- `[SHOULD]` Use `JSONB` (not `JSON`) for JSON data — supports indexing, containment operators (`@>`, `<@`), and efficient querying.
- `[SHOULD]` Use `TEXT` instead of `VARCHAR` when no maximum length constraint is needed — in PostgreSQL there is no performance difference.
- `[SHOULD]` Use `BOOLEAN` type (not `INTEGER` 0/1) for boolean values.
- `[SHOULD]` Use `GENERATED ALWAYS AS IDENTITY` for auto-incrementing keys (modern PostgreSQL 10+).
- `[SHOULD]` Use `INET` / `CIDR` types for IP addresses — not `VARCHAR`.

## 7. PostgreSQL-Specific: Indexing

- `[MUST]` Create indexes on foreign key columns — PostgreSQL does not auto-create indexes on foreign keys (unlike some other databases).
- `[MUST]` Use `CONCURRENTLY` when creating indexes on production tables to avoid locking (`CREATE INDEX CONCURRENTLY`).
- `[SHOULD]` Use partial indexes (`WHERE` clause on index) for queries that filter on a common condition.
- `[SHOULD]` Use `GIN` indexes for `JSONB` containment queries and full-text search (`tsvector`).
- `[SHOULD]` Use expression indexes for queries on computed values (e.g., `CREATE INDEX idx_lower_email ON users (LOWER(email))`).
- `[SHOULD]` Use covering indexes (`INCLUDE` clause) to support index-only scans.
- `[SHOULD]` Periodically review and drop unused indexes — use `pg_stat_user_indexes` to identify them.
- `[SHOULD-NOT]` Over-index tables — each index adds write overhead. Profile with `EXPLAIN ANALYZE` before adding indexes.

## 8. PostgreSQL-Specific: Query Performance

- `[MUST]` Use parameterized queries (`$1`, `$2` or prepared statements) — never concatenate user input into SQL strings (SQL injection prevention).
- `[MUST]` Use `EXPLAIN ANALYZE` to validate query plans before deploying queries that touch large tables.
- `[SHOULD]` Use `EXISTS` instead of `IN` for subquery existence checks on large datasets — `EXISTS` short-circuits on first match.
- `[SHOULD]` Prefer keyset (cursor-based) pagination (`WHERE id > last_seen_id ORDER BY id LIMIT n`) over `LIMIT`/`OFFSET` for large datasets.
- `[SHOULD]` Use `RETURNING` clause on `INSERT`, `UPDATE`, `DELETE` to retrieve affected rows without a separate `SELECT`.
- `[SHOULD]` Use `COPY` (not row-by-row `INSERT`) for bulk data loading.
- `[SHOULD]` Use connection pooling (PgBouncer, pgpool-II) — PostgreSQL's process-per-connection model is expensive.
- `[SHOULD-NOT]` Wrap columns in functions in `WHERE` clauses without a matching expression index — this prevents index usage.

## 9. PostgreSQL-Specific: Transactions & Concurrency

- `[MUST]` Wrap related multi-statement operations in explicit transactions (`BEGIN` / `COMMIT`).
- `[MUST]` Keep transactions as short as possible — long-running transactions block `VACUUM` and cause table bloat.
- `[SHOULD]` Use `SAVEPOINT` within complex transactions to enable partial rollback.
- `[SHOULD]` Use advisory locks (`pg_advisory_lock`) for application-level coordination instead of `SELECT ... FOR UPDATE` on sentinel rows.
- `[SHOULD]` Handle `deadlock_detected` and `serialization_failure` errors with application-level retry logic.

## 10. PostgreSQL-Specific: Functions & Procedures

- `[MUST]` Use `SECURITY DEFINER` sparingly and always pair with `SET search_path = pg_catalog, public` to prevent search-path injection attacks.
- `[SHOULD]` Use `LANGUAGE sql` for simple functions (better inlining by the planner) and `LANGUAGE plpgsql` for procedural logic.
- `[SHOULD]` Mark functions as `IMMUTABLE`, `STABLE`, or `VOLATILE` correctly — incorrect volatility classification can produce wrong results from cached plans.
- `[SHOULD]` Use `RETURNS TABLE(...)` for set-returning functions instead of `SETOF RECORD` for type safety.

## 11. Migrations & Schema Evolution

- `[MUST]` Use versioned, sequential migration files — never modify a migration that has been applied to any environment.
- `[MUST]` Make migrations backward-compatible when possible — add columns as nullable with defaults, then backfill and add constraints in a separate migration.
- `[SHOULD]` Use `IF NOT EXISTS` / `IF EXISTS` guards on `CREATE` and `DROP` statements for idempotency.
- `[SHOULD]` Test migrations on a copy of production data before deploying.
- `[SHOULD-NOT]` Drop columns in the same migration that removes application code references — deploy the code change first, then remove the column.

## 12. Security

- `[MUST]` Never store plaintext passwords — use `pgcrypto`'s `crypt()` / `gen_salt()` or handle hashing at the application layer.
- `[MUST]` Use role-based access control — grant minimum necessary privileges. Never use the `postgres` superuser for application connections.
- `[MUST]` Enable SSL for all database connections in production (`sslmode=require` or `sslmode=verify-full`).
- `[SHOULD]` Use Row-Level Security (RLS) policies for multi-tenant data isolation.
- `[SHOULD]` Rotate credentials regularly and use secrets management rather than hardcoded connection strings.

---

## Completion Checklist — Naming & Schema

- [ ] All identifiers use `snake_case` (no `camelCase`, no Hungarian notation) ← COMMONLY MISSED
- [ ] Primary key columns named `{table}_id` (not bare `id`) ← COMMONLY MISSED
- [ ] `TIMESTAMPTZ` used instead of `TIMESTAMP` for timezone-aware data
- [ ] `NUMERIC` / `DECIMAL` used for monetary values (not `FLOAT`)
- [ ] Every table has a primary key and appropriate constraints

## Completion Checklist — PostgreSQL Performance

- [ ] Foreign key columns have indexes ← COMMONLY MISSED
- [ ] Production index creation uses `CONCURRENTLY`
- [ ] `EXPLAIN ANALYZE` run on queries touching large tables ← COMMONLY MISSED
- [ ] Keyset pagination used instead of `LIMIT` / `OFFSET` for large datasets
- [ ] `EXISTS` used instead of `IN` for subquery existence checks
- [ ] `RETURNING` used instead of separate `SELECT` after mutations

## Completion Checklist — Security & Transactions

- [ ] All queries use parameterized statements (no string concatenation) ← COMMONLY MISSED
- [ ] Application connects with minimum-privilege role (not superuser)
- [ ] SSL enabled for all database connections
- [ ] Transactions are short — no user-facing waits inside a transaction
- [ ] `SECURITY DEFINER` functions set `search_path` explicitly

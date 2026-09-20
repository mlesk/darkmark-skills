---
name: efcore-standards
description: Standards for Entity Framework Core data access, emphasizing explicit Fluent API configuration, proper DbContext lifecycle, efficient querying, migration management, and relationship modeling.
scope: Projects using Entity Framework Core for data access against relational databases.
---

# Entity Framework Core Standards

> **Sources:**
> - [Entity Framework Core Documentation](https://learn.microsoft.com/en-us/ef/core/)
> - [Microsoft EF Core Modeling](https://learn.microsoft.com/en-us/ef/core/modeling/)
> - [EF Core Best Practices — Code Maze](https://code-maze.com/entity-framework-core-best-practices/)
> - [Top 10 Mistakes Developers Make in EF Core — Anton Dev Tips](https://antondevtips.com/blog/top-10-mistakes-developers-make-in-ef-core)
> - [EF Core Relationship Conventions](https://learn.microsoft.com/en-us/ef/core/modeling/relationships/conventions)
> - [EF Core Performance Docs](https://learn.microsoft.com/en-us/ef/core/performance/)

---

## 1. Configuration Approach

EF Core supports three configuration mechanisms with the following **strict precedence** (highest to lowest):

1. **Fluent API** (`OnModelCreating` / `IEntityTypeConfiguration<T>`) — always wins
2. **Data Annotations** (attributes on entity classes) — overrides conventions
3. **Conventions** (EF defaults) — applied last

### Rules

- `[MUST]` Use **Fluent API** as the primary and only configuration mechanism. It is the only mechanism with full fidelity over the EF model.
- `[MUST-NOT]` Use Data Annotations for model configuration — all configuration must be expressed via Fluent API for consistency and full capability.
- `[MUST]` Use `IEntityTypeConfiguration<TEntity>` to group per-entity configuration into a dedicated class — do NOT put all configuration in `OnModelCreating`:
  ```csharp
  public class PortfolioConfiguration : IEntityTypeConfiguration<Portfolio>
  {
      public void Configure(EntityTypeBuilder<Portfolio> builder)
      {
          builder.ToTable("Portfolios");
          builder.HasKey(p => p.Id);
          builder.Property(p => p.Name).IsRequired().HasMaxLength(200);
      }
  }
  ```
- `[MUST]` Register all configurations in `OnModelCreating` using assembly scanning:
  ```csharp
  protected override void OnModelCreating(ModelBuilder modelBuilder)
  {
      modelBuilder.ApplyConfigurationsFromAssembly(typeof(PortfolioConfiguration).Assembly);
  }
  ```
- `[MUST]` Use Fluent API for all configurations including those commonly expressed as annotations — e.g., required fields (`.IsRequired()`), max length (`.HasMaxLength()`), column types (`.HasColumnType()`), composite keys, alternate keys, table splitting, owned types, query filters.

## 2. Entity Class Design

- `[MUST]` Entity classes must be POCOs — no EF-specific base class required.
- `[MUST]` Use clear, descriptive class names that represent the domain entity (e.g., `Product`, `Order`, `Customer` — never `Tbl` or `Entity1`).
- `[MUST]` Primary key property must be named `Id` or `<TypeName>Id` to satisfy convention:
  ```csharp
  public class Portfolio
  {
      public int Id { get; set; }        // or: public int PortfolioId { get; set; }
  }
  ```
- `[MUST]` Define navigation properties as `virtual` only if lazy loading proxies are enabled. Otherwise, non-virtual is preferred to avoid confusion about loading behavior.
- `[MUST]` Initialize collection navigation properties to prevent null reference exceptions:
  ```csharp
  public ICollection<Holding> Holdings { get; set; } = [];
  ```
- `[MUST]` Use `.Ignore()` in Fluent API to exclude computed or transient properties from the model:
  ```csharp
  builder.Ignore(p => p.DisplayLabel);
  ```
- `[MUST]` Exclude entities from migrations (but keep in model) when sharing types across bounded contexts:
  ```csharp
  builder.Entity<IdentityUser>().ToTable("AspNetUsers", t => t.ExcludeFromMigrations());
  ```
- `[SHOULD]` Keep entity classes focused on data shape — avoid embedding business logic, HTTP concerns, or validation.
- `[SHOULD]` Use the correct C# types that map to optimal database types — avoid relying on EF Core defaults like `nvarchar(max)` for all strings or `decimal(18,2)` for all decimals. Configure via Fluent API (`HasMaxLength()`, `HasColumnType()`).
- `[SHOULD]` Configure non-nullable fields via Fluent API (`.IsRequired()`) — do not rely solely on application-layer enforcement.
- `[SHOULD]` Use records for read-model / projection types.
- `[SHOULD-NOT]` Use nullable types for fields that should always have a value — unnecessary nullability complicates queries and degrades storage.

## 3. DbContext Configuration

- `[MUST]` Register `DbContext` using dependency injection (`AddDbContext<T>` or `AddDbContextFactory<T>`) — never manually instantiate `DbContext` without managing its lifetime.
- `[MUST]` Dispose `DbContext` instances properly — use `using` statements when creating via `IDbContextFactory`. DI-managed contexts are disposed automatically at scope end.
- `[MUST]` Expose each root aggregate as a `DbSet<T>` property on the context:
  ```csharp
  public class InvestmentDbContext : DbContext
  {
      public DbSet<Portfolio> Portfolios { get; set; }
      public DbSet<Holding> Holdings { get; set; }
      public DbSet<Transaction> Transactions { get; set; }
  }
  ```
- `[MUST]` Call `modelBuilder.ApplyConfigurationsFromAssembly(...)` instead of configuring entities inline in `OnModelCreating`.
- `[MUST]` Do not expose `DbSet<T>` for owned types — they cannot have `DbSet`s and must be accessed through their owner.
- `[MUST]` Set a default schema at the model level when using multiple schemas:
  ```csharp
  modelBuilder.HasDefaultSchema("investment");
  ```
- `[SHOULD]` Use `DbContextFactory` for long-lived services (background workers, Blazor Server) where a scoped `DbContext` is inappropriate.
- `[SHOULD]` Keep `DbContext` classes focused on a single bounded context.
- `[SHOULD]` Configure connection strings per environment using `appsettings.{Environment}.json` — never hardcode connection strings.
- `[SHOULD]` Enable sensitive data logging only in development (`EnableSensitiveDataLogging()`) — never in production.
- `[SHOULD-NOT]` Use a single `DbContext` instance across multiple threads — `DbContext` is not thread-safe.

## 4. Keys

- `[MUST]` Define primary keys explicitly via Fluent API unless the `Id` / `<TypeName>Id` convention is followed:
  ```csharp
  builder.HasKey(p => p.Id);
  ```
- `[MUST]` Use composite keys via Fluent API:
  ```csharp
  builder.HasKey(r => new { r.State, r.LicensePlate });
  ```
- `[MUST]` Do NOT manually assign a PK value if the database generates it — EF will interpret the entity as existing and attempt an UPDATE instead of INSERT.
- `[SHOULD]` Use `int` or `Guid` for primary keys. Use `Guid` when entities are created client-side or across distributed systems.
- `[SHOULD]` Use alternate keys (`.HasAlternateKey()`) only when a property must serve as the target of a foreign key. For uniqueness-only constraints, use a unique index instead.

## 5. Properties & Columns

- `[MUST]` Configure required properties explicitly via Fluent API — do not rely on nullability inference alone:
  ```csharp
  builder.Property(p => p.Name).IsRequired();
  ```
- `[MUST]` Set `HasMaxLength` on all `string` properties mapped to `nvarchar`/`varchar` columns:
  ```csharp
  builder.Property(p => p.Name).IsRequired().HasMaxLength(200);
  ```
- `[MUST]` Use `HasColumnName` to control the database column name when it must differ from the property name:
  ```csharp
  builder.Property(p => p.CreatedAt).HasColumnName("created_utc");
  ```
- `[MUST]` Use `HasColumnType` for `decimal` properties to avoid precision warnings:
  ```csharp
  builder.Property(p => p.MarketValue).HasColumnType("decimal(18,4)");
  ```
- `[SHOULD]` Use `HasComment` to document columns with non-obvious domain meaning:
  ```csharp
  builder.Property(p => p.IrpCostBasis).HasComment("Inflation-adjusted cost basis in base currency.");
  ```

## 6. Relationships & Navigation Properties

### General Rules

- `[MUST]` Always configure relationships explicitly via Fluent API — do not rely solely on navigation property conventions.
- `[MUST]` Always specify both sides of a relationship:
  ```csharp
  builder.HasMany(p => p.Holdings)
         .WithOne(h => h.Portfolio)
         .HasForeignKey(h => h.PortfolioId)
         .OnDelete(DeleteBehavior.Cascade);
  ```
- `[MUST]` Always include the explicit FK property in the entity class:
  ```csharp
  public class Holding
  {
      public int Id { get; set; }
      public int PortfolioId { get; set; }        // explicit FK
      public Portfolio Portfolio { get; set; }    // navigation
  }
  ```
- `[MUST]` Specify `OnDelete` behavior explicitly — never rely on defaults:
  - Use `DeleteBehavior.Cascade` for owned/dependent entities.
  - Use `DeleteBehavior.Restrict` or `DeleteBehavior.ClientSetNull` for optional relationships.
- `[MUST]` Configure relationships explicitly when EF Core conventions cannot determine the correct mapping — e.g., multiple relationships between the same two types, or when the dependent end of a one-to-one is ambiguous.
- `[SHOULD]` Use `DeleteBehavior.Restrict` or `DeleteBehavior.NoAction` when cascading deletes could cause unintended data loss.
- `[SHOULD]` Prefer navigation properties over manual FK joins in LINQ queries — EF Core generates correct joins from navigations.
- `[SHOULD]` Use `OnDelete(DeleteBehavior.ClientCascade)` when you need cascade behavior but the database doesn't support it (e.g., cycles in SQL Server).

### Navigation Properties

- `[MUST]` Use `ICollection<T>` (not `List<T>` or `IEnumerable<T>`) for collection navigations:
  ```csharp
  public ICollection<Holding> Holdings { get; set; } = [];
  ```
- `[MUST]` Initialize collection navigations to an empty collection to prevent null reference exceptions.
- `[MUST]` Do NOT use `virtual` navigation properties unless lazy loading is intentionally enabled.
- `[SHOULD]` Use `IReadOnlyCollection<T>` with a private setter for DDD aggregate roots to enforce encapsulation.

### Many-to-Many

- `[SHOULD]` Use EF Core's implicit join table for simple many-to-many relationships (no payload on join):
  ```csharp
  builder.HasMany(p => p.Tags).WithMany(t => t.Portfolios);
  ```
- `[MUST]` Create an explicit join entity when the join table has payload columns (e.g., timestamps, attributes):
  ```csharp
  builder.HasMany(p => p.Tags)
         .WithMany(t => t.Portfolios)
         .UsingEntity<PortfolioTag>(
             j => j.HasOne(pt => pt.Tag).WithMany().HasForeignKey(pt => pt.TagId),
             j => j.HasOne(pt => pt.Portfolio).WithMany().HasForeignKey(pt => pt.PortfolioId));
  ```

## 7. Owned Entities

Use owned entities for value objects that have no identity of their own (DDD value objects).

- `[MUST]` Configure value-object types via `.OwnsOne()`/`.OwnsMany()` in Fluent API:
  ```csharp
  builder.OwnsOne(p => p.CostBasis, m =>
  {
      m.Property(x => x.Amount).HasColumnName("CostBasis_Amount").HasColumnType("decimal(18,4)");
      m.Property(x => x.Currency).HasColumnName("CostBasis_Currency").HasMaxLength(3);
  });
  ```
- `[MUST]` Do NOT create `DbSet<T>` for owned types.
- `[MUST]` Rename owned type columns via `HasColumnName` — the default `Navigation_Property` naming is not human-readable.
- `[MUST]` Use `.OwnsMany()` for collections of value objects:
  ```csharp
  builder.OwnsMany(p => p.PriceHistory, ph =>
  {
      ph.WithOwner().HasForeignKey("PortfolioId");
      ph.Property<int>("Id");
      ph.HasKey("Id");
  });
  ```
- `[SHOULD]` Store owned types in the owner's table (default) unless the owned type is large or sparse.

## 8. Querying — Projections & Filtering

- `[MUST]` Use projections (`.Select()`) to retrieve only the columns needed — never load entire entities when only a subset of fields is required:
  ```csharp
  // CORRECT — projects only what is needed
  var summaries = await context.Holdings
      .Where(h => h.PortfolioId == portfolioId)
      .Select(h => new HoldingSummaryDto { Symbol = h.Symbol, MarketValue = h.MarketValue })
      .ToListAsync();

  // WRONG — loads full entity with all columns
  var holdings = await context.Holdings.Where(h => h.PortfolioId == portfolioId).ToListAsync();
  ```
- `[MUST]` Apply filtering (`.Where()`) as early as possible in the query chain — filter before projecting, joining, or ordering to minimize the data processed by the database.
- `[MUST]` Use `AsNoTracking()` for read-only queries — disables change tracking, reducing memory overhead and improving performance. Use `AsNoTrackingWithIdentityResolution()` when identity resolution is still needed.
- `[MUST]` Always use async query methods (`ToListAsync()`, `FirstOrDefaultAsync()`, `SingleOrDefaultAsync()`, `CountAsync()`) — never block with synchronous counterparts in ASP.NET Core applications.
- `[MUST]` Never call `.Result` or `.Wait()` on EF async operations.
- `[MUST]` Always add `.Take(n)` or pagination to queries that can return unbounded result sets.
- `[SHOULD]` Use `AsSplitQuery()` when eager loading multiple collections to avoid Cartesian explosion — but profile first, as split queries add round trips.
- `[SHOULD]` Use compiled queries (`EF.CompileQuery` / `EF.CompileAsyncQuery`) for hot-path queries executed frequently with different parameters — eliminates LINQ expression tree compilation overhead.
- `[SHOULD]` Prefer `Any()` / `Exists` over `Count() > 0` for existence checks — the database can short-circuit on first match.
- `[SHOULD]` Set `UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking)` at the context level for read-only contexts (e.g., reporting).
- `[SHOULD-NOT]` Call `.ToList()` or `.ToListAsync()` before applying filters — this materializes the entire table into memory and filters client-side.
- `[MUST-NOT]` Use `Select *` patterns (loading full entities) for display/reporting scenarios — always project to DTOs or anonymous types.

## 9. Querying — Loading Related Data

- `[MUST]` Use **eager loading** (`.Include()`) as the default strategy for related data:
  ```csharp
  var portfolios = await context.Portfolios
      .Include(p => p.Holdings)
          .ThenInclude(h => h.Security)
      .ToListAsync();
  ```
- `[MUST]` Use filtered includes (`.Include(e => e.Collection.Where(...))`) when only a subset of related data is needed — avoids loading entire collections:
  ```csharp
  .Include(p => p.Transactions.Where(t => t.TradeDate >= cutoff).OrderByDescending(t => t.TradeDate).Take(10))
  ```
- `[SHOULD]` Use explicit loading (`.Entry().Collection().Load()` / `.LoadAsync()`) when related entities are needed conditionally after the principal is loaded.
- `[SHOULD]` Prefer projections over `.Include()` when you need specific fields from related entities — projections generate more efficient SQL.
- `[SHOULD]` Use `AsSplitQuery()` when including multiple collection navigations to prevent Cartesian products:
  ```csharp
  var portfolios = await context.Portfolios
      .Include(p => p.Holdings)
      .Include(p => p.Transactions)
      .AsSplitQuery()
      .ToListAsync();
  ```
- `[SHOULD-NOT]` Enable lazy loading globally in web applications — it causes N+1 query problems and unpredictable database access patterns. If used, restrict to specific scenarios with explicit opt-in.
- `[SHOULD-NOT]` Chain deep `.ThenInclude()` hierarchies without profiling — each level adds joins and result set size.

## 10. Pagination

- `[MUST]` Implement pagination for any query that could return unbounded result sets — use `Skip()` and `Take()` at minimum.
- `[MUST]` Always include an `OrderBy()` before `Skip()` / `Take()` — without deterministic ordering, pagination results are undefined.
- `[SHOULD]` Prefer keyset (cursor-based) pagination over offset-based for large datasets:
  ```csharp
  // Keyset — efficient for large data
  .Where(t => t.Id > lastSeenId).Take(pageSize)
  ```
- `[SHOULD-NOT]` Load entire tables into memory and paginate client-side — always push pagination to the database.

## 11. Saving Data & Change Tracking

- `[MUST]` Use `SaveChangesAsync()` — never `SaveChanges()` — in ASP.NET Core applications.
- `[MUST]` Use `AddRange()` / `UpdateRange()` / `RemoveRange()` for batch operations — not individual `Add()` calls in a loop.
- `[MUST]` Never call `SaveChanges()` / `SaveChangesAsync()` inside a loop — accumulate changes and save once after the loop.
- `[MUST]` Wrap `ExecuteUpdateAsync()` / `ExecuteDeleteAsync()` batch operations in an explicit transaction when combined with tracked entity changes — batch operations bypass the change tracker and are not automatically rolled back if `SaveChangesAsync()` fails.
- `[MUST]` Keep `DbContext` instances short-lived (scoped per HTTP request or unit-of-work).
- `[MUST]` Do NOT reuse a `DbContext` across parallel async operations — it is not thread-safe.
- `[SHOULD]` Wrap `SaveChangesAsync` calls in an explicit transaction:
  ```csharp
  await using var transaction = await context.Database.BeginTransactionAsync();
  // ... operations ...
  await context.SaveChangesAsync();
  await transaction.CommitAsync();
  ```
- `[SHOULD]` Use `ExecuteUpdateAsync()` / `ExecuteDeleteAsync()` (EF Core 7+) for bulk updates/deletes that don't need entity-level change tracking:
  ```csharp
  await context.Holdings
      .Where(h => h.PortfolioId == portfolioId)
      .ExecuteDeleteAsync();
  ```
- `[SHOULD]` Return affected data using `.Returning()` or query after save only when needed — avoid unnecessary round trips.

## 12. Concurrency Control

- `[MUST]` Implement optimistic concurrency control for entities subject to concurrent updates — configure a row version property via Fluent API (`.IsRowVersion()`) and handle `DbUpdateConcurrencyException`.
- `[SHOULD]` Design a clear conflict resolution strategy — show error to user, last-writer-wins, or merge. Do not silently swallow `DbUpdateConcurrencyException`.
- `[SHOULD]` Use `.IsConcurrencyToken()` on specific columns via Fluent API when row versioning is not available or when only certain fields need protection.

## 13. Indexing

- `[MUST]` Create indexes on columns frequently used in `WHERE`, `ORDER BY`, and `JOIN` conditions — use `HasIndex()` in Fluent API.
- `[MUST]` Verify that EF Core's convention-created FK indexes are appropriate — review migrations before applying.
- `[MUST]` Define unique indexes via `IsUnique()` for natural keys / unique constraints:
  ```csharp
  builder.HasIndex(p => p.Isin).IsUnique().HasDatabaseName("IX_Securities_Isin");
  ```
- `[MUST]` Use composite indexes when queries filter on multiple columns together; order columns with highest selectivity first:
  ```csharp
  builder.HasIndex(h => new { h.PortfolioId, h.Symbol }).HasDatabaseName("IX_Holdings_Portfolio_Symbol");
  ```
- `[MUST]` Name all indexes explicitly using `HasDatabaseName` — do not rely on generated names:
  ```csharp
  builder.HasIndex(h => h.Symbol).HasDatabaseName("IX_Holdings_Symbol");
  ```
- `[SHOULD]` Use `IncludeProperties` for covering indexes on read-heavy tables:
  ```csharp
  builder.HasIndex(t => t.TradeDate)
         .IncludeProperties(t => new { t.Symbol, t.Quantity, t.Price })
         .HasDatabaseName("IX_Transactions_TradeDate_Covering");
  ```
- `[SHOULD]` Include filter expressions on indexes where applicable (e.g., `HasFilter("[IsActive] = 1")` for SQL Server):
  ```csharp
  builder.HasIndex(t => t.SettlementDate)
         .HasFilter("[SettlementDate] IS NOT NULL")
         .HasDatabaseName("IX_Transactions_SettlementDate_NotNull");
  ```
- `[SHOULD-NOT]` Over-index — each index slows down writes. Profile with execution plans before adding indexes.

## 14. Migrations

- `[MUST]` Use EF Core migrations to manage all schema changes — never modify the database schema manually outside of migrations.
- `[MUST]` Commit all migration files (migration class, designer file, snapshot) to version control.
- `[MUST]` Use descriptive migration names that indicate purpose:
  ```
  dotnet ef migrations add Add_Holdings_Symbol_Index
  ```
- `[MUST]` Review generated migration code before applying — verify it matches intended schema changes and does not cause data loss.
- `[MUST]` Do not delete or edit existing applied migrations — add a new corrective migration instead.
- `[MUST]` Use `migrationBuilder.Sql(...)` for data migrations within a migration file; keep data migrations separate from schema migrations.
- `[SHOULD]` Apply migrations via SQL scripts or CI/CD pipeline in production — not via `Database.Migrate()` at application startup (avoids concurrency issues and requires elevated permissions).
- `[SHOULD]` Test migrations against a copy of production-scale data before deploying — schema changes on large tables can be slow and locking.
- `[SHOULD]` Make migrations backward-compatible when possible — add nullable columns first, backfill, then add constraints in a subsequent migration.

## 15. Performance Optimization

- `[MUST]` Use `AsNoTracking()` for all read-only queries.
- `[MUST]` Use async methods (`ToListAsync`, `SaveChangesAsync`, `FirstOrDefaultAsync`) throughout — never mix sync and async database calls.
- `[MUST]` Profile queries using EF Core logging, `ToQueryString()`, or database-level tools (`EXPLAIN ANALYZE`, SQL Server Profiler) before optimizing.
- `[SHOULD]` Use compiled queries for hot paths.
- `[SHOULD]` Use `AsSplitQuery()` when eager loading multiple collections causes Cartesian explosion.
- `[SHOULD]` Use connection pooling — EF Core uses ADO.NET connection pooling by default; ensure pool size is adequate for workload.
- `[SHOULD]` Use `DbContextPooling` (`AddDbContextPool<T>`) for high-throughput scenarios to amortize context creation overhead.
- `[SHOULD]` Avoid loading large result sets into memory — use streaming (`AsAsyncEnumerable()`) or pagination.
- `[SHOULD-NOT]` Use lazy loading in performance-sensitive code paths — it causes unpredictable N+1 queries.
- `[SHOULD-NOT]` Ignore EF Core query warnings — enable `ConfigureWarnings(w => w.Throw(RelationalEventId.MultipleCollectionIncludeWarning))` during development to catch issues early.

## 16. Conventions Customization

- `[SHOULD]` Override `ConfigureConventions` to apply model-wide defaults rather than repeating per-entity:
  ```csharp
  protected override void ConfigureConventions(ModelConfigurationBuilder configurationBuilder)
  {
      // Apply max length to all string properties
      configurationBuilder.Properties<string>().HaveMaxLength(500);
      // Apply precision to all decimals
      configurationBuilder.Properties<decimal>().HavePrecision(18, 4);
  }
  ```
- `[SHOULD]` Remove unused conventions to speed up model building:
  ```csharp
  configurationBuilder.Conventions.Remove(typeof(ForeignKeyIndexConvention)); // only if managing FK indexes manually
  ```

## 17. Naming Conventions

| Object | Convention | Example |
|---|---|---|
| Table | PascalCase plural (by convention via `DbSet` name) | `Portfolios` |
| Column | PascalCase (by convention via property name) | `MarketValue` |
| Primary key constraint | `PK_<TableName>` | `PK_Portfolios` |
| Foreign key constraint | `FK_<Table>_<PrincipalTable>_<Column>` | `FK_Holdings_Portfolios_PortfolioId` |
| Index | `IX_<Table>_<Columns>` | `IX_Holdings_Symbol` |
| Unique index | `IX_<Table>_<Columns>` with `IsUnique` | `IX_Securities_Isin` |
| Owned column | `<Navigation>_<Property>` (EF default) — override with `HasColumnName` | `CostBasis_Amount` |

- `[MUST]` All constraint and index names must be set explicitly via Fluent API — do not rely on EF-generated names in production schemas.

## 18. Security

- `[MUST]` Use LINQ queries or parameterized raw SQL (`FromSqlInterpolated`, `FromSqlRaw` with parameters) — never concatenate user input into SQL strings.
- `[MUST]` Validate and sanitize all user input before using it in queries, even with LINQ — defense in depth.
- `[MUST]` Store connection strings in secure configuration (User Secrets, Azure Key Vault, environment variables) — never in source code.
- `[SHOULD]` Use the principle of least privilege for database connection credentials — the application account should not have DDL or admin permissions in production.
- `[SHOULD]` Enable encryption on database connections in production environments.

## 19. Testing

- `[MUST]` Test against a real database (or realistic provider like Testcontainers) for integration tests — `InMemory` provider does not enforce referential integrity, constraints, or SQL semantics.
- `[SHOULD]` Use `Respawn` or transaction rollback to reset database state between tests.
- `[SHOULD]` Test migration scripts in a staging environment with production-scale data.
- `[SHOULD]` Test both happy-path and concurrency-conflict scenarios.
- `[SHOULD-NOT]` Use `InMemoryDatabase` provider as the primary test strategy — it behaves differently from relational databases and masks real bugs.

## 20. Tooling

- Use `context.Model.ToDebugString()` during development to inspect the resolved model.
- Enable EF Core logging in development to capture generated SQL:
  ```csharp
  optionsBuilder.LogTo(Console.WriteLine, LogLevel.Information);
  ```
- Use `dotnet ef dbcontext optimize` in production to pre-compile the model and reduce startup time.

---

## Completion Checklist — Configuration & Conventions

- [ ] All entity configuration uses Fluent API exclusively (no Data Annotations) ← COMMONLY MISSED
- [ ] Per-entity `IEntityTypeConfiguration<T>` classes used (not inline in `OnModelCreating`)
- [ ] `ApplyConfigurationsFromAssembly()` used for registration
- [ ] All constraint and index names set explicitly via `HasDatabaseName`
- [ ] Convention overrides applied in `ConfigureConventions` where applicable

## Completion Checklist — Relationships

- [ ] All relationships explicitly configured via Fluent API with both sides specified ← COMMONLY MISSED
- [ ] Explicit FK properties included in entity classes
- [ ] `OnDelete` behavior specified explicitly for every relationship ← COMMONLY MISSED
- [ ] Many-to-many relationships use implicit join entities (no explicit join table unless payload columns needed)
- [ ] Collection navigations use `ICollection<T>` and are initialized to empty collection

## Completion Checklist — Query Performance

- [ ] All read-only queries use `AsNoTracking()` ← COMMONLY MISSED
- [ ] Projections (`.Select()`) used instead of loading full entities for display/reporting ← COMMONLY MISSED
- [ ] `.Where()` applied before `.Select()`, `.Include()`, or `.ToListAsync()`
- [ ] Eager loading (`.Include()`) used as default loading strategy
- [ ] Async methods used for all database operations (`ToListAsync`, `SaveChangesAsync`)
- [ ] `AsSplitQuery()` used when including multiple collections
- [ ] Compiled queries used for frequently executed hot-path queries
- [ ] All unbounded queries have `.Take(n)` or pagination

## Completion Checklist — Data Integrity & Safety

- [ ] `SaveChangesAsync()` never called inside a loop ← COMMONLY MISSED
- [ ] `SaveChangesAsync()` wrapped in explicit transaction ← COMMONLY MISSED
- [ ] Batch operations (`ExecuteUpdateAsync`/`ExecuteDeleteAsync`) wrapped in transactions when combined with tracked changes
- [ ] Concurrency tokens (`.IsRowVersion()`) on entities with concurrent update risk ← COMMONLY MISSED
- [ ] `DbUpdateConcurrencyException` handled with explicit conflict resolution strategy
- [ ] All user input validated before use in queries

## Completion Checklist — Migrations & Deployment

- [ ] All migration files committed to version control
- [ ] Migration names are descriptive (`AddCustomerTable`, not `Migration1`)
- [ ] Generated migration SQL reviewed before applying to any environment ← COMMONLY MISSED
- [ ] Applied migrations never modified or deleted
- [ ] Data migrations use `migrationBuilder.Sql()` and are separate from schema migrations
- [ ] Migrations applied via CI/CD pipeline or SQL scripts (not `Database.Migrate()` at startup in production)
- [ ] Backward-compatible migrations used (nullable columns first, constraints in follow-up migration)

## Completion Checklist — DbContext Lifecycle

- [ ] `DbContext` registered via DI (`AddDbContext` or `AddDbContextPool`)
- [ ] `DbContext` from `IDbContextFactory` disposed with `using` ← COMMONLY MISSED
- [ ] `DbContext` kept short-lived (scoped per request or unit-of-work)
- [ ] No `DbContext` shared across threads
- [ ] Connection strings stored securely (not in source code)
- [ ] Entity configurations extracted to `IEntityTypeConfiguration<T>` classes

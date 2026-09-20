# C# Coding Standards

> **Agent instruction:** These rules are MANDATORY. Apply them to ALL generated or modified C# code without exception. Rules marked `[MUST]` are hard requirements; `[PREFER]` indicates strong preference. When in doubt, follow the most specific rule.

**Source:** [Microsoft C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)

---

## 1. Naming Conventions

### Casing Rules

| Identifier | Casing | Example |
|---|---|---|
| Namespace | PascalCase | `Investment.Portfolio.Analysis` |
| Class / Struct / Record | PascalCase | `PortfolioEntry` |
| Interface | PascalCase + `I` prefix | `IPortfolioRepository` |
| Method | PascalCase | `CalculateReturn` |
| Property | PascalCase | `MarketValue` |
| Public field | PascalCase | `DefaultRate` |
| Private / internal field | `_camelCase` | `_portfolioItems` |
| Local variable | camelCase | `currentBalance` |
| Parameter | camelCase | `accountId` |
| Constant (`const`) | PascalCase | `MaxRetryCount` |
| Enum type | PascalCase | `AssetClass` |
| Enum member | PascalCase | `FixedIncome` |
| Event | PascalCase | `OnPriceChanged` |
| Delegate | PascalCase | `PriceChangedHandler` |
| Generic type parameter | `T` prefix + PascalCase | `TEntity`, `TResult` |
| Primary ctor param (record) | PascalCase | `record Person(string FirstName)` |
| Primary ctor param (class/struct) | camelCase | `class Box(int width)` |

### Naming Rules

- `[MUST]` Prefix private instance fields with `_` (underscore).
- `[MUST]` Prefix interfaces with `I`.
- `[MUST]` Use meaningful, descriptive names — not abbreviations unless universally understood (e.g., `id`, `url`, `dto`).
- `[MUST]` Do not use Hungarian notation or type-encoding in names.
- `[MUST]` Do not suffix class names with `Class`, `Data`, `Info`, `Manager` unless domain-appropriate.
- `[MUST]` Use nouns or noun phrases for types; use verb phrases for methods.
- `[PREFER]` Static members: qualify with class name at call site (`ClassName.StaticMember`), never via derived class.

---

## 2. File & Namespace Layout

- `[MUST]` One type per file; filename matches type name.
- `[MUST]` Use file-scoped namespace declarations:
  ```csharp
  // CORRECT
  namespace Investment.Portfolio;

  public class PortfolioEntry { }
  ```
- `[MUST]` Place `using` directives **outside** the namespace declaration:
  ```csharp
  // CORRECT
  using System.Collections.Generic;

  namespace Investment.Portfolio;
  ```
  ```csharp
  // WRONG — causes fragile name resolution
  namespace Investment.Portfolio
  {
      using System.Collections.Generic;
  }
  ```

---

## 3. Formatting & Layout

- `[MUST]` 4 spaces for indentation. No tab characters.
- `[MUST]` Allman brace style — opening and closing braces on their own lines, aligned with current indentation:
  ```csharp
  if (condition)
  {
      DoSomething();
  }
  ```
- `[MUST]` One statement per line.
- `[MUST]` One declaration per line.
- `[MUST]` Add at least one blank line between method and property definitions.
- `[MUST]` Line breaks before binary operators when wrapping long expressions.
- `[PREFER]` Limit lines to ~120 characters (docs use 65; production code may use up to 120).
- `[PREFER]` Use parentheses to make compound conditions explicit:
  ```csharp
  if ((startX > endX) && (startX > previousX)) { }
  ```

---

## 4. Type & Variable Declarations

### `var` (implicit typing)

- `[MUST]` Use `var` when the type is **obvious** from the right-hand side:
  ```csharp
  var account = new BrokerageAccount();   // obvious: new
  var rate = 0.05m;                        // obvious: literal
  var accounts = (List<Account>)source;    // obvious: cast
  ```
- `[MUST]` Do NOT use `var` when the type is not immediately clear:
  ```csharp
  // WRONG
  var result = GetPortfolioData();

  // CORRECT
  PortfolioData result = GetPortfolioData();
  ```
- `[MUST]` Use `var` for loop variables in `for` loops.
- `[MUST]` Do NOT use `var` in `foreach` — use the explicit element type.
- `[MUST]` Use `var` in LINQ query variables and range variables.
- `[MUST]` Do NOT use `var` in place of `dynamic`.

### Language Keywords vs. BCL Types

- `[MUST]` Use language keywords for built-in types, not BCL type names:
  ```csharp
  string name;   // not String
  int count;     // not Int32
  bool isValid;  // not Boolean
  ```
- `[PREFER]` Use `int` over unsigned integer types unless the domain requires unsigned semantics.

### `new` Operator

- `[MUST]` Use target-typed `new()` or `var`-based instantiation — not both:
  ```csharp
  var entry = new PortfolioEntry();   // preferred with var
  PortfolioEntry entry = new();       // preferred when type is declared explicitly
  // AVOID:
  PortfolioEntry entry = new PortfolioEntry();
  ```
- `[MUST]` Use object initializers instead of sequential property assignments:
  ```csharp
  // CORRECT
  var entry = new PortfolioEntry { Symbol = "AAPL", Quantity = 100, Price = 182.50m };

  // WRONG
  var entry = new PortfolioEntry();
  entry.Symbol = "AAPL";
  entry.Quantity = 100;
  entry.Price = 182.50m;
  ```

---

## 5. Strings

- `[MUST]` Use string interpolation for concatenation of short strings:
  ```csharp
  string label = $"{entry.Symbol}: {entry.MarketValue:C}";
  ```
- `[MUST]` Use `StringBuilder` when concatenating in loops or with large amounts of text.
- `[PREFER]` Use raw string literals over escape sequences or verbatim strings:
  ```csharp
  var json = """
      {
        "symbol": "AAPL",
        "price": 182.50
      }
      """;
  ```
- `[MUST]` Use expression-based string interpolation, not positional/composite format:
  ```csharp
  // CORRECT
  Console.WriteLine($"{account.Name}: {account.Balance:C}");

  // AVOID
  Console.WriteLine("{0}: {1:C}", account.Name, account.Balance);
  ```

---

## 6. Collections & Arrays

- `[MUST]` Use collection expressions to initialize all collection types:
  ```csharp
  string[] assetClasses = ["Equity", "FixedIncome", "Cash"];
  List<int> ids = [1, 2, 3];
  ```

---

## 7. Constructors & Initialization

- `[PREFER]` Use `required` properties instead of constructors to force initialization:
  ```csharp
  public class TradeOrder
  {
      public required string Symbol { get; init; }
      public required decimal Quantity { get; init; }
  }
  ```
- `[MUST]` Pascal case for primary constructor parameters on **record** types.
- `[MUST]` camelCase for primary constructor parameters on **class** and **struct** types.

---

## 8. Delegates & Events

- `[MUST]` Use `Func<>` and `Action<>` instead of defining custom delegate types unless a named delegate adds clarity.
- `[MUST]` Use lambda expressions for event handlers that don't need to be unsubscribed:
  ```csharp
  priceService.PriceChanged += (s, e) => UpdateDisplay(e.NewPrice);
  ```
- `[MUST]` Use concise delegate instantiation syntax:
  ```csharp
  Action<decimal> onPrice = UpdateDisplay;   // not: new Action<decimal>(UpdateDisplay)
  ```

---

## 9. Exception Handling

- `[MUST]` Use `try-catch` with specific exception types — never catch `Exception` without a filter unless re-throwing.
- `[MUST]` Always re-throw with `throw;` (not `throw ex;`) to preserve stack trace.
- `[MUST]` Use `using` declarations (not `try-finally` with `Dispose`) for `IDisposable` resources:
  ```csharp
  // CORRECT
  using var connection = new DbConnection(connectionString);
  var results = connection.Query(sql);

  // WRONG
  DbConnection connection = new(connectionString);
  try { ... }
  finally { connection?.Dispose(); }
  ```
- `[MUST]` Use scoped `using` (no braces) where the resource lifetime naturally ends at method scope.

---

## 10. Boolean Logic & Operators

- `[MUST]` Use `&&` and `||` (short-circuit) instead of `&` and `|` in boolean expressions.

---

## 11. LINQ

- `[MUST]` Use meaningful names for query variables (e.g., `activeAccounts`, not `q` or `result`).
- `[MUST]` Use `where` clauses before `orderby`/`select` to filter early.
- `[MUST]` Use Pascal-cased aliases on anonymous type properties:
  ```csharp
  select new { AccountName = account.Name, HoldingCount = account.Holdings.Count }
  ```
- `[MUST]` Use implicit typing (`var`) for LINQ query variables.
- `[MUST]` Align query clauses under the `from` clause:
  ```csharp
  var activeHoldings = from holding in portfolio.Holdings
                       where holding.MarketValue > 0
                       orderby holding.Symbol
                       select holding;
  ```
- `[MUST]` Use multiple `from` clauses instead of `join` when accessing inner collections.
- `[PREFER]` Use LINQ method syntax for single-operation chains; query syntax for multi-clause queries.

---

## 12. Async / Await

- `[MUST]` Use `async`/`await` for all I/O-bound operations.
- `[MUST]` Suffix async methods with `Async`: `GetPortfolioAsync()`.
- `[MUST]` Use `ConfigureAwait(false)` in library/infrastructure code to avoid deadlocks.
- `[MUST]` Do not use `.Result` or `.Wait()` on tasks — always `await`.

---

## 13. Comments & Documentation

- `[MUST]` Use XML doc comments (`///`) on all public members:
  ```csharp
  /// <summary>Calculates the unrealized gain/loss for the holding.</summary>
  /// <param name="currentPrice">The current market price per unit.</param>
  /// <returns>Unrealized gain/loss in base currency.</returns>
  public decimal CalculateUnrealizedGain(decimal currentPrice) { ... }
  ```
- `[MUST]` Place inline comments on a separate line above the code, not at end-of-line.
- `[MUST]` Begin comment text with an uppercase letter and end with a period.
- `[MUST]` One space between `//` and comment text.
- `[MUST]` Do not use `/* */` block comments.
- `[MUST]` Do not use comments to explain *what* the code does — only *why* when the reason is non-obvious.

---

## 14. Modern Language Features

- `[MUST]` Use modern C# features when available — do not use outdated constructs.
- `[MUST]` Use pattern matching instead of type checks + casts:
  ```csharp
  if (asset is Equity equity) { ... }
  ```
- `[MUST]` Use switch expressions over switch statements where appropriate.
- `[MUST]` Use records for immutable data transfer objects.
- `[PREFER]` Use primary constructors on classes/structs for simple initialization.
- `[PREFER]` Use expression-bodied members for single-expression methods and properties.

---

## 15. Security

- `[MUST]` Follow [Secure Coding Guidelines](https://learn.microsoft.com/en-us/dotnet/standard/security/secure-coding-guidelines).
- `[MUST]` Never store secrets in source code or config files committed to source control.
- `[MUST]` Validate all external inputs before use.
- `[MUST]` Use parameterized queries — never string-concatenate SQL.

---

## 16. Tooling Enforcement

- Use `.editorconfig` to automate style enforcement in Visual Studio / Rider.
- Enable Roslyn analyzers and treat style warnings as build warnings in CI.
- Reference: [dotnet/docs .editorconfig](https://github.com/dotnet/docs/blob/main/.editorconfig)

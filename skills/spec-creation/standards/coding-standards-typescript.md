# TypeScript General Principles, Tooling, and Coding Standards

## Baseline

- `[MUST]` Use the Google TypeScript Style Guide as the primary style reference: https://google.github.io/styleguide/tsguide.html.
- `[MUST]` Apply the local `ts-coding-standards` skill as the project-level supplement for type safety, error handling, async patterns, and module design.
- `[MUST]` Prefer consistency within an existing file when touching legacy code, but all new files and substantial rewrites must follow Google-style TypeScript.

## General Principles & Tooling

- `[MUST]` Optimize for type safety over convenience. Do not trade correctness for shorter code.
- `[MUST]` Keep code explicit and readable. Prefer simple, obvious implementations over clever abstractions.
- `[MUST]` Configure `tsconfig.json` with strict settings, including at minimum `strict`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noPropertyAccessFromIndexSignature`, `noFallthroughCasesInSwitch`, `noImplicitOverride`, `noImplicitReturns`, `noUnusedLocals`, and `noUnusedParameters`.
- `[MUST]` Use `Prettier` for automated formatting.
- `[MUST]` Use `ESLint` with TypeScript-aware rules, including `@typescript-eslint`.
- `[MUST]` Ensure all TypeScript files pass type checking in the standard toolchain.

## Source Files, Imports, and Exports

- `[MUST]` Use UTF-8 source files.
- `[MUST]` Use ES module syntax. Do not use `namespace`, `module`, triple-slash references, or `import x = require(...)`.
- `[MUST]` Prefer named exports. Do not use default exports.
- `[MUST]` Keep exports minimal. Only export symbols that are used outside the module.
- `[MUST]` Do not use mutable exports such as `export let`.
- `[MUST]` Use `import type` and `export type` for type-only imports and re-exports where appropriate.
- `[PREFER]` Use relative imports within the same logical project.
- `[PREFER]` Use named imports for commonly used symbols and namespace imports only when they improve clarity.

## Naming and Declarations

- `[MUST]` Use `const` by default and `let` only when reassignment is required. Never use `var`.
- `[MUST]` Declare one variable per declaration.
- `[MUST]` Use descriptive names. Avoid ambiguous abbreviations and internal-letter deletions.
- `[MUST]` Follow Google naming conventions: `UpperCamelCase` for classes, interfaces, types, and enums; `lowerCamelCase` for variables, functions, methods, parameters, and properties; `CONSTANT_CASE` only for true module-level constants and enum values.
- `[MUST]` Do not prefix or suffix identifiers with `_`.
- `[MUST]` Do not encode type information into names. Avoid patterns like `IUser`, `optValue`, or Hungarian notation.

## Type System

- `[MUST]` Prefer `unknown` over `any`. Narrow with type guards before use.
- `[MUST]` If `any` is unavoidable, keep usage local, document why, and suppress lint rules only as narrowly as possible.
- `[MUST]` Prefer interfaces for object-shaped types.
- `[PREFER]` Use type aliases for unions, branded types, mapped helpers, tuples, or other non-object compositions.
- `[MUST]` Use structural typing intentionally by annotating object literals at declaration boundaries when the shape matters.
- `[MUST]` Prefer optional properties and parameters over explicit `| undefined` where omission is part of the API.
- `[MUST]` Avoid nullable or undefined-bearing type aliases that spread absence through multiple layers. Add `| null` or `| undefined` at the usage site instead.
- `[MUST]` Use `readonly` for data that must not be reassigned after construction.
- `[MUST]` Prefer `T[]` and `readonly T[]` for simple array element types; use `Array<T>` or `ReadonlyArray<T>` when the element type is complex and the longer form is clearer.
- `[PREFER]` Use discriminated unions for state machines, result types, and API response variants.
- `[PREFER]` Use branded types for identifiers and validated domain values where accidental interchange would be dangerous.
- `[PREFER]` Use the simplest type construct that clearly expresses intent. Avoid overusing mapped and conditional types when a straightforward interface is easier to read and maintain.
- `[MUST]` Use `as` syntax for type assertions. Avoid assertions unless they are justified by an obvious invariant or an explicit runtime check.
- `[MUST]` Do not use `{}` as a catch-all type. Prefer `unknown`, `object`, or `Record<string, T>` depending on intent.

## Functions, Classes, and Control Flow

- `[MUST]` Use function declarations for named top-level functions.
- `[MUST]` Do not use function expressions when an arrow function or function declaration is clearer.
- `[PREFER]` Use arrow functions for callbacks and nested functions that need lexical `this`.
- `[MUST]` Prefer explicit parameter forwarding in callbacks instead of passing unstable callbacks such as `parseInt` directly to array methods.
- `[MUST]` Use braces for all control-flow blocks in project code, even when the body is one line.
- `[MUST]` Use `===` and `!==`. The only allowed loose equality shortcut is `value == null` or `value != null` when intentionally checking both `null` and `undefined`.
- `[MUST]` Keep `try` blocks focused on the statements that may throw.
- `[MUST]` Every `switch` must include a `default` case, and non-empty cases must not fall through.
- `[MUST]` Use `for...of`, `Object.keys`, `Object.values`, or `Object.entries` instead of unfiltered `for...in`.
- `[PREFER]` Use object destructuring over array destructuring when names improve readability.
- `[PREFER]` Use parameter properties and field initializers when they reduce boilerplate without hiding intent.
- `[MUST]` Avoid container classes made only of static members. Prefer module-level constants and functions.
- `[MUST]` Do not use `#private` fields in project TypeScript. Use TypeScript visibility modifiers instead.

## Error Handling and Async Code

- `[MUST]` Throw only `Error` instances or subclasses of `Error`.
- `[MUST]` Instantiate errors with `new Error(...)`.
- `[MUST]` Type caught errors as `unknown` and narrow before using them.
- `[PREFER]` Use `Result`-style patterns or discriminated unions for expected failure paths instead of exceptions for normal control flow.
- `[MUST]` Do not leave empty `catch` blocks without a comment explaining why ignoring the error is correct.
- `[MUST]` Prefer explicit async flows and clear Promise handling over implicit side effects.

## Comments and Documentation

- `[MUST]` Use JSDoc for exported APIs and for non-obvious classes, methods, and functions.
- `[MUST]` Document all top-level exports unless they exist only for framework or tooling integration.
- `[MUST]` Keep comments additive. Do not restate what is already obvious from names and types.
- `[MUST]` Write JSDoc in Markdown.
- `[MUST]` Do not duplicate type information in JSDoc for TypeScript code.
- `[MUST]` Place JSDoc before decorators.

## Disallowed and Restricted Patterns

- `[MUST NOT]` Do not rely on automatic semicolon insertion. End statements with semicolons.
- `[MUST NOT]` Do not use wrapper object types or constructors such as `String`, `Number`, or `Boolean`.
- `[MUST NOT]` Do not use `const enum`.
- `[MUST NOT]` Do not use `@ts-ignore`, `@ts-nocheck`, or `@ts-expect-error` except in narrow, justified test-only scenarios where no safer alternative exists.
- `[MUST NOT]` Do not use `eval`, `Function(...string)`, `with`, `debugger`, or direct prototype manipulation in application code.
- `[MUST NOT]` Do not modify built-in objects or their prototypes.
- `[MUST NOT]` Do not use decorators unless they are required by an adopted framework.

## Review Heuristics

- `[MUST]` Prefer changes that remove ambiguity, reduce unsafe casts, and make invalid states unrepresentable.
- `[MUST]` Fix root causes instead of silencing type errors.
- `[PREFER]` Separate large formatting-only cleanups from functional changes.
# Specification: Implementation Guidance

> Concrete conventions an autonomous agent uses to implement spec-02 without inventing answers.

## 0. Upstream Architecture Sidecars Consumed

<!--
List every active `spec-02[a-z]-*.md` sidecar this spec-03 inherits constraints from. If the solution has no sidecars, write "none" and remove the table.

Sidecars are **immutable upstream architecture** — spec-03 references them, never redefines them.

| Sidecar file                | Anchors consumed                                  | What spec-03 inherits literally                       |
| --------------------------- | -------------------------------------------------- | ----------------------------------------------------- |
| `spec-02a-<slice>.md`       | `spec-02a#technical-contracts`, `spec-02a#rua-rules` | e.g. RUA semantics, idempotency key shape, lineage triple |
-->

## 1. Repository Layout

## 2. Naming Conventions

### 2.1 Files

### 2.2 Types

### 2.3 Methods

### 2.4 Tests

## 3. Per-Standard Instantiation

<!-- for each 02-standards/coding-standards-*.md applicable: rule-by-rule capture of [MUST] instantiations and [SHOULD] adopt/elevate/reject decisions -->

## 4. Error Model

### 4.1 Exception Classes

### 4.2 Result Types

### 4.3 Validation Results

### 4.4 Boundary Mapping

## 5. Validation Strategy

### 5.1 Domain Invariants

### 5.2 Boundary Validation

### 5.3 UI Validation

## 6. Testing Strategy

### 6.1 Domain Tests

### 6.2 Integration Tests

### 6.3 End-to-End Tests

### 6.4 Architecture Tests

### 6.5 Test Data

## 7. Dependency Injection / Composition

### 7.1 Composition Root

### 7.2 Registration Conventions

### 7.3 Lifetimes

## 8. Configuration & Secrets

### 8.1 Sources & Override Order

### 8.2 Per-Environment Variation

### 8.3 Secret Storage

## 9. Persistence Mapping

<!-- per spec-01 remembered concept: naming, key strategy, concurrency, migrations -->

## 10. Async / Concurrency Posture

## 11. Static Analysis

<!-- linters, formatters, analyzers, severity policy -->

## 12. Implementation Decisions Index

<!-- pointers into implementation-decisions.md -->

# Specification: Architecture

> Realizes `spec-01-domain-model.md`. Cites `02-standards/design-standards-clean-architecture.md` (or chosen style).

## 1. Architectural Style

<!-- clean / vertical-slice / hexagonal / hybrid; justification -->

## 2. Stack

### 2.1 Languages & Runtimes

### 2.2 UI Stack

### 2.3 Data-Store Stack

### 2.4 Host & Orchestration Stack

### 2.5 Standards Mapping

<!-- which 02-standards file governs which choice -->

## 3. Project / Package Map

<!-- spec-01 modules → projects/packages; dependency direction preserved -->

## 4. Boundaries

### 4.1 Inbound Boundaries

<!-- HTTP, CLI, scheduled jobs, message bus, etc. — abstraction shape, owning module -->

### 4.2 Outbound Boundaries

<!-- persistence, external APIs, time, file system — abstraction shape, owning module -->

## 5. Cross-Cutting Concerns

### 5.1 Logging & Telemetry

### 5.2 Error Handling

### 5.3 Validation

### 5.4 Authn / Authz

### 5.5 Configuration

### 5.6 Secrets

## 6. Persistence Shape

<!-- per spec-01 remembered concept: storage class, transactional boundary -->

## 7. Deployment Topology

### 7.1 Processes & Hosts

### 7.2 Communication

### 7.3 Lifecycle

### 7.4 Environments

## 8. Non-Functional Realization

<!-- for each spec-00 NFR: the architectural mechanism -->

## 9. Sidecar Index

<!--
List every architecture sidecar emitted for this solution. Sidecars are conditional formal members of the spec-02 family (see dm-spec-creation SKILL.md §"Architecture sidecar family"). If no sidecars are needed, write "none" and remove the table.

| File                                | Slice / Module      | Authority boundary (which base § it narrows; what it MUST NOT contradict) | Standards loaded beyond base |
| ----------------------------------- | ------------------- | ------------------------------------------------------------------------- | ---------------------------- |
| `spec-02a-<slice>.md`               | …                  | narrows §…; MUST NOT contradict spec-01 §… or base spec-02 §…             | e.g. coding-standards-efcore.md, coding-standards-sql.md |
-->

## 10. Architectural Decisions Index

<!-- pointers into decisions.md -->

---
name: rest-api-standards
description: Standards for RESTful API design covering resource modeling, URI conventions, error handling, pagination, async operations, multitenancy, and security. Basic REST semantics and HTTP method/status code definitions are omitted — agents already know those.
scope: HTTP-based RESTful API design and implementation, with emphasis on .NET Web API projects.
---

# REST API Design Standards

> Distilled from [Microsoft Azure REST API Design Best Practices](https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design). Basic REST architectural constraints, standard HTTP method semantics, and content negotiation are omitted — these are universally understood.

---

## Resource URI Design

- [MUST] Organize the API around resources — each resource is identified by a unique URI
- [MUST] Use nouns (not verbs) for resource names — HTTP methods already convey the action (e.g., `/orders` not `/create-order`)
- [MUST] Use plural nouns for collection URIs (e.g., `/customers`, `/orders`)
- [MUST] Use a hierarchical structure for collections and items (e.g., `/customers/{id}`, `/customers/{id}/orders`)
- [MUST-NOT] Embed verbs or actions in URIs — use HTTP methods to express operations
- [MUST-NOT] Mirror internal database structure in the API — model business entities, not tables
- [MUST-NOT] Require resource URIs deeper than _collection/item/collection_ — keep relationships simple and navigable
- [MUST] Use path parameters to identify a specific resource (e.g., `/users/42`)
- [MUST] Use query parameters for filtering, sorting, pagination, and optional refinements (e.g., `?role=admin&sort=name&page=2`)
- [MUST-NOT] Use path segments for filtering or optional parameters — use query strings instead

---

## HTTP Status Codes — Non-Obvious Rules

- [MUST] Differentiate authentication vs. authorization errors:
  - `401 Unauthorized` — missing or invalid credentials (authentication failure)
  - `403 Forbidden` — valid credentials but insufficient permissions (authorization failure)
- [MUST] Use `422 Unprocessable Entity` for business rule violations when the request is syntactically valid but semantically incorrect
- [MUST] Use `429 Too Many Requests` when rate limiting is enforced
- [MUST] Return `202 Accepted` for long-running operations that cannot complete within a normal response time
- [MUST-NOT] Return `200 OK` for error conditions — use `4xx` for client errors and `5xx` for server errors
- [MUST-NOT] Use `500 Internal Server Error` for client input errors — use `400` or `422`
- [SHOULD-NOT] Expose stack traces or internal details in `5xx` responses — log them server-side and return a generic error message

---

## Error Response Design

- [MUST] Use a consistent, structured error response format across all endpoints
- [MUST] Use RFC 7807 Problem Details format (or a project-standard equivalent) including `type`, `title`, `status`, `detail`, and `instance` fields
- [MUST] Return field-level validation errors in a structured `errors` object (e.g., `{ "errors": { "email": ["The email field is required."] } }`)
- [MUST] Include a `traceId` or correlation identifier in error responses for debugging
- [MUST-NOT] Return `200 OK` with `{ "success": false }` — use proper HTTP error status codes
- [SHOULD] In .NET, use the built-in `ProblemDetails` support (`AddProblemDetails()`, `UseExceptionHandler()`, `UseStatusCodePages()`)

---

## Pagination, Filtering & Sorting

- [MUST] Implement pagination for all collection endpoints that may return large datasets
- [MUST] Support `limit` and `offset` (or equivalent cursor-based) query parameters with meaningful defaults (e.g., `limit=25`, `offset=0`)
- [MUST] Impose a server-side upper limit on page size to prevent denial-of-service (e.g., `max-limit=100`)
- [MUST-NOT] Return unbounded collections — always paginate
- [SHOULD] Support filtering via query parameters (e.g., `?status=shipped&minCost=100`)
- [SHOULD] Support sorting via a `sort` query parameter (e.g., `?sort=price`)
- [SHOULD] Validate all requested filter/sort/field parameters and reject invalid or unauthorized fields

---

## Asynchronous Operations

- [MUST] Return `202 Accepted` for long-running operations (POST, PUT, PATCH, DELETE) that cannot complete within a normal response time
- [MUST] Include a `Location` header in the `202` response pointing to a status endpoint
- [MUST] Return `303 See Other` from the status endpoint once the async operation creates a new resource, with a `Location` header pointing to the new resource URI
- [SHOULD] Include current status, estimated completion time, and/or a cancellation link in the status endpoint response

---

## Multitenancy

- [MUST] Clearly define how tenants are identified in requests (subdomain, path, header, or JWT claim)
- [MUST] Ensure tenant isolation — a tenant must never access another tenant's data
- [SHOULD] Prefer header-based or token-based tenant identification for cleaner RESTful URIs
- [SHOULD] Preserve the hostname between reverse proxy and backend services to avoid URL redirection issues

---

## Distributed Tracing & Observability

- [MUST] Propagate trace context headers (`Correlation-ID`, `X-Request-ID`, or `X-Trace-ID`) through all API requests and responses
- [SHOULD] Echo the correlation ID back in the response for end-to-end traceability

---

## API Documentation & Contract

- [MUST] Provide an OpenAPI (Swagger) specification for all public APIs
- [SHOULD] Follow a contract-first design approach — define the API contract before writing implementation code

---

## Security

- [MUST] Use HTTPS for all API endpoints — never serve APIs over plain HTTP
- [MUST] Validate all client input — reject unexpected fields, types, or values with `400 Bad Request`
- [MUST] Authenticate all API requests using standard mechanisms (OAuth 2.0, API keys, JWT)
- [MUST-NOT] Expose internal implementation details (database schema, stack traces, internal URIs) in API responses
- [SHOULD] Implement rate limiting and throttling to protect against denial-of-service attacks (return `429 Too Many Requests`)
- [SHOULD] Use CORS policies to restrict which origins can call the API
- [SHOULD] Validate `Content-Length` and impose request body size limits

---

## Completion Checklists

### Designing a New Resource Endpoint

- [ ] Define the resource URI using plural nouns and hierarchical structure
- [ ] Map CRUD operations to the correct HTTP methods (GET, POST, PUT, PATCH, DELETE)
- [ ] Implement pagination with `limit`/`offset` and a server-side max ← COMMONLY MISSED
- [ ] Include `Location` header in `201 Created` responses ← COMMONLY MISSED
- [ ] Use consistent error response format (RFC 7807 Problem Details) ← COMMONLY MISSED
- [ ] Differentiate `401` (unauthenticated) vs `403` (unauthorized) correctly
- [ ] Provide an OpenAPI spec entry for the endpoint

### Adding a Collection Endpoint

- [ ] Implement pagination — never return unbounded results ← COMMONLY MISSED
- [ ] Support filtering, sorting, and field selection via query parameters
- [ ] Validate and sanitize all query parameters
- [ ] Impose an upper limit on `limit` parameter to prevent abuse
- [ ] Return `200 OK` with empty array (not `404`) when no items match filters

### Implementing Async / Long-Running Operations

- [ ] Return `202 Accepted` with a `Location` header pointing to the status endpoint ← COMMONLY MISSED
- [ ] Implement the status endpoint returning current progress
- [ ] Return `303 See Other` with `Location` header when the resource is created ← COMMONLY MISSED
- [ ] Include cancellation link in status responses where appropriate

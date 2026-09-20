---
name: aspnet-standards
description: Standards for ASP.NET Core web application development, covering request handling, middleware, dependency injection, configuration, caching, error handling, and performance best practices.
scope: ASP.NET Core web APIs and server-side applications targeting .NET 8+.
---

# ASP.NET Core Coding Standards

> Based on [ASP.NET Core Best Practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices) for ASP.NET Core 10.0.

---

## Async & Thread Safety

- [MUST] Make all controller/Razor Page actions asynchronous — the entire call stack must be async to benefit from `async`/`await`
- [MUST] Call all data access and I/O APIs asynchronously when an async overload is available
- [MUST] Use `ReadToEndAsync` or `DeserializeAsync` for reading HTTP request/response bodies — never synchronous `ReadToEnd`
- [MUST] Use `HttpContext.Request.ReadFormAsync` instead of `HttpContext.Request.Form` to avoid sync-over-async
- [MUST-NOT] Block async execution by calling `Task.Wait()` or `Task<T>.Result`
- [MUST-NOT] Call `Task.Run()` and immediately `await` it — ASP.NET Core already runs on thread pool threads; this adds unnecessary scheduling overhead
- [MUST-NOT] Use `async void` in controller actions — the request completes at the first `await`, causing crashes on later writes
- [MUST-NOT] Acquire locks in common code paths — design for parallel execution
- [SHOULD] Make all hot code paths (frequently called, high execution time) asynchronous
- [SHOULD] Consider using message brokers (e.g., Azure Service Bus) to offload long-running work or start with something dependency free, an outbox and a timed process that runs in the background to process queued work.

---

## HttpContext Safety

- [MUST] Copy data from `HttpContext` before spawning background work — `HttpContext` is recycled after the request completes
- [MUST] Store `IHttpContextAccessor` (not `HttpContext` itself) in fields, and access `.HttpContext` at the point of use with a null check
- [MUST] Return `Task` (not `void`) from async actions so the framework knows when the action completes
- [MUST-NOT] Store `IHttpContextAccessor.HttpContext` in a field or variable — it captures a null or incorrect context
- [MUST-NOT] Access `HttpContext` from multiple threads in parallel — it is not thread-safe
- [MUST-NOT] Capture `HttpContext` in closures passed to background threads or `Task.Run()`
- [MUST-NOT] Use `HttpContext` after the request has completed (after the pipeline `Task` finishes)

---

## Dependency Injection & Scoped Services

- [MUST] Create a new `IServiceScope` (via `IServiceScopeFactory`) when resolving scoped services in background threads
- [MUST-NOT] Capture scoped services (e.g., `DbContext`) injected into controllers and use them in background tasks — they will be disposed when the request ends, causing `ObjectDisposedException`
- [SHOULD] Inject `IServiceScopeFactory` (which is a singleton) for any fire-and-forget or background work that needs DI services

---

## HTTP Client Management

- [MUST] Use `IHttpClientFactory` to retrieve `HttpClient` instances
- [MUST-NOT] Create and dispose `HttpClient` instances directly — closed instances leave sockets in `TIME_WAIT` state, leading to socket exhaustion

---

## Data Access & Entity Framework Core

- [MUST] Call all data access APIs asynchronously
- [MUST] Filter and aggregate data in LINQ queries (`.Where`, `.Select`, `.Sum`) so filtering happens in the database, not in memory
- [MUST-NOT] Retrieve more data than necessary for the current HTTP request
- [MUST-NOT] Use projection queries on collections that result in N+1 SQL queries
- [SHOULD] Use no-tracking queries (`AsNoTracking()`) in EF Core for read-only data access
- [SHOULD] Cache frequently accessed data with `IMemoryCache` or `IDistributedCache` when slightly stale data is acceptable
- [SHOULD] Minimize network round trips — retrieve required data in a single call rather than multiple calls
- [SHOULD] Consider `DbContext` pooling and explicitly compiled queries for high-scale apps
- [SHOULD] Be aware that EF Core may resolve some query operators on the client — review for client evaluation performance issues

---

## Pagination & Large Collections

- [MUST] Add pagination (page size + page index) when returning collections to avoid `OutOfMemoryException`, thread pool starvation, and slow responses
- [MUST-NOT] Load large amounts of data all at once in a single response
- [SHOULD] Use `IAsyncEnumerable<T>` instead of `IEnumerable<T>` for action return types to avoid synchronous collection iteration and thread pool starvation
- [SHOULD] Use `ToListAsync()` before returning an `IEnumerable<T>` if `IAsyncEnumerable<T>` is not used

---

## Memory & Garbage Collection

- [MUST] Pool large buffers using `ArrayPool<T>` instead of allocating and discarding them
- [MUST-NOT] Allocate many short-lived large objects (≥85KB) in hot code paths — they go on the Large Object Heap and trigger expensive Gen 2 GC collections
- [MUST-NOT] Read large request bodies or response bodies entirely into memory (`byte[]` or `string`) — this can exhaust the LOH and cause full GC pauses
- [SHOULD] Cache large objects that are frequently used to avoid repeated expensive allocations
- [SHOULD] Use `System.Text.Json` (the default since ASP.NET Core 3.0) for async, high-performance JSON serialization
- [SHOULD] Buffer data into memory asynchronously before passing to synchronous serializers/deserializers

---

## Exceptions

- [MUST] Include logic to detect and handle conditions that would cause an exception — avoid using exceptions for normal control flow
- [MUST-NOT] Use throwing/catching exceptions as a means of normal program flow, especially in hot code paths
- [SHOULD] Use Application Insights or profiling tools to identify common exceptions affecting performance

---

## Response Handling

- [MUST] Check `HttpResponse.HasStarted` before modifying response headers
- [MUST] Use `HttpResponse.OnStarting()` to set headers just before they are flushed to the client
- [MUST-NOT] Modify status codes or headers after the response body has started writing
- [MUST-NOT] Call `next()` in middleware if you have already started writing to the response body

---

## Request Validation

- [MUST] Check `HttpRequest.ContentLength` for `null` before comparing — `null` means length is unknown, not zero
- [MUST-NOT] Assume `Request.ContentLength` is non-null — comparisons like `> 1024` return `false` for `null`, which can create security holes

---

## Middleware & Pipeline

- [MUST] Keep middleware components fast — they execute on every request and early-pipeline middleware has the largest performance impact
- [MUST-NOT] Use custom middleware with long-running tasks — offload to background services
- [SHOULD] Use performance profiling tools (Visual Studio Diagnostics, PerfView) to identify hot code paths
- [SHOULD] Profile threads added to the thread pool to detect thread pool starvation

---

## Background & Long-Running Tasks

- [MUST] Implement background tasks as hosted services (`IHostedService` / `BackgroundService`)
- [MUST-NOT] Wait for long-running tasks to complete as part of ordinary HTTP request processing
- [SHOULD] Use Azure Functions, message brokers, or out-of-process workers for CPU-intensive background work
- [SHOULD] Use SignalR for real-time communication with clients from background processes

---

## Caching

- [MUST] Cache aggressively — use `IMemoryCache`, `IDistributedCache`, or response caching where appropriate
- [SHOULD] Cache large objects that are frequently used to prevent repeated expensive allocations
- [SHOULD] Use response caching middleware and output caching for frequently requested endpoints

---

## Completion Checklists

### README

- [ ] The README.md [MUST] be updated with explanation how to start the application via Aspire for local development.
- [ ] The application [MUST] be started via Aspire and then tested to verify all components are working including accessing the web application(s) either in the browser or via a headless browser to verify the application loads.

### New Controller / Razor Page Action

- [ ] Mark action method `async Task<IActionResult>` (or appropriate return type) — never `async void`
- [ ] Use `await` for all data access and I/O calls
- [ ] Add pagination for collection-returning endpoints ← COMMONLY MISSED
- [ ] Return `IAsyncEnumerable<T>` or call `ToListAsync()` instead of returning `IEnumerable<T>` ← COMMONLY MISSED
- [ ] Validate `Request.ContentLength` for null before size comparisons

### Background Task Implementation

- [ ] Implement as `IHostedService` or `BackgroundService`
- [ ] Create a new `IServiceScope` for resolving scoped services ← COMMONLY MISSED
- [ ] Copy needed `HttpContext` data before spawning the task — never capture `HttpContext`
- [ ] Do not reference controller-injected scoped services (e.g., `DbContext`) ← COMMONLY MISSED

### Adding an HTTP Client Dependency

- [ ] Register via `IHttpClientFactory` in `Program.cs` / DI configuration
- [ ] Inject `IHttpClientFactory` or a typed client — never `new HttpClient()` ← COMMONLY MISSED
- [ ] Configure resilience policies (retry, circuit breaker) via Polly or Microsoft.Extensions.Http.Resilience

### Middleware Component

- [ ] Keep processing fast — avoid long-running operations
- [ ] Check `HttpResponse.HasStarted` before modifying headers ← COMMONLY MISSED
- [ ] Use `OnStarting()` callback for last-minute header modifications
- [ ] Do not call `next()` after writing to the response body
- [ ] Profile with PerfView to verify no thread pool starvation impact

### EF Core Data Access

- [ ] Use `async` versions of all EF Core methods (`ToListAsync`, `FirstOrDefaultAsync`, `SaveChangesAsync`)
- [ ] Apply `.AsNoTracking()` for read-only queries ← COMMONLY MISSED
- [ ] Filter in the database with `.Where()` — avoid client-side evaluation
- [ ] Check for N+1 query patterns in collection projections ← COMMONLY MISSED
- [ ] Consider `DbContext` pooling for high-scale scenarios

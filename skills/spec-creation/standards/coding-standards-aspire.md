---
name: aspire-standards
description: Standards for building cloud-native distributed applications with .NET Aspire, covering AppHost orchestration, service defaults, integrations, health checks, observability, and deployment.
scope: .NET Aspire projects using AppHost orchestration, service discovery, and the Aspire integrations catalog.
---

# .NET Aspire Standards

> **Sources:**
>
> - [Aspire Skill — github/awesome-copilot](https://github.com/github/awesome-copilot/tree/main/skills/aspire)
> - [Aspire Configuration Skill — aaronontheweb](https://agentskills.so/skills/aaronontheweb-dotnet-skills-aspire-configuration)
> - [Aspire Documentation](https://aspire.dev/reference/overview/)
> - [Aspire Architecture, Testing & Deployment references](https://github.com/github/awesome-copilot/tree/main/skills/aspire/references)
>
> **Recommendation:** Install the Aspire skill from [`github/awesome-copilot`](https://github.com/github/awesome-copilot/tree/main/skills/aspire) for comprehensive AI-assisted Aspire development. The skill includes CLI reference, architecture deep-dive, polyglot API signatures, integration catalog, deployment guides, testing patterns, dashboard features, MCP server setup, and troubleshooting. Copy `skills/aspire/` into your project's agent skills directory. Additionally, configure the Aspire MCP server (`aspire mcp init`) for live docs search and integration discovery from within your AI assistant.

---

## 0. Prerequisites & Environment Verification

> **References:**
>
> - [Prerequisites](https://aspire.dev/get-started/prerequisites/?apphost=csharp)
> - [Install CLI](https://aspire.dev/get-started/install-cli/)

Before any Aspire work begins, the following prerequisites MUST be verified
during the Environment Discovery phase. If any are missing, the build MUST
not proceed until they are installed.

### Required Tools

| Tool                  | Version Target                                   | Verification Command                     | Install                                                                                          |
| --------------------- | ------------------------------------------------ | ---------------------------------------- | ------------------------------------------------------------------------------------------------ | ----- |
| .NET SDK              | Latest stable required by Aspire (see tech-spec) | `dotnet --list-sdks`                     | [dotnet.microsoft.com/download/dotnet](https://dotnet.microsoft.com/download/dotnet)             |
| Aspire CLI            | Latest stable                                    | `aspire --version`                       | `curl -sSL https://aspire.dev/install.sh \\                                                      | bash` |
| OCI Container Runtime | Any                                              | `docker --version` or `podman --version` | [Docker Desktop](https://www.docker.com/products/docker-desktop) or [Podman](https://podman.io/) |

The specific .NET SDK version required by Aspire changes over time. The
`technical-specification.md` Dependencies & Target Versions table is the
authoritative source for the project's target SDK version. During Environment
Discovery, compare the installed SDK against that target.

### Verification Protocol

- `[MUST]` During Environment Discovery, run ALL three verification commands
  above. If any fails, report it as a **Missing Tool** in `environment.md`
  with the install command.
- `[MUST]` Verify the installed .NET SDK version meets or exceeds the target
  version declared in the project's `technical-specification.md`. Aspire's
  AppHost requires the SDK version specified in the tech spec — older SDKs
  will not work even if they are present.
- `[MUST]` If `aspire --version` fails, install the Aspire CLI before
  proceeding:

  ```bash
  # macOS / Linux
  curl -sSL https://aspire.dev/install.sh | bash

  # Windows (PowerShell)
  powershell -ExecutionPolicy ByPass -c "irm https://aspire.dev/install.ps1 | iex"
  ```

  After installation, verify with `aspire --version`. If the command is
  still not found, restart the terminal session to pick up PATH changes.

- `[MUST]` Verify a container runtime is available and running. Docker
  Desktop must be started (not just installed). For Podman, set the
  environment variable:
  ```bash
  export ASPIRE_CONTAINER_RUNTIME=podman
  ```
- `[SHOULD]` After all prerequisites pass, run `aspire new aspire-starter --dry-run`
  (or equivalent) as a smoke test that the full Aspire toolchain is
  functional end-to-end.
- `[MUST-NOT]` Proceed to the build phase if any prerequisite is missing or
  reports an error. Flag the status as BLOCKED with the specific missing
  tool and install instructions.

### Auto-Remediation

When a prerequisite is missing and the builder has terminal access, it
SHOULD attempt automatic installation:

1. **.NET SDK missing or outdated:** Run the appropriate installer for the
   detected OS, targeting the version specified in `technical-specification.md`.
2. **Aspire CLI missing:** Run the install script above.
3. **Container runtime not running:** Attempt `open -a Docker` (macOS) or
   `systemctl start docker` (Linux). If not installed, flag as BLOCKED.
4. **After any auto-install:** Re-run the verification command to confirm
   success before proceeding.

---

## 0.1 General Guidance

- `[MUST]` Keep an aspire project at the top level of the project a sibling to the src directory. This keeps aspire which is a development time concept separate from the core project. So it should look like this:

```plaintext
project/
   |___aspire/
          |__ AppHost/
          |__ ServiceDefaults/
   |__src/
```

- `[MUST]` Always ensure the aspire app host is configured to utilize the same .Net SDK version as the overall project.

---

## 1. AppHost Orchestration

- `[MUST]` Use a single AppHost project as the orchestration entry point for the entire distributed application — the AppHost is the conductor that defines all services, infrastructure, and their relationships.
- `[MUST]` Require .NET 10.0+ SDK for the AppHost project, even when orchestrating non-.NET workloads.
- `[MUST]` Require a container runtime (Docker Desktop, Podman, or Rancher Desktop) to be available for container-based resources.
- `[MUST]` Use `DistributedApplication.CreateBuilder(args)` as the standard AppHost entry point pattern.
- `[SHOULD]` Use project templates (`aspire new aspire-starter`, `aspire-apphost-singlefile`, etc.) to scaffold new projects rather than hand-creating AppHost structure.
- `[SHOULD]` Keep the AppHost's `Program.cs` declarative and readable — it should read as a topology map of the distributed system.

## 2. Resource Model & Dependencies

- `[MUST]` Use `.WithReference()` to wire dependencies between resources — this injects connection strings/endpoint URLs as environment variables and creates dependency edges in the resource DAG.
- `[MUST]` Use `.WaitFor()` in combination with `.WithReference()` when a downstream service requires the dependency to be healthy before starting — `.WithReference()` alone creates a dependency edge but does not gate on health.
- `[MUST]` Give every resource a meaningful, unique name that reflects its role (`"catalog-db"`, `"cart-cache"`, `"order-api"`) — resource names become environment variable keys and appear in the dashboard.
- `[SHOULD]` Use `.WithHttpEndpoint(targetPort: N)` to declare what port your service listens on — let DCP auto-assign external ports unless a fixed port is required.
- `[SHOULD]` Use `.WithExternalHttpEndpoints()` to mark services that need external access in deployment (maps to ingress/load balancer).
- `[SHOULD]` Use `.WithReplicas(n)` for services that should scale — this maps to Kubernetes replicas and Azure Container Apps min replicas on publish.
- `[SHOULD-NOT]` Create circular dependencies between resources — the dependency DAG must remain acyclic.

## 3. Service Discovery & Configuration

- `[MUST]` Use environment-variable-based service discovery — Aspire automatically injects `ConnectionStrings__<name>` for infrastructure and `services__<name>__<scheme>__0` for HTTP services. Read these via standard configuration APIs in each language.
- `[MUST]` Map every Aspire resource output to explicit configuration keys using `.WithEnvironment()` when the default injection pattern is insufficient — every injected value must be representable as a production environment variable without Aspire.
- `[MUST]` Use `builder.Configuration.GetConnectionString("name")` in .NET services, `os.environ["ConnectionStrings__name"]` in Python, `process.env.ConnectionStrings__name` in JavaScript, etc.
- `[MUST]` Use `AddParameter("name", secret: true)` for secrets — secrets are prompted at runtime, not logged, and map to Key Vault / Kubernetes Secrets on publish.
- `[SHOULD]` Use `IOptions<T>` with `BindConfiguration()` and `ValidateDataAnnotations().ValidateOnStart()` in .NET services to bind Aspire-injected configuration to strongly-typed options.
- `[SHOULD]` Store parameters in User Secrets (`dotnet user-secrets`) for local development — never hardcode secrets in AppHost code.
- `[SHOULD-NOT]` Rely on opaque service discovery mechanisms that cannot be mirrored in production without Aspire — every configuration value should be transparent and overridable.

## 4. Configuration Flow & Production Parity

- `[MUST]` Keep Aspire hosting packages (`Aspire.Hosting.*`) exclusively in the AppHost project — application projects must not reference Aspire hosting packages.
- `[MUST]` Ensure every value injected by the AppHost can be set in production as standard environment variables or config files without Aspire — production parity is non-negotiable.
- `[MUST]` Application code must bind to `IOptions<T>` or `IConfiguration` only — never consume Aspire client packages or service discovery directly in application code.
- `[SHOULD]` Use `WithReference(db, "ConnectionName")` to set explicit connection string names rather than relying on resource name defaults when clarity is needed.
- `[SHOULD]` Drive feature toggles through AppHost configuration (`WithEnvironment("Feature__Enabled", "true")`) so dev/test/production parity is maintained via the same config mechanism.
- `[SHOULD-NOT]` Hide configuration behind Aspire-only abstractions that disappear in production.

## 5. ServiceDefaults Pattern

- `[MUST]` Create a `ServiceDefaults` shared project for all .NET services that standardizes OpenTelemetry, health checks, and resilience configuration.
- `[MUST]` Call `builder.AddServiceDefaults()` in every .NET service's `Program.cs` and `app.MapDefaultEndpoints()` to expose `/health` and `/alive` endpoints.
- `[SHOULD]` Configure resilience policies (retries, circuit breakers via Polly) in ServiceDefaults for consistent cross-service resilience behavior.
- `[SHOULD]` Configure OpenTelemetry exporters in ServiceDefaults — tracing, metrics, and structured logging should be standardized across all .NET services.

## 6. Integrations

- `[MUST]` Follow the two-package pattern: hosting package (`Aspire.Hosting.*`) in the AppHost, client package (`Aspire.*`) in the service. Never mix these.
- `[MUST]` Use `aspire add <integration>` CLI command to install integrations — ensures correct package versions and configuration.
- `[SHOULD]` Use the Aspire MCP server tools (`list_integrations`, `get_integration_docs`) or `aspire add` interactive mode to discover available integrations rather than searching NuGet manually.
- `[SHOULD]` Use Community Toolkit integrations (`CommunityToolkit.Aspire.*`) for non-Microsoft polyglot workloads (Go, Java, Node.js, Ollama, etc.).
- `[SHOULD]` Let client packages auto-configure health checks, OpenTelemetry, and connection resilience — don't manually re-implement what the integration provides.

## 7. Polyglot Workloads

- `[MUST]` Use the correct `Add*App()` method for each language/runtime: `AddPythonApp()`, `AddNodeApp()`, `AddViteApp()`, `AddGolangApp()`, `AddJavaApp()`, etc.
- `[MUST]` Set `targetPort` on `.WithHttpEndpoint()` to match the port the non-.NET service actually listens on.
- `[MUST]` For any non-.NET executable that serves HTTP (frontend dev servers, API servers), declare its endpoint with `.WithHttpEndpoint(port: <port>, isProxied: false)` so that the Aspire dashboard exposes a clickable URL for the resource. Without this, the resource runs but has no accessible endpoint in the dashboard.
  - Use `isProxied: false` when the executable manages its own HTTP stack and must not be fronted by Aspire's built-in reverse proxy. This applies to all frontend dev servers (Vite, webpack-dev-server, Next.js dev, etc.) because they rely on direct WebSocket connections for hot module reload (HMR).
  - Example for a Vite SPA:
    ```csharp
    builder.AddExecutable("frontend", "npm", "../MyApp.Web", "run", "dev")
        .WithReference(backend)
        .WithHttpEndpoint(port: 5173, isProxied: false);
    ```
- `[SHOULD]` Configure OpenTelemetry manually in non-.NET services, pointing at the OTLP endpoint auto-injected by Aspire (`OTEL_EXPORTER_OTLP_ENDPOINT`).
- `[SHOULD]` Read connection strings and service URLs via standard environment variable APIs in each language — the env var pattern is identical across all runtimes.

### 7.1 Vite / Node.js Frontend Dev Server — Port & Proxy Pattern

**The port 5173 conflict:** Aspire's DCP orchestrator (`dcp run-controllers`) always binds port **5173** for its own API server. Do not declare `port: 5173` for a Vite or any other frontend resource — it will conflict with DCP and Vite will fall back to the next available port, causing URL mismatches.

- `[MUST-NOT]` Use port 5173 for `AddNpmApp` / `AddViteApp` `.WithHttpEndpoint()` — that port is reserved by Aspire's DCP process.
- `[MUST]` Use `env: "VITE_PORT"` (or equivalent) on `.WithHttpEndpoint()` so Aspire injects the assigned port into the Vite process, and read it in `vite.config.ts`:

  ```csharp
  // AppHost
  builder.AddNpmApp("web", "../MyApp.Web", "dev")
      .WithReference(api)
      .WithHttpEndpoint(port: 5174, env: "VITE_PORT")  // NOT 5173
      .WithEnvironment("BROWSER", "none");
  ```

  ```ts
  // vite.config.ts — read the injected port, don't hardcode
  export default defineConfig({
    server: {
      port: parseInt(process.env.VITE_PORT || "5174"),
    },
  });
  ```

- `[MUST]` Use **Vite's dev server proxy** to forward `/api/*` requests to the backend — do not set `VITE_API_BASE_URL` to an absolute `http://localhost:<port>` URL. Absolute URLs create cross-origin requests that require CORS. The proxy keeps all browser traffic on a single origin.

  ```ts
  // vite.config.ts
  export default defineConfig({
    server: {
      port: parseInt(process.env.VITE_PORT || "5174"),
      proxy: {
        // Use the Aspire-injected service URL as the proxy target
        "/api": process.env.services__api__http__0 || "http://localhost:5000",
      },
    },
  });
  ```

  ```ts
  // src/api/client.ts — relative base URL, no hostname
  const BASE_URL = (import.meta.env.VITE_API_BASE_URL as string) ?? "";
  // fetch('/api/games') → proxied by Vite → no CORS
  ```

- `[MUST-NOT]` Configure CORS on the API to allow the frontend origin when both are managed by Aspire — that is a sign the frontend is calling the API directly instead of through the Vite proxy. CORS configuration on the API is only needed when the frontend and API are deployed to genuinely different origins in production.

- `[SHOULD]` Keep `VITE_API_BASE_URL` empty (or absent) in `.env.development` when the Vite proxy is in use. An absolute value here will bypass the proxy and trigger cross-origin requests.

## 8. Health Checks & Resource Lifecycle

- `[MUST]` Expose health check endpoints (`/health`, `/alive`) in every service — Aspire and deployment platforms rely on these for readiness and liveness probes.
- `[MUST]` Use `.WaitFor()` on resources that must be healthy before dependents start — e.g., databases must be ready before API services.
- `[SHOULD]` Use custom health checks (`.WithHealthCheck("ready", "/health/ready")`) when the default integration health checks are insufficient.
- `[SHOULD]` Use the eventing system (`builder.Eventing.Subscribe<BeforeResourceStartedEvent>()`) for lifecycle hooks like database migration before service start.
- `[SHOULD]` Understand resource lifecycle states: `NotStarted → Starting → Running → Stopping → Stopped`, with `FailedToStart` and `RuntimeUnhealthy → Restarting` branches.

## 9. Smoke Test Orchestration

When Aspire is used, the smoke test phase must exercise the full AppHost — not individual services in isolation.

- `[MUST]` Start the Aspire AppHost (`aspire run` or `dotnet run` on the AppHost project) during the smoke test phase. Do not start services individually — the AppHost manages service discovery, port allocation, and dependency ordering.
- `[MUST]` Verify all declared resources reach `Running` state. Use the Aspire Dashboard API or poll resource health endpoints in dependency order (databases → backends → frontends).
- `[MUST]` Verify the frontend resource binds to its configured port (not a fallback port). A fallback port indicates a port conflict that will break proxy routing and service discovery URLs.
- `[MUST]` Verify at least one API call completes through the frontend's proxy path (browser → Vite proxy → API → database → response). This confirms service discovery URLs, proxy configuration, and CORS-free same-origin routing all function correctly.
- `[MUST-NOT]` Accept a smoke test pass if the frontend binds to a different port than configured — this indicates a port conflict that will break proxy routing.
- `[SHOULD]` Check the Aspire Dashboard for resource health warnings or restart loops before declaring smoke test success.
- `[SHOULD]` Verify inter-service communication by confirming the API can reach its database and any dependent services through Aspire-injected connection strings.

## 10. Testing

- `[MUST]` Use `Aspire.Hosting.Testing` package with `DistributedApplicationTestingBuilder` for integration tests — tests spin up the full AppHost with real containers.
- `[MUST]` Use `await using` on the built application to ensure proper cleanup even on test failure.
- `[MUST]` Call `app.WaitForResourceReadyAsync("resource-name")` before making requests in tests — ensures all dependencies are healthy.
- `[MUST]` Use `app.CreateHttpClient("service-name")` to get pre-configured HTTP clients for service under test.
- `[SHOULD]` Set reasonable test timeouts (`[Fact(Timeout = 120_000)]`) since container startup adds latency.
- `[SHOULD]` Use `--exclude-resource` argument to exclude resources not needed for specific test scenarios.
- `[SHOULD]` Use test-specific configuration overrides via `builder.Configuration["key"] = "value"` for test isolation.
- `[SHOULD]` Mark test projects with `<IsAspireTestProject>true</IsAspireTestProject>` in the `.csproj`.
- `[SHOULD-NOT]` Rely on state from previous tests — each test should be independent.

## 11. Deployment & Publishing

- `[MUST]` Use `aspire publish` to generate deployment manifests — Aspire does not deploy directly; it generates artifacts (Docker Compose, Kubernetes YAML/Helm, Bicep for Azure).
- `[MUST]` Review generated deployment manifests before applying — verify resource mappings, secrets handling, and network configuration.
- `[MUST]` Use `AddParameter("name", secret: true)` for all secrets — these map to `.env` files (Docker), Kubernetes Secrets, or Azure Key Vault references on publish.
- `[SHOULD]` Use conditional resource configuration for environment-specific behavior: `RunAsEmulator()` for local dev, real cloud resources for publish mode (`builder.ExecutionContext.IsPublishMode`).
- `[SHOULD]` Integrate `aspire publish` into CI/CD pipelines — generate manifests in the build step, deploy via standard infrastructure tooling (Helm, Bicep, Terraform).
- `[SHOULD]` Use `PublishAsDockerFile()` when custom Dockerfile control is needed for specific services.
- `[SHOULD-NOT]` Deploy Aspire applications without reviewing the generated manifest — auto-generated configuration may not match production requirements.

## 12. Dashboard & Observability

- `[MUST]` Use the Aspire Dashboard (auto-launched with `aspire run`) for real-time observability during development — it surfaces logs, traces, and metrics across all services.
- `[SHOULD]` Use the Dashboard's GenAI Visualizer for tracing AI/LLM call flows when building AI-powered applications.
- `[SHOULD]` Use structured logging correlated with distributed trace context — Aspire auto-configures this for .NET services via ServiceDefaults.
- `[SHOULD]` Configure non-.NET services to export telemetry via OTLP to appear in the Dashboard.

## 13. Security

- `[MUST]` Never hardcode secrets (connection strings, API keys, passwords) in AppHost code — use `AddParameter("name", secret: true)` and resolve from User Secrets, environment variables, or Key Vault.
- `[MUST]` Use connection string parameterization for database passwords: `builder.AddPostgres("db", password: dbPassword)`.
- `[SHOULD]` Use managed identity in Azure deployments instead of connection strings with embedded credentials.
- `[SHOULD]` Enable SSL/TLS for all inter-service communication in production deployments — see **Section 14** for Aspire certificate configuration APIs.
- `[SHOULD-NOT]` Commit `.env` files or User Secrets to version control.

## 14. SSL / TLS Certificate Configuration

> **Reference:** [Certificate Configuration](https://aspire.dev/app-host/certificate-configuration/)

Aspire provides two complementary certificate API surfaces:

1. **HTTPS endpoint APIs** — configure the certificate a resource presents when serving HTTPS traffic (server authentication).
2. **Certificate trust APIs** — configure which certificates a resource trusts when making outbound HTTPS connections (client authentication / dashboard telemetry).

Both apply at **run time only** — custom certificates are _not_ included in publish or deployment artifacts.

### 14.1 Trusting the Development Certificate

- `[MUST]` Ensure the Aspire development certificate is trusted before starting any HTTPS work. The recommended approach is the Aspire CLI:

  ```bash
  # Trust the dev certificate (one-time)
  aspire certs trust

  # If you encounter unexpected HTTPS / cert trust errors, reset:
  aspire certs clean
  aspire certs trust
  ```

  When you run `aspire run`, the CLI automatically ensures the certificate is created and trusted.

- `[MUST]` On **Linux**, applications using OpenSSL will not discover the dev certificate unless `SSL_CERT_DIR` includes `~/.aspnet/dev-certs/trust`. Add the following to `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

  ```bash
  if [ -z "$SSL_CERT_DIR" ]; then
      export SSL_CERT_DIR="/usr/lib/ssl/certs:$HOME/.aspnet/dev-certs/trust"
  else
      export SSL_CERT_DIR="$SSL_CERT_DIR:$HOME/.aspnet/dev-certs/trust"
  fi
  ```

### 14.2 HTTPS Endpoint Configuration (Server-Side)

- `[MUST]` Use `WithHttpsDeveloperCertificate()` on non-.NET resources (Node.js, Python, containers) that need to serve HTTPS traffic during local development:

  ```csharp
  var frontend = builder.AddViteApp("frontend", "../frontend")
      .WithHttpsDeveloperCertificate();

  // With encrypted private key
  var certPassword = builder.AddParameter("cert-password", secret: true);
  var api = builder.AddUvicornApp("api", "../api", "app:main")
      .WithHttpsDeveloperCertificate(certPassword);
  ```

- `[SHOULD]` Use `WithHttpsCertificate(certificate)` when a resource must present a specific X.509 certificate (e.g., corporate / mTLS scenarios):

  ```csharp
  var cert = new X509Certificate2("path/to/certificate.pfx", "password");
  builder.AddContainer("api", "my-api:latest")
      .WithHttpsCertificate(cert);
  ```

- `[SHOULD]` Use `WithHttpsCertificateConfiguration(ctx => { ... })` for resources that require custom certificate file paths, environment variables, or command-line arguments:

  ```csharp
  builder.AddContainer("api", "my-api:latest")
      .WithHttpsCertificateConfiguration(ctx =>
      {
          ctx.EnvironmentVariables["TLS_CERT_FILE"] = ctx.CertificatePath;
          ctx.EnvironmentVariables["TLS_KEY_FILE"]  = ctx.KeyPath;
          return Task.CompletedTask;
      });
  ```

  The callback provides `CertificatePath` (PEM), `KeyPath` (PEM), `PfxPath` (PKCS#12), and optional `Password`.

- `[SHOULD]` Use `WithoutHttpsCertificate()` on resources that do not support HTTPS or that manage their own certificates:

  ```csharp
  var redis = builder.AddRedis("cache")
      .WithoutHttpsCertificate();
  ```

### 14.3 Certificate Trust Configuration (Client-Side)

- `[MUST]` Use `WithDeveloperCertificateTrust(true)` on resources that need to trust the dev certificate for outbound connections (e.g., dashboard OTLP telemetry):

  ```csharp
  var frontend = builder.AddNpmApp("frontend", "../frontend")
      .WithHttpsDeveloperCertificate()        // serve HTTPS
      .WithDeveloperCertificateTrust(true);   // trust dev cert for outbound
  ```

- `[SHOULD]` Use `AddCertificateAuthorityCollection()` to bundle and distribute custom / corporate CA certificates:

  ```csharp
  var certs = new X509Certificate2Collection();
  certs.ImportFromPemFile("corporate-ca.pem");

  var caBundle = builder.AddCertificateAuthorityCollection("corporate-certs")
      .WithCertificates(certs);

  builder.AddNpmApp("my-project", "../myapp")
      .WithCertificateAuthorityCollection(caBundle);
  ```

- `[SHOULD]` Set `WithCertificateTrustScope()` appropriately for each resource type:

  | Scope      | Behaviour                                                   | Default For         |
  | ---------- | ----------------------------------------------------------- | ------------------- |
  | `Append`   | Adds custom certs to existing trust store                   | Node.js, containers |
  | `System`   | Combines custom + system root certs, replaces default store | Python              |
  | `Override` | Replaces default store with only configured certs           | —                   |
  | `None`     | Disables all custom cert trust; uses platform defaults      | .NET on Windows     |

  Python does not natively support `Append` mode — use `System` (the default for Python resources).

### 14.4 Common Patterns

**Service with HTTPS + dashboard telemetry:**

```csharp
builder.AddNpmApp("frontend", "../frontend")
    .WithHttpsDeveloperCertificate()      // HTTPS endpoints
    .WithDeveloperCertificateTrust(true); // trust dashboard cert for OTLP
```

**Redis with TLS:**

```csharp
builder.AddRedis("cache")
    .WithHttpsDeveloperCertificate();
```

**Corporate CA + custom server cert:**

```csharp
var serverCert = new X509Certificate2("server-cert.pfx", "password");
var customCA   = new X509Certificate2Collection();
customCA.Import("corporate-ca.pem");

var caBundle = builder.AddCertificateAuthorityCollection("corporate-certs")
    .WithCertificates(customCA);

builder.AddContainer("api", "my-api:latest")
    .WithHttpsCertificate(serverCert)
    .WithCertificateAuthorityCollection(caBundle);
```

**Disable all automatic cert configuration:**

```csharp
builder.AddPythonModule("api", "./api", "uvicorn")
    .WithoutHttpsCertificate()
    .WithCertificateTrustScope(CertificateTrustScope.None);
```

### 14.5 Limitations

- Certificate configuration APIs are **run-mode only** — they do not affect `aspire publish` output.
- These APIs are marked as experimental (`ASPIRECERTIFICATES001`).
- Not all runtimes support all trust scopes (notably Python and `Append`).
- Custom certificate configuration requires the target resource to support TLS natively.

---

## 15. Migration from Docker Compose

- `[SHOULD]` Map Docker Compose services to Aspire resources: `services` → `AddContainer()` / `AddProject<T>()`, `depends_on` → `.WithReference()` + `.WaitFor()`, `ports` → `.WithHttpEndpoint()`, `environment` → `.WithEnvironment()`.
- `[SHOULD]` Start with `aspire new aspire-apphost-singlefile` for an empty AppHost and incrementally replace Docker Compose services.
- `[SHOULD]` Use `AddDockerComposeFile()` to reference existing Docker Compose files during gradual migration.

---

## Completion Checklist — AppHost Structure

- [ ] Single AppHost project orchestrates all services ← COMMONLY MISSED
- [ ] Every resource has a meaningful, unique name
- [ ] `.WithReference()` used for all inter-service dependencies
- [ ] `.WaitFor()` used for dependencies that must be healthy before dependents start ← COMMONLY MISSED
- [ ] Secrets use `AddParameter("name", secret: true)`, not hardcoded values
- [ ] ServiceDefaults project created and referenced by all .NET services

## Completion Checklist — Configuration & Production Parity

- [ ] Aspire hosting packages only in AppHost (not in application projects) ← COMMONLY MISSED
- [ ] Application code uses `IOptions<T>` / `IConfiguration` only (no Aspire client packages) ← COMMONLY MISSED
- [ ] Every AppHost-injected value representable as standard env vars in production
- [ ] Feature toggles driven through `WithEnvironment()` for dev/test/prod parity
- [ ] Connection string names explicit via `WithReference(resource, "ConnectionName")`

## Completion Checklist — SSL / TLS Certificates

- [ ] Development certificate trusted via `aspire certs trust` before first run ← COMMONLY MISSED
- [ ] On Linux: `SSL_CERT_DIR` includes `~/.aspnet/dev-certs/trust` in shell profile
- [ ] Non-.NET resources serving HTTPS use `WithHttpsDeveloperCertificate()`
- [ ] Resources needing outbound HTTPS to dashboard use `WithDeveloperCertificateTrust(true)` ← COMMONLY MISSED
- [ ] Certificate trust scope set appropriately per resource type (especially `System` for Python)
- [ ] Resources that manage their own certs use `WithoutHttpsCertificate()` / `CertificateTrustScope.None`

## Completion Checklist — Deployment

- [ ] `aspire publish` used to generate deployment manifests (not manual creation)
- [ ] Generated manifests reviewed before applying ← COMMONLY MISSED
- [ ] Conditional resources used: emulators locally, real services in publish mode
- [ ] CI/CD pipeline integrates `aspire publish` as a build step
- [ ] Secrets map to appropriate platform mechanism (Key Vault, K8s Secrets, `.env`)

## Completion Checklist — Testing & Observability

- [ ] Integration tests use `DistributedApplicationTestingBuilder` with real containers
- [ ] `WaitForResourceReadyAsync()` called before test assertions ← COMMONLY MISSED
- [ ] Tests use `await using` for proper cleanup
- [ ] Health endpoints (`/health`, `/alive`) exposed on all services ← COMMONLY MISSED
- [ ] Non-.NET services export OTLP telemetry to Aspire Dashboard
- [ ] Dashboard used during development for logs, traces, and metrics

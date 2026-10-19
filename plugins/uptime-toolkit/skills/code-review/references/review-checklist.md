# Uptime-app code-review checklist

Use this checklist after static checks. Mark each applicable section as reviewed and cite evidence in the final report. “Good” describes evidence to look for; “Bad” describes review signals. The checklist is a decision aid, not a reason to report stylistic preferences as defects.

## Always review

### Correctness and regression

Good:

- The changed behavior is consistent with existing callers, API responses, error conventions, and persistence semantics.
- Success, failure, empty, malformed, timeout, retry, and concurrent paths are intentional.
- Existing behavior that must remain stable is covered by tests or preserved by the implementation.

Bad:

- A changed field, status code, route, cookie, error, or generated contract is incompatible with a caller.
- Errors are swallowed, converted to success, or exposed with misleading status and messages.
- Partial updates leave inconsistent state, retries duplicate side effects, or a race is possible.

### Security, secrets, and privacy

Good:

- Authorization is enforced at the boundary and again where ownership matters; untrusted input is validated and constrained.
- Passwords/tokens are hashed or protected appropriately, cookies have deliberate `Secure`, `HttpOnly`, `SameSite`, expiry, and scope settings, and logs exclude credentials and personal data.
- SQL uses parameters/ORM safely; file uploads validate size/type/content and use controlled names and locations; browser output is escaped by default.
- Secrets are injected through configuration and absent from source, tests, logs, generated artifacts, and client bundles.

Bad:

- Authentication is treated as authorization, user-controlled IDs bypass ownership checks, or a new endpoint is accidentally public.
- JWT/cookie/token validation accepts the wrong algorithm, missing claims, expired/revoked credentials, or unsafe cross-origin requests.
- Hardcoded API keys, passwords, private keys, bearer tokens, `.env` values, or sensitive debug output appear in the diff.
- Dynamic SQL, shell execution, unsafe HTML, open redirects, path traversal, unrestricted uploads, or overly broad CORS is introduced.

### Tests and verification

Good:

- Tests target changed business rules and security boundaries, include meaningful failure cases, and are deterministic.
- Integration tests cover persistence/API behavior when mocks would hide contract or transaction problems.
- Static checks and relevant tests pass, and unavoidable coverage gaps are stated.

Bad:

- Only the happy path is tested for authentication, input validation, migrations, state changes, or concurrent behavior.
- Tests assert implementation details while missing externally observable behavior.
- A changed critical path has no regression test and the diff gives no strong reason why.

## Backend sections

### Go idioms and reliability

Good:

- `gofmt`, idiomatic names, wrapped/contextual errors where useful, correct `context.Context` propagation, bounded work, and explicit resource cleanup.
- Goroutines have cancellation/ownership, channels have clear lifecycle, shared state is synchronized, and timeouts prevent stuck requests or probes.
- Public identifiers have useful doc comments; comments explain why rather than restating code.

Bad:

- Ignored errors, unchecked type assertions, nil dereferences, leaked bodies/files/rows, unbounded goroutines, lost cancellation, or data races.
- Package names, exported APIs, or error handling violate Go conventions without a reason.

### Layering and API contract

Good:

- HTTP handlers decode/validate transport input, call a service, and map domain errors to responses.
- Services own business invariants and orchestration; repositories own queries; models do not become a hidden transport contract.
- New/changed routes have complete Swaggo annotations and regenerated `backend/docs/` artifacts, and migrations match model/query changes.

Bad:

- SQL/GORM calls or business policy appear in handlers, service code writes HTTP responses, or repository code knows about users’ HTTP identity.
- A route, request/response, status code, auth requirement, migration, or generated OpenAPI document is changed out of sync.

### Data and migration safety

Good:

- Constraints, indexes, nullability, ownership, and transaction boundaries match the domain; migrations are ordered and safe for existing data.
- Queries use context and parameters, handle not-found distinctly, and do not accidentally expose password hashes or private fields.

Bad:

- Destructive/non-backward-compatible schema changes lack a rollout path, down migration, or data preservation plan.
- N+1 queries, missing ownership filters, unconstrained pagination, or a read-modify-write race is introduced.

## Frontend sections

### Next.js and React boundaries

Good:

- Server components remain server-side when possible; client components are limited to interactive/browser-only behavior and receive serializable props.
- Async/loading/error/empty states, cancellation or stale-response handling, and navigation/auth redirects are deliberate.
- Data fetching, auth storage, and API errors follow the existing client conventions.

Bad:

- Secrets, privileged tokens, database access, or server-only modules reach a client bundle or `NEXT_PUBLIC_*` variable.
- A component reads browser APIs during server rendering, causes hydration mismatch, performs effects without cleanup, or refetches in a loop.
- User input is rendered as unsafe HTML, a request can be forged cross-origin, or an auth failure leaves protected content visible.

### TypeScript, UI, and accessibility

Good:

- Types describe actual API/domain shapes; nullability and errors are handled explicitly; components and handlers have clear names.
- Forms have labels, keyboard access, focus/error feedback, semantic elements, and useful loading/disabled states.
- Shared behavior is extracted only when it reduces duplication without obscuring a feature.

Bad:

- `any`, non-null assertions, type casts, or duplicated API shapes hide a real runtime possibility.
- Missing labels/alt text, inaccessible custom controls, unannounced errors, broken responsive layout, or buttons that submit unexpectedly.
- Dead imports/components, unreachable branches, stale state, or duplicated constants make future changes unsafe.

## Cross-cutting and dependency changes

Check package/module lockfiles, version compatibility, licenses where the project requires it, reproducible installs, CI/build scripts, generated files, and environment defaults. Flag a dependency update that is unpinned, unexplained, breaks the lockfile, expands privileges, or has known security implications supported by repository evidence.

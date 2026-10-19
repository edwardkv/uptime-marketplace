---
name: code-review
description: Review diffs in the uptime-app Go backend and Next.js frontend, run targeted static checks first, and report actionable findings ordered from P0 to P3.
metadata:
  short-description: Review uptime-app diffs by stack and priority
---

# Code review for uptime-app

Review the requested commit, branch, or working-tree diff in this repository. The result is a prioritized list of findings, not a rewrite of the code. Do not change application files while reviewing unless the user explicitly asks for a fix.

## Required workflow

1. Establish the review scope before reading implementation details:
   - Inspect `git status --short --branch`.
   - Identify the comparison point. For a commit use `git diff <commit>^ <commit>`; for a branch use `git diff <merge-base>...HEAD`; for uncommitted work include staged and unstaged changes with `git diff HEAD` and `git diff --cached`.
   - Read the complete diff and list changed paths. Use the merge-base or explicit commit supplied by the user; do not silently review an unrelated range.
   - Read relevant `AGENTS.md` files and the current implementation around each changed area. A diff alone is insufficient for behavior, ownership, and security review.
2. Run the targeted checks before making review conclusions:
   ```bash
   .codex/skills/code-review/scripts/static_checks.sh --changed-files <changed-path>...
   ```
   Pass every changed path. The script runs Go checks only when `backend/` is affected and Next.js checks only when `frontend/` is affected. If the script cannot run because a required tool or dependency is missing, record that as review context and do not claim the checks passed.
3. Read [references/review-checklist.md](references/review-checklist.md) completely. Apply only the sections selected by the changed paths, plus the always-on security, secrets, correctness, and maintainability sections. Do not skip a selected section because a linter passed.
4. Trace each changed behavior through its layers and callers. Check both the happy path and failure, timeout, authorization, empty, and malformed-input paths where applicable. Compare API behavior with its callers and, for backend routes, with Swaggo annotations and generated docs.
5. Report findings only when they are actionable and supported by the diff or repository evidence. For each finding include:
   - priority (`P0`, `P1`, `P2`, or `P3`),
   - file and line (or the closest changed line),
   - what is wrong and why it matters,
   - a concrete correction direction.
6. End with a compact summary of checks run, affected areas, test/coverage gaps, and explicit “no findings” statements for reviewed sections. Order findings by priority, then by file.

## Scope routing

- `backend/`, Go files, SQL migrations, backend configuration, Docker/backend deployment files: apply the backend, data, API, and security sections.
- `frontend/`, TypeScript/TSX/CSS, Next configuration, ESLint, or frontend package files: apply the frontend, accessibility, client/server-boundary, and security sections.
- CI, scripts, dependency manifests, generated API docs, or shared configuration: apply dependency/reproducibility, security, and regression sections; inspect both consumers when behavior can cross the boundary.
- Documentation-only changes: review correctness and consistency, but do not invent application findings.

## Project architecture to enforce

### Backend

The backend is a Go service. `cmd/server` wires configuration, database, repositories, services, and HTTP transport. Keep application-only code under `internal/`:

- `internal/http`: routing, decoding/encoding, authentication middleware, status codes, and transport-specific validation. Handlers should stay thin.
- `internal/service`: business rules, orchestration, validation that represents domain behavior, authentication/token policy, and use-case errors.
- `internal/repository`: persistence queries and storage concerns. Repositories accept `context.Context` and must not own HTTP concerns.
- `internal/model`: persistence/domain data structures and explicit serialization choices.
- `internal/config`: environment and runtime configuration; secrets come from configuration, never source literals.
- `internal/migration`: versioned schema changes, with reversible `up`/`down` migrations when the project convention supports it.
- `pkg`: only packages intentionally reusable by external consumers.

Flag transport handlers that contain business rules, services that build HTTP responses, repositories that decide authorization, direct database access from handlers/services, or new cross-layer shortcuts without a compelling boundary reason.

### Frontend

The frontend is Next.js 16 with the App Router. Routes, pages, layouts, and global styles belong in `frontend/src/app`; reusable UI belongs in `src/components`; browser/API/auth helpers belong in `src/lib`. Preserve the server/client boundary: use `"use client"` only where browser state or events require it, keep secrets and privileged operations server-side, and do not edit `.next/` generated output. Follow the existing two-space TypeScript style, PascalCase components/types, and camelCase variables/functions.

## Review discipline

- Treat security and data exposure as first-class findings: authentication/authorization, token and cookie handling, input validation, injection, unsafe file handling, XSS, CSRF/CORS, sensitive logging, secret leakage, dependency risk, and insecure defaults.
- Check tests for changed behavior, not just changed lines. Missing tests are a finding when a regression would be plausible or the change is security-, data-, or state-sensitive. Do not demand tests for trivial wiring without risk.
- Check names, dead code, duplicated logic, error propagation, context/timeouts, resource cleanup, race-prone state, accessibility, loading/error/empty states, and API contract consistency when relevant.
- Distinguish a real defect from a preference. Mention positive evidence briefly, but reserve findings for changes that should be corrected.
- Do not downgrade a vulnerability because it is outside the changed lines if the diff introduces or exposes the path. Do not report pre-existing unrelated issues unless the change makes them relevant.

## Priority rubric

- **P0** — immediate critical risk: exploitable security issue, secret exposure, data loss/corruption, authentication bypass, or a production-critical path that cannot work. Recommend stopping merge/release.
- **P1** — high-impact defect: likely authorization/data-integrity failure, severe outage or crash, broken API contract, unsafe migration, or regression in a core user flow. Fix before merge.
- **P2** — meaningful correctness, reliability, maintainability, accessibility, or test gap that should be fixed soon but does not make the change unsafe to release by itself.
- **P3** — low-risk cleanup or clarity issue: naming, duplication, minor dead code, non-critical documentation, or an improvement with limited immediate impact.

If no P0–P3 findings exist, say so explicitly. Never manufacture a priority merely to fill the scale.

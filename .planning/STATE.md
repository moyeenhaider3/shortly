# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-15)

**Core value:** The Flutter app works unchanged against `backend-nest` (same routes, status codes, envelope, error codes as Express), and the developer understands every NestJS concept used.
**Current focus:** Phase 1 — Foundation & Config
**Working mode:** Mentorship. Claude explains and gives snippets, the developer writes all `backend-nest/` code, Claude reviews, then this file is updated.

## Current Position

Phase: 1 of 9 (Foundation & Config)
Plan: 1 of 4 in current phase
Step: 01-01 verified; next 01-02 (Docker Postgres) + 01-03 (ConfigModule) taken together for speed
Status: In progress
Last activity: 2026-10-15 — 01-01 done: Nest scaffold (CJS, npm, oxlint), port 5001, hot reload and lint verified

Progress: [█░░░░░░░░░] 3%

## Performance Metrics

**Velocity:**
- Total plans completed: 1
- Average duration: -
- Total execution time: -

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: PostgreSQL + Prisma in Docker (host 5433); Nest on 5001; separate JWT secret
- [Init]: Admins see all active links on `GET /api/urls` in Nest (deliberate divergence from Express)
- [Init]: Small steps: one concept and 1–3 files per step, verified before moving on
- [Init]: Work on branch `nest-backend`; never push to `main`

### Concepts Learned

<!-- Append as each concept is introduced and verified, e.g. "Phase 1 / 01-01: Modules, providers, DI". Used to avoid re-explaining and to build on prior knowledge. -->

- 01-01: Module / controller / provider; constructor dependency injection; NestFactory bootstrap; hot reload (`start:dev`); CJS chosen over ESM; scaffold uses oxlint (not ESLint)

### Pending Todos

None yet.

### Blockers/Concerns

- Node: `backend-nest/.nvmrc` = 24 (matches Express). Developer's machine runs v26 and has no version manager; fnm was recommended, install status unknown.
- `*.tsbuildinfo` still missing from `backend-nest/.gitignore` (build cache shows as untracked).
- backend-nest not yet committed (developer staging it).

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-10-15
Stopped at: 01-01 complete; guiding 01-02 + 01-03 together
Resume file: None

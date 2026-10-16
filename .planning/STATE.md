---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Phase 1 complete; next is `/gsd-plan-phase 2`, then guide 02-01 (AppException + global exception filter)
last_updated: "2026-10-15T09:58:22.377Z"
last_activity: 2026-10-15 -- Phase 2 planning complete
progress:
  total_phases: 9
  completed_phases: 0
  total_plans: 9
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-15)

**Core value:** The Flutter app works unchanged against `backend-nest` (same routes, status codes, envelope, error codes as Express), and the developer understands every NestJS concept used.
**Current focus:** Phase 3 — Data Layer with Prisma
**Working mode:** Mentorship. Claude explains and gives snippets, the developer writes all `backend-nest/` code, Claude reviews, then this file is updated.

## Current Position

Phase: 3 of 9 (Data Layer with Prisma)
Plan: 2 of 4 in current phase (03-01, 03-02 complete)
Step: next is 03-03 (idempotent seed); 03-04 (transactional recordVisit) after it
Status: In progress
Last activity: 2026-10-16 -- 03-02 reviewed and verified

Progress: [█░░░░░░░░░] 11%

## Performance Metrics

**Velocity:**

- Total plans completed: 5
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
- [03-01]: Prisma pinned to exactly 7.10.1 (npm `latest` of `prisma` is the 8.0 RC with a different workflow); generated client in `src/generated/prisma` (git-ignored)
- [Process]: Every command/snippet needs an explanation and a file-link map (developer request; also in CLAUDE.md)

### Concepts Learned

<!-- Append as each concept is introduced and verified, e.g. "Phase 1 / 01-01: Modules, providers, DI". Used to avoid re-explaining and to build on prior knowledge. -->

- 01-01: Module / controller / provider; constructor dependency injection; NestFactory bootstrap; hot reload (`start:dev`); CJS chosen over ESM; scaffold uses oxlint (not ESLint)
- 01-02: Docker Compose (service, port mapping host:container, named volume, healthcheck); DATABASE_URL anatomy; .env vs .env.example
- 01-03: Dynamic modules (`ConfigModule.forRoot`), `isGlobal`, Joi schema, fail-fast boot, `ConfigService` via `app.get()`; env vars are strings until validated
- 01-04: Feature modules, `nest g` schematics (auto-wire imports/controllers), `@Controller`/`@Get`, returned objects become JSON; Nest runs on Express underneath (`X-Powered-By: Express`)
- 02-01: Exceptions layer; `HttpException`; `AppException` (parameter-property shorthand); `@Catch()` filter + `ArgumentsHost`; `APP_FILTER` (DI-aware global registration); `else if` order because AppException is an HttpException; a controller belongs to one module only
- 02-02: Filter branches by error kind (404, body-parser); Nest wraps parser errors as BadRequestException (type lost), so `bodyParser:false` + own `json()` + error middleware converts to AppException; `NestMiddleware` + `MiddlewareConsumer.forRoutes('*path')`; `NestExpressApplication` for `app.set`; `enableCors`; `@Req()`
- 02-03: Pipes; `ValidationPipe` options (`transform`, `whitelist`, `exceptionFactory`); DTO classes; class-validator decorators with `context` {code, rank}; class-transformer `@Transform`; lowest-rank-wins to mimic first-failure; mass-assignment stripping
- 03-01: Prisma schema language (models, enum, `@id @default(uuid()) @db.Uuid`, `@unique`, nullable unique, `@@index`, relations with `onDelete: Cascade`); relational vs embedded modelling (Visit as a table); unique implies index; Prisma 7 layout (`prisma.config.ts`, `prisma-client` generator with required `output`, generate separate from migrate); `migrate dev`, shadow DB, `migration.sql`, `_prisma_migrations`; npm dist-tags and version pinning
- 03-02: Provider wrapping a third-party client (`extends PrismaClient`); Prisma 7 driver adapter (`@prisma/adapter-pg`); `OnModuleInit`/`OnModuleDestroy`; `enableShutdownHooks()` and signals (SIGINT/SIGTERM); `@Global()` modules + `exports`; constructor injection across modules without imports; raw queries via tagged template (never `*Unsafe` with user input)

### Pending Todos

- Delete `backend-nest/src/demo/` (DemoModule/DemoController, TEMPORARY) once real endpoints cover the error lifecycle (target: Phase 4); remove `DemoModule` from `app.module.ts` too
- Commit `backend-nest/` (developer staging it)
- 03-01 nits: add `"ignorePatterns": ["src/generated/**"]` to `.oxlintrc.json` (not yet there; lint passes today); replace stale 'client lives in node_modules' comment in `backend-nest/.gitignore`; delete stray untracked repo-root `package-lock.json`
- Delete `src/demo/` incl. `GET /demo/db` and `POST /demo/visits` in Phase 4 (keep `CreateUserDto`)
- test/app.e2e-spec.ts still expects the old hello route; rewritten in Phase 7

### Blockers/Concerns

- Node: `backend-nest/.nvmrc` = 24 (matches Express). Developer's machine runs v26 and has no version manager; fnm was recommended, install status unknown.
- `@nestjs/config` is v12 (Standard Schema): Joi options nest under `validationOptions.libraryOptions`.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Testing | 02-04 and 02-05 (`contract-tests/` suite) postponed until all feature topics are covered; run last (developer request, Nest-only focus) | Deferred | 2026-10-16 |

## Session Continuity

Last session: 2026-10-15
Stopped at: Phase 1 complete; next is `/gsd-plan-phase 2`, then guide 02-01 (AppException + global exception filter)
Resume file: None

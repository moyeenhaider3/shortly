# Roadmap: Shortly — NestJS Backend (`backend-nest`)

## Overview

We rebuild the Express backend in NestJS one small, verified step at a time. Phases 1–2 lay the foundation (app, config, Docker Postgres, the exact response/error envelope) and capture a contract-test baseline from Express. Phases 3–5 build the data layer, auth and every feature until the contract suite and the Flutter app pass against `backend-nest`: **parity milestone**. Phases 6–9 then follow the rest of the learning roadmap: API docs and security, testing and observability, async jobs and caching, and finally CI/CD.

Every plan is executed in **mentorship mode** (see PROJECT.md): Claude explains and provides snippets; the developer writes the code; Claude reviews; STATE.md is updated.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Config** - Nest app on 5001, validated config, Postgres in Docker, `/health` (Day 1, Day 9)
- [ ] **Phase 2: Request Lifecycle & Contract Baseline** - Exception filter, envelope, validation pipe, logger; contract suite green against Express (Day 2, Day 8)
- [ ] **Phase 3: Data Layer with Prisma** - Schema, migrations, seed, PrismaService, transactions (Day 3)
- [ ] **Phase 4: Authentication & Authorization** - Signup/login/logout/me, JWT strategy, cookie + Bearer, roles guard (Day 5)
- [ ] **Phase 5: Features & Parity** - URLs, redirect, analytics, admin users; contract suite + Flutter pass against Nest (Day 2, Day 4)
- [ ] **Phase 6: API Docs & Security Hardening** - Swagger, cursor pagination, Helmet, throttling, Argon2, refresh tokens (Day 4, Day 5)
- [ ] **Phase 7: Testing & Observability** - Unit + e2e tests, Pino, correlation ids, Terminus, graceful shutdown, Dockerfile (Day 8, Day 9)
- [ ] **Phase 8: Async Jobs & Performance** - BullMQ click tracking, DLQ, Redis cache-aside, k6 (Day 6, Day 7)
- [ ] **Phase 9: CI/CD & Capstone** - Path-filtered workflow, migration step, rollback, README + PRR (Day 10)

## Phase Details

### Phase 1: Foundation & Config

**Goal**: A NestJS app lives in `backend-nest/`, boots on port 5001 only with valid configuration, talks to a Dockerised Postgres, and answers `/health` exactly like Express.
**Dev setup**: Hybrid. Postgres runs in Docker Compose; the Nest app and Prisma CLI run natively on the host against `localhost:5433`.
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05
**Roadmap days**: Day 1 (modules, DI, ConfigModule), Day 9 (Docker basics)
**Success Criteria** (what must be TRUE):

  1. `npm run start:dev` in `backend-nest/` serves on http://localhost:5001 while Express keeps running on 5000
  2. Removing `JWT_SECRET` from `.env` (or making it 10 characters) makes boot fail with a readable Joi error
  3. `docker compose up -d` starts Postgres on 5433 and `docker compose ps` shows it healthy
  4. `curl localhost:5001/health` returns the same JSON keys as `curl localhost:5000/health`
  5. `npm run lint` passes

**Plans**: 4 plans

Plans:

- [x] 01-01: Scaffold with Nest CLI, tour of `main.ts` / `AppModule` / controller / service, port 5001, scripts, ESLint + Prettier
- [x] 01-02: Docker Compose Postgres (5433, named volume, healthcheck), `.env` / `.env.example`, `.gitignore`
- [x] 01-03: `ConfigModule` with Joi schema (fail fast, no fallbacks), typed config access via `ConfigService`
- [x] 01-04: `HealthModule` with `GET /health` matching Express

### Phase 2: Request Lifecycle & Contract Baseline

**Goal**: Every response and error that leaves `backend-nest` already has the Express envelope, input validation is declarative, and a framework-agnostic contract suite proves the Express baseline.
**Depends on**: Phase 1
**Requirements**: LIFE-01, LIFE-02, LIFE-03, LIFE-04, LIFE-05, PARITY-01, PARITY-02
**Roadmap days**: Day 2 (pipes, guards, interceptors, filters), Day 8 (contract testing)
**Success Criteria** (what must be TRUE):

  1. `curl localhost:5001/api/nope` returns 404 `{success:false,message:"Cannot find GET /api/nope on this server",code:"NOT_FOUND"}`, identical to Express (a single-segment `GET /nope` is `URL_NOT_FOUND` on Express because the redirect route matches it; Nest matches that after Phase 5)
  2. Sending malformed JSON returns a 400 envelope; a deliberately thrown `Error` returns 500 `INTERNAL_SERVER_ERROR` with no stack trace in the body
  3. A demo DTO rejects bad input with the `code` and `message` the matching Express validator uses
  4. Each request prints `[timestamp] METHOD URL` in the Nest console
  5. `BASE_URL=http://localhost:5000 npm test` in `contract-tests/` passes every test against Express

**Plans**: 5 plans

Plans:
**Wave 1**

- [ ] 02-01-PLAN.md: `AppException` + global `@Catch()` exception filter producing `{success:false,message,code}`

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 02-02-PLAN.md: 404 shape, JSON parse errors, request logger middleware, CORS and `trust proxy` in `main.ts`

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 02-03-PLAN.md: Global `ValidationPipe` with an `exceptionFactory` mapping to Express codes; demo DTO
- [ ] 02-04-PLAN.md: `contract-tests/` project (Jest + supertest against `BASE_URL`), helpers, `/health` + 404 + malformed-JSON tests

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 02-05-PLAN.md: Full contract suite (auth, urls, redirect, analytics, users, error paths) green against Express

### Phase 3: Data Layer with Prisma

**Goal**: The relational model for users, links and visits exists in Postgres, is migrated and seeded, and is reachable from anywhere through an injectable `PrismaService`.
**Depends on**: Phase 2
**Requirements**: DATA-01, DATA-02, DATA-03, DATA-04
**Roadmap days**: Day 3 (ORM trade-offs, modelling, migrations, transactions, N+1)
**Success Criteria** (what must be TRUE):

  1. `npx prisma migrate dev` creates `User`, `Url`, `Visit` tables with the unique constraints and indexes listed in DATA-01 (visible in Prisma Studio)
  2. `npx prisma db seed` creates one ADMIN and one NORMAL user, and re-running it does not create duplicates
  3. `PrismaService` is injected into another provider without being re-imported per module, and the app logs a clean disconnect on Ctrl-C
  4. A visit-recording call that is forced to fail after the increment leaves `clickCount` unchanged (transaction rollback demonstrated)

**Plans**: 4 plans

Plans:

- [ ] 03-01: Install Prisma, write `schema.prisma` (User / Url / Visit / Role), first migration, Prisma Studio tour
- [ ] 03-02: Global `PrismaModule` + `PrismaService` with lifecycle hooks
- [ ] 03-03: Idempotent seed script (ADMIN + NORMAL users)
- [ ] 03-04: Transactional `recordVisit` (increment + insert) with a rollback experiment

### Phase 4: Authentication & Authorization

**Goal**: Users can sign up, log in, log out and read their profile; protected and admin-only routes are enforced with guards, using the same cookie + Bearer behaviour and error codes as Express.
**Depends on**: Phase 3
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07
**Roadmap days**: Day 5 (JWT, Passport strategies, guards, hashing)
**Success Criteria** (what must be TRUE):

  1. Signup returns 201 with `{user,token}`, sets an httpOnly `token` cookie, and always creates role NORMAL even when `role: "ADMIN"` is sent
  2. `GET /api/auth/me` works with either the cookie or `Authorization: Bearer`, and returns 401 `UNAUTHORIZED` / `INVALID_TOKEN` / `USER_DELETED` in the matching cases
  3. A NORMAL user's token gets 403 `FORBIDDEN` on an `@Roles(ADMIN)` route
  4. The auth section of the contract suite passes against `localhost:5001`

**Plans**: 4 plans

Plans:

- [ ] 04-01: `UsersModule` + `UsersService.createUser` (validation, bcrypt, unique-violation → 409) and `toPublic`
- [ ] 04-02: `AuthModule` with `JwtModule.registerAsync`, signup / login, cookie options
- [ ] 04-03: Passport `JwtStrategy` (cookie-then-Bearer extractor), `JwtAuthGuard`, `@CurrentUser()`, `/me`, logout
- [ ] 04-04: `@Roles()` decorator + `RolesGuard`; run the auth contract tests

### Phase 5: Features & Parity

**Goal**: Every remaining endpoint works, and the same contract suite and the Flutter app succeed against `backend-nest`: **parity milestone**.
**Depends on**: Phase 4
**Requirements**: URL-01, URL-02, URL-03, URL-04, URL-05, URL-06, URL-07, URL-08, REDIR-01, ANLY-01, USER-01, USER-02, PARITY-03, PARITY-04
**Roadmap days**: Day 2 (custom validators), Day 4 (REST design)
**Success Criteria** (what must be TRUE):

  1. A user can create a random and a custom-alias link, see them in `GET /api/urls`, edit, and deactivate them; an ADMIN sees everyone's active links
  2. Opening `http://localhost:5001/<code>` in a browser lands on the original site, and the link's analytics show the new visit
  3. An ADMIN can list users and create another ADMIN; a NORMAL user gets 403
  4. `BASE_URL=http://localhost:5001 npm test` passes, with only the documented admin-list difference
  5. The Flutter web app, built with `API_BASE_URL=http://localhost:5001/api`, works on every screen

**Plans**: 5 plans

Plans:

- [ ] 05-01: Port `generateShortCode` + validators; `UrlsService.create` and the public alias check
- [ ] 05-02: List / get / update / delete with ownership checks, admin-list fix, `shortUrl` response mapper
- [ ] 05-03: `RedirectController` (registered last, 302, ip + user agent) and the analytics endpoint
- [ ] 05-04: Admin `GET/POST /api/users`
- [ ] 05-05: Full contract run against Nest + Flutter end-to-end check

### Phase 6: API Docs & Security Hardening

**Goal**: The API is self-documented and hardened beyond Express, with no change for existing clients.
**Depends on**: Phase 5
**Requirements**: DOCS-01, DOCS-02, SEC-01, SEC-02, SEC-03, SEC-04
**Roadmap days**: Day 4 (OpenAPI, pagination), Day 5 (Helmet, throttler, Argon2, refresh rotation)
**Success Criteria** (what must be TRUE):

  1. `/api/docs` shows every endpoint with request/response schemas and a working "Authorize" button
  2. `GET /api/urls?limit=2` returns 2 items and a `nextCursor` that fetches the next page; plain `GET /api/urls` is unchanged
  3. The 6th rapid login attempt gets 429, and responses include Helmet headers
  4. A seeded bcrypt user logs in and their hash is now Argon2; replaying an already-rotated refresh token is rejected
  5. The contract suite still passes

**Plans**: 5 plans

Plans:

- [ ] 06-01: `@nestjs/swagger` setup and decorators
- [ ] 06-02: Opt-in cursor pagination on `GET /api/urls`
- [ ] 06-03: Helmet + `@nestjs/throttler`
- [ ] 06-04: Argon2 hashing provider with bcrypt rehash-on-login
- [ ] 06-05: Refresh tokens: issue, rotate, detect reuse, revoke

### Phase 7: Testing & Observability

**Goal**: The codebase is covered by fast unit tests and isolated e2e tests, emits structured, traceable logs, and is packaged as a production container.
**Depends on**: Phase 6
**Requirements**: TEST-01, TEST-02, OBS-01, OBS-02, OBS-03, OBS-04
**Roadmap days**: Day 8 (unit, integration, e2e), Day 9 (Pino, Terminus, shutdown, Docker)
**Success Criteria** (what must be TRUE):

  1. `npm test` runs service unit tests with a mocked Prisma in seconds; `npm run test:e2e` runs against a separate test database
  2. Each log line is JSON and carries the request's `x-request-id`, which is also echoed in the response header
  3. `/health/ready` reports the database down when Postgres is stopped, while `/health/live` stays up
  4. `docker build` produces a non-root image that serves the API when given env vars

**Plans**: 5 plans

Plans:

- [ ] 07-01: Unit tests for `UrlsService`, `UsersService`, `AuthService` with `@nestjs/testing`
- [ ] 07-02: E2E suite on an isolated Postgres database (reset per run)
- [ ] 07-03: `nestjs-pino` with correlation ids
- [ ] 07-04: Terminus liveness/readiness + graceful shutdown hooks
- [ ] 07-05: Multi-stage, non-root Dockerfile

### Phase 8: Async Jobs & Performance

**Goal**: Redirects are fast and resilient: click tracking runs in the background, and hot links are served from Redis.
**Depends on**: Phase 7
**Requirements**: ASYNC-01, ASYNC-02, PERF-01, PERF-02
**Roadmap days**: Day 6 (BullMQ, DLQ, idempotent workers), Day 7 (cache-aside, invalidation, k6)
**Success Criteria** (what must be TRUE):

  1. With the worker stopped, redirects still return 302 instantly and the jobs wait in the queue; starting the worker drains them and `clickCount` is correct
  2. A job forced to fail retries with backoff, then appears in the dead-letter queue; replaying a processed job does not double-count
  3. A second redirect for the same code does not hit Postgres (visible in query logs); editing the link updates the redirect immediately
  4. A k6 run produces a latency/throughput comparison for Express vs Nest

**Plans**: 4 plans

Plans:

- [ ] 08-01: Redis in Docker Compose (6380), BullMQ module and producer in the redirect path
- [ ] 08-02: Worker with retries/backoff, dead-letter queue and idempotency key
- [ ] 08-03: Redis cache-aside for code → url with TTL and invalidation on update/delete
- [ ] 08-04: k6 load-test script and comparison

### Phase 9: CI/CD & Capstone

**Goal**: Every change to `backend-nest` is automatically linted, tested and contract-checked; migrations have a defined deploy and rollback path; the project is documented for the team.
**Depends on**: Phase 8
**Requirements**: CI-01, CI-02, CI-03
**Roadmap days**: Day 10 (CI gates, migrations, rollback, PRR)
**Success Criteria** (what must be TRUE):

  1. Pushing a change under `backend-nest/` triggers the new workflow (lint → unit → e2e → contract) and does **not** trigger `deploy.yml`'s backend job
  2. The workflow applies migrations with `prisma migrate deploy` against a CI Postgres service
  3. `backend-nest/README.md` lets a new teammate run the app, tests and Docker from scratch, and includes the PRR checklist and rollback steps

**Plans**: 3 plans

Plans:

- [ ] 09-01: GitHub Actions workflow with a Postgres/Redis service and path filters
- [ ] 09-02: Migration step + documented rollback strategy (expand/contract)
- [ ] 09-03: README, architecture notes, production-readiness checklist

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Config | 4/4 | Complete | 2026-10-15 |
| 2. Request Lifecycle & Contract Baseline | 0/5 | Not started | - |
| 3. Data Layer with Prisma | 0/4 | Not started | - |
| 4. Authentication & Authorization | 0/4 | Not started | - |
| 5. Features & Parity | 0/5 | Not started | - |
| 6. API Docs & Security Hardening | 0/5 | Not started | - |
| 7. Testing & Observability | 0/5 | Not started | - |
| 8. Async Jobs & Performance | 0/4 | Not started | - |
| 9. CI/CD & Capstone | 0/3 | Not started | - |

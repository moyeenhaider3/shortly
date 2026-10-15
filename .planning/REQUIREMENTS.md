# Requirements: Shortly — NestJS Backend (`backend-nest`)

**Defined:** 2026-10-15
**Core Value:** The Flutter app works unchanged against `backend-nest` — same routes, status codes, JSON envelope and error codes as the Express backend — and the developer understands every NestJS concept used to get there.

"Matches Express" below always means: same HTTP status, same JSON keys, same `message` text and same `code` string as `backend/` for the same input (see the contract table in PROJECT.md).

## v1 Requirements

### Foundation (roadmap Day 1, Day 9)

- [x] **FOUND-01**: Developer can start the Nest app from `backend-nest/` with `npm run start:dev` and it listens on port 5001, independent of `backend/`
- [x] **FOUND-02**: App refuses to boot, with a clear message, when `DATABASE_URL` is missing or `JWT_SECRET` is missing or shorter than 32 characters (Joi-validated `ConfigModule`, no fallbacks)
- [x] **FOUND-03**: Developer can start PostgreSQL with `docker compose up -d` from `backend-nest/` (host port 5433, named volume, healthcheck) without touching MongoDB
- [x] **FOUND-04**: `GET /health` returns 200 `{success:true,message,timestamp}` matching Express
- [x] **FOUND-05**: `npm run lint` and `npm run format` enforce ESLint + Prettier on `backend-nest/src`

### Request Lifecycle (roadmap Day 2)

- [ ] **LIFE-01**: Every error response has the shape `{success:false,message,code}` with the status code and `code` matching Express (global exception filter + `AppException`)
- [ ] **LIFE-02**: Requests to unknown routes return 404 `{success:false,message:"Cannot find <METHOD> <URL> on this server",code:"NOT_FOUND"}`
- [ ] **LIFE-03**: Malformed JSON bodies return a 400 client error; unexpected exceptions return 500 `INTERNAL_SERVER_ERROR` with no internals leaked, and are logged
- [ ] **LIFE-04**: Request bodies are validated with `class-validator` DTOs through a global `ValidationPipe`, and failures map to the same `code`/`message` Express returns for that field
- [ ] **LIFE-05**: Every request is logged as `[ISO-timestamp] METHOD URL` (middleware), and CORS + `trust proxy` behave as in Express

### Contract Tests (roadmap Day 8)

- [ ] **PARITY-01**: Developer can run one contract test suite against any base URL (`BASE_URL=http://localhost:5000 npm test`) covering every endpoint and error path in the contract
- [ ] **PARITY-02**: The contract suite passes against the Express backend (golden baseline) before Nest feature work starts
- [ ] **PARITY-03**: The contract suite passes against `backend-nest`, with the only differences being documented decisions (the admin-list fix)
- [ ] **PARITY-04**: The Flutter web app runs every screen end-to-end against `backend-nest` using `--dart-define=API_BASE_URL=http://localhost:5001/api`

### Data Layer (roadmap Day 3)

- [ ] **DATA-01**: Prisma schema defines `User`, `Url` and `Visit` (UUID ids, unique email, unique `shortCode`, unique nullable `customAlias`, indexes on `userId`/`urlId`/`visitedAt`, `Role` enum, timestamps)
- [ ] **DATA-02**: Developer can create and apply migrations with `npx prisma migrate dev`, and load an ADMIN and a NORMAL test user with a seed script
- [ ] **DATA-03**: A global `PrismaModule` exposes a `PrismaService` that connects on module init and disconnects on shutdown
- [ ] **DATA-04**: Recording a visit increments `clickCount` and inserts a `Visit` row in one transaction (no partial writes)

### Authentication (roadmap Day 5)

- [ ] **AUTH-01**: User can sign up with name/email/password (`POST /api/auth/signup`): 201, always role NORMAL, sets an httpOnly `token` cookie, returns `{user,token}`; validation and duplicate-email (409) errors match Express
- [ ] **AUTH-02**: User can log in (`POST /api/auth/login`): 200 with cookie and `{user,token}`; wrong email or password returns 401 `INVALID_CREDENTIALS` without revealing which one
- [ ] **AUTH-03**: Logged-in user can log out (`POST /api/auth/logout`): cookie cleared, 200
- [ ] **AUTH-04**: Logged-in user can fetch their profile (`GET /api/auth/me`) without `passwordHash`
- [ ] **AUTH-05**: Protected routes accept the JWT from the `token` cookie or the `Authorization: Bearer` header and reject with `UNAUTHORIZED` / `INVALID_TOKEN` / `USER_DELETED` exactly as Express does (Passport JWT strategy + guard)
- [ ] **AUTH-06**: ADMIN-only routes return 403 `FORBIDDEN` for NORMAL users (`@Roles()` decorator + `RolesGuard`)
- [ ] **AUTH-07**: Passwords are stored as bcrypt hashes (cost 10); plaintext passwords never appear in responses or logs

### URLs (roadmap Day 2, Day 4)

- [ ] **URL-01**: Logged-in user can shorten a valid http/https URL and gets a random 7-character base62 code (collision retry up to 5 times, reserved words skipped): 201
- [ ] **URL-02**: Logged-in user can shorten with a custom alias; format (3–30 chars slug), reserved-word and uniqueness checks return 400 `INVALID_ALIAS` with Express's reason text
- [ ] **URL-03**: Anyone can check alias availability (`GET /api/urls/check/:alias`) and get `{alias,available,reason?}`
- [ ] **URL-04**: A NORMAL user lists their own active links newest first with `count`; an ADMIN lists all active links (deliberate fix of the Express quirk)
- [ ] **URL-05**: Owner or ADMIN can fetch a link by id; a malformed id returns 400 `INVALID_ID`, a missing or inactive one 404 `URL_NOT_FOUND`, another user's link 403 `FORBIDDEN`
- [ ] **URL-06**: Owner or ADMIN can change a link's destination (`PATCH /api/urls/:id`); an invalid URL returns 400 `INVALID_URL_FORMAT`
- [ ] **URL-07**: Owner or ADMIN can deactivate a link (`DELETE /api/urls/:id`); the row is soft-deleted (`isActive=false`) and disappears from lists and redirects
- [ ] **URL-08**: Every URL response includes `shortUrl` built from the request's protocol and host (correct `https` behind a proxy)

### Redirect & Analytics

- [ ] **REDIR-01**: Anyone visiting `GET /:code` (short code or custom alias) of an active link is redirected with 302 to the original URL, and the visit (ip from `x-forwarded-for` or the socket, user agent) is recorded; unknown or inactive codes return 404 `URL_NOT_FOUND`
- [ ] **ANLY-01**: Owner or ADMIN can view analytics (`GET /api/urls/:id/analytics`): `totalClicks`, `lastVisitedAt`, `createdAt` and the 10 most recent visits newest first

### User Management

- [ ] **USER-01**: ADMIN can list all users (`GET /api/users`), newest first, without password hashes
- [ ] **USER-02**: ADMIN can create a NORMAL or ADMIN user (`POST /api/users`) without a session cookie being set; an invalid role returns 400 `INVALID_ROLE`

### API Design & Docs (roadmap Day 4)

- [ ] **DOCS-01**: Developer can browse interactive OpenAPI docs for every endpoint at `/api/docs` (`@nestjs/swagger`)
- [ ] **DOCS-02**: `GET /api/urls` accepts optional `?limit=&cursor=` for cursor-based pagination and returns `nextCursor`; without the params, the response is unchanged

### Security Hardening (roadmap Day 5)

- [ ] **SEC-01**: Responses carry Helmet security headers
- [ ] **SEC-02**: Repeated login/signup attempts beyond the configured limit get 429 (`@nestjs/throttler`)
- [ ] **SEC-03**: Login also issues a refresh token; `POST /api/auth/refresh` rotates it and revocation of a reused token is detected — additive, the existing access-token flow keeps working
- [ ] **SEC-04**: New passwords are hashed with Argon2, and existing bcrypt hashes are transparently re-hashed on successful login

### Testing (roadmap Day 8)

- [ ] **TEST-01**: Services have Jest unit tests using `@nestjs/testing` with a mocked `PrismaService` (alias validation, ownership checks, code generation)
- [ ] **TEST-02**: An e2e suite (supertest) runs against an isolated test database that is reset between runs

### Observability & Production Readiness (roadmap Day 9)

- [ ] **OBS-01**: Logs are structured JSON (Pino) and every log line for a request carries a correlation id taken from or returned in `x-request-id`
- [ ] **OBS-02**: Liveness `/health/live` and readiness `/health/ready` (database check) endpoints exist via Terminus; `/health` is unchanged
- [ ] **OBS-03**: On SIGTERM the app stops accepting connections, finishes in-flight requests and closes database/queue connections
- [ ] **OBS-04**: A multi-stage Dockerfile builds a small, non-root production image that runs `backend-nest`

### Async Processing (roadmap Day 6)

- [ ] **ASYNC-01**: The redirect responds without waiting on the visit write; visits are queued in BullMQ (Redis in Docker Compose) and persisted by a worker
- [ ] **ASYNC-02**: Failed visit jobs retry with backoff, then land in a dead-letter queue; the worker is idempotent, so a replayed job never double-counts

### Performance (roadmap Day 7)

- [ ] **PERF-01**: Redirect lookups use a Redis cache-aside (code → url, with TTL) and the cache entry is invalidated when a link is updated or deactivated
- [ ] **PERF-02**: Developer can run a k6 load test script against either backend and compare redirect latency and throughput

### CI/CD (roadmap Day 10)

- [ ] **CI-01**: A separate GitHub Actions workflow, path-filtered to `backend-nest/**`, runs lint, unit, e2e and contract tests on push/PR; `deploy.yml` is not modified
- [ ] **CI-02**: The workflow runs `prisma migrate deploy` as an explicit step, and a documented rollback procedure exists
- [ ] **CI-03**: `backend-nest/README.md` documents setup, scripts, environment variables, architecture and the production-readiness checklist

## v2 Requirements

Deferred. Tracked but not in the current roadmap.

- **V2-01**: URI API versioning (`/api/v1`) — the roadmap Day 4 topic; would break the shared contract
- **V2-02**: Idempotency-Key support for `POST /api/urls`
- **V2-03**: Distributed cron with Redlock (e.g. nightly visit roll-ups)
- **V2-04**: Streaming CSV export of analytics with backpressure
- **V2-05**: One-off read-only importer from the Express MongoDB, preserving ids
- **V2-06**: Deploy `backend-nest` to Render with a managed Postgres
- **V2-07**: Fix the admin-list quirk in the Express backend too

## Out of Scope

| Feature | Reason |
|---------|--------|
| Changes to `backend/`, `frontend/`, `deploy.yml` | Live system; this project must not disturb it |
| Email verification, password reset, OAuth | Not in the Express backend; parity first |
| Prisma on MongoDB | PostgreSQL chosen for the relational-modelling lessons |
| Admin edit/delete of users | Not in the Express backend |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| FOUND-04 | Phase 1 | Complete |
| FOUND-05 | Phase 1 | Complete |
| LIFE-01 | Phase 2 | Pending |
| LIFE-02 | Phase 2 | Pending |
| LIFE-03 | Phase 2 | Pending |
| LIFE-04 | Phase 2 | Pending |
| LIFE-05 | Phase 2 | Pending |
| PARITY-01 | Phase 2 | Pending |
| PARITY-02 | Phase 2 | Pending |
| DATA-01 | Phase 3 | Pending |
| DATA-02 | Phase 3 | Pending |
| DATA-03 | Phase 3 | Pending |
| DATA-04 | Phase 3 | Pending |
| AUTH-01 | Phase 4 | Pending |
| AUTH-02 | Phase 4 | Pending |
| AUTH-03 | Phase 4 | Pending |
| AUTH-04 | Phase 4 | Pending |
| AUTH-05 | Phase 4 | Pending |
| AUTH-06 | Phase 4 | Pending |
| AUTH-07 | Phase 4 | Pending |
| URL-01 | Phase 5 | Pending |
| URL-02 | Phase 5 | Pending |
| URL-03 | Phase 5 | Pending |
| URL-04 | Phase 5 | Pending |
| URL-05 | Phase 5 | Pending |
| URL-06 | Phase 5 | Pending |
| URL-07 | Phase 5 | Pending |
| URL-08 | Phase 5 | Pending |
| REDIR-01 | Phase 5 | Pending |
| ANLY-01 | Phase 5 | Pending |
| USER-01 | Phase 5 | Pending |
| USER-02 | Phase 5 | Pending |
| PARITY-03 | Phase 5 | Pending |
| PARITY-04 | Phase 5 | Pending |
| DOCS-01 | Phase 6 | Pending |
| DOCS-02 | Phase 6 | Pending |
| SEC-01 | Phase 6 | Pending |
| SEC-02 | Phase 6 | Pending |
| SEC-03 | Phase 6 | Pending |
| SEC-04 | Phase 6 | Pending |
| TEST-01 | Phase 7 | Pending |
| TEST-02 | Phase 7 | Pending |
| OBS-01 | Phase 7 | Pending |
| OBS-02 | Phase 7 | Pending |
| OBS-03 | Phase 7 | Pending |
| OBS-04 | Phase 7 | Pending |
| ASYNC-01 | Phase 8 | Pending |
| ASYNC-02 | Phase 8 | Pending |
| PERF-01 | Phase 8 | Pending |
| PERF-02 | Phase 8 | Pending |
| CI-01 | Phase 9 | Pending |
| CI-02 | Phase 9 | Pending |
| CI-03 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 56 total
- Mapped to phases: 56
- Unmapped: 0 ✓

---
*Requirements defined: 2026-10-15*
*Last updated: 2026-10-15 after initialization*

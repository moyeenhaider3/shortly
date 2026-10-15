# Shortly — NestJS Backend (`backend-nest`)

## What This Is

A second, independent backend for the Shortly URL shortener, built with **NestJS 11 + Prisma + PostgreSQL (Docker)**. It reproduces the existing Express 5 + Mongoose backend in `backend/` so the same Flutter client can run against either one by changing `API_BASE_URL`. It is also a **hands-on learning project**: the developer is new to NestJS and builds every file by hand, following the 10-day curriculum in `roadmap/`.

## Core Value

The Flutter app works unchanged against `backend-nest` — same routes, status codes, JSON envelope and error codes as the Express backend — and the developer understands every NestJS concept used to get there.

## Mentorship Protocol (how we work)

This is not a "Claude writes the code" project. Every session follows this loop:

1. **Concept first** — explain the NestJS / Prisma idea the step needs (what it is, why it exists, how it maps to the Express version in `backend/`).
2. **Snippet** — give ready-to-use code with standard comments (JSDoc on classes/methods, short inline comments for non-obvious lines), plus the exact file path.
3. **Commands** — the exact shell commands to run (install, generate, migrate, start).
4. **Verify** — a concrete check (curl, test run, log line) the developer runs to confirm it works.
5. **Developer implements** — the developer types/creates the files themselves.
6. **Review** — when the developer says "done", Claude reads the files, points out issues, and explains them.
7. **Record** — update `.planning/STATE.md` (and plan checkboxes) so the next session resumes exactly here.

Rules:
- **Claude does not write or edit files inside `backend-nest/`** unless the developer explicitly asks for it in that moment. Planning files under `.planning/` are Claude's to maintain.
- Steps are **small**: one concept and 1–3 files per step, verified before moving on.
- Do **not** use `/gsd:execute-phase` (it would have an agent write the code). Use `/gsd:plan-phase` to plan, then the guided loop above, then `/gsd:verify-work`.

## Requirements

### Validated

(None yet — each requirement is validated when its contract tests pass against `backend-nest`.)

### Active

See `.planning/REQUIREMENTS.md` for the full REQ-ID list. Summary:

- [ ] Foundation: Nest app on port 5001, fail-fast validated config, Postgres in Docker, `/health`
- [ ] Request lifecycle: identical success/error envelope, 404 shape, DTO validation, request logging
- [ ] Contract test suite that runs against any base URL (golden baseline from Express)
- [ ] Data layer: Prisma schema (User / Url / Visit), migrations, seed, transactional visit recording
- [ ] Auth: signup / login / logout / me, cookie + Bearer JWT, roles guard
- [ ] URLs, redirect, analytics, admin users — full parity (with the admin-list fix)
- [ ] Hardening: Swagger, opt-in cursor pagination, Helmet, rate limiting, refresh tokens, Argon2, tests, Pino, Terminus, Dockerfile
- [ ] Async & performance: BullMQ click tracking, Redis cache-aside, k6 load test
- [ ] CI/CD: path-filtered workflow with lint/test/contract gates and a migration step

### Out of Scope

- Modifying `backend/` (Express), `frontend/` (Flutter) or `.github/workflows/deploy.yml` — the existing system is live on Render and must stay untouched.
- Migrating existing MongoDB data — the Nest backend starts with an empty Postgres (an importer is a v2 idea).
- Email verification, password reset, OAuth — the Express backend does not have them; parity first.
- Deploying `backend-nest` to Render — deferred until Phase 8 is done; local-only until then.

## Context

**Reference implementation (`backend/`, Express 5 + Mongoose 9 + TypeScript):**

| Layer | Files |
|---|---|
| App wiring | `src/app.ts` (trust proxy, CORS `*`, json/urlencoded, cookie-parser, logger, routes, 404, error handler), `src/server.ts` (crash guards, non-blocking DB connect) |
| Config | `src/config/env.ts` (dotenv with fallbacks — incl. an insecure `JWT_SECRET` fallback) |
| Models | `src/models/user.model.ts` (name, email unique+lowercase, passwordHash, role ADMIN/NORMAL), `src/models/url.model.ts` (originalUrl, shortCode unique, customAlias unique+sparse, createdBy, clickCount, embedded `visits[]`, isActive) |
| Services | `auth.service.ts`, `user.service.ts`, `url.service.ts`, `analytics.service.ts` |
| Middleware | `auth.middleware.ts` (cookie first, then Bearer; verify JWT; user must still exist), `role.middleware.ts`, `error.middleware.ts` (`AppError`, `notFoundHandler`, `errorHandler`), `logger.middleware.ts` |
| Utils | `jwt.ts`, `validators.ts` (RESERVED_WORDS, isValidUrl, alias format 3–30 slug), `generateShortCode.ts` (7 chars, base62, crypto) |

**API contract to match:**

| Method | Path | Auth | Status | Body |
|---|---|---|---|---|
| GET | `/health` | — | 200 | `{success,message,timestamp}` |
| POST | `/api/auth/signup` | — | 201 | `{success,message,data:{user:{id,name,email,role},token}}` + `Set-Cookie: token` |
| POST | `/api/auth/login` | — | 200 | same shape |
| POST | `/api/auth/logout` | ✓ | 200 | `{success,message}` + clears cookie |
| GET | `/api/auth/me` | ✓ | 200 | `{success,data:user-without-passwordHash}` |
| GET | `/api/urls/check/:alias` | — | 200 | `{success,data:{alias,available,reason?}}` |
| POST | `/api/urls` | ✓ | 201 | `{success,data:url}` |
| GET | `/api/urls` | ✓ | 200 | `{success,count,data:[url]}` |
| GET | `/api/urls/:id` | ✓ | 200 | `{success,data:url}` |
| GET | `/api/urls/:id/analytics` | ✓ | 200 | `{success,data:{id,originalUrl,shortCode,customAlias,totalClicks,lastVisitedAt,createdAt,recentVisits}}` |
| PATCH | `/api/urls/:id` | ✓ | 200 | `{success,message,data:url}` |
| DELETE | `/api/urls/:id` | ✓ | 200 | `{success,message}` (soft delete) |
| GET | `/api/users` | ADMIN | 200 | `{success,data:[{id,name,email,role,createdAt}]}` |
| POST | `/api/users` | ADMIN | 201 | `{success,message,data:user}` |
| GET | `/:shortCode` | — | 302 | `Location: originalUrl`; visit recorded |
| * | unmatched | — | 404 | `{success:false,message:"Cannot find METHOD URL on this server",code:"NOT_FOUND"}` |

`url` = `{id,originalUrl,shortCode,customAlias,shortUrl,clickCount,isActive,createdBy,createdAt,updatedAt}`, where `shortUrl = ${protocol}://${host}/${shortCode}`.

Error codes: `UNAUTHORIZED`, `INVALID_TOKEN`, `USER_DELETED`, `FORBIDDEN`, `VALIDATION_ERROR`, `WEAK_PASSWORD`, `INVALID_ROLE`, `EMAIL_ALREADY_EXISTS` (409), `INVALID_CREDENTIALS`, `ORIGINAL_URL_REQUIRED`, `INVALID_URL_FORMAT`, `INVALID_ALIAS`, `INVALID_ID`, `URL_NOT_FOUND`, `CODE_GENERATION_FAILED`, `NOT_FOUND`, `INTERNAL_SERVER_ERROR`.

**Client:** `frontend/lib/core/network/api_client.dart` (Dio, Bearer token from SharedPreferences, reads `data['message']` on errors). The models accept `id` or `_id` and treat ids as opaque strings, so UUIDs are safe.

**Learning track:** `roadmap/day-01` … `roadmap/day-10`. Each phase lists the roadmap days it covers.

**Environment:** macOS, Node v26 locally (`backend/.nvmrc` pins 24), Docker 29.8 + Compose v5.5. Work happens on branch `nest-backend`; `main` auto-deploys the Express backend to Render on push.

## Constraints

- **Isolation**: All new code lives in `backend-nest/` with its own `package.json`, lockfile, `.env` and `.gitignore` — no root workspace, no shared `node_modules`.
- **Ports**: Nest on **5001** (Express keeps 5000); Postgres on host **5433**; Redis later on host **6380**.
- **Secrets**: `backend-nest` uses its own `JWT_SECRET` (≥ 32 chars, validated at boot, no fallback).
- **Parity**: Response bodies, status codes and error codes must match the Express contract above unless a decision below says otherwise.
- **Additive extensions**: Roadmap features (pagination, refresh tokens, Swagger…) must not break the existing Flutter client — opt-in params or new endpoints only.
- **Git**: Commits go to branch `nest-backend`; never push to `main` from this work.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Separate `backend-nest/` folder, Express untouched | Two codebases side by side; zero risk to the live deploy | — Pending |
| PostgreSQL + Prisma (not Prisma-on-Mongo) | Matches roadmap Day 3: relational modelling, `Visit` table, transactions, migrations | — Pending |
| UUID string ids | Flutter treats ids as opaque strings; String column leaves room for a legacy-id import later | — Pending |
| Admins see **all** active links on `GET /api/urls` in Nest | Fixes the Express quirk (controller calls `getUserUrls` instead of the admin-aware `getUrls`); a deliberate, documented divergence the contract tests account for | — Pending |
| bcrypt first, Argon2 later with rehash-on-login | Parity first; upgrade hashes transparently in Phase 6 | — Pending |
| Mentorship mode — developer writes all `backend-nest` code | Goal is hands-on NestJS mastery, not just a working app | — Pending |
| Small steps (1 concept, 1–3 files, verify each) | Developer chose this pace | — Pending |
| Contract test suite before Nest features | Captures a golden baseline from Express so parity is provable | — Pending |
| GSD helper agents not installed — research/plan-check/verifier off | Planning and verification happen inline in guided sessions | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-10-15 after initialization*

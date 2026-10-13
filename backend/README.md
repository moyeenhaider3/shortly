# Shortly: Backend (`backend`)

REST API and redirect server for Shortly, built with **Node.js, TypeScript, Express 5, MongoDB (Mongoose) and JWT**.

> Part of a two-app project. To see how this API connects to the Flutter app, read the **[root README](../README.md)**. For the client itself, read the **[frontend README](../frontend/README.md)**.

## Features

- Sign up, log in, and log out with JWT. The token is sent both in an `httpOnly` cookie and in the response body.
- Two roles, `NORMAL` and `ADMIN`. Only admins can manage users.
- Short links with random 7-character codes or a custom alias. Aliases are checked for format, reserved words, and uniqueness.
- Public redirects at `GET /:shortCode` that count every visit (time, IP, user agent).
- Per-link analytics: total clicks, last visit, and the 10 most recent visits.
- Soft delete: a deactivated link stops redirecting but stays in the database.
- One error format for every response, with machine-readable `code`s.

## Tech stack

| Concern | Library |
|---|---|
| HTTP server | `express` 5 |
| Database | `mongoose` 9 → MongoDB |
| Auth | `jsonwebtoken`, `bcryptjs`, `cookie-parser` |
| Cross-origin | `cors` |
| Config | `dotenv` |
| Dev runner | `tsx watch` |
| Build | `tsc` (TypeScript 7) → `dist/` |

---

## Getting started

### Prerequisites

- Node.js 18 or newer (Express 5 needs it)
- MongoDB running locally (default `mongodb://127.0.0.1:27017`), or a connection string to a remote one

### Setup

```bash
cd backend
cp .env.example .env     # then edit the values, at least JWT_SECRET
npm install
npm run dev
```

Expected output:

```
🚀 Server running in [development] mode on port 5000
🍃 MongoDB Connected: 127.0.0.1
```

Check it:

```bash
curl http://localhost:5000/health
# {"success":true,"message":"Server is healthy and running","timestamp":"..."}
```

### Scripts

| Command | What it does |
|---|---|
| `npm run dev` | Runs `src/server.ts` with `tsx` and restarts on file changes |
| `npm run build` | Compiles TypeScript to `dist/` |
| `npm start` | Runs the compiled server: `node dist/server.js` (run `build` first). This is what runs in production |
| `npm run start:prod` | Same, but loads `.env.prod` instead of the ambient environment. For testing a production-like config locally |

There is no test script yet.

### Environment variables

Read in [`src/config/env.ts`](src/config/env.ts). Copy them from [`.env.example`](.env.example).

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `5000` | HTTP port. The Flutter client expects `5000` locally. On Render, leave it unset — the platform assigns it |
| `NODE_ENV` | `development` | `production` makes the auth cookie `secure` (HTTPS only). `development` logs every handled error |
| `MONGODB_URI` | `mongodb://127.0.0.1:27017/url_shortener_db` | Mongo connection string |
| `JWT_SECRET` | `fallback_secret_for_dev_only` | Secret used to sign tokens. **Always set this.** The fallback is not safe outside local development |
| `JWT_EXPIRES_IN` | `7d` | Token lifetime, in any format [`jsonwebtoken`](https://github.com/auth0/node-jsonwebtoken#usage) accepts |

> The server starts listening **before** MongoDB connects. If the database is down, `/health` still responds, a connection error is logged, and database-backed routes fail until MongoDB is available. This also means a green `/health` does **not** prove the database is reachable.

### Deployment

Deployed to Render at [`https://shortly-dgxi.onrender.com`](https://shortly-dgxi.onrender.com), triggered by a push to `main`. **[`DEPLOYMENT.md`](../DEPLOYMENT.md)** is the full runbook — service settings, Atlas setup, GitHub secrets, rollback and troubleshooting.

Two things matter when running behind Render's proxy:

- **`app.set('trust proxy', 1)`** in [`src/app.ts`](src/app.ts). Render terminates HTTPS at its proxy and forwards over plain HTTP, so without it `req.protocol` reads `http` and every generated `shortUrl` comes back as `http://`. The setting makes Express honour `X-Forwarded-Proto`. It is inert locally.
- **The build command needs `npm ci --include=dev`.** With `NODE_ENV=production` set, npm skips devDependencies, and `typescript` is one, so a plain `npm ci` fails the build with `tsc: not found`.

> **Free tier:** the service spins down after roughly 15 minutes of inactivity, and the next request takes 30–60 seconds while it wakes. Deploys are unaffected.

---

## Project structure

```
src/
├── server.ts                 # Starts the server, connects to MongoDB, handles process-level errors
├── app.ts                    # Express app: CORS, parsers, logger, routes, error handlers
├── config/
│   ├── env.ts                # Typed environment config with defaults
│   └── db.ts                 # mongoose.connect
├── routes/                   # URL → controller wiring and per-route middleware
│   ├── auth.routes.ts        # /api/auth
│   ├── url.routes.ts         # /api/urls
│   ├── user.routes.ts        # /api/users (admin)
│   └── redirect.routes.ts    # /:shortCode
├── controllers/              # Reads req, calls a service, shapes the JSON response
├── service/                  # Business logic and database access
│   ├── auth.service.ts       # signup / login / getUserById
│   ├── user.service.ts       # create (validation + hashing) / list users
│   ├── url.service.ts        # create / read / update / soft-delete links, alias checks
│   └── analytics.service.ts  # record visits, analytics summary
├── models/
│   ├── user.model.ts         # User + UserRole enum
│   └── url.model.ts          # Url + embedded visits
├── middlewares/
│   ├── auth.middleware.ts    # authenticate: JWT from cookie or Bearer header → req.user
│   ├── role.middleware.ts    # restrictTo(...roles)
│   ├── error.middleware.ts   # AppError, 404 handler, global error handler
│   └── logger.middleware.ts  # [timestamp] METHOD /url
├── utils/
│   ├── jwt.ts                # signToken / verifyToken
│   ├── generateShortCode.ts  # crypto-random base62 code
│   └── validators.ts         # isValidUrl, isValidAliasFormat, RESERVED_WORDS
└── types/express.d.ts        # Adds req.user to Express's Request type
```

**How a request moves through the code:** `route → (authenticate → restrictTo) → controller → service → model`. Errors are thrown as `AppError` and passed with `next(error)` to the global `errorHandler`.

Middleware runs in the order set in [`app.ts`](src/app.ts): `cors` → `json`/`urlencoded` → `cookieParser` → `requestLogger` → `/health` → `/api/auth`, `/api/urls`, `/api/users` → `/:shortCode` redirect (mounted **last** so it doesn't catch API paths) → 404 → error handler.

---

## API reference

Base URL: `http://localhost:5000` locally, `https://shortly-dgxi.onrender.com` in production. The examples below use the local one.

**Authentication:** protected routes accept either

- the `token` cookie, set by `signup` and `login`, or
- the header `Authorization: Bearer <token>`. The Flutter client uses this one.

**Response envelope:**

```jsonc
{ "success": true,  "data": ..., "message"?: "...", "count"?: n }
{ "success": false, "message": "...", "code": "ERROR_CODE" }
```

### Health

| Method | Path | Auth |
|---|---|---|
| `GET` | `/health` | public |

### Auth: `/api/auth`

| Method | Path | Auth | Body | Success |
|---|---|---|---|---|
| `POST` | `/signup` | public | `{ name, email, password }` | `201` `{ user, token }` and sets the cookie |
| `POST` | `/login` | public | `{ email, password }` | `200` `{ user, token }` and sets the cookie |
| `POST` | `/logout` | user | none | `200`, clears the cookie |
| `GET` | `/me` | user | none | `200` user document (without `passwordHash`) |

Signup always creates a `NORMAL` user. Any `role` sent in the body is ignored.

```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"jane@example.com","password":"secret123"}'
```

```json
{
  "success": true,
  "message": "Logged in successfully",
  "data": {
    "user": { "id": "665f…", "name": "Jane", "email": "jane@example.com", "role": "NORMAL" },
    "token": "eyJhbGciOi…"
  }
}
```

### URLs: `/api/urls`

All routes need a logged-in user, **except** `/check/:alias`.

| Method | Path | Auth | Body | Success |
|---|---|---|---|---|
| `GET` | `/check/:alias` | public | none | `200` `{ alias, available, reason? }` |
| `POST` | `/` | user | `{ originalUrl, customAlias? }` | `201` URL object |
| `GET` | `/` | user | none | `200` `[URL]` and `count`: the caller's active links, newest first |
| `GET` | `/:id` | owner / admin | none | `200` URL object |
| `GET` | `/:id/analytics` | owner / admin | none | `200` analytics summary |
| `PATCH` | `/:id` | owner / admin | `{ originalUrl }` | `200` updated URL object |
| `DELETE` | `/:id` | owner / admin | none | `200`. Soft delete: sets `isActive: false` |

**URL object:**

```json
{
  "id": "6660…",
  "originalUrl": "https://example.com/a/very/long/path",
  "shortCode": "my-promo",
  "customAlias": "my-promo",
  "shortUrl": "http://localhost:5000/my-promo",
  "clickCount": 12,
  "isActive": true,
  "createdBy": "665f…",
  "createdAt": "2026-10-13T09:00:00.000Z",
  "updatedAt": "2026-10-13T09:00:00.000Z"
}
```

`shortUrl` is built from the request's protocol and `Host` header.

**Analytics summary:**

```json
{
  "id": "6660…",
  "originalUrl": "https://example.com/…",
  "shortCode": "my-promo",
  "customAlias": "my-promo",
  "totalClicks": 12,
  "lastVisitedAt": "2026-10-13T10:15:00.000Z",
  "createdAt": "2026-10-13T09:00:00.000Z",
  "recentVisits": [
    { "visitedAt": "2026-10-13T10:15:00.000Z", "ip": "::1", "userAgent": "Mozilla/5.0 …" }
  ]
}
```

`recentVisits` holds the **10 most recent** visits, newest first.

**Alias rules** (used by both `/check/:alias` and `POST /`):

- 3–30 characters: letters, numbers and single hyphens, and it cannot start or end with a hyphen
- stored in lowercase
- cannot be a reserved word: `api, admin, auth, dashboard, login, logout, signup, health, public, static, assets, favicon.ico, robots.txt, sitemap.xml, urls, users`
- cannot match any existing `customAlias` **or** `shortCode`

If you don't give an alias, the server generates a random 7-character base62 code. It tries up to 5 times to find one that isn't taken or reserved.

`originalUrl` must be a valid `http://` or `https://` URL.

### Users: `/api/users` (admin only)

| Method | Path | Body | Success |
|---|---|---|---|
| `GET` | `/` | none | `200` `[{ id, name, email, role, createdAt }]`, newest first |
| `POST` | `/` | `{ name, email, password, role: "NORMAL" \| "ADMIN" }` | `201` new user. **No cookie is set**, so the admin stays logged in as themselves |

### Redirect

| Method | Path | Auth | Success |
|---|---|---|---|
| `GET` | `/:shortCode` | public | `302` to `originalUrl` |

The server looks the code up as either `shortCode` or `customAlias` among **active** links. It then adds 1 to `clickCount` and appends a visit `{ visitedAt, ip, userAgent }` in a single atomic `$inc` + `$push` update. `ip` comes from `X-Forwarded-For` if present, otherwise from the socket address.

---

## Data model

**User** (`users` collection)

| Field | Type | Notes |
|---|---|---|
| `name` | string | 2–50 chars |
| `email` | string | unique, stored in lowercase |
| `passwordHash` | string | bcrypt, 10 salt rounds. Never returned |
| `role` | `ADMIN` \| `NORMAL` | default `NORMAL` |
| `createdAt`, `updatedAt` | Date | set automatically |

**Url** (`urls` collection)

| Field | Type | Notes |
|---|---|---|
| `originalUrl` | string | required |
| `shortCode` | string | unique, indexed. Equals the alias when one is given |
| `customAlias` | string? | unique, sparse |
| `createdBy` | ObjectId → User | indexed |
| `clickCount` | number | default 0 |
| `visits` | `[{ visitedAt, ip, userAgent }]` | embedded array, one entry per redirect |
| `isActive` | boolean | `false` after a soft delete |
| `createdAt`, `updatedAt` | Date | set automatically |

> Visits are stored inside the link document. That keeps reads simple, but a very busy link would make its document grow without limit, and MongoDB caps a document at 16 MB. Move visits to their own collection before running this at real traffic.

### Creating an admin

Public signup only creates `NORMAL` users, and only an existing admin can call `POST /api/users`. To create the **first** admin, promote a user directly in the database:

```js
// mongosh
use url_shortener_db
db.users.updateOne({ email: "you@example.com" }, { $set: { role: "ADMIN" } })
```

---

## Errors

Every error goes through [`errorHandler`](src/middlewares/error.middleware.ts). Two kinds of error are reported to the client as they are: `AppError`s, and body-parser's own errors (for example malformed JSON). Anything else becomes a generic `500 INTERNAL_SERVER_ERROR`, so internal details don't leak.

| Status | `code` | When |
|---|---|---|
| 400 | `VALIDATION_ERROR` | Missing or invalid name, email or password |
| 400 | `WEAK_PASSWORD` | Password shorter than 6 characters |
| 400 | `INVALID_ROLE` | `role` is not `NORMAL` or `ADMIN` |
| 400 | `ORIGINAL_URL_REQUIRED` | `originalUrl` is missing |
| 400 | `INVALID_URL_FORMAT` | `originalUrl` is not a valid http(s) URL |
| 400 | `INVALID_ALIAS` | Alias fails a format, reserved-word or uniqueness check |
| 400 | `INVALID_ID` | `:id` is not a valid ObjectId |
| 400 | `entity.parse.failed` | Malformed JSON body |
| 401 | `UNAUTHORIZED` | No token |
| 401 | `INVALID_TOKEN` | Token is invalid or expired |
| 401 | `USER_DELETED` | Token is valid but the user no longer exists |
| 401 | `INVALID_CREDENTIALS` | Wrong email or password |
| 403 | `FORBIDDEN` | Wrong role, or not the owner of the link |
| 404 | `URL_NOT_FOUND` | Link doesn't exist or is deactivated |
| 404 | `USER_NOT_FOUND` | `/me` for a user that no longer exists |
| 404 | `NOT_FOUND` | No route matched |
| 409 | `EMAIL_ALREADY_EXISTS` | Email already registered |
| 500 | `CODE_GENERATION_FAILED` | No free random code found after 5 attempts |
| 500 | `INTERNAL_SERVER_ERROR` | Anything unexpected |

---

## Notes and limitations

- **CORS** reflects any origin (`origin: true`) and allows credentials. Fine for local development. Set an allow-list before deploying.
- **`GET /api/urls`** returns only the caller's own links, admins included. `UrlService.getUrls` already has an "admin sees all" version, but nothing uses it yet.
- **`X-Forwarded-For`** is trusted as-is for visit IPs. Only rely on it behind a proxy you control.
- **No rate limiting** on login or redirect routes.
- **No automated tests yet.**

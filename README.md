# Shortly — URL Shortener

Shortly shortens links, lets you pick a custom alias, and counts every click. It has two parts:

| Part | Folder | Stack | Dev | Production | Docs |
|---|---|---|---|---|---|
| **Backend** (API + redirects) | [`backend/`](backend/) | Node.js, TypeScript, Express 5, MongoDB (Mongoose), JWT | `http://localhost:5000` | [Render](https://shortly-dgxi.onrender.com) | [Backend README](backend/README.md) |
| **Frontend** (dashboard app) | [`frontend/`](frontend/) | Flutter (web first; mobile and desktop also build), BLoC, Dio, go_router | `http://localhost:8080` | [GitHub Pages](https://moyeenhaider3.github.io/shortly/) | [Frontend README](frontend/README.md) |

This file explains how the two parts fit together. Setup, structure and API details for each part are in its own README. For how a push to `main` reaches production, see [Deployment](#deployment).

---

## Architecture

```mermaid
flowchart LR
    subgraph Client["frontend (Flutter)"]
        UI[Screens / BLoCs] --> Repo[Repositories]
        Repo --> Api["ApiClient (Dio)<br/>baseUrl = API_BASE_URL<br/>(default http://localhost:5000/api)"]
        Prefs[(SharedPreferences<br/>jwt_token)] <--> Api
    end

    subgraph Server["backend (Express :5000)"]
        Routes["/api/auth · /api/urls · /api/users"] --> Services --> DB[(MongoDB<br/>url_shortener_db)]
        Redirect["GET /:shortCode"] --> Services
    end

    Api -- "JSON over HTTP<br/>Authorization: Bearer &lt;JWT&gt;" --> Routes
    Visitor([Anyone with a short link]) -- "GET /abc1234" --> Redirect
    Redirect -- "302 → original URL" --> Visitor
```

There are two separate kinds of traffic:

1. **The app talking to the API.** The Flutter app calls `/api/*` on the backend to log in and to manage links, users and analytics.
2. **Visitors opening short links.** A short link such as `http://localhost:5000/abc1234` goes **straight to the backend**, not to the Flutter app. The backend records the visit and sends back a `302` redirect to the original URL.

---

## How the frontend connects to the backend

### 1. Base URL

The API address is set in one place: [`frontend/lib/core/network/api_client.dart`](frontend/lib/core/network/api_client.dart)

```dart
static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');
```

It is a **build-time** value. Running without a flag keeps the localhost default, so local development needs no setup. To point the app somewhere else, pass the value at build or run time instead of editing the file:

```bash
flutter run   -d chrome --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
flutter build web --release --dart-define=API_BASE_URL=https://shortly-dgxi.onrender.com/api
```

Every repository builds its request paths on top of this, for example `'/urls'` becomes `<baseUrl>/urls`. The backend port comes from `PORT` in `backend/.env` and defaults to `5000`.

The UI also needs the bare host (without the `/api` suffix) to show what a short link will look like. That comes from `ApiClient.publicHost`, which is derived from `baseUrl`, so it follows the same flag and there is no second place to update.

> **Android emulator:** inside the emulator, `localhost` means the emulator itself. Use `http://10.0.2.2:5000/api` there. On a physical device, use your machine's LAN IP.

### 2. Authentication (JWT)

```mermaid
sequenceDiagram
    participant App as Flutter app
    participant Prefs as SharedPreferences
    participant API as Express API
    participant DB as MongoDB

    App->>API: POST /api/auth/login {email, password}
    API->>DB: find user, bcrypt.compare
    API-->>App: 200 {data: {user, token}} + Set-Cookie: token (httpOnly)
    App->>Prefs: save token as "jwt_token"

    Note over App,API: Every later request
    App->>API: GET /api/urls  (Authorization: Bearer <token>)
    API->>API: authenticate middleware: verify JWT, load user
    API-->>App: 200 {success, data}

    Note over App: On app start, AuthBloc runs AppStarted → GET /api/auth/me<br/>to restore the session. Any 401 removes the stored token.
```

- The backend sends the JWT back in **two** ways: in the response body (`data.token`) and in an `httpOnly` cookie named `token`.
- The Flutter app uses the **body token**. It saves it in `SharedPreferences` and a Dio interceptor adds `Authorization: Bearer <token>` to every request.
- The backend's [`authenticate`](backend/src/middlewares/auth.middleware.ts) middleware looks for the cookie first and falls back to the `Bearer` header, so both ways work.
- On a `401`, the client deletes the stored token. The router then sends the user back to `/login`.

### 3. CORS

[`backend/src/app.ts`](backend/src/app.ts) enables CORS with `origin: "*"` and `credentials: true`. It allows the `Content-Type` and `Authorization` headers and the methods `GET, POST, PATCH, DELETE, OPTIONS`. This is why Flutter web on `localhost:8080`, and the deployed app on GitHub Pages, can both call the API.

> **Known issue — the wildcard disables the cookie.** The CORS spec forbids combining `Access-Control-Allow-Origin: *` with credentialed requests, so browsers drop the `token` cookie that `signup` and `login` set. It works anyway because the Flutter client authenticates with the `Bearer` header (see below) and never relies on the cookie. To make the cookie path work in the browser, replace the wildcard with an explicit list of allowed origins:
>
> ```ts
> origin: ['http://localhost:8080', 'https://moyeenhaider3.github.io'],
> ```

### 4. Response format

Every API response uses the same envelope, and the client parses it the same way everywhere:

```jsonc
// success
{ "success": true, "data": { ... }, "message": "optional", "count": 3 /* list endpoints only */ }

// error
{ "success": false, "message": "Human readable text", "code": "MACHINE_CODE" }
```

On the client, repositories read `response.data['data']`. `ApiClient.getErrorMessage()` takes the `message` field from error responses, and that text is what the user sees in toasts and inline alerts.

### 5. Endpoint map: who calls what

| Backend endpoint | Auth | Used by the client in |
|---|---|---|
| `POST /api/auth/signup` | public | `AuthRepository.signup` → Sign-up screen |
| `POST /api/auth/login` | public | `AuthRepository.login` → Login screen |
| `POST /api/auth/logout` | user | `AuthRepository.logout` → user menu |
| `GET  /api/auth/me` | user | `AuthRepository.getCurrentUser` → session restore on startup |
| `GET  /api/urls/check/:alias` | public | `UrlRepository.checkAliasAvailability` → live alias check on the Dashboard |
| `POST /api/urls` | user | `UrlRepository.createUrl` → "Create link" panel |
| `GET  /api/urls` | user | `UrlRepository.getUrls` → Dashboard, Links, Analytics overview |
| `GET  /api/urls/:id` | owner / admin | `UrlRepository.getUrlById` → link detail |
| `GET  /api/urls/:id/analytics` | owner / admin | `UrlRepository.getUrlAnalytics` → `/links/:id` analytics screen |
| `PATCH /api/urls/:id` | owner / admin | *not used by the client yet* |
| `DELETE /api/urls/:id` | owner / admin | `UrlRepository.deleteUrl` → "Deactivate" (soft delete) |
| `GET  /api/users` | admin | `UserRepository.getUsers` → `/users` screen |
| `POST /api/users` | admin | `UserRepository.createUser` → "Add user" dialog |
| `GET  /:shortCode` | public | not called by the app. Visitors open it directly, and the app shows and copies `shortUrl` |
| `GET  /health` | public | not called by the app. Use it to check the server is up |

### 6. Short URLs

The backend builds each link's `shortUrl` from the incoming request's protocol and `Host` header — `http://localhost:5000/<shortCode>` in dev, `https://shortly-dgxi.onrender.com/<shortCode>` in production. The client never builds short URLs itself. It displays, copies and turns into a QR code whatever `shortUrl` the API returns. Because the URL comes from the request, behind a proxy or on a different host the links follow whatever host the client called.

For the protocol to be right in production, [`app.ts`](backend/src/app.ts) sets `app.set('trust proxy', 1)`. Render terminates HTTPS at its proxy and forwards to the app over plain HTTP, so without that line `req.protocol` would read `http` and every generated link would come back as `http://` — still working, but through an extra redirect and looking insecure when copied. The setting makes Express honour the proxy's `X-Forwarded-Proto` header. It changes nothing locally, where there is no proxy.

### 7. Roles

| Role | How you get it | What it can do |
|---|---|---|
| `NORMAL` | Public sign-up (always `NORMAL`, even if the request asks for another role) | Manage and see analytics for **their own** links |
| `ADMIN` | Created by another admin through `POST /api/users` | Everything above, plus view, update or delete any link by id and manage users |

The backend enforces roles with [`restrictTo`](backend/src/middlewares/role.middleware.ts) and ownership checks. The client also hides `/users` from non-admins in [`app_router.dart`](frontend/lib/core/router/app_router.dart), but that is only so they don't land on a page that would fail. The backend check is what actually protects the data.

**Creating the first admin:** no endpoint can create the first admin. Sign up normally, then promote that user in MongoDB:

```js
// mongosh
use url_shortener_db
db.users.updateOne({ email: "you@example.com" }, { $set: { role: "ADMIN" } })
```

---

## Quick start (run both)

**You need:** Node.js 18+, MongoDB running locally on `27017`, and Flutter with Dart SDK `^3.13.2`.

```bash
# 1. Backend: terminal 1
cd backend
cp .env.example .env          # then set JWT_SECRET
npm install
npm run dev                   # → 🚀 Server running ... on port 5000
                              # → 🍃 MongoDB Connected: 127.0.0.1

# 2. Check it is up
curl http://localhost:5000/health

# 3. Frontend: terminal 2
cd frontend
flutter pub get
flutter run -d chrome --web-port=8080
```

Then open `http://localhost:8080`, sign up, and create a link. Opening the short link in a new tab redirects you and adds a click.

In VS Code you can also use the launch configurations in [`frontend/.vscode/launch.json`](frontend/.vscode/launch.json), for example **"Flutter Web (Chrome) + peek"**.

---

## Deployment

Pushing to `main` runs [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), which deploys both parts in order. The frontend job waits for the backend, so the app is never published against a backend that failed to start.

```mermaid
flowchart LR
    Push([push to main]) --> B["<b>backend job</b><br/>npm ci · tsc<br/>POST Render deploy hook<br/>poll until status = live<br/>GET /health"]
    B -- "only if green" --> F["<b>frontend job</b><br/>flutter build web<br/>--dart-define=API_BASE_URL<br/>--base-href /shortly/"]
    F --> P([GitHub Pages])
    B --> R([Render])
```

Both jobs read the backend address from the `BACKEND_URL` repository **variable**, so the URL lives in exactly one place.

### One-time setup

**1. Render** — create a Web Service from this repo:

| Setting | Value |
|---|---|
| Root Directory | `backend` |
| Build Command | `npm ci --include=dev && npm run build` |
| Start Command | `npm start` |
| Health Check Path | `/health` |
| Auto-Deploy | **Off** (the workflow triggers deploys through the hook) |
| Environment | `MONGODB_URI`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `NODE_ENV=production`. Do **not** set `PORT`; Render provides it |

`--include=dev` matters: `NODE_ENV=production` makes npm skip devDependencies, and `typescript` lives there, so without the flag the build fails with `tsc: not found`.

**2. GitHub → Settings → Environments → `production`** — restrict deployment branches to `main`, then add three secrets:

| Secret | Where to find it |
|---|---|
| `RENDER_DEPLOY_HOOK_URL` | Render → service → Settings → Deploy Hook |
| `RENDER_API_KEY` | Render → Account Settings → API Keys |
| `RENDER_SERVICE_ID` | The `srv-…` id shown on the service page |

**3. GitHub → Settings → Secrets and variables → Actions → _Variables_ tab** — add a repository variable `BACKEND_URL`, for example `https://shortly-dgxi.onrender.com`, with no `/api` and no trailing slash. It is a variable rather than a secret because it is compiled into the public JavaScript anyway.

**4. GitHub → Settings → Pages** — set **Source** to **GitHub Actions**. No token is needed; the workflow authenticates with OIDC.

### Notes

- **Nothing secret reaches the client.** The only value injected into the Flutter build is the public backend URL.
- The workflow runs on `push` to `main` and on manual dispatch, never on `pull_request`, so a fork cannot reach the secrets.
- The repository token is read-only by default; only the Pages job is granted `pages: write` and `id-token: write`.
- The site is served from a subpath, so the build passes `--base-href /shortly/` and copies `index.html` to `404.html` so that refreshing a deep link still loads the app.

---

## Troubleshooting connection issues

| What you see | Likely cause | Fix |
|---|---|---|
| `Network connection error` / `connection refused` in the app | Backend not running, or the port doesn't match | Start the backend. Make sure `PORT` in `.env` matches the `API_BASE_URL` the app was built with |
| Requests take about 10 s and then fail | Backend is up but MongoDB isn't. The server stays up (so `/health` still works), but Mongoose holds database queries until they time out | Start MongoDB and check `MONGODB_URI` |
| CORS error in the browser console | `cors` options in `app.ts` changed, or a custom header was added on the client | Add the header to `allowedHeaders` or the method to `methods` |
| App keeps returning to `/login` | Token expired (`JWT_EXPIRES_IN`), or `JWT_SECRET` changed so old tokens no longer verify | Log in again |
| Works in Chrome, fails on the Android emulator | `localhost` points at the emulator itself | Run with `--dart-define=API_BASE_URL=http://10.0.2.2:5000/api` |
| Deployed app still calls `localhost:5000` | The web build ran without the flag | Rebuild with `--dart-define=API_BASE_URL=…`. The deploy workflow passes it from the `BACKEND_URL` repository variable |
| First request after an idle period takes ~30–60 s | Render's free tier spins the service down when idle | Expected on the free tier. The next requests are fast again |
| Short link returns a `404` JSON error | Link was deactivated (soft deleted) or the code is wrong | Deactivated links stop redirecting on purpose |

For debugging the running Flutter app (console and HTTP logs), see [Debugging in the frontend README](frontend/README.md#debugging).

---

## More detail

- **[Backend README](backend/README.md):** environment variables, full API reference with request and response examples, data model, error codes, and project structure.
- **[Frontend README](frontend/README.md):** screens, state management, routing, folder structure, theming, tests, and debugging.

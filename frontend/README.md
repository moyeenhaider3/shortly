# Shortly: Frontend (`frontend`)

Flutter dashboard for Shortly: create short links (with or without a custom alias), manage them, read click analytics, and, for admins, manage users. It is built **web-first** and lays itself out for phones, tablets and desktops.

> Part of a two-app project. To see how this app connects to the API, read the **[root README](../README.md)**. For the API itself, read the **[backend README](../backend/README.md)**.

## Features

| Screen | Route | What it does |
|---|---|---|
| Login / Sign up | `/login`, `/signup` | Sign in or create an account. After login you go back to the page you originally asked for (`?from=`) |
| Dashboard | `/` | Create-link panel with a **live alias check**, overview stats, recent links, and a QR code for each new link |
| Links | `/links` | All your links: search (**⌘/Ctrl + K**), filter (all / custom / generated), sort (newest, oldest, most or fewest clicks), pages of 20. Row actions: copy, open, QR code, deactivate |
| Link analytics | `/links/:id` | Totals, last visit, and the last 10 visits with browser, OS and device. Visitor IPs are **masked** until you choose to reveal them |
| Analytics overview | `/analytics` | Account-wide numbers worked out on the client from `GET /urls`: top links by clicks, links created per week |
| Users (admin) | `/users` | List every account and add `NORMAL` or `ADMIN` users |

Also included: light, dark, or system theme (your choice is saved), a splash screen while the session is restored, and a 404 page.

**Placeholder cards:** "Clicks over time", "Top referrers" and "Countries" are drawn as greyed-out placeholders. The backend does not provide that data yet.

---

## Getting started

### Prerequisites

- Flutter SDK with **Dart `^3.13.2`**
- Chrome, for web, or a simulator or device
- The **backend running on `http://localhost:5000`**. See the [backend README](../backend/README.md#getting-started). To skip it and use the deployed API instead, see [Pointing at a different backend](#pointing-at-a-different-backend)

### Run

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port=8080
```

Or in VS Code, pick one of the configurations in [`.vscode/launch.json`](.vscode/launch.json):

| Configuration | Use |
|---|---|
| **Flutter Web (Chrome) + peek** | Web on port 8080, with flutter-peek debugging enabled |
| **Flutter (selected device) + peek** | Whatever device is selected in VS Code, with flutter-peek |
| **Flutter (profile)** | Profile-mode build, for performance work |

### Pointing at a different backend

The API address is a build-time value in [`lib/core/network/api_client.dart`](lib/core/network/api_client.dart):

```dart
static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5000/api');
```

Running without a flag uses the localhost default, so the command above needs no extra setup. To point somewhere else, pass `--dart-define` rather than editing the file:

| Where you run the app | Flag |
|---|---|
| Web, iOS simulator, desktop | *(none — the default already fits)* |
| Android emulator | `--dart-define=API_BASE_URL=http://10.0.2.2:5000/api` |
| Physical device | `--dart-define=API_BASE_URL=http://<your-LAN-IP>:5000/api` |
| Against production | `--dart-define=API_BASE_URL=https://shortly-dgxi.onrender.com/api` |

The same flag drives `ApiClient.publicHost`, the bare `host:port` the UI shows when previewing what a short link will look like. Both come from one value, so there is nothing else to change.

### Other commands

```bash
flutter test            # unit + widget tests (test/presentation/)
flutter analyze         # lints (flutter_lints, page width 120)
flutter build web       # release build → build/web/ (localhost default)

# release build aimed at the deployed backend, as CI does it
flutter build web --release \
  --base-href /shortly/ \
  --dart-define=API_BASE_URL=https://shortly-dgxi.onrender.com/api
```

### Deployment

Pushing to `main` builds this app and publishes it to [GitHub Pages](https://moyeenhaider3.github.io/shortly/), with `API_BASE_URL` taken from the `BACKEND_URL` repository variable. **[`DEPLOYMENT.md`](../DEPLOYMENT.md)** is the full runbook — pipeline, one-time setup and troubleshooting.

---

## Architecture

```
UI (screens / widgets)
   │  dispatches events, reads state
   ▼
BLoC / Cubit  ──►  Repository  ──►  ApiClient (Dio)  ──►  Express API
   ▲                                   │
   └──────── state ◄───────────────────┘
```

| Layer | Folder | Notes |
|---|---|---|
| **DI** | `lib/core/di/` | `get_it` service locator (`sl`). Registers `SharedPreferences`, `ApiClient`, the repositories, `AuthBloc` (singleton), `UrlBloc` (factory) and `AppRouter` |
| **Network** | `lib/core/network/` | `ApiClient` wraps Dio with a 10 s timeout. Interceptors add `Bearer` tokens, clear the token on `401`, and log traffic |
| **Routing** | `lib/core/router/` | `go_router` with auth guards (see below). Clean path URLs, no `#` |
| **Repositories** | `lib/repositories/` | One per API area: `AuthRepository`, `UrlRepository`, `UserRepository`. They unwrap `{ data }` and turn errors into `Exception(message)` |
| **Models** | `lib/models/` | `UserModel`, `UrlModel`, `UrlAnalyticsModel` / `VisitModel` (Equatable, `fromJson`) |
| **App-wide state** | `lib/bloc/` | `AuthBloc` (session) and `UrlBloc` (the user's links) |
| **Feature state** | `lib/presentation/features/*/cubit/` | Per-screen cubits: alias check, links table query, link analytics, users |
| **UI** | `lib/presentation/` | Features, shared components, layout, theme, utils |

### Session and auth flow

1. `main.dart` sends `AppStarted` to `AuthBloc`. If a token is stored, the bloc calls `GET /auth/me` to restore the session.
2. While the status is `unknown`, the router keeps the user on `/splash` and remembers where they were going.
3. When the session is `authenticated`, a `BlocListener` in `main.dart` sends `FetchUrls`. On logout it sends `UrlsCleared`, so the next person using the same browser never sees the previous user's links.
4. Login and signup save the JWT in `SharedPreferences` under `jwt_token`. Logout calls the API and then deletes the token whether or not the call succeeded.

### Route guards ([`app_router.dart`](lib/core/router/app_router.dart))

- Not logged in and the route isn't public → `/login?from=<target>`
- Logged in and on `/login` or `/signup` → `from` or `/`
- `/users` without the admin role → `/`. The API enforces this too; the redirect just avoids showing a page that would fail.
- `from` is only followed if it is a path inside this app. This stops it being used to redirect users to other sites.

### Live alias check

[`AliasCheckCubit`](lib/presentation/features/dashboard/cubit/alias_check_cubit.dart) checks an alias in two stages. First it applies the format rules in the app instantly ([`link_rules.dart`](lib/presentation/utils/link_rules.dart)). Then, 400 ms after typing stops, it calls `GET /urls/check/:alias`. A request counter throws away responses that arrive out of order. Submitting is blocked only when the alias is **known** to be unusable. If the check itself fails, you can still submit, and the server has the final say.

---

## Project structure

```
lib/
├── main.dart                         # Bootstrap: DI, path URLs, BlocProviders, MaterialApp.router
├── core/
│   ├── di/injection_container.dart   # get_it registrations
│   ├── network/api_client.dart       # Dio, baseUrl, interceptors, getErrorMessage
│   └── router/app_router.dart        # go_router config + auth guards
├── bloc/
│   ├── auth/                         # AuthBloc / events / state
│   └── url/                          # UrlBloc / events / state (keeps a cached list of links)
├── models/                           # user_model, url_model, url_analytics_model
├── repositories/                     # auth_, url_, user_repository
└── presentation/
    ├── features/
    │   ├── auth/                     # login, signup, auth layout, password field
    │   ├── dashboard/                # create-link panel, alias field, stats, recent links
    │   ├── links/                    # table, toolbar, pagination, LinkQuery pipeline
    │   ├── analytics/                # overview, per-link analytics, visits table, link_stats
    │   └── users/                    # admin user list + add-user dialog
    ├── components/                   # buttons, cards, fields, toast, charts, QR dialog, skeletons…
    ├── layout/                       # AppShell (nav), breakpoints, responsive grid, page scaffold
    ├── theme/                        # colours, typography, spacing tokens, light/dark, ThemeModeCubit
    └── utils/                        # formatters, IP masking, user-agent parser, file saver, link launcher

test/presentation/                    # alias check, app shell, link query, link stats, users, utils
assets/fonts/                         # Inter (400–700), JetBrains Mono (400–500), bundled
web/                                  # index.html (loading splash), manifest, icons
```

## UI conventions

- **Responsive:** [`breakpoints.dart`](lib/presentation/layout/breakpoints.dart) defines `compact` (< 600), `medium` (600–1023), `expanded` (1024–1439) and `large` (≥ 1440). Use `context.breakpoint` and `responsiveValue(...)`. Don't compare widths directly.
- **Theme:** use the colours, spacing (4 pt scale) and typography from `presentation/theme/`. Don't hard-code values. Cards are flat with a 1 px border; shadows are only for menus, popovers and dialogs.
- **Fonts:** Inter for UI text, JetBrains Mono for short codes and URLs.
- **Web-only features** (such as downloading a QR code PNG) check `canSaveFiles`, and the button is hidden on other platforms.

## Libraries

| Package | Used for |
|---|---|
| `flutter_bloc`, `equatable` | State management |
| `dio` | HTTP |
| `go_router` | Routing, guards, deep links |
| `get_it` | Dependency injection |
| `shared_preferences` | JWT and theme preference |
| `qr_flutter` | QR codes for short links |
| `url_launcher` | Opening links |
| `intl` | Date and number formatting |
| `web`, `flutter_web_plugins` | Browser downloads, path URL strategy |

---

## Debugging

To read the running app's console and HTTP traffic, use the **flutter-peek** MCP tools. Launch the app with one of the **"+ peek"** configurations. They write the VM service URI to `/tmp/flutter_peek_vmservice.txt`, which is where flutter-peek looks for it.

- **Mobile and desktop:** start with `http_summary` and `list_console_logs(level: "error")`, then open individual entries with the `get_*` tools.
- **Web (Chrome):** the HTTP tools return nothing, because browsers have no `dart:io` HTTP profiler. Use the console tools instead. Dio's `LogInterceptor` prints every request, response and `DioException` to stdout, so search the console for the URL or status code.

Common problems:

| What you see | Check |
|---|---|
| `Network connection error` | Is the backend running on port 5000? Does `baseUrl` match? |
| Sent back to `/login` straight after logging in | The token was rejected (`401`). Check `JWT_SECRET` and `JWT_EXPIRES_IN` on the backend |
| Empty Users page or redirected away from it | Only `ADMIN` accounts can open it. See [creating an admin](../backend/README.md#creating-an-admin) |

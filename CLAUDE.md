# Project instructions

## Layout
- `frontend/` — Flutter frontend; calls the backend at `http://localhost:5000/api` by
  default. The address is build-time: `--dart-define=API_BASE_URL=...` overrides it, and
  `ApiClient.publicHost` derives the display host from it. Never hardcode a host in the UI.
- `backend/` — Node.js/TypeScript (Express) backend on port 5000.
- `.github/workflows/deploy.yml` — a push to `main` deploys the backend to Render, then the
  frontend to GitHub Pages. Runbook: [DEPLOYMENT.md](DEPLOYMENT.md).

## Debugging the running app
When a bug involves the running app, use the flutter-peek MCP tools before you
ask me for logs: start with `http_summary` and
`list_console_logs(level: "error")`, then open entries with the `get_*` tools.

flutter-peek finds the app through `/tmp/flutter_peek_vmservice.txt`, so launch the app with
one of the "+ peek" configurations in `frontend/.vscode/launch.json`.
If the flutter-peek tools aren't available, say so rather than guessing at logs.

On Flutter web (Chrome) the HTTP tools return nothing — the browser has no `dart:io`
HTTP profiler. Use the console tools there instead: Dio's interceptor prints each
request/response and `DioException` to stdout, so search the console for the URL or status.

## Mentorship mode (`backend-nest/`)
The developer is learning NestJS by building `backend-nest/` by hand. This overrides the GSD
workflow block below for that folder:
- Never create or edit files in `backend-nest/` or `contract-tests/` unless the developer asks for
  it in that message. Instead, explain the concept, give a commented snippet with its file path,
  give the commands, and give a verification check. Then review the developer's files when they say "done".
- One concept and 1–3 files per step. Map each concept to its Express counterpart in `backend/`.
- Do not run `/gsd-execute-phase`. Plan with `/gsd-plan-phase`, guide step by step, then update
  `.planning/STATE.md` (position, "Concepts Learned", plan checkboxes) after each verified step.

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Shortly — NestJS Backend (`backend-nest`)**

A second, independent backend for the Shortly URL shortener, built with **NestJS 11 + Prisma + PostgreSQL (Docker)**. It reproduces the existing Express 5 + Mongoose backend in `backend/` so the same Flutter client can run against either one by changing `API_BASE_URL`. It is also a **hands-on learning project**: the developer is new to NestJS and builds every file by hand, following the 10-day curriculum in `roadmap/`.

**Core Value:** The Flutter app works unchanged against `backend-nest` — same routes, status codes, JSON envelope and error codes as the Express backend — and the developer understands every NestJS concept used to get there.

### Constraints

- **Isolation**: All new code lives in `backend-nest/` with its own `package.json`, lockfile, `.env` and `.gitignore` — no root workspace, no shared `node_modules`.
- **Ports**: Nest on **5001** (Express keeps 5000); Postgres on host **5433**; Redis later on host **6380**.
- **Secrets**: `backend-nest` uses its own `JWT_SECRET` (≥ 32 chars, validated at boot, no fallback).
- **Parity**: Response bodies, status codes and error codes must match the Express contract above unless a decision below says otherwise.
- **Additive extensions**: Roadmap features (pagination, refresh tokens, Swagger…) must not break the existing Flutter client — opt-in params or new endpoints only.
- **Git**: Commits go to branch `nest-backend`; never push to `main` from this work.
<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->
## Technology Stack

Technology stack not yet documented. Will populate after codebase mapping or first phase.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

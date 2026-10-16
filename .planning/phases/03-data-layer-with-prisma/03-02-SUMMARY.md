---
phase: 03-data-layer-with-prisma
plan: 02
status: complete
completed: 2026-10-16
requirements: [DATA-03]
---

# 03-02 Summary: Global PrismaModule and PrismaService

## Built
- `src/prisma/prisma.service.ts`: `PrismaService extends PrismaClient`, `PrismaPg` adapter from `ConfigService` DATABASE_URL, `$connect` on init, `$disconnect` on destroy, fixed-string logs
- `src/prisma/prisma.module.ts`: `@Global()` module providing and exporting `PrismaService`; imported once in `AppModule`
- `main.ts`: `app.enableShutdownHooks()`
- `GET /demo/db` (TEMPORARY): `user.count()` + tagged-template `$queryRaw`; `DemoModule` has no PrismaModule import

## Verified (Nest only)
tsc, lint, build clean; `GET /demo/db` -> 200 `{users:0, ok:1}`; `/health` and `/api/nope` envelopes unchanged; no `*Unsafe` calls. On a separate port, boot logged `Connected to PostgreSQL`, SIGINT logged `Disconnected from PostgreSQL` and the process exited.

## Follow-ups
- `GET /demo/db` is deleted with `src/demo/` in Phase 4.
- The "remove enableShutdownHooks and see no disconnect" experiment was not observed by the reviewer.

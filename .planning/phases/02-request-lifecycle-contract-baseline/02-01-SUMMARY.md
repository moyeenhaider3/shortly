---
phase: 02-request-lifecycle-contract-baseline
plan: 01
status: complete
completed: 2026-10-16
requirements: [LIFE-01, LIFE-03]
---

# 02-01 Summary: AppException + global exception filter

Developer wrote all code in `backend-nest/`; mentor reviewed each step.

## Built
- `src/common/exceptions/app.exception.ts`: `AppException extends HttpException` `(message, status, code='INTERNAL_ERROR')`
- `src/common/filters/all-exceptions.filter.ts`: `@Catch()` filter; AppException as-is, other 4xx HttpException as `BAD_REQUEST`, everything else 500 `INTERNAL_SERVER_ERROR` with generic message; stack only via `Logger.error`
- `src/demo/` (TEMPORARY): `GET /demo/app-exception` (409) and `GET /demo/boom` (500)
- `app.module.ts`: `APP_FILTER` provider + `DemoModule`

## Verified
- `/demo/app-exception` -> 409 `{success,message,code}` exactly
- `/demo/boom` -> 500 generic body, sentinel `hunter2` absent
- `/health` still 200; `tsc` clean; lint: only the pre-existing `HealthController` warning (removed in 02-02)

## Review fix
- `DemoController` was declared in both `AppModule` and `DemoModule`; removed from `AppModule`.

## Follow-ups
- 02-02 refines the 4xx branch (404, JSON parse errors).
- Delete `src/demo/` in Phase 4 (tracked in STATE.md).

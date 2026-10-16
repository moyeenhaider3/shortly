---
phase: 02-request-lifecycle-contract-baseline
plan: 03
status: complete
completed: 2026-10-16
requirements: [LIFE-04, LIFE-01]
---

# 02-03 Summary: DTO validation with Express-parity errors

## Built
- `src/users/dto/create-user.dto.ts`: `CreateUserDto` (Express EMAIL_REGEX, trim/lowercase transforms, rules carry `context {code, rank}`)
- `src/common/pipes/validation-exception.factory.ts`: lowest-rank failure becomes `AppException(message, 400, code)`
- `main.ts`: global `ValidationPipe({transform, whitelist, exceptionFactory})`
- `POST /demo/users` (TEMPORARY) returning name/email/role only

## Verified (Nest only, by curl)
No body and `{}` -> rank 1; name `A` -> rank 2; bad email -> rank 3; short and numeric password -> `WEAK_PASSWORD`; role `SUPER` -> `INVALID_ROLE`; all-bad payload -> rank 2 message; valid body -> 201, email lowercased, `isAdmin` stripped, no password; earlier 500/404/parse-error envelopes unchanged; tsc, lint, build clean.

## Follow-ups
- Delete `src/demo/` in Phase 4 (keep `CreateUserDto`).
- Express parity diff deferred with 02-04/02-05.

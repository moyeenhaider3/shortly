---
phase: 02-request-lifecycle-contract-baseline
plan: 02
status: complete
completed: 2026-10-16
requirements: [LIFE-02, LIFE-03, LIFE-05]
---

# 02-02 Summary: 404, parse errors, logger, CORS, trust proxy

## Built
- Filter: 404 branch (`Cannot find METHOD originalUrl on this server`, `NOT_FOUND`)
- `main.ts`: `bodyParser:false`, `json()`/`urlencoded()`, error middleware turning body-parser errors (`type` string + `expose`) into `AppException(message, status, type)`; `trust proxy` 1; `enableCors`
- `LoggerMiddleware` (`[ISO] METHOD originalUrl`) applied with `forRoutes('*path')`
- `GET /demo/proto` (TEMPORARY) to observe `trust proxy`

## Verified (Nest only, by curl)
404 envelope; malformed JSON 400 `entity.parse.failed`; oversized body 413 `entity.too.large`; CORS and preflight headers; protocol https/http via `X-Forwarded-Proto`; 500 stays generic; tsc, lint, build clean.

## Findings
- Nest maps a body-parser SyntaxError to a plain BadRequestException (type/expose lost), hence the main.ts middleware.

## Follow-ups
- Express parity comparison deferred with 02-04/02-05.

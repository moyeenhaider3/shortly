# Project instructions

## Layout
- `frontend/` — Flutter frontend; calls the backend at `http://localhost:5000/api`.
- `backend/` — Node.js/TypeScript (Express) backend on port 5000.

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

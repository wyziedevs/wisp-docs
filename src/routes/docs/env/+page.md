---
title: Environment Variables
description: Every environment variable Wisp reads, grouped by what it controls: the server, logs and traces, and the CLI and tests.
group: Reference
order: 81
---

Read once at start. Switches take `on`/`off` (also `1`/`0`, `true`/`false`). Your own: `wisp::env("KEY")`, `wisp::env_or("KEY", 4)`, or `#[derive(Config)]`.

## Server

<div class="table-wrap">

| Name | What it does |
|---|---|
| `HOST`, `PORT` | listen address (`0.0.0.0:3000` in release, `127.0.0.1` in dev) |
| `WISP_DEV` | dev mode: on in debug builds (5xx details, `static/` from disk, dev log). `on` in a release build adds no dev page: the 5xx page is for debug builds only |
| `WISP_THREADS` | worker threads, one per CPU |
| `WISP_IO` | Linux: `epoll` instead of io_uring; `uring` fails at start where it does not work |
| `WISP_MAX_CONNS` | open connections before new ones get a 503 (10000; 0 no cap) |
| `WISP_BODY_LIMIT` | largest request body in bytes (1 MB); `const BODY_LIMIT` per route |
| `WISP_HANDLER_TIMEOUT` | handler timeout in seconds |
| `WISP_WS_IDLE` | seconds a quiet WebSocket lives (60; 0 never) |
| `WISP_CLIENT_IP_HEADER` | header with the client address behind a proxy; the client is the last address of the header's last line, the one the trusted proxy added; a client can forge the first |
| `WISP_SECURE_HEADERS` | `off` leaves out `nosniff` and `referrer-policy` |
| `WISP_HSTS` | `on` adds `strict-transport-security` |
| `WISP_SERVER_TIMING` | `Server-Timing` on every answer (on in dev, off otherwise; off costs nothing): `total;dur=ms`, and in a debug build `before`, `handler`, `render` |
| `WISP_PROBLEM_JSON` | `on`: errors as RFC 9457 problem JSON |
| `WISP_REQUEST_ID` | `on`: every request gets an id (`cx.request_id()`), echoed as `x-request-id` |
| `WISP_API_DOCS` | serve `/_wisp/openapi.json` and `/_wisp/docs` (on in dev; no `/_wisp/docs` on Cloudflare, Pages, Vercel, Netlify) |
| `WISP_SECRET`, `WISP_SECRET_OLD` | key for signed cookies and tokens, and the one before (rotation) |
| `WISP_DATA` | folder for table files (`off` keeps tables in memory; blank is unset) |
| `WISP_FSYNC` | `second` (default), `always`, `off` |
| `WISP_STORE` | a store for tables: `d1:DB`, `deno-kv`, `libsql://…` |
| `WISP_STORE_TOKEN` | bearer token for a `libsql://` store |
| `WISP_STORE_POLL` | seconds between store change polls (several servers); not a number stops the server at start |
| `WISP_BASE` | base path, set at build (`/app`) |
| `SITE_URL` | site address for sitemaps, feeds and absolute links (also read from `.env`; blank is unset, a trailing `/` is dropped) |
| `SITE_TITLE` | feed title |
| `METRICS_KEY` | bearer key for `/_wisp/metrics` |
| `CRON_SECRET` | bearer key hosts send to `/_wisp/cron/<schedule>` |
| `WISP_NODE_HTTP` | `1`: Node, Bun and Deno targets serve with the runtime's own HTTP server |
| `AWS_LAMBDA_RUNTIME_API` | set by Lambda: the binary answers its runtime API |
| `WISP_EDITOR`, `EDITOR` | what the dev error dialog's Open runs (`code -g`) |

</div>

`#[derive(Rest)]` bearer tokens and OAuth client ids and secrets are read from the names their attributes give.

## Set by the CLI and Hosts

Not for you to set. `wisp build` and the host bridges set them for the app they build or run.

<div class="table-wrap">

| Name | What it does |
|---|---|
| `WISP_REQUEST_ONLY` | `1` while `wisp build` builds for Cloudflare, Pages, Vercel or Netlify: leaves the server loop for raw connections out of the wasm (541 KB instead of 584 KB for the bench app). An older `wisp` ignores it |
| `WISP_WARM_UP` | the Cloudflare worker's warm-up instance: it answers one request with the runtime alone (no `init`, hook or random) so the real first request runs compiled code (`WISP_WARM_UP=1`; first request faster than with no warm-up, not as fast as running the app) |

</div>

## Logs and Traces

<div class="table-wrap">

| Name | What it does |
|---|---|
| `WISP_LOG` | `json`: a JSON line per request |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP/HTTP traces to `<endpoint>/v1/traces` |
| `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` | the traces URL, as is |
| `OTEL_EXPORTER_OTLP_HEADERS` | `api-key=…,x=…` |
| `OTEL_EXPORTER_OTLP_TRACES_HEADERS` | the same, for traces only (wins) |
| `OTEL_SERVICE_NAME` | service name on spans |
| `OTEL_BSP_SCHEDULE_DELAY` | batch delay in ms (5000) |

</div>

## CLI and Tests

<div class="table-wrap">

| Name | What it does |
|---|---|
| `WISP_NO_UPDATE_CHECK` | `1` silences the CLI-older-than-app warning |
| `WISP_PORT_TRIES` | how many next ports `wisp dev` tries when one is taken (20) |
| `WISP_CWEBP` | the `cwebp` `wisp build` uses for images |
| `WISP_SASS` | the Dart Sass for `src/app.scss` |
| `WISP_TSC` | the `tsc` for `wisp check --types` |
| `WISP_BROWSER` | Chrome or Edge for browser tests |
| `NO_COLOR` | plain CLI output |

</div>

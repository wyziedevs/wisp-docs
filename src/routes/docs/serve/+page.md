---
title: Serve Extras
description: Gzip, ranges, security headers, health checks and handler timeouts.
group: Deploy and Run
order: 62
---

All on the built-in server; each costs nothing for what does not use it.

| Feature | What it does |
|---|---|
| gzip | Embedded text files (`wisp.js`, app css, client modules, `static/` in a release build) are compressed once, on the first request with `accept-encoding: gzip`, then that copy is sent (`vary: accept-encoding`). Pages and API answers are not: a proxy or CDN does those better. |
| Range | Files answer `range: bytes=a-b`, `a-` and `-n` with 206 and `content-range`; past the end is 416. One range only: several, or a malformed one, get the whole file. A range is of the file, never of its gzip. `if-range` is honored with the file's etag. |
| Security headers | HTML and error pages carry `x-content-type-options: nosniff` and `referrer-policy: strict-origin-when-cross-origin` unless the app set its own. |
| Health | `GET /_wisp/health` is 200 `ok`, and 503 `stopping` once the server drains, so a load balancer moves traffic away first. |
| Handler timeout | A handler still waiting after the limit is dropped and answers 503. It is checked when the handler waits: one that blocks its thread without awaiting cannot be stopped. |
| OpenTelemetry | See [Observe](/docs/deploy-observe). |

| Env var | What it does |
|---|---|
| `WISP_HSTS=on` | adds `strict-transport-security` (one year, subdomains) to every answer; for a site served over https by the proxy in front |
| `WISP_SECURE_HEADERS=off` | leaves out the first two security headers |
| `WISP_HANDLER_TIMEOUT=30` | handler timeout in seconds |

---
title: Deploying
description: Binary, static, prerender, service, Docker, logs, metrics and traces.
group: Deploy and run
order: 60
---

| You have | Use |
|---|---|
| VPS or server | `wisp build`, copy the binary; `wisp service install` keeps it running |
| Container host (Fly.io, Railway, Render, Cloud Run, Azure Container Apps) | `wisp build --docker` |
| Static host (GitHub/GitLab Pages, S3) | `wisp build --static` (or `--spa`) |
| Edge or serverless (Cloudflare, Deno Deploy, Vercel, Netlify, Amplify, Firebase, Azure Static Web Apps) | `wisp build --target <host>` |
| AWS Lambda / Bun | `--target lambda` / `--target bun` |

An app that signs cookies needs `WISP_SECRET` (32+ random characters) on
every host.

A plain `wisp build` inside a host's CI picks that target from its
variables and says so: `WORKERS_CI` or `CF_PAGES` (cloudflare), `VERCEL`,
`NETLIFY`, `DENO_DEPLOYMENT_ID` (deno), `AWS_APP_ID` (node). Vercel gets
`.vercel/output` in the app folder. `--target native` forces the plain
binary.

`wisp deploy init <cloudflare|deno|vercel|netlify|lambda|fly|pages>` writes
`.github/workflows/deploy.yml` (build and deploy on push to `main`; its first
line names the secrets; `--force` replaces it). `wisp deploy init
fly|render|railway` writes that host's config (and a Dockerfile if none).

## Binary, static, prerender

`wisp build`: one release binary with static files and styles inside,
listening on `$HOST:$PORT` (`0.0.0.0:3000` in release).

HTTP/2 without a proxy in front: the `h2` feature serves h2c with prior
knowledge on the same port (a proxy that speaks h2c to its backend, or
`curl --http2-prior-knowledge`); HTTP/1 is unchanged and pays nothing.
There is no TLS in the server, so browsers still want the proxy.

```toml
# Cargo.toml
wisp = { version = "..", features = ["h2"] }
```

`wisp build --static [--out site]` writes `dist/`: every parameterless page
as `about/index.html`, plus `static/` and the `/_app` files (with
`--sourcemap`, their `.map`s). A `[params]` route lists its pages:

```html
<!-- src/routes/blog/[slug]/+page.wisp (or its +page.rs) -->
---
fn entries() -> Vec<&'static str> {
    vec!["hello", "second-post"]
}
---
```

`entries` returns a `String` or `&str` per param, or a tuple in path order;
for `[[optional]]` and `[...rest]` an empty string leaves it out. A route
with actions or a `+server.rs` needs a server (the export warns).

`--spa` is `--static` plus an `index.html` fallback (Netlify:
`/* /index.html 200` in `_redirects`; Cloudflare Pages with no `404.html`).
A `const SSR: bool = false;` page whose `[params]` have no `entries` is
written once (params `0`) to `_app/spa/N.html`; `index.html` lists them and
wisp.js draws the one whose route fits, with that address's params. It
gets its data from `+page.js`.

Prerender in a server build:

```html
---
const PRERENDER: bool = true;
fn entries() -> Vec<&'static str> { vec!["hello", "second-post"] }  // with [params]
let post = db::post(&slug).await?;
---
```

`wisp build` builds the binary, runs it once (`init` runs) to render those
pages, builds again with the bytes inside, and serves them as they are (ETag,
304). Before that (`cargo run`, other targets) each worker keeps the first
render. One render serves all, so `cx` in statements, markup or `load` is a
build error; its layouts render once as for a request without cookies.
`--static` prerenders every page.

## Service

`wisp build`, then `wisp service install` (as root or an administrator) runs
the release binary from the app folder as an OS service that starts at boot.
`start`, `stop`, `status` and `uninstall` follow. Options: `--user <name>`,
`--port <n>`, `--name <service>` (default the package name), `--dry-run` (print
what would be written and run, change nothing).

- Linux: `/etc/systemd/system/<name>.service` with `Restart=on-failure`,
  `EnvironmentFile=-/etc/<name>.env` (made 0600 if missing: put `WISP_SECRET`
  there), `WorkingDirectory`, `LimitNOFILE=1048576`, `User=` when given, and
  `AmbientCapabilities=CAP_NET_BIND_SERVICE` for `--port` below 1024. Then
  `daemon-reload`, `enable`, `start`. The `--user` must be able to read the
  app folder.
- macOS: `/Library/LaunchDaemons/wisp.<name>.plist`, loaded with `launchctl`.
- Windows: a scheduled task at startup (`schtasks`, as SYSTEM). A true Windows
  service must answer the Service Control Manager, which needs `unsafe`
  FFI that Wisp does not have, so `stop` ends the process without draining.

SIGTERM (systemd stop, launchd) and Ctrl+C reach the runtime, which stops
accepting and drains for up to 10 seconds.

## Docker

```sh
wisp build --docker              # --force replaces existing files
docker build -t my-app .
docker run -p 3000:3000 -e WISP_SECRET=... my-app
```

A two-stage `Dockerfile` (`rust:slim` then `debian:stable-slim`, `HOST=0.0.0.0`,
`WISP_DATA=/data`) and `.dockerignore`. Saved tables live in `/data`: mount
a volume (`-v my-app-data:/data`). Docker's default seccomp refuses
io_uring, so the server uses an epoll per worker; a profile allowing
`io_uring_setup`, `io_uring_enter`, `io_uring_register` brings it back.

## Logs, metrics, traces

Off until set; binary, Docker, Lambda; no app code.

`WISP_LOG=json`: a JSON line per request on stdout (`off` default):
`{"time","method","route":"/blog/[slug]","path":"/blog/hello","status","ms","bytes","id","ip"}`.
`route` is the route folder (null if none), `path` omits the query, `ip` is
`cx.client_ip()` (`WISP_CLIENT_IP_HEADER`); the id is the client's
`x-request-id` or made, and is echoed.

`METRICS_KEY` serves `/_wisp/metrics` (Prometheus text) to
`Authorization: Bearer <METRICS_KEY>` (else 401; unset: 404; scrape config
`metrics_path: /_wisp/metrics`, `authorization: { credentials: <key> }`):
`wisp_requests_total{route, status}` (status class `2xx`; `route=""` if none
matched), `wisp_request_duration_seconds{route}` (histogram, 1 ms to 10 s),
`wisp_requests_in_flight`, `wisp_uptime_seconds`,
`process_resident_memory_bytes` (Linux).

`OTEL_EXPORTER_OTLP_ENDPOINT` (`http://localhost:4318`; or
`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`, used as is) sends OTLP/HTTP JSON traces
to `<endpoint>/v1/traces`: a server span per request (`GET /blog/[slug]`),
an incoming `traceparent` continued, the reply carrying its own (`trace` in
`WISP_LOG=json`). `OTEL_SERVICE_NAME`, `OTEL_EXPORTER_OTLP_HEADERS`
(`api-key=…,x=…`), `OTEL_BSP_SCHEDULE_DELAY` (ms, 5000). A down collector
costs requests nothing. Plain HTTP only (use a Collector for TLS).

```rust
let _s = wisp::span("charge card"); // child span until dropped
let t = wisp::traceparent();        // Some("00-…-01"): header for a downstream call
```

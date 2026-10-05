---
title: Deploying
description: Deploy a Wisp app as a single binary, a static or SPA site, a prerendered build, a system service or a Docker image, with the steps for each option.
group: Deploy and Run
order: 60
---

Run `wisp build`, copy the binary, run it. Pick the build for your host:

<div class="table-wrap">

| You have | Use |
|---|---|
| VPS or server | `wisp build`; `wisp service install` keeps it running ([VPS](/docs/hosting/vps/)) |
| Container host ([Fly.io](/docs/hosting/fly/), [Railway](/docs/hosting/railway/), [Render](/docs/hosting/render/), [Cloud Run](/docs/hosting/cloud-run/), [Azure](/docs/hosting/azure/)) | `wisp build --docker` ([Docker](/docs/hosting/docker/)) |
| Static host ([GitHub Pages](/docs/hosting/github-pages/), GitLab Pages, S3) | `wisp build --static` (or `--spa`) |
| Edge or serverless ([Cloudflare](/docs/hosting/cloudflare/), [Deno Deploy](/docs/hosting/deno-deploy/), [Vercel](/docs/hosting/vercel/), [Netlify](/docs/hosting/netlify/), Amplify, Firebase, [Azure Static Web Apps](/docs/hosting/azure/)) | `wisp build --target <host>` ([Edge and serverless targets](/docs/deploy-targets/)) |
| [AWS Lambda](/docs/hosting/aws-lambda/) / [Bun](/docs/hosting/bun/) / [Node](/docs/hosting/node/) | `--target lambda` / `--target bun` / `--target node` |

</div>

An app that signs cookies needs `WISP_SECRET` (32+ random characters, for example `openssl rand -hex 32`) on every host. Without it the server logs one line at start, and a request that needs it answers 500 while the server keeps running. Logs, metrics and traces: [Observe](/docs/deploy-observe/). Step by step for each host: [Hosting](/docs/hosting/).

A plain `wisp build` inside a host's CI picks the target from its variables and says so: `WORKERS_CI` or `CF_PAGES` (cloudflare), `VERCEL` (output in `.vercel/output`), `NETLIFY`, `DENO_DEPLOYMENT_ID` (deno), `AWS_APP_ID` (node). `--target native` forces the plain binary.

`wisp deploy init <host>` writes a config:

<div class="table-wrap">

| Host | Writes |
|---|---|
| `cloudflare`, `deno`, `vercel`, `netlify`, `lambda`, `pages` (GitHub Pages) | `.github/workflows/deploy.yml`: build and deploy on push to `main`; line 1 names the secrets; `--force` replaces it |
| `fly`, `render`, `railway` | that host's config, and a Dockerfile if none |

</div>

## Binary

`wisp build` makes one release binary with static files and styles inside. It listens on `$HOST:$PORT` (`0.0.0.0:3000` in release).

HTTP/2 without a proxy: the `h2` feature serves h2c with prior knowledge on the same port (for a proxy that speaks h2c, or `curl --http2-prior-knowledge`). HTTP/1 is unchanged and pays nothing. Streams are answered at once, within the flow-control windows. There is no TLS in the server, so browsers still want the proxy.

```toml
# Cargo.toml
wisp = { version = "..", features = ["h2"] }
```

## Static and SPA

`wisp build --static [--out site]` writes `dist/`: every parameterless page as `about/index.html`, plus `static/` and the `/_app` files (`.map`s with `--sourcemap`). Forms need a server: the export warns for each page with actions, and for each exported page whose HTML holds a form that posts (`method="post"`, `action="?/name"`), whichever page its action is on. A `[params]` route lists its pages:

```html
<!-- src/routes/blog/[slug]/+page.wisp (or its +page.rs) -->
---
fn entries() -> Vec<&'static str> {
    vec!["hello", "second-post"]
}
---
```

- `entries` returns a `String` or `&str` per param, or a tuple in path order. For `[[optional]]` and `[...rest]` an empty string leaves it out.
- A route with actions or a `+server.rs` needs a server (the export warns).
- `--spa` is `--static` plus an `index.html` fallback (Netlify: `/* /index.html 200` in `_redirects`; Cloudflare Pages with no `404.html`).
- A `const SSR: bool = false;` page whose `[params]` have no `entries` is written once (params `0`) to `_app/spa/N.html`. `index.html` lists them, and wisp.js draws the one whose route fits, with that address's params. It gets its data from `+page.js`.

## Prerender

```html
---
const PRERENDER: bool = true;
// with [params]
fn entries() -> Vec<&'static str> {
    vec!["hello", "second-post"]
}
let post = db::post(&slug).await?;
---
```

- `wisp build` builds the binary, runs it once (`init` runs) to render those pages, builds again with the bytes inside, and serves them as they are (ETag, 304).
- Before that (`cargo run`, other targets) each worker keeps the first render.
- One render serves all, so `cx` in statements, markup or `load` is a build error. Its layouts render once, as for a request without cookies.
- `--static` prerenders every page.
- The build calls `wisp::prerender` on the app; you never call it yourself.

## Service

`wisp build`, then `wisp service install` (as root or administrator; it refuses an app folder with a quote, `%` or a control character in its path) runs the release binary from the app folder as an OS service that starts at boot. Then `start`, `stop`, `status`, `uninstall`.

<div class="table-wrap">

| Option | What it does |
|---|---|
| `--user <name>` | run as that user |
| `--port <n>` | listen port |
| `--name <service>` | service name (default: the package name) |
| `--dry-run` | print what would be written and run, change nothing |

</div>

- Linux: `/etc/systemd/system/<name>.service` with `Restart=on-failure`, `EnvironmentFile=-/etc/<name>.env` (made 0600 if missing: put `WISP_SECRET` there), `WorkingDirectory`, `LimitNOFILE=1048576`, `User=` when given, and `AmbientCapabilities=CAP_NET_BIND_SERVICE` for `--port` below 1024. Then `daemon-reload`, `enable`, `start`. The `--user` must read the app folder.
- macOS: `/Library/LaunchDaemons/wisp.<name>.plist`, loaded with `launchctl`.
- Windows: a scheduled task at startup (`schtasks`, as SYSTEM). A true Windows service must answer the Service Control Manager, which needs `unsafe` FFI that Wisp does not have, so `stop` ends the process without draining.

SIGTERM (systemd stop, launchd) and Ctrl+C make the runtime stop accepting and drain for up to 10 seconds.

## Docker

```sh
wisp build --docker              # --force replaces existing files
docker build -t my-app .
docker run -p 3000:3000 -e WISP_SECRET=... my-app
```

- Writes a two-stage `Dockerfile` (`rust:slim` then `debian:stable-slim`, `HOST=0.0.0.0`, `WISP_DATA=/data`) and `.dockerignore`.
- Saved tables live in `/data`: mount a volume (`-v my-app-data:/data`).
- Docker's default seccomp refuses io_uring, so the server uses an epoll per worker. A profile allowing `io_uring_setup`, `io_uring_enter`, `io_uring_register` brings it back. The io_uring backend is implemented but untested end to end (the test VPS kernel refuses io_uring buffer rings); epoll is the tested default.

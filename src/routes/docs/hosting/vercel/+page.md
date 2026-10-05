---
title: Host on Vercel
description: Deploy a Wisp app to Vercel as a prebuilt output, choose the Node function or the Edge runtime per route, and set up cron and secrets.
group: Hosting
order: 78
---

Vercel runs the app as WebAssembly in a Node function, or on its Edge runtime.

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target vercel                   # .vercel/output
wisp build --target vercel --edge            # every route on the Edge runtime
```

In Vercel's CI a plain `wisp build` picks the target from `VERCEL` and writes to `.vercel/output`.

## Deploy

```sh
npx vercel deploy --prebuilt
```

`wisp deploy init vercel` writes a GitHub Actions workflow that builds and deploys on push to `main`. It reads the secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID`.

## Environment

- `WISP_SECRET` as an environment variable of the project, for an app that signs cookies.
- Read other values with `wisp::env("KEY")` (`std::env::var` sees nothing).
- `CRON_SECRET`, if the app has `wisp::cron`: set it too; Vercel's cron sends it.
- [Environment variables](/docs/env/).

## Limits

- Per route: `const RUNTIME: wisp::Runtime = wisp::Runtime::Edge;` in a `+page.rs` or `+server.rs` puts that route on the Edge runtime and the rest stay on the Node function. See [Edge runtime per route](/docs/deploy-targets/#edge-runtime-per-route).
- The build stops, naming the route, if an Edge route uses what WebAssembly lacks (`std::fs`, `std::thread`, `std::process`, `std::net`, websockets).
- WebSockets answer 501; use `Response::events` (SSE). Streaming is live.
- Vercel may freeze the instance after the response, so finish background work first.
- Cron: `wisp::cron` becomes `crons` in `config.json` (Hobby plan: daily only).
- `wisp::channel`, `wisp::every` and `RateLimit` are not in the edge build.

## Files and Data

- `static/` goes to `.vercel/output/static` and stays the CDN's.
- `Table::saved` and `Rest` are per-instance memory. `WISP_STORE` accepts `libsql://` (Turso or any libSQL server, with `WISP_STORE_TOKEN`); see [Saved tables](/docs/deploy-targets/#saved-tables).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

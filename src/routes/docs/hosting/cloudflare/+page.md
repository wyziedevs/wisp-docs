---
title: Host on Cloudflare
description: Deploy a Wisp app to Cloudflare Workers or Cloudflare Pages as WebAssembly, with secrets, D1 for saved tables, cron triggers and the edge limits.
group: Hosting
order: 76
---

Cloudflare runs the app as WebAssembly on its edge, as a Worker (`cloudflare`) or on Pages (`pages`).

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target cloudflare               # Workers: dist/cloudflare
wisp build --target pages                    # Pages: dist/pages
```

`--out <folder>` changes the folder. No wasm-bindgen or other tool is needed. In Cloudflare's CI a plain `wisp build` picks the target from `WORKERS_CI` or `CF_PAGES`.

## Deploy

Workers, from `dist/cloudflare`:

```sh
npx wrangler deploy
npx wrangler secret put WISP_SECRET
```

Pages, from `dist/pages` (`_worker.js` and `_routes.json`):

```sh
npx wrangler pages deploy .
```

For Workers, `wisp deploy init cloudflare` writes a GitHub Actions workflow that builds and deploys on push to `main`; it reads the secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

## Environment

- `WISP_SECRET`: a Worker secret (above), or on Pages under Settings.
- Read other values with `wisp::env("KEY")`; `std::env::var` sees nothing and there is no `.env`.
- `CRON_SECRET`, if the app has `wisp::cron`: set it as a secret; the cron triggers send it.
- `WISP_STORE=d1:DB` and the rest: [Environment variables](/docs/env/).

## Limits

- No threads, sockets or files: use `wisp::spawn` and `wisp::sleep`, not `tokio::spawn`. See [What works on the edge](/docs/deploy-targets/#what-works-on-the-edge).
- WebSockets work through `WebSocketPair`, one connection to one isolate ([WebSockets](/docs/deploy-targets/#websockets)); `Response::stream` and `Response::events` (SSE) are live.
- `wisp::channel`, `wisp::every` and `RateLimit` are not in the edge build.
- Started timers and fetches keep the instance alive (`waitUntil`).
- Cron: `wisp::cron` becomes `[triggers] crons` in `wrangler.toml` (Workers); Pages has no trigger, so the build says so and stops.

## Files and Data

- `static/` goes into the build output and is served by Cloudflare before the app runs (Workers: `public` with an `[assets]` entry in `wrangler.toml`; Pages: beside `_worker.js`).
- `Table::saved` and `Rest` are per-instance memory unless `WISP_STORE=d1:DB` is set, with a `[[d1_databases]]` binding named `DB` in `wrangler.toml`. See [Saved tables](/docs/deploy-targets/#saved-tables).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

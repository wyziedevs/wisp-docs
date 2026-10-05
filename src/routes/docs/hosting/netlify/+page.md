---
title: Host on Netlify
description: Deploy a Wisp app to Netlify as a function or an edge function with the Netlify CLI, with secrets, scheduled functions and the platform limits.
group: Hosting
order: 79
---

Netlify runs the app as WebAssembly in a function, or in an edge function with `--edge`.

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target netlify                  # dist/netlify
wisp build --target netlify --edge           # edge function
```

In Netlify's CI a plain `wisp build` picks the target from `NETLIFY`.

## Deploy

From `dist/netlify`:

```sh
npx netlify deploy --prod
```

`wisp deploy init netlify` writes a GitHub Actions workflow that builds and deploys on push to `main`. It reads the secrets `NETLIFY_AUTH_TOKEN` and `NETLIFY_SITE_ID`.

## Environment

- `WISP_SECRET` as an environment variable of the site, for an app that signs cookies.
- Read other values with `wisp::env("KEY")` (`std::env::var` sees nothing).
- `CRON_SECRET`, if the app has `wisp::cron`: set it too; the scheduled function sends it.
- [Environment variables](/docs/env/).

## Limits

- Per route: `const RUNTIME: wisp::Runtime = wisp::Runtime::Edge;` puts a route on the edge; the rest stay on the function. See [Edge runtime per route](/docs/deploy-targets/#edge-runtime-per-route).
- Edge functions have the edge limits (no `std::fs`, `std::thread`, `std::process`, `std::net`, websockets); the build stops, naming the route, if an Edge route uses them.
- WebSockets answer 501; use `Response::events` (SSE). Streaming is live.
- Netlify keeps the instance alive (`waitUntil`) for started timers and fetches.
- Cron: `wisp::cron` becomes a scheduled function. With `--edge` there is no trigger to write: the build says so and stops.
- `wisp::channel`, `wisp::every` and `RateLimit` are not in the edge build.

## Files and Data

- `static/` goes to `public`, which Netlify serves; with `--edge` the edge function skips it via `excludedPath`.
- `Table::saved` and `Rest` are per-instance memory. `WISP_STORE` accepts `libsql://` (Turso or any libSQL server, with `WISP_STORE_TOKEN`); see [Saved tables](/docs/deploy-targets/#saved-tables).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

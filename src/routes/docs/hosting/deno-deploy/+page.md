---
title: Host on Deno Deploy
description: Deploy a Wisp app to Deno Deploy as WebAssembly with deployctl, use Deno KV for saved tables, and know the limits of the platform.
group: Hosting
order: 77
---

Deno Deploy runs the app as WebAssembly on Deno's edge.

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target deno                     # dist/deno (--out <folder>)
```

In Deno Deploy's CI a plain `wisp build` picks the target from `DENO_DEPLOYMENT_ID`.

## Deploy

From `dist/deno`:

```sh
deployctl deploy --entrypoint main.ts
deno run -A main.ts          # try it locally
```

`wisp deploy init deno` writes a GitHub Actions workflow that builds and deploys on push to `main` with `denoland/deployctl`. It reads no secrets: it uses GitHub's OIDC token. Edit `project: <name>` in it to your project.

## Environment

- `WISP_SECRET` as a project environment variable in Deno Deploy, for an app that signs cookies.
- Read other values with `wisp::env("KEY")`; `std::env::var` sees nothing and there is no `.env`.
- `WISP_STORE=deno-kv` and the rest: [Environment variables](/docs/env/).

## Limits

- Deno Deploy has no sockets, so it always serves with `Deno.serve`. (Locally `deno run -A main.ts` reads raw sockets, and `WISP_NODE_HTTP=1` selects `Deno.serve`.)
- WebSockets answer 501; use `Response::events` (SSE). `Response::stream` and `Response::events` are live.
- No threads or files: use `wisp::spawn` and `wisp::sleep`. See [What works on the edge](/docs/deploy-targets/).
- `wisp::channel`, `wisp::every` and `RateLimit` are not in the edge build, and there is no cron trigger to write: the build says so and stops when the app uses `wisp::cron`.

## Files and Data

- `dist/deno` has no separate static folder: the app answers for `static/` itself.
- `Table::saved` and `Rest` are per-instance memory unless `WISP_STORE=deno-kv` (or `deno-kv:<path>` for a file or URL) is set. See [Saved tables](/docs/deploy-targets/).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

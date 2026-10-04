---
title: Host on Node
description: Run a Wisp app on Node 20 or newer as a WebAssembly build with npm start, for Amplify, Firebase, Azure, Stormkit, Zeabur or any Node host.
group: Hosting
order: 82
---

The `node` target runs the app as WebAssembly under Node 20 or newer. It is the target for Amplify, Firebase, Azure, Stormkit, Zeabur and any other Node host. For your own server, the [native binary](/docs/hosting/vps/) is faster and has more features.

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target node                     # dist/node (--out <folder>)
```

In AWS Amplify's CI a plain `wisp build` picks `node` from `AWS_APP_ID`.

## Deploy

From `dist/node`:

```sh
npm start
```

It runs `node server.mjs` and listens on `$PORT`. The output's `hosts/` folder has a note for each host (`amplify.md`, `firebase.md`, `azure.md`, `stormkit.md`, `zeabur.md`) with its manifest or function glue.

## Environment

- `WISP_SECRET`: set it in the host's environment settings, for an app that signs cookies.
- Read other values with `wisp::env("KEY")` (`std::env::var` sees nothing).
- `WISP_NODE_HTTP=1` serves with `node:http`. See [Environment variables](/docs/env/).

## Limits

- The app's own HTTP/1.1 parser answers over raw sockets. At startup a request over loopback must be answered as the app answers it (twice, on one connection); if not, or with `WISP_NODE_HTTP=1`, it serves with `node:http` (one stderr line says which). Only that path reads at most `WISP_BODY_LIMIT` (default 1 MB) of a body and answers 413 past it.
- WebSockets answer 501; use `Response::events` (SSE). Streaming is live.
- No threads or files: use `wisp::spawn` and `wisp::sleep`. See [What works on the edge](/docs/deploy-targets/).
- There is no cron trigger to write: the build says so and stops when the app uses `wisp::cron`.

## Files and Data

- `Table::saved` and `Rest` are per-instance memory unless `WISP_STORE` is set (`libsql://`; see [Saved tables](/docs/deploy-targets/)).

## More

[Host on Azure](/docs/hosting/azure/), [Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

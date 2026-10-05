---
title: Host on Bun
description: Run a Wisp app on Bun as a WebAssembly build served with Bun.listen, with the fallback to Bun.serve and the limits of the build.
group: Hosting
order: 81
---

Bun runs the app as WebAssembly, serving raw sockets with `Bun.listen`. For a plain server, the [native binary](/docs/hosting/vps/) is faster and has more features.

## Build

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target bun                      # dist/bun (--out <folder>)
```

## Deploy

From `dist/bun`:

```sh
bun server.mjs
```

The folder's `package.json` has `"start": "bun server.mjs"`. Copy the folder to the machine and run it there.

## Environment

- `WISP_SECRET`: set it in the process environment, for an app that signs cookies.
- Read other values with `wisp::env("KEY")` (`std::env::var` sees nothing).
- `WISP_NODE_HTTP=1` serves with `Bun.serve` instead of `Bun.listen`. See [Environment variables](/docs/env/).

## Limits

- The app's own HTTP/1.1 parser answers over raw sockets (pipelining, keep-alive, chunked bodies, 413, 431 and each route's `BODY_LIMIT`). At startup a request over loopback must be answered as the app answers it (twice, on one connection); if not, it serves with `Bun.serve` and one stderr line says so.
- WebSockets work: Wisp's parser on the raw socket, or `server.upgrade` with `Bun.serve`.
- No threads or files: use `wisp::spawn` and `wisp::sleep`. See [What works on the edge](/docs/deploy-targets/).
- There is no cron trigger to write: the build says so and stops when the app uses `wisp::cron`.

## Files and Data

- `Table::saved` and `Rest` are per-instance memory unless `WISP_STORE` is set (`libsql://`; see [Saved tables](/docs/deploy-targets/)).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

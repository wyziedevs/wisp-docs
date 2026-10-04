---
title: Host on a VPS
description: Run a Wisp app as one binary on a VPS or any server you control, keep it running as a service, and put a proxy in front for TLS.
group: Hosting
order: 71
---

A VPS is a server you rent and run yourself. Wisp fits it best: one binary, no runtime to install, and the full feature set (WebSockets, streaming, saved tables on disk).

## Build

```sh
wisp build
```

This makes one release binary with the static files and styles inside. A native binary runs only on the OS and CPU it was built for, so build on the server or on a machine like it.

## Deploy

Copy the binary to the server and run it. It listens on `$HOST:$PORT` (`0.0.0.0:3000` in release).

```sh
scp target/release/my-app me@server:/srv/my-app/
ssh me@server 'cd /srv/my-app && WISP_SECRET=... ./my-app'
```

To keep it running and start it at boot, run this on the server from the app folder, as root:

```sh
wisp service install --user my-app --port 3000
wisp service status
```

On Linux this writes a systemd unit with `Restart=on-failure` and `EnvironmentFile=-/etc/<name>.env`. See [Deploying](/docs/deploy/) for every option, and for macOS and Windows.

## Environment

- `WISP_SECRET`: 32 or more random characters, needed by an app that signs cookies. With `wisp service install` on Linux, put it in `/etc/<name>.env` (made 0600 if missing).
- `HOST`, `PORT`, `WISP_THREADS` and the rest: [Environment variables](/docs/env/).

## Limits

- There is no TLS in the server. Put a reverse proxy in front for HTTPS; set `WISP_CLIENT_IP_HEADER` so `cx.client_ip()` sees the real address.
- SIGTERM and Ctrl+C stop accepting and drain for up to 10 seconds.
- WebSockets and streaming both work.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables (`Table::saved`, `#[derive(Rest)]`) are log files in the `data` folder next to where you run it; `WISP_DATA` moves it. Back that folder up. See [Where rows are kept](/docs/api-tables/).

## More

[Deploying](/docs/deploy/), [Logs, metrics and traces](/docs/deploy-observe/), [Serve extras](/docs/serve/).

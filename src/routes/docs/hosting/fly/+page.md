---
title: Host on Fly.io
description: Deploy a Wisp app to Fly.io from its Dockerfile, with wisp deploy init fly writing fly.toml and a Dockerfile if there is none.
group: Hosting
order: 73
---

Fly.io runs containers on machines it starts for you. Wisp builds the Dockerfile as it is.

## Build

```sh
wisp deploy init fly       # fly.toml, and a Dockerfile if there is none
```

This writes `fly.toml` (internal port 3000, `force_https`, machines that stop when idle and start on a request, 256 MB, one shared CPU) and the same `Dockerfile` as `wisp build --docker`. The app name in it is your package name and must be unique on Fly. `--force` replaces the file.

## Deploy

```sh
fly launch --copy-config --no-deploy
fly secrets set WISP_SECRET=<32 or more random characters>
fly deploy
```

## Environment

- `WISP_SECRET` as a Fly secret (above), for an app that signs cookies.
- Other variables: [Environment variables](/docs/env/).

## Limits

- The image is the [Docker](/docs/hosting/docker/) one: epoll instead of io_uring under Docker's default profile.
- WebSockets and streaming work, as in any container.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables live in `/data` inside the machine. The generated `fly.toml` has no volume mount, so add one for `/data` if the rows must outlive a deploy; otherwise use a custom store ([Where rows are kept](/docs/api-tables/)).

## More

[Host with Docker](/docs/hosting/docker/), [Deploying](/docs/deploy/).

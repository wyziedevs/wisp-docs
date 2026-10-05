---
title: Host with Docker
description: Build a Docker image of a Wisp app with wisp build --docker, run it with a volume for saved tables, and use it on any container host.
group: Hosting
order: 72
---

Docker packages the binary in a small image that runs on your machine or any container host. WebSockets, streaming and saved tables all work.

## Build

```sh
wisp build --docker      # --force replaces existing files
docker build -t my-app .
```

`wisp build --docker` writes a two-stage `Dockerfile` (`rust:slim`, then `debian:stable-slim`, `HOST=0.0.0.0`, `PORT=3000`, `WISP_DATA=/data`) and a `.dockerignore` (it keeps `.env` and `.env.*` out of the image; `wisp new` also lists them in `.gitignore`). Files that exist are left alone unless you pass `--force`; the Dockerfile you have is the one that is built.

## Deploy

```sh
docker run -p 3000:3000 -e WISP_SECRET=... -v my-app-data:/data my-app
```

Fly.io, Railway, Render, Cloud Run and Azure Container Apps build the Dockerfile as it is: [Fly.io](/docs/hosting/fly/), [Railway](/docs/hosting/railway/), [Render](/docs/hosting/render/), [Cloud Run](/docs/hosting/cloud-run/), [Azure](/docs/hosting/azure/).

## Environment

- `WISP_SECRET`: 32 or more random characters, needed by an app that signs cookies. Pass it with `-e` or an env file.
- Other variables: [Environment variables](/docs/env/).

## Limits

- Docker's default seccomp profile refuses io_uring, so the server uses an epoll loop per worker. A profile allowing `io_uring_setup`, `io_uring_enter` and `io_uring_register` brings it back.
- The image runs as `nobody`.
- WebSockets and streaming work.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables live in `/data`: mount a volume there (`-v my-app-data:/data`) or they go with the container. See [Where rows are kept](/docs/api-tables/).

## More

[Deploying](/docs/deploy/), [Host on a VPS](/docs/hosting/vps/).

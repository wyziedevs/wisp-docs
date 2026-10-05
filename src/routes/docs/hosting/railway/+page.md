---
title: Host on Railway
description: Deploy a Wisp app to Railway from its Dockerfile, using the railway.toml that wisp deploy init railway writes.
group: Hosting
order: 75
---

Railway builds a Dockerfile from your project and runs it as a service.

## Build

```sh
wisp deploy init railway      # railway.toml, and a Dockerfile if there is none
```

`railway.toml` sets the builder to `DOCKERFILE` with `Dockerfile` as the path, and a restart policy of `ON_FAILURE` with 10 retries. The Dockerfile is the one `wisp build --docker` writes. `--force` replaces the file.

## Deploy

```sh
railway up
```

Railway builds the Dockerfile and sets `PORT`, which the app listens on. Or point a service at the repository.

## Environment

- `WISP_SECRET`: 32 or more random characters, in the service's variables, for an app that signs cookies.
- Other variables: [Environment variables](/docs/env/).

## Limits

- The image is the [Docker](/docs/hosting/docker/) one: epoll instead of io_uring under Docker's default profile.
- WebSockets and streaming work, as in any container.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables live in `/data` inside the container, so give that path storage that outlives a deploy, or use a custom store ([Where rows are kept](/docs/api-tables/)).

## More

[Host with Docker](/docs/hosting/docker/), [Deploying](/docs/deploy/).

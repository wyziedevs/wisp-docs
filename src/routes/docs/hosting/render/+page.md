---
title: Host on Render
description: Deploy a Wisp app to Render from its Dockerfile, using the render.yaml blueprint that wisp deploy init render writes.
group: Hosting
order: 74
---

Render builds a Dockerfile from your repository and runs it as a web service.

## Build

```sh
wisp deploy init render       # render.yaml, and a Dockerfile if there is none
```

`render.yaml` is a blueprint with one `web` service on the `docker` runtime, named for your package, with `WISP_SECRET` set to `generateValue: true`. The Dockerfile is the one `wisp build --docker` writes. `--force` replaces the file.

## Deploy

Commit both files and push. In Render choose New, Blueprint and pick the repository. Render builds the Dockerfile and sets `PORT`, which the app listens on.

## Environment

- `WISP_SECRET` is generated for you by the blueprint; to set your own, use the service's environment settings.
- Other variables: [Environment variables](/docs/env/).

## Limits

- The image is the [Docker](/docs/hosting/docker/) one: epoll instead of io_uring under Docker's default profile.
- WebSockets and streaming work, as in any container.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables live in `/data` inside the container. The blueprint does not attach storage, so rows are lost with the instance unless you mount a persistent disk at `/data` or use a custom store ([Where rows are kept](/docs/api-tables/)).

## More

[Host with Docker](/docs/hosting/docker/), [Deploying](/docs/deploy/).

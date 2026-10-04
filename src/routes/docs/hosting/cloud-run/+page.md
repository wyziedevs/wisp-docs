---
title: Host on Cloud Run
description: Deploy a Wisp app to Google Cloud Run from its Dockerfile with gcloud run deploy --source, and set secrets and saved table storage.
group: Hosting
order: 84
---

Cloud Run runs a container image. Wisp builds the Dockerfile as it is.

## Build

```sh
wisp build --docker          # Dockerfile and .dockerignore (--force replaces them)
```

## Deploy

```sh
gcloud run deploy --source .
```

The image listens on `$PORT` (the Dockerfile sets `HOST=0.0.0.0` and `PORT=3000`).

## Environment

- `WISP_SECRET`: 32 or more random characters, set as an environment variable or secret of the service, for an app that signs cookies.
- Other variables: [Environment variables](/docs/env/).

## Limits

- The image is the [Docker](/docs/hosting/docker/) one: epoll instead of io_uring under Docker's default profile.
- WebSockets and streaming work in the binary. Any limit the platform puts on them is Cloud Run's, not Wisp's.

## Files and Data

- `static/` and the styles are inside the binary.
- Saved tables live in `/data` inside the container, which does not outlive the instance unless you give it storage there. Otherwise use a custom store ([Where rows are kept](/docs/api-tables/)).

## More

[Host with Docker](/docs/hosting/docker/), [Deploying](/docs/deploy/).

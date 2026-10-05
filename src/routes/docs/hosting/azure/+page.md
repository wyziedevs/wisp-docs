---
title: Host on Azure
description: Deploy a Wisp app to Azure with Container Apps from a Dockerfile, App Service on Node, or Static Web Apps with a function, using the node target.
group: Hosting
order: 85
---

Azure takes Wisp three ways: a container (Container Apps), the Node build (App Service), or Static Web Apps with an HTTP function.

## Build

Container:

```sh
wisp build --docker
```

App Service and Static Web Apps (Node 20 or newer):

```sh
rustup target add wasm32-unknown-unknown     # once
wisp build --target node                     # dist/node
```

## Deploy

- Container Apps: build the Dockerfile as it is. See [Host with Docker](/docs/hosting/docker/).
- App Service or Container Apps with the Node build: deploy `dist/node`. It runs `npm start`, which listens on `$PORT`.
- Static Web Apps (managed functions answer under `/api` only): `dist/node/hosts/azure.md` has the HTTP function (v4 model) that passes every request on, using the original address Azure keeps in `x-ms-original-url`, and the `navigationFallback` rewrite to `/api/wisp` for `staticwebapp.config.json`.

## Environment

- `WISP_SECRET`: set it in the service's application settings, for an app that signs cookies.
- Other variables: [Environment variables](/docs/env/).

## Limits

- A container build has no edge limits and runs the full feature set.
- The Node build has the edge limits (WebSockets work), and no `std::fs`, `std::thread`, `std::process` or `std::net`; use `wisp::spawn` and `wisp::sleep`. See [Host on Node](/docs/hosting/node/) and [What works on the edge](/docs/deploy-targets/#what-works-on-the-edge).

## Files and Data

- Container: saved tables live in `/data`; give it storage that outlives the instance.
- Node build: tables are per-instance memory unless `WISP_STORE` is set. See [Where rows are kept](/docs/api-tables/).

## More

[Edge and serverless targets](/docs/deploy-targets/), [Deploying](/docs/deploy/).

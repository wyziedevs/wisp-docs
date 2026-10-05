---
title: Hosting
description: Host a Wisp app on a VPS, Docker, Fly.io, Render, Railway, Cloudflare, Deno Deploy, Vercel, Netlify, AWS Lambda, Bun, Node, GitHub Pages, Cloud Run or Azure.
group: Hosting
order: 70
---

Wisp builds one binary for a server, an image for a container host, plain files for a static host, or WebAssembly for an edge or serverless host. Pick your host below for the build command, the deploy steps, its environment and its limits. The general rules are in [Deploying](/docs/deploy/) and [Edge and serverless targets](/docs/deploy-targets/).

<div class="table-wrap">

| Host | Build command | Runtime |
|---|---|---|
| [VPS](/docs/hosting/vps/) | `wisp build` | native binary |
| [Docker](/docs/hosting/docker/) | `wisp build --docker` | container |
| [Fly.io](/docs/hosting/fly/) | `wisp deploy init fly` | container |
| [Render](/docs/hosting/render/) | `wisp deploy init render` | container |
| [Railway](/docs/hosting/railway/) | `wisp deploy init railway` | container |
| [Cloudflare](/docs/hosting/cloudflare/) | `wisp build --target cloudflare` or `pages` | WebAssembly on Workers or Pages |
| [Deno Deploy](/docs/hosting/deno-deploy/) | `wisp build --target deno` | WebAssembly on Deno |
| [Vercel](/docs/hosting/vercel/) | `wisp build --target vercel` | WebAssembly, Node function or Edge |
| [Netlify](/docs/hosting/netlify/) | `wisp build --target netlify` | WebAssembly, function or edge function |
| [AWS Lambda](/docs/hosting/aws-lambda/) | `wisp build --target lambda` | static Linux binary |
| [Bun](/docs/hosting/bun/) | `wisp build --target bun` | WebAssembly on Bun |
| [Node](/docs/hosting/node/) | `wisp build --target node` | WebAssembly on Node 20+ |
| [GitHub Pages](/docs/hosting/github-pages/) | `wisp build --static` | static files |
| [Cloud Run](/docs/hosting/cloud-run/) | `wisp build --docker` | container |
| [Azure](/docs/hosting/azure/) | `wisp build --docker` or `--target node` | container or WebAssembly on Node |

</div>

An app that signs cookies needs `WISP_SECRET` (32 or more random characters) on every host: [Environment variables](/docs/env/).

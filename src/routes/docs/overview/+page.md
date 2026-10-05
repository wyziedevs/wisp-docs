---
title: Overview
description: A short overview of what Wisp gives you for speed, reactivity, AI token cost, rendering, data, styling, tooling and deployment, plus the project status today.
group: Start
order: 3
---

Wisp is a fast, fun web framework for Rust: ultra fast to run, cheap in AI tokens to write, durable and flexible.

<div class="table-wrap">

| Area | What you get |
|---|---|
| Reactivity | `$state`, `$derived`, `$effect` in a plain `<script>`, no build step. Islands (`client:visible`, `client:idle`, `client:media`) load code when needed. Components ship no JavaScript by default. Hot reload keeps `$state`; markup edits show about 85 ms after the save (measured on the demo, Windows, Ryzen 7 7800X3D). |
| AI and tokens | [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) and [llms-full.txt](https://github.com/wyziedevs/wisp/blob/main/llms/llms-full.txt) hold the whole reference. `wisp mcp` serves the docs to coding agents. A whole app takes less than half the tokens of SvelteKit or Next.js ([Tokens](/docs/tokens/)). |
| Rendering | Server-side rendering with streamed responses and server-streamed `{#await}`. Prerendered pages in a server build, `wisp build --static` and `--spa`. |
| Data and forms | `#[action]` form handlers with validation, and uploads. `#[remote]` functions called from the browser. `#[derive(Rest)]` gives a JSON CRUD API; a store keeps rows in log files or any database. |
| Styling | Scoped CSS in a `<style>` block, Tailwind and Sass built in. |
| Tooling | `wisp lsp` with a VS Code extension, plus Zed, tree-sitter and Prettier. `wisp fmt`, `wisp check`, `wisp test`, `wisp test --browser`. Devtools on `Alt+Shift+W`. |
| Deploy | One binary, `--docker`, `--static`, or `--target cloudflare\|deno\|vercel\|netlify\|node\|bun\|lambda`. `wisp deploy init <host>` writes a GitHub Actions workflow or a Fly, Render or Railway config. |

</div>

## Speed

Zero cost on the request hot path is the first rule: see [Benchmarks](/docs/benchmarks/). Wisp has no unsafe code outside its Linux I/O drivers and the edge exports.

## Docs

- [Design](/docs/design/): the template language, routing, actions and the runtime.
- [Browser code](/docs/client/): scripts, directives, islands, stores and the router.
- [APIs and platforms](/docs/api/): JSON APIs, validation, auth, OpenAPI and testing.
- [Deploying](/docs/deploy/) covers every host. [Testing and mixing with Rust code](/docs/embed/) covers axum, hyper and Lambda.
- [Examples](https://github.com/wyziedevs/wisp/tree/main/examples): a demo app, a JSON API and Wisp inside axum.

Issues and pull requests are welcome; read the design rule at the top of [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) first. License: [MIT](https://github.com/wyziedevs/wisp/blob/main/LICENSE).

## Status

Wisp is young and still being hardened: see [Security and hardening](/docs/security/) for the tests, the fuzzing and what is not claimed.

Every feature passes four gates: fast (no cost for apps that don't use it), cheap (one line, file or attribute), durable (checked at build time, no new runtime panics) and done (tests, an AGENTS.md entry, a docs section). Wisp was built in five phases, all shipped.

- Phase 1, the compiler: scoped styles, source maps, TypeScript in scripts, accessibility warnings, public and private environment variables (`env.PUBLIC_X`), Content Security Policy.
- Phase 2, developer experience: editor support (`wisp lsp`), formatter (`wisp fmt`), hot reload that keeps state, devtools, browser E2E tests (`wisp test --browser`).
- Phase 3, rendering and routing: SPA mode (`const SSR: bool = false;`), code loading on demand, server functions (`#[remote]`), shallow routing, snapshots, per-page prerendering (`const PRERENDER: bool = true;`), trailing slash.
- Phase 4, content and assets: Markdown pages, image optimization, i18n, sitemap and robots.txt.
- Phase 5, platform: service worker and PWA, web components (`{@element "x-card"}`), third-party UI (`wisp ui add`, framework islands), observability (`WISP_LOG=json`, `/_wisp/metrics`, OpenTelemetry).
- Decisions: images use a pinned `cwebp` (sha256 checked, `$WISP_CWEBP` override; if unavailable the build warns and serves the original); Markdown uses `pulldown-cmark` at build time only; E2E tests are Rust only; i18n is supported while Wisp's own docs stay English.

---
title: Overview
description: What Wisp gives you for reactivity, AI tokens, rendering, data, styling, tooling and deploy.
group: Start
order: 3
---

Wisp is the framework for the AI age: ultra fast to run, cheap in AI tokens to write, durable, and flexible.

## Features

**Reactivity**

- `$state`, `$derived` and `$effect` in a plain `<script>`, with no build step.
- Islands (`client:visible`, `client:idle`, `client:media`) load code only when needed.
- Components are server-rendered and ship no JavaScript by default.
- Hot reload keeps your `$state`; markup edits show in under 100 ms.

**AI and tokens**

- [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) and [llms-full.txt](https://github.com/wyziedevs/wisp/blob/main/llms/llms-full.txt) hold the whole reference.
- `wisp mcp` serves the docs to coding agents.
- A whole app takes about half the tokens of SvelteKit or Next.js ([Tokens](/docs/tokens)).
- The compiler infers types, so apps write fewer of them.

**Rendering**

- Server-side rendering, with streamed responses and server-streamed `{#await}` blocks.
- Prerendered pages in a server build, `wisp build --static` and `--spa`.

**Data and forms**

- `#[action]` form handlers with validation, and uploads.
- `#[remote]` functions called from the browser.
- `#[derive(Rest)]` gives a JSON CRUD API; a store keeps rows in log files or any database.

**Styling**

- Scoped CSS in a `<style>` block, Tailwind and Sass built in.

**Tooling**

- A language server (`wisp lsp`) with a VS Code extension, plus Zed, tree-sitter and Prettier.
- `wisp fmt`, `wisp check`, `wisp test` and `wisp test --browser`.
- Devtools on `Alt+Shift+W` and a component workshop in dev.

**Deploy**

- One binary, `--docker`, `--static`, or `--target cloudflare|deno|vercel|netlify|node|bun|lambda`.
- `wisp deploy init <host>` writes a GitHub Actions workflow or a Fly, Render or Railway config.

## Speed

Zero cost on the request hot path is the first rule. [Benchmarks](/docs/benchmarks) says what is measured and how to run it. Wisp has no `unsafe` code outside its Linux I/O drivers and the edge exports.

## Docs and links

- [Design](/docs/design): the template language, routing, actions and the runtime.
- [Browser code](/docs/client): scripts, directives, islands, stores and the router.
- [APIs and platforms](/docs/api): JSON APIs, validation, auth, OpenAPI and testing.
- [Deploying](/docs/deploy) covers every host. [Testing and mixing with Rust code](/docs/embed) covers axum, hyper and Lambda.
- [examples](https://github.com/wyziedevs/wisp/tree/main/examples): a demo app, a JSON API and Wisp inside axum.

## Contributing

Issues and pull requests are welcome; read the design rule at the top of [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) first.

## License

[MIT](https://github.com/wyziedevs/wisp/blob/main/LICENSE)

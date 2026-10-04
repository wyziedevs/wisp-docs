---
title: Getting Started
description: Install Wisp, make an app with wisp new, run it with wisp dev and build one binary.
group: Start
order: 1
---

Wisp is a fast, fun web framework for Rust. A folder is a URL, and its `+page.wisp` is the page: an optional block of Rust, then markup. Templates compile to plain Rust, and the app, styles and static files become one small binary.

## Install and Run

You need [Rust](https://rustup.rs) 1.88 or later.

```bash
cargo install --git https://wisp.ar0.eu wisp-cli
wisp new my-app        # --template demo|minimal|api
cd my-app
wisp dev               # http://127.0.0.1:3000
```

`wisp dev` rebuilds as you edit, hot reload keeps your `$state`, and `Alt+Shift+W` opens the devtools with the routes table.

## A Page

`src/routes/+page.wisp`:

```html
---
let name: String = cx.query_or("name", "world");
---
<h1>Hello, {name}!</h1>

<button on:click="count++">Clicked {:count} times</button>

<script>
  let count = $state(0)
</script>
```

The `---` block is Rust that runs per request, `{name}` renders on the server, and `{:count}` is JavaScript state in the browser. With JavaScript off, the server's HTML still works.

## Data and a Form

A model lives in `src/db.rs`; its `pub` items are in every route file:

```rust
#[model]
pub struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
pub static TODOS: Table<Todo> = Table::saved();
```

An action handles the form; `fields` writes a labelled input per parameter:

```html
---
#[action]
fn add(todo: Todo) {
    TODOS.add(todo);
}

let count = TODOS.len();
---
<title>Todos ({count})</title>
<form action="?/add" fields><button>Add</button></form>
{#each TODOS.all() as todo}
  <p>{todo.text}</p>
{/each}
```

A bad value is a 422 that shows each problem next to its input and keeps what was typed, with no JavaScript. There is no `use` line: a prelude brings in `Cx`, `Table`, `Email`, `redirect`, `error` and the rest.

## Files

```
src/main.rs                 wisp::main!();   (generated; leave it)
src/app.html                shell with %wisp.head% %wisp.body% (optional)
src/app.css | app.scss      served at /_app/app.css (Tailwind if it imports it; Sass, no Node)
src/hooks.rs                fn init() once; fn before(cx) every request
src/db.rs                   models and tables; its pub items are in every route file
src/components/Card.wisp    <Card title={x}>...</Card>
src/routes/.../+page.wisp   page: optional --- Rust block, then markup
src/routes/.../+layout.wisp wraps pages below; must <slot />
src/routes/.../+error.wisp  error page
src/routes/.../+server.rs   endpoints: fn get/post/put/patch/delete/list
src/routes/.../+page.md     Markdown page
static/                     served at /
```

Folders: `blog` static, `[slug]` param, `[[lang]]` optional, `[...rest]` rest, `[id=int]` digits, `(group)` not in the URL. More in [Files and routes](/docs/design).

## Check, Test, Build

```bash
wisp check      # templates, routes, accessibility lints
wisp test       # your tests (wisp test --browser drives a real browser)
wisp fmt        # format
wisp build      # one release binary
```

`wisp build --static` writes HTML for any static host, `--docker` a container, `--target cloudflare|deno|vercel|netlify|node|bun|lambda` an edge or serverless build. See [Deploying](/docs/deploy).

## Next

- [Overview](/docs/overview): what Wisp gives you.
- [Browser code](/docs/client): `$state`, directives, islands.
- [APIs and platforms](/docs/api): a JSON API from one struct.
- [Data, files and jobs](/docs/data) and [Auth](/docs/auth).
- With an AI agent: [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), or `wisp mcp` (`claude mcp add wisp -- wisp mcp`).

## All Pages

**Start**

- [Why Wisp](/docs/why): Wisp is fast to run, cheap for an AI to write, and shaped by how the code looks
- [Overview](/docs/overview): What Wisp gives you for reactivity, AI tokens, rendering, data, styling, tooling and deploy
- [Benchmarks](/docs/benchmarks): What Wisp measures for speed, and how to run the benchmark tools yourself

**Design**

- [Design and files](/docs/design): Principles, dependency budget, workspace, the files of an app, routes and Markdown pages
- [Pages and templates](/docs/design-pages): A page's Rust block, loads, actions, validation, limits, caching and accessibility lints
- [Tooling, images and translations](/docs/design-tooling): Recipes, the component kit, images and i18n
- [Template syntax and styles](/docs/design-syntax): Template syntax, escaping, components, snippets and scoped styles in .wisp files
- [Actions, forms and UI](/docs/design-forms): Actions, validation, uploads, wisp.js form handling and the built-in UI
- [Hooks, state and streaming](/docs/design-state): Hooks, per-request state and values, streaming and the await block
- [Runtime and build](/docs/design-runtime): The server, drivers, limits, the single request entry point and what wisp build does
- [CLI, dev loop and security](/docs/design-cli): wisp new, the dev loop, fmt, security, CSP and milestones
- [AI agents and editors](/docs/design-editors): AGENTS.md, the MCP server, the language server and editor support
- [Parity features](/docs/design-features): What a server framework is expected to have, and what Wisp does for each
- [Cookies and sign-in](/docs/design-sessions): Cookies, signed cookies, sessions, sign-in, password hashing

**Browser code**

- [Browser code](/docs/client): Scripts, runes, directives and TypeScript in the same .wisp file
- [Server values and client blocks](/docs/client-templates): Server values in the browser, {:expr} holes, client blocks, snippets and first paint
- [Islands and loading](/docs/client-islands): Islands, web components, third-party scripts and loading code on demand
- [The router and forms](/docs/client-router): The router, morphs, snapshots and use:enhance for forms
- [Server functions and errors](/docs/client-server): Remote functions, turning server rendering off, errors and source maps
- [PWA and the dev loop](/docs/client-pwa): Installable and offline apps, and the dev loop with hot reload and devtools
- [Client components and state](/docs/client-components): Client components, custom elements, state helpers and shared stores

**APIs**

- [APIs and platforms](/docs/api): JSON endpoints, #[derive(Rest)] resources, queries and hooks
- [Input, output and errors](/docs/api-requests): Input, output, errors as JSON, webhooks, idempotent retries and big lists
- [Auth, limits, jobs and config](/docs/api-production): Auth, rate limits, live updates, background jobs and configuration
- [OpenAPI and tests](/docs/api-openapi): The generated OpenAPI document and docs page, and testing an API
- [Where rows are kept](/docs/api-tables): Table storage, WISP_DATA, custom stores, the edge and paging

**Data and auth**

- [Data, files and jobs](/docs/data): Tables, relay, files, validation rules, jobs, cache and the admin page
- [Auth and integrations](/docs/auth): Roles, signed tokens, two-factor codes, outbound HTTP, email and OAuth sign-in

**Deploy and run**

- [Deploying](/docs/deploy): Binary, static, prerender, service and Docker
- [Edge and serverless targets](/docs/deploy-targets): Build for Cloudflare, Deno, Vercel, Netlify, Lambda, Bun and more
- [Serve extras](/docs/serve): Gzip, ranges, security headers, health checks and handler timeouts
- [Testing and mixing with Rust code](/docs/embed): Testing an app in process, WebSockets, and Wisp inside axum, hyper and Lambda
- [Logs, metrics and traces](/docs/deploy-observe): JSON request logs, Prometheus metrics and OpenTelemetry traces

**Project**

- [Tokens](/docs/tokens): What an app costs to write in AI tokens, measured against other stacks
- [Tokens, app by app](/docs/tokens-apps): Four small apps in Wisp and six other frameworks, with the Wisp versions

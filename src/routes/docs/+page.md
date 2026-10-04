---
title: Getting started
description: Install Wisp, make an app with wisp new, run it with wisp dev and build one binary.
group: Start
order: 1
---

Wisp is a fast, fun web framework for Rust. A folder is a URL, and its `+page.wisp` is the page: an optional block of Rust that loads data and handles forms, then markup. Templates compile to plain Rust, and the whole app, styles and static files included, becomes one small binary.

## Install

You need [Rust](https://rustup.rs) 1.88 or later.

```bash
cargo install --git https://github.com/wyziedevs/wisp wisp-cli
```

## Make an app

```bash
wisp new my-app
cd my-app
wisp dev
```

Then open http://127.0.0.1:3000. `wisp new app [--template demo|minimal|api]` picks a starting point. `wisp dev` rebuilds as you edit, hot reload keeps your `$state`, and `Alt+Shift+W` opens the devtools with the routes table.

## A page

Pages live in `src/routes`. This is `src/routes/+page.wisp`:

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

The `---` block is Rust that runs for each request, `{name}` is rendered on the server, and `{:count}` is JavaScript state in the browser. Turn JavaScript off and the server's HTML still works.

## Data and a form

A model lives in `src/db.rs`, and its `pub` items are in every route file:

```rust
#[model]
pub struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
pub static TODOS: Table<Todo> = Table::saved();
```

An action handles the form. `fields` writes a labelled input per parameter:

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

A bad value is a 422 that shows each problem next to its input and keeps what was typed. It works without JavaScript. There is no `use` line: a prelude brings in `Cx`, `Table`, `Email`, `redirect`, `error` and the rest.

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

Folders: `blog` static, `[slug]` param, `[[lang]]` optional, `[...rest]` rest, `[id=int]` digits, `(group)` not in the URL. See [Files and routes](/docs/design-app) for all of it.

## Check, test, build

```bash
wisp check      # templates, routes, accessibility lints
wisp test       # your tests (wisp test --browser drives a real browser)
wisp fmt        # format
wisp build      # one release binary
```

`wisp build --static` writes a folder of HTML for any static host, `--docker` a container, and `--target cloudflare|deno|vercel|netlify|node|bun|lambda` an edge or serverless build. See [Deploying](/docs/deploy).

## Next

- [Overview](/docs/overview): what Wisp gives you, and how fast it is.
- [Browser code](/docs/client): `$state`, directives, islands.
- [APIs and platforms](/docs/api): a whole JSON API from one struct.
- [Data, files and jobs](/docs/data) and [Auth](/docs/auth).
- Coding with an AI agent? Read [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), or run `wisp mcp` to serve the docs to it (`claude mcp add wisp -- wisp mcp`).

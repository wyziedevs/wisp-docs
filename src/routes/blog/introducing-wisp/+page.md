---
title: Introducing Wisp
description: Meet Wisp, a fast, fun web framework for Rust with file routes, templates compiled to Rust, form actions and one binary. Learn what it is and why we built it.
date: 2026-10-04
author: The Wisp Team
tags: Release, Engineering
---

Today we are sharing Wisp, a fast, fun web framework for Rust. A folder is a URL, its `+page.wisp` is the page, and the whole app, styles and static files included, builds to one small binary.

Below are what a Wisp app looks like, the four rules the framework follows, and where to start.

## What a Wisp App Looks Like

Here is a todo list that validates its input, keeps its rows across restarts and works without JavaScript. The model lives in `src/db.rs`:

```rust
#[model]
struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
pub static TODOS: Table<Todo> = Table::saved();
```

And the page is `src/routes/+page.wisp`:

```html
---
#[action]
fn add(todo: Todo) {
    TODOS.add(todo);
}
#[action]
fn remove(id: u64) {
    TODOS.remove(id);
}
---

<title>Todos ({TODOS.len()})</title>
<form action="?/add" fields><button>Add</button></form>
{#each TODOS.all() as todo}
  <p>{todo.text} <button action="?/remove&id={todo.id}">Remove</button></p>
{/each}
```

The block at the top is Rust that runs on the server. The markup below it is HTML with a few template tags. The form writes its own inputs and errors, and a bad value is a 422 that shows each problem beside its input and keeps what was typed. There are no `use` lines, no router file and no handler wiring.

## Four Rules, in Order

When two goals pull apart, Wisp has an order for choosing:

1. **Fast.** A route pays only for the features it uses. A change that touches the request path is checked by an instructions-per-request A/B before it lands, and a feature a route does not use must add none.
2. **Cheap in tokens.** AI writes most code now, and every token it reads and writes costs time and money. Wisp uses conventions over configuration, types the compiler infers, and forms that write their own inputs and errors.
3. **Durable.** Each fast path is proven when the server starts, falls back to the plain path if the proof fails, and a panic in a handler is caught and answered as a 500.
4. **Flexible.** Last in the order, and never at the cost of the first three.

Speed is never traded away for convenience. How it is measured, and how to run the benchmark tools yourself, is on the [Benchmarks](/docs/benchmarks/) page.

## Why Tokens

Code written by a model is paid for by the token, so we count them. The same five features, a list page, a contact form, a JSON endpoint, a layout and a live search, written as a complete app in each stack:

<div class="table-wrap">

| Stack | Tokens | Files |
|---|---:|---:|
| **Wisp** | **432** | 6 |
| Nuxt (Vue) | 1043 | 8 |
| SvelteKit | 1134 | 9 |
| Next.js (React) | 1146 | 8 |
| Express (Node.js) | 1335 | 7 |
| React (Vite + Express) | 1558 | 8 |

</div>

A bigger app, with sign up and in, a posts table, uploads, live refresh and a component, is 958 tokens in Wisp, 3473 in SvelteKit and 3331 in Next.js. Every stack's contact form checks the same rules with the same messages as Wisp's. The numbers come from `cargo run -p wisp-tokens`, which counts every hand-written file and its path with a byte-pair style estimate. The [Tokens](/docs/tokens/) page has the method and the apps, so you can check the count.

For agents, [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole reference in one file, and `wisp mcp` serves the docs over MCP.

## One Binary, Any Host

Templates compile to plain Rust, and `wisp build` writes one binary. It runs on a VPS, in a container, as static HTML or on an edge host:

```bash
wisp build
wisp build --static
wisp build --docker
wisp build --target cloudflare
```

`--target` also takes `deno`, `vercel`, `netlify`, `node`, `bun` and `lambda`. See [Deploying](/docs/deploy/).

## Reactivity in the Same File

Pages work without JavaScript, and behavior lives in the same file as the markup. A `<script>` with `$state` adds it, and a write redraws only what read the value:

```html
---
let name: String = cx.query_or("name", "world".to_string());
---

<h1>Hello, {name}!</h1>

<button on:click="count++">Clicked {:count} times</button>

<script>
  let count = $state(0)
</script>
```

Turn JavaScript off and the server's HTML still works. See [Browser code](/docs/client/).

## Get Started

You need Rust 1.88 or later:

```bash
cargo install wisp-web
wisp new my-app
cd my-app
wisp dev
```

The [Quick Start](/docs/quick-start/) covers the concepts in one page, and the [Tutorial](/docs/tutorial/) builds a small app from an empty folder. The code is at [wyziedevs/wisp](https://github.com/wyziedevs/wisp), and issues and pull requests are welcome. See [Community](/community/) for where to ask.

Thank you for trying Wisp.

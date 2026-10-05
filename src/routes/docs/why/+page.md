---
title: Why Wisp
description: Why choose Wisp: it runs fast, costs an AI few tokens to write, and keeps short code that reads like the page, with Rust underneath and one binary to ship.
group: Start
order: 2
---

## Short Code That Reads Like the Page

A folder is a URL, and its `+page.wisp` is the page: a block of Rust that loads data and handles forms, then markup. A model, a saved table, a validated action, a form and a list fit in about twenty lines. No imports (a prelude brings the usual names), no router file, no handler wiring. See [Getting started](/docs/).

## Fast

Zero cost on the request hot path: a route pays only for the features it uses, and a change that touches the path is checked by an instructions-per-request A/B before it lands. See [Benchmarks](/docs/benchmarks/).

## Cheap to Write

An AI pays for every token it reads and writes, in time and money. Wisp uses conventions over configuration, types the compiler infers, and forms that write their own inputs and errors.

- The same five features take 476 tokens in Wisp, 1,134 in SvelteKit and 1,146 in Next.js.
- A larger app with sign up, uploads and live refresh takes 1,016, against 3,666 and 3,458.
- `cargo run -p wisp-tokens` counts every hand-written file and its path with a byte-pair style estimate. See [Tokens](/docs/tokens/).

For agents: [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole reference in one file, and `wisp mcp` serves the docs over MCP (`claude mcp add wisp -- wisp mcp`).

## And More

- A page is one `+page.wisp`: its models, tables, actions, markup and scoped style in a single file. Larger sites split into `src/db.rs`, `+page.rs`, `+server.rs` and components ([One file or several](/docs/design-pages/#one-file-or-several)).
- One binary carries its styles and static files. It runs on a VPS, in a container, as static HTML or on an edge host ([Deploying](/docs/deploy/)).
- Every fast path is proven at startup, falls back, and a panic in a handler is caught and answered as a 500.
- Forms work without JavaScript, and reactivity lives in the same file as the markup ([Browser code](/docs/client/)).

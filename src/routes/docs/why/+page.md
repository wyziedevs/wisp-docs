---
title: Why Wisp
description: Wisp is fast to run, cheap for an AI to write, and shaped by how the code looks.
group: Start
order: 2
---

## Short Code That Reads Like the Page

A folder is a URL, and its `+page.wisp` is the page: a block of Rust that loads data and handles forms, then markup. A model, a saved table, a validated action, a form and a list fit in about twenty lines. No imports (a prelude brings the usual names), no router file, no handler wiring. See [Getting started](/docs).

## Fast

Zero cost on the request hot path: a route pays only for the features it uses, and a change that touches the path is checked by an instructions-per-request A/B before it lands. See [Benchmarks](/docs/benchmarks).

## Cheap to Write

AI writes most code now, and every token costs time and money. Wisp uses conventions over configuration, types the compiler infers, and forms that write their own inputs and errors.

- The same five features take 464 tokens in Wisp, 1002 in SvelteKit and 1010 in Next.js.
- A larger app with sign up, uploads and live refresh takes 995, against 3368 and 3220.
- `cargo run -p wisp-tokens` counts every hand-written file and its path with a byte-pair style estimate. See [Tokens](/docs/tokens).

For agents: [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole reference in one file, and `wisp mcp` serves the docs over MCP (`claude mcp add wisp -- wisp mcp`).

## And

- One binary carries its styles and static files. It runs on a VPS, in a container, as static HTML or on an edge host ([Deploying](/docs/deploy)).
- Every fast path is proven at startup, falls back, and never panics after startup.
- Forms work without JavaScript, and reactivity lives in the same file as the markup ([Browser code](/docs/client)).

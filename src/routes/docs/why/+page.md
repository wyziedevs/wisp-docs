---
title: Why Wisp
description: Wisp is fast to run, cheap for an AI to write, and shaped by how the code looks.
group: Start
order: 2
---

Three things decided what Wisp is.

## The code is short and reads like the page

A folder is a URL, and its `+page.wisp` is the page: a block of Rust that loads data and handles forms, then markup. A model, a saved table, a validated action, a form and a list fit in one file of about twenty lines. There are no imports (a prelude brings in the usual names), no router file and no handler wiring. See [Getting started](/docs) for the page.

## It is fast

The first rule is zero cost on the request hot path: a route pays only for the features it uses, and a change that touches the path is checked by an instructions-per-request A/B before it lands. [Benchmarks](/docs/benchmarks) says what is measured and how to run it.

## It is cheap to write

AI writes most code now, and every token it reads and writes costs time and money. Wisp is built so an app costs the fewest: conventions instead of configuration, types the compiler infers, and forms that write their own inputs and errors. The same five features take 464 tokens in Wisp, 928 in SvelteKit and 934 in Next.js; a larger app with sign up, uploads and live refresh takes 995, against 3368 and 3220. The counts come from `cargo run -p wisp-tokens`, which counts every hand-written file and its path with a byte-pair style estimate. [Tokens](/docs/tokens) has the method and the apps.

For coding agents there is [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), the whole reference in one file, and `wisp mcp`, which serves the docs over the Model Context Protocol (`claude mcp add wisp -- wisp mcp`).

## And

It builds to one binary that carries its styles and static files, runs on a VPS, in a container, as static HTML or on an edge host ([Deploying](/docs/deploy)), and every fast path is proven at startup, falls back, and never panics after startup. Forms work without JavaScript, and reactivity lives in the same file as the markup ([Browser code](/docs/client)).

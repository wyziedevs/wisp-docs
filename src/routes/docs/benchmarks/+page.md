---
title: Benchmarks
description: What Wisp measures for speed, and how to run the benchmark tools yourself.
group: Start
order: 4
---

Wisp's first rule is zero cost on the request hot path. This page has no numbers, only what is measured and how to run it.

```bash
git clone https://github.com/wyziedevs/wisp
cd wisp
cargo run -r -p bench-run -- --paths fortunes
```

You need Rust. `bench/README.md` lists every option, the frameworks compared, and how each path is checked for identical output before it is measured. Results depend on the machine: read them as a comparison on one machine, not as absolutes.

## What Is Checked

<div class="table-wrap">

| Check | What it does |
|---|---|
| Instructions per request | A change that touches the request path runs A/B against the build before it, counting CPU instructions for the same requests. A feature a route does not use must add none. |
| Startup self-tests | Each fast path (the I/O driver, parsers, caches) is proven at server start, and falls back to the plain path if the proof fails. |
| Comparable frameworks | `bench/` holds the same server-rendered page, JSON and plaintext routes written the way each framework's docs would write them, a load generator and a runner. |

</div>

## Tokens

Writing cost is measured by a program in the repository: `cargo run -p wisp-tokens --release`. See [Tokens](/docs/tokens).

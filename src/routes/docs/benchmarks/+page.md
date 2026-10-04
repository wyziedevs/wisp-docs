---
title: Benchmarks
description: What Wisp measures for speed, and how to run the benchmark tools yourself.
group: Start
order: 4
---

Wisp's first rule is zero cost on the request hot path. This page says what is measured and how to run it; it carries no numbers of its own.

## What is checked

- **Instructions per request.** A change that touches the request path is run A/B against the build before it, counting CPU instructions for the same requests. A feature a route does not use must add none.
- **Startup self-tests.** Each fast path (the I/O driver, parsers, caches) is proven when the server starts, and falls back to the plain path if the proof fails, so speed never costs correctness.
- **Comparable frameworks.** The repository's `bench/` folder holds the same server-rendered page, JSON and plaintext routes written the way each framework's own docs would write them, a load generator and a runner.

## Run it yourself

You need Rust and the Wisp repository:

```bash
git clone https://github.com/wyziedevs/wisp
cd wisp
cargo run -r -p bench-run -- --paths fortunes
```

`bench/README.md` in the repository lists every option, the frameworks compared, and how each path is checked for identical output before it is measured. Results depend on the machine, so read them as a comparison on one machine, not as absolutes.

## Tokens

Writing cost is measured the same way, by a program in the repository: `cargo run -p wisp-tokens --release`. See [Tokens](/docs/tokens).

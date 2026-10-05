---
title: Benchmarks
description: See what Wisp measures to prove it is fast and cheap in tokens, and how to run the benchmark tools yourself to check the numbers on your own machine.
group: Start
order: 4
---

Wisp's first rule is zero cost on the request hot path. This page is what is measured and how to run it. The numbers below are dated, with the machine they ran on, and the losses are listed with them. The native TechEmpower tables are on the [home page](/#measured) and in [`bench/tfb/RESULTS.md`](https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md).

```bash
git clone https://github.com/wyziedevs/wisp
cd wisp
cargo run -r -p bench-run -- --paths fortunes
```

You need Rust. `bench/README.md` lists every option, the frameworks compared, and how each path is checked for identical output before it is measured. Results depend on the machine, so compare frameworks run on the same machine and treat the absolute numbers with care.

## Native, Linux (2026-10-04)

TechEmpower's plaintext and JSON tests with their own wrk scripts, on one shared 4-vCPU VM (AMD EPYC), the server on 2 pinned cores, medians of 3 runs of 15 s. Not an official TechEmpower result.

<div class="table-wrap">

| Test | Wisp | Actix Web | Axum | Fastify | Express |
|---|---:|---:|---:|---:|---:|
| Plaintext, 256 connections, pipelined | 1,129,577 | 603,163 | 276,948 | 51,713 | 40,421 |
| JSON, 64 connections | 96,089 | 89,648 | 78,427 | 21,965 | 14,746 |

</div>

- Plaintext: first at 256, 1,024 (623,348) and 4,096 (532,959) connections. At 16,384 Wisp's default limit of 10,000 connections refuses the overflow, so it is not first there.
- JSON: first at 64, 128 and 512 connections, but Actix Web is ahead at 16 and 256 (90,199 against 71,879 at 16), and the ranges overlap at the others. The same Wisp binary moved 11% to 21% between moments on this VM, which is larger than most gaps between the Rust servers. The JSON numbers support no ranking.
- Fortunes, an earlier run (2026-09-28, other Linux VPS, 64 connections, CPU per request): Wisp 97,502 requests a second, Actix Web 86,169, Axum 76,818. A virtual machine's kernel is most of each request, so fast servers bunch together on plaintext.
- A later rerun on a CPU-capped VPS was not valid, so this site claims no current Linux ranking.

What these numbers come from:

- **Driver fast path.** The epoll and io_uring drivers receive, answer and send in their own turn without waking the connection's task, and for routes the build found never wait, `http::on_driver` answers without polling the future at all.
- **One pass over the request.** The request line, headers and a JSON body are read in as few passes as possible, borrowed from the receive buffer instead of copied.
- **Pooled buffers.** A connection holds buffers only while it has a request; idle ones go back to a pool per thread.
- **No cost for what is off.** HTTP/2 (feature `h2`) is noticed only where HTTP/1 already refused the bytes, so HTTP/1 pays nothing. Features a route does not use add no instructions, checked by the A/B above.

## Edge and JavaScript Hosts (2026-10-04)

The same app built with `wisp build --target node|bun|deno|cloudflare`, against Hono, on Windows 10, Ryzen 7 7800X3D, Node 26, Deno 2.5, Bun 1.4, workerd 1.20261001. `oha`, 64 connections, 10 s runs, median of 5, Wisp and Hono alternating. The machine was not idle (an unrelated app used about 0.8 of a core), so compare the two numbers within a row and treat the absolute values with care. Requests a second, Wisp / Hono:

<div class="table-wrap">

| Host | `/` | `/list1000` | `/json-big` | `/params` + cookie |
|---|---:|---:|---:|---:|
| Node, raw sockets (default) | 100,865 / 54,327 | 6,561 / 1,873 | 20,812 / 19,677 | 113,240 / 46,760 |
| Deno, raw sockets (default) | 118,877 / 92,507 | 6,426 / 2,022 | 9,027 / 5,702 | 93,841 / 64,674 |
| Bun, raw sockets (default) | 133,387 / 127,725 | 9,287 / 3,149 | 20,017 / 19,549 | 53,876 / 36,407 |
| workerd | 7,694 / 9,447 | 5,093 / 2,007 | 5,962 / 8,480 | 14,581 / 14,624 |

</div>

- On Node, Deno and Bun, Wisp's default path reads raw sockets and the app's own HTTP parser answers, about 1 microsecond a request inside the wasm, so it is ahead on all four routes. `WISP_NODE_HTTP=1` serves through the host's own server instead and then loses on `/` (Node -15%, Deno -21%, Bun -35%).
- On workerd, a quieter run alternating with Hono (median of 5): `/` 19,645 and 20,908 (-6%), `/json-big` 11,441 and 11,894 (-4%), `/params` 19,258 and 20,256 (-5%), `/list1000` 6,033 and 2,359 (2.6 times). The wasm's own work is a few microseconds a request; the gap on `/` is workerd's cost of entering wasm and of a response with a head, and on `/json-big` it is a serializer in wasm against V8's `JSON.stringify`.
- Cold start on workerd is Wisp's loss: 25 ms against 19 ms for Hono in that run (39 and 24 to 27 ms in the busier one), about 7 ms of it the host loading the module and the rest the first request compiling. A warm-up request at load took the first request from about 17 ms to 5 ms in one run, with no app code run.
- The wasm for the bench app is 541 KB (541,063 bytes) since the Cloudflare, Pages, Vercel and Netlify builds leave out the server loop for raw connections (`WISP_REQUEST_ONLY`, 584,353 before). `tests/wasm-size.sh` fails CI when a build grows past its budget.
- Where speed and size disagree, speed wins, so `opt-level = 3` stays, and `wasm-opt` and allocator swaps that measured no faster were not kept.

The full tables, the dropped experiments and a ranking against fifteen other frameworks per host are in [`bench/edge/README.md`](https://github.com/wyziedevs/wisp/blob/main/bench/edge/README.md) and `bench/rank`. That ranking ran on a CPU-capped VPS, so this site quotes none of its places.

## What Is Checked

<div class="table-wrap">

| Check | What it does |
|---|---|
| Instructions per request | A change that touches the request path runs A/B against the build before it, counting CPU instructions for the same requests. A feature a route does not use must add none. |
| Startup self-tests | Each fast path (the I/O driver, parsers, caches) is proven at server start, and falls back to the plain path if the proof fails. |
| Comparable frameworks | `bench/` holds the same server-rendered page, JSON and plaintext routes written the way each framework's docs would write them, a load generator and a runner. |

</div>

## Tokens

Writing cost is measured by a program in the repository: `cargo run -p wisp-tokens --release`. See [Tokens](/docs/tokens/).

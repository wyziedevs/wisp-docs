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

Source: [`bench/tfb/RESULTS.md`](https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md) (generated from `results.json`). TechEmpower's plaintext and JSON tests with their own wrk scripts, run 2026-10-04 on one shared 4-vCPU VM (AMD EPYC 7B13), the server on 2 pinned cores, medians of 3 runs of 15 s. Not an official TechEmpower result. Contenders are in a fixed order, not ranked; "Failed" means no run completed a request, and a `0` median means at least 2 of 3 runs completed none. The full results add min, max, latency and errors per row. The same Wisp binary moved between moments on this VM, so gaps inside the min-max ranges are ties.

<div class="table-wrap">

Plaintext, pipelined, requests per second (median of 3), by connections:

| Contender | 256 | 1024 | 4096 | 16384 |
|---|---:|---:|---:|---:|
| **Wisp** | **1,129,577** | **623,348** | **532,959** | **220** |
| Axum | 276,948 | 381,324 | 446,398 | 171,231 |
| Actix Web | 603,163 | 366,626 | 351,844 | 0 |
| Express | 40,421 | 36,184 | 27,554 | 0 |
| Fastify | 51,713 | 62,345 | 58,956 | 16,573 |
| Hono (Node) | 28,966 | 29,602 | 34,173 | 0 |
| Hono (Bun) | 10,599 | 10,375 | 9,652 | 6,910 |
| SvelteKit | 10,929 | 8,464 | 8,359 | 0 |
| Next.js | No valid result: no pipelined response completed (heap raised to 8 GB, still none) | No valid result: no pipelined response completed (heap raised to 8 GB, still none) | No valid result: no pipelined response completed (heap raised to 8 GB, still none) | not run |

Rows whose min-max ranges overlap are ties. 256: Fastify and Express; Hono (Node), SvelteKit and Hono (Bun). 1024: Axum and Actix Web; Express and Hono (Node). 4096: Hono (Node) and Express. 16384: Wisp's range (0 to 29,252) overlaps every row that answered, so no rank is drawn there.

JSON, requests per second (median of 3), by connections:

| Contender | 16 | 32 | 64 | 128 | 256 | 512 |
|---|---:|---:|---:|---:|---:|---:|
| **Wisp** | **71,879** | **86,813** | **96,089** | **107,834** | **91,876** | **73,714** |
| Axum | 79,105 | 86,901 | 78,427 | 92,662 | 60,465 | 47,070 |
| Actix Web | 90,199 | 99,098 | 89,648 | 106,246 | 108,428 | 71,315 |
| Express | 16,945 | 16,586 | 14,746 | 13,795 | 18,023 | 22,644 |
| Fastify | 21,996 | 21,210 | 21,965 | 19,977 | 21,249 | 24,163 |
| Hono (Node) | 17,069 | 15,571 | 8,988 | 9,354 | 13,084 | 15,349 |
| Hono (Bun) | 52,353 | 54,056 | 59,619 | 51,580 | 47,379 | 28,439 |
| SvelteKit | 7,990 | 9,774 | 10,378 | 7,714 | 6,062 | 6,698 |
| Next.js | 1,499 | 1,285 | 1,524 | 1,513 | 1,370 | 1,715 |

Rows whose min-max ranges overlap are ties. 16: Actix Web and Axum, Axum and Wisp; Fastify, Hono (Node) and Express. 32: Wisp with Actix Web and with Axum; Express, Hono (Node) and SvelteKit. 64: Wisp, Actix Web and Axum; SvelteKit and Hono (Node). 128: Wisp and Actix Web. 256: Fastify and Express. 512: Wisp and Actix Web; Axum and Hono (Bun).

</div>

Earlier run (2026-09-28, other Linux VPS, 64 connections, plaintext and fortunes, CPU per request): [`bench/README.md`](https://github.com/wyziedevs/wisp/blob/main/bench/README.md). A later rerun on a CPU-capped VPS (about 75% steal) was invalid and is not published, so this site claims no current Linux ranking; rank tables are pending a valid run. Instructions per request (callgrind, valid on any host load): `GET /` 1572, `GET /user/0` 2310, `POST /user` 1773 at d72eee5; 1585, 2323 and 1789 after the chunked fix.

What these numbers come from:

- **Driver fast path.** The epoll and io_uring drivers receive, answer and send in their own turn without waking the connection's task, and for routes the build found never wait, `http::on_driver` answers without polling the future at all.
- **One pass over the request.** The request line, headers and a JSON body are read in as few passes as possible, borrowed from the receive buffer instead of copied.
- **Pooled buffers.** A connection holds buffers only while it has a request; idle ones go back to a pool per thread.
- **No cost for what is off.** HTTP/2 (feature `h2`) is noticed only where HTTP/1 already refused the bytes, so HTTP/1 pays nothing. Features a route does not use add no instructions, checked by the A/B above.

## Edge and JavaScript Hosts (2026-10-04)

The same app built with `wisp build --target node|bun|deno|cloudflare`, against Hono, on Windows 10, Ryzen 7 7800X3D, Node 26, Deno 2.5, Bun 1.4, workerd 1.20261001. `oha`, 64 connections, 10 s runs, median of 5, Wisp and Hono alternating; Wisp is the first number in each cell. The machine was not idle (an unrelated app used about 0.8 of a core), so treat the absolute values with care. Run validity not recorded (no steal data); raw data, no ranking is drawn from it. Measured before 2026-10-05, so before cddf6ca (integer rendering) and the wasm size work; Hono's version is not recorded. Requests a second, Wisp / Hono:

<div class="table-wrap">

| Host | `/` | `/list1000` | `/json-big` | `/params` + cookie |
|---|---:|---:|---:|---:|
| Node, raw sockets (default) | 100,865 / 54,327 | 6,561 / 1,873 | 20,812 / 19,677 | 113,240 / 46,760 |
| Deno, raw sockets (default) | 118,877 / 92,507 | 6,426 / 2,022 | 9,027 / 5,702 | 93,841 / 64,674 |
| Bun, raw sockets (default) | 133,387 / 127,725 | 9,287 / 3,149 | 20,017 / 19,549 | 53,876 / 36,407 |
| workerd | 7,694 / 9,447 | 5,093 / 2,007 | 5,962 / 8,480 | 14,581 / 14,624 |

</div>

- On Node, Deno and Bun, Wisp's default path reads raw sockets and the app's own HTTP parser answers, about 1 microsecond a request inside the wasm. `WISP_NODE_HTTP=1` serves through the host's own server instead, which on `/` trails Hono by 15% on Node, 21% on Deno and 35% on Bun (`bench/edge/README.md`).
- On workerd, a quieter run alternating with Hono (median of 5): `/` 19,645 and 20,908 (-6%), `/json-big` 11,441 and 11,894 (-4%), `/params` 19,258 and 20,256 (-5%), `/list1000` 6,033 and 2,359 (2.6 times). The wasm's own work is a few microseconds a request; the gap on `/` is workerd's cost of entering wasm and of a response with a head, and on `/json-big` it is a serializer in wasm against V8's `JSON.stringify`.
- Cold start on workerd, process start to the first 200, VPS, 21 alternating rounds (2026-10-05, after 3bd0169; the script, `cold.mjs`, is not committed, so this is not reproducible from the repo): Wisp loses. `/` 72.2 ms against 58.5 for Hono and 49.6 for itty, `/json-big` 75.4 / 57.4 / 50.1, `/params` 71.9 / 54.2 / 46.4, `/list1000` 63.6 / 51.4 / 46.3: 13 to 18 ms behind Hono. An earlier, differently defined run (first request inside a running workerd) read 25 ms against 19; it is superseded.
- The wasm for the bench app, Cloudflare build, is 354,711 bytes (126,826 gzip) as of 2026-10-05 (3bd0169; 558,015 before the size work), measured on one Windows machine; the gate (`cargo run -p wisp-gate`) fails a build past its size budget. Hono's bundle is JavaScript, not wasm, so the two sizes are not compared. `tests/wasm-size.sh` fails CI when a build grows past its budget.
- Where speed and size disagree, speed wins, so `opt-level = 3` stays, and `wasm-opt` and allocator swaps that measured no faster were not kept.

The full tables, the dropped experiments and the raw numbers for fifteen other frameworks per host are in [`bench/edge/README.md`](https://github.com/wyziedevs/wisp/blob/main/bench/edge/README.md) and `bench/rank`. Run validity is not recorded for those runs (no steal data), so this site quotes no place or rank from them.

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

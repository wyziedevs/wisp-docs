---
title: Security and Hardening
description: What Wisp does to refuse hostile input, how it is tested, what each hardening pass fixed, and what is not claimed for a young framework.
group: Project
order: 92
---

Wisp is young and has not been audited, and it can be broken. This page lists what is done, how it is tested, and what was found and fixed, so you can judge for yourself. Defaults and the CSP are in [CLI, dev loop and security](/docs/design-cli/), limits in [Runtime and build](/docs/design-runtime/).

## Status: Young, Actively Hardened

- More than 1,000 tests run on every change: the runtime, the compiler, the CLI, the edge bridges and an app that uses every feature, plus a test that compiles every code sample of the reference.
- Parsers are fuzzed with a seeded generator that breaks inputs the way hostile clients do: the HTTP/1 parser, HTTP/2 frames and HPACK, JSON, forms, cookies, WebSocket frames and the signing code. The compiler's template and Rust scanners are fuzzed with malformed, deeply nested and huge input, and `wisp fmt` with a round trip that must be idempotent and keep every visible character. A failing seed repeats.
- A table of request-smuggling shapes (conflicting lengths, doubled `Transfer-Encoding`, bad chunking) must each be refused.
- Every fast path is proven at startup and falls back, and nothing after startup panics. No `unsafe` outside the Linux I/O drivers and the edge exports.
- Each pass hunts for bugs in one area (HTTP, the app and browser script, the build, the CLI, the edge bridges) and each finding gets a test. The list below is what the latest passes changed.

## What the Latest Passes Hardened

**Servers**

- HTTP/2: a reset a client makes us send (the MadeYouReset shape) spends the same reset budget as one it sends. Past 1 MiB of incoming bodies only the oldest stream's window reopens. A peer sending past the receive window gets FLOW_CONTROL_ERROR. `content-length` is digits only, and repeats must agree.
- HTTP/2: a DATA frame that carries only padding spends the empty-frame flood budget, as an empty one does.
- A chunked body trickled in a few bytes a read is read once, resuming where the last read stopped, not again from its start (that was quadratic CPU).
- WebSocket ping, pong and close frames (at most 125 bytes by spec) are taken even when the route's message limit is smaller.
- A full page cache (`CACHE`) flooded with unique query strings sweeps its expired entries at most once a second, not on every miss.
- `#[derive(Rest)]` POST, PUT and PATCH with a value a `#[unique]` field already holds answer 422, not 500.
- A streamed answer still hears its client leave after 64 KB were sent behind it, so the connection and its `WISP_MAX_CONNS` slot are freed.
- `WISP_CLIENT_IP_HEADER` takes the last address of the header's last line, which the trusted proxy added; a client can forge the first.
- `Error::redirect` with a CR or LF in the location is a logged 500, and a non-3xx status is logged and sent as 303. Neither panics or splits a header.
- A dev 5xx page never shows in a release build, even with `WISP_DEV=on`. Stop signals are caught before the `listening` line.

**Files and uploads**

- Upload file names lose a drive (`C:`) and an NTFS stream (`:stream`), as well as paths.
- Static files and `Response::file_in` answer 404 for Windows device names (`nul`, `CON.txt`, `COM1`) and for names Windows trims (`a.txt.`, `a.txt `).

**Browser script and dev mode**

- The template-swap and the other dev endpoints answer only a loopback `Host` (against DNS rebinding), and the swap also needs the `x-wisp-dev` header, so another site cannot rewrite your templates.
- `wisp.js` leaves cross-origin form posts to the browser. A form field named `__wispEnhance` cannot replace `use:enhance`. The `javascript:` scheme guard on URL attributes is fuzzed with random URLs.

**Build and CLI**

- A route file name that is not UTF-8 or has a control character is an error, not text injected into generated comments. `wisp fmt` no longer panics on a tag cut off after an attribute name.
- `wisp service install` quotes `ExecStart`, escapes the plist XML, and refuses an app folder with a quote, `%` or a control character in its path, which could add unit directives. `wisp mcp` caps a message line at 16 MiB instead of buffering without bound.

**Edge hosts**

- Raw connections on Node, Bun and Deno have the native head and body deadlines: a trickled request is refused 408 when its next bytes come.
- The bridges that read a body with the host's `fetch` stop one byte past the route's limit and the app answers 413, so an endless body is not held in memory.
- A WebSocket message past the limit closes with 1009, and 4009 on Deno, whose `close` accepts no 1009.
- Windows hosts pass environment names to the app upper-cased, so reading `PATH` works.

## Not Claimed

- No audit, no bug bounty and no certification. A TLS server is not built in: put a proxy in front for browsers, as [Deploying](/docs/deploy/) says.
- Fuzzing and tests find what they are written to find. The fuzz targets are in the repository: read them.
- A debug build is for your machine: behind a proxy on the same machine every peer is loopback, so never serve one.

Found something? Open an issue on [GitHub](https://github.com/wyziedevs/wisp), and a failing request or file is the best report.

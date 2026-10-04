---
title: Runtime and Build
description: Understand the Wisp runtime: the server and its settings, I/O drivers, connection limits, HTTP/2, the single request entry point, the App trait and wisp build.
group: Design
order: 16
---

`wisp::main!()` is `wisp::app!()` plus a `main` that calls `wisp::run::<App>()`. An app that sets things up first writes that `main` itself. `wisp::serve::<App>(addr)` is the async form for apps that own their runtime; it runs until its future is dropped. Feature list (base path, slots, fonts, layers...): [design-features](/docs/design-features/).

## Server

`wisp::run::<App>()` serves on `$HOST:$PORT` (default 3000), thread per core.

- One worker per CPU (`WISP_THREADS`), each a single-threaded tokio runtime with its own I/O driver. The main thread accepts and hands out connections in turn. A connection lives on one thread, so the request path never wakes another.
- Why: a multi-thread tokio runtime funnels every socket event through one driver, which left cores idle when measured (bench/README.md).
- Tradeoff: no work stealing. A handler that blocks its thread stalls that thread's connections. Dev builds log any handler holding its thread 100 ms or more in one go, with what to use instead.
- On SIGTERM (systemd, Docker, Kubernetes) or Ctrl+C: stop accepting, answer requests under way with `connection: close`, wait for responses the drivers are still sending, close idle connections (the client retries on a new one), return after at most 10 s or at a second signal.
- Under `wisp dev` the app holds a pipe from the CLI as stdin and exits when it closes, so a killed `wisp dev` never leaves an app on the port.
- A panic in a handler becomes a 500 for that request; the connection survives. A log line that cannot be written (stderr's reader gone) is dropped, not a panic.
- TLS and compression belong to the reverse proxy or CDN (Caddy, nginx, Cloudflare), keeping the binary small and the hot path simple. Or run Wisp as a tower service under hyper or axum: [embed](/docs/embed/).

### Settings

All from the environment. Strict: one that is set but invalid stops the server with a message, never a silent default. `HOST` takes an IP or a name (`localhost`). A port in use, or one needing privileges, fails with what to do.

<div class="table-wrap">

| Setting | What it does |
|---|---|
| `PORT`, `HOST` | Where to listen: 3000, on 127.0.0.1 in dev and 0.0.0.0 otherwise |
| `WISP_DEV` | Dev mode: `on` in debug builds, `off` in release (5xx details, `static/` from disk, dev log) |
| `WISP_THREADS` | Worker threads, one per CPU by default |
| `WISP_BODY_LIMIT` | Largest request body (`1048576`, `512KB`, `10MB`); 1 MB by default |
| `WISP_SECRET` | Signs cookies; at least 32 characters |
| `WISP_SECRET_OLD` | The secret before, still accepted on cookies it signed (rotation) |
| `ORIGIN` | The site's address (`https://example.com`), for a proxy that does not pass `Host` on |
| `WISP_CLIENT_IP_HEADER` | Header the proxy puts the client's address in, for `cx.client_ip()` |
| `WISP_MAX_CONNS` | Open connections, WebSockets included, before new ones get a 503; 10000 by default, 0 for no cap |
| `WISP_IO` | Linux: `epoll` for an epoll per worker instead of io_uring; `uring` to fail at start, saying why, where io_uring does not work |

</div>

Behind a proxy:

- Form posts are checked against `Host`, the proxy's `X-Forwarded-Host` (a page on another site cannot set it), or `ORIGIN` when set. The first refused post logs how to fix a proxy that changes `Host`.
- `cx.client_ip()` trusts only the header `WISP_CLIENT_IP_HEADER` names (for `x-forwarded-for`, the entry the proxy added), else the peer's address.

### I/O Drivers

**io_uring** (Linux 6.1+, `crates/wisp/src/uring.rs`):

- Each worker has its own ring and its own listener on the same port (`SO_REUSEPORT`: the kernel spreads connections).
- One `io_uring_enter` per worker turn submits every queued response and runs completions that came in (`DEFER_TASKRUN`), instead of a `recv` and `send` per request.
- Receives stay armed for a connection's life (multishot, into buffers the ring lends back and forth); accepts are one multishot request per worker.
- The ring is one more thing tokio's epoll waits on (via eventfd), so handlers await timers, channels and database drivers as before. A WebSocket is handed to a tokio socket.
- At start a throwaway ring receives and sends once through the workers' code, with a buffer ring. One stderr line (`wisp: io: ...`) says which I/O runs and why not better.

**epoll** (`crates/wisp/src/epoll.rs`): used where io_uring does not work (older kernel, container seccomp profile, `io_uring_disabled` sysctl, some 6.8 kernels that refuse buffer rings; per-call buffers measured slower than epoll), or with `WISP_IO=epoll`.

- Each worker has an epoll of its own, sockets edge-triggered from accept to close. A connection does one `recv` and one `send` per request; only a send the socket has no room for is left to the driver.
- A connection is a task, but when its socket brings a request the driver polls the connection's future itself with the task's waker: a request whose handler does not wait is received, answered and sent without the scheduler.
- Which routes never wait is worked out at build. An `async fn before` in hooks.rs runs before every route and takes the fast path off all of them: keep it sync.
- Receive deadlines and stalled sends are one pass a second over the worker's connections, not a timer each.

Other systems accept on the main thread and hand connections out, on tokio's sockets.

The io_uring and epoll drivers are the `unsafe` modules of a native build (ring setup, memory shared with the kernel, socket calls std lacks), each block with why it holds. An earlier io_uring prototype that waited in `io_uring_enter` with no deferred task work measured level with plain tokio (bench/README.md).

### Connections and Limits

- One task per connection. `Cx` owns the read buffer; the task also owns a write buffer and an `Out { head, body }` pair of `String`s, all reused across requests.
- A connection holds them only while it has a request. An idle one (tokio's or epoll's; not yet the ring's), a WebSocket and a streamed response give them back to the thread's pool, so an idle keep-alive connection costs about 4 KB on Windows (task and socket). A wakeup with nothing to read (tokio on Windows reports every new socket readable) gives them back again.
- HTTP/1.1 with keep-alive and pipelining: every complete request in the read buffer is answered into the write buffer, then one `write_all`.
- Requests are parsed in place (`httparse`) and recorded in `Cx` as byte spans into its buffer, so `Cx` has no lifetime and handlers take `&mut Cx`.
- `Date` is cached per thread, reformatted once a second.

<div class="table-wrap">

| Limit | Value |
|---|---|
| Headers | 16 KB, 100 headers |
| Body | 1 MB (`WISP_BODY_LIMIT`, or a route's `BODY_LIMIT`), checked against `Content-Length` before any is read |
| Receive | 10 s for a request's head, then 10 s per part of its body (an upload may take minutes while it keeps coming) |
| Keep-alive idle | 60 s |
| Client taking a response | 30 s for any of it |
| Body buffer | grows as it arrives, at most 1 MB ahead; a large `Content-Length` alone allocates nothing |
| Out of descriptors | accepting pauses 50 ms at a time, logged once a second |

</div>

- A refused request is answered, the sending side closed, and what the client still sends is read and dropped for up to 2 s (and 1 MB), so the close does not reset the connection before the client reads why.
- On the wire: HTTP/1.1 without `Host`, or any request with two, is 400 (RFC 9112 section 3.2). An absolute-form target (`GET http://host/x`, as a proxy sends) is its path with its host as `Host` (3.2.2). `Expect: 100-continue` is answered only to HTTP/1.1.
- These deadlines and buffer rules are one module of plain functions (`crates/wisp/src/policy.rs`) that tokio's sockets, epoll, the ring and the epoll driver's own answers all call, tested on a made-up clock.
- Chunked request bodies, strictly: `Transfer-Encoding: chunked` alone (any other coding is 501), hex sizes of at most 16 digits, CRLF ends, extensions and trailers skipped but bounded, framing may not more than double a body's size. Data is moved together in place, so `cx.body()` is one slice either way. `Content-Length` with `Transfer-Encoding`, two `Transfer-Encoding`s, or chunked HTTP/1.0 is 400.

### HTTP/2

Off by default; the `h2` feature compiles it (nothing of it otherwise). A connection opening with the HTTP/2 preface is served as h2c with prior knowledge (`src/h2.rs`): own HPACK (static and dynamic tables, Huffman), no new dependency.

- Noticed only where the HTTP/1 parser already refused the bytes (`PRI * HTTP/2.0`), so HTTP/1 requests pay nothing, feature on or off.
- Each stream's HEADERS and DATA become an HTTP/1.1 request through `Cx::from_request` and the same `decide`/`serialize`; the answer goes back as HEADERS and DATA. Streams are answered one at a time, in the order they end.
- Limits: 100 concurrent streams (more refused), 16 KiB header lists and frames, 4 KiB HPACK table, the route's body limit (413). Flow control both ways, SETTINGS, PING, GOAWAY, RST_STREAM.
- GOAWAY `ENHANCE_YOUR_CALM` ends the connection on: a reset flood (resets beyond answers + 200), a CONTINUATION flood (64 pieces or 16 KiB), 1000 frames asking no request, an HPACK bomb (decoded list over 16 KiB).
- No `Upgrade: h2c`, no ALPN: the `tls` feature is the client's (`wisp::fetch`); the server has no TLS.

## One Request Entry Point

The built-in server is one front end. `respond` decides an answer as a `Reply { status, headers, body }`; the HTTP/1.1 writer adds `content-length`, `date` and `connection`. Everything else calls the same code, with the same parser and limits ([embed](/docs/embed/), [deploy](/docs/deploy/)):

<div class="table-wrap">

| Entry | What it is |
|---|---|
| `wisp::prepare::<A>()` | runs `init`, sets what a request needs |
| `wisp::handle::<A>(Request) -> Reply` | answers one request in process |
| `wisp::test::client::<A>()` | `handle` with cookies, for tests |
| `wisp::test::browser::<A>()` (feature `browser`) | the built-in server on a free port, driven in headless Chrome or Edge over DevTools by a small blocking WebSocket client (`crates/wisp/src/test/browser.rs`) |
| `wisp::tower::service::<A>()` (feature `tower`) | a `tower::Service` |
| `wisp build --static` | runs `handle` for each page, writes files |
| `wisp build --target` | compiles the same code to WebAssembly (`crates/wisp/src/edge.rs`) with a small JS bridge, no wasm-bindgen |

</div>

Edge detail: the app marks a path `const` when its answer cannot change (a baked page, a trailing-slash redirect), in an app with no `before`, `after` or `reroute` hook, when it read no header but `if-none-match` and `x-wisp-error` and had no query. The bridge's web `fetch` keeps the first answer and its 304 and replays them (GET, HEAD, `if-none-match`) without entering the wasm. `tests/platform/tests/fast.rs` pins them to native's.

### The `App` Trait

Generated code implements one trait:

```rust
pub trait App: 'static {
    fn init() -> impl Future<Output = Result<()>>;
    fn handle(
        route: Option<usize>,
        cx: &mut Cx,
        out: &mut Out,
    ) -> impl Future<Output = Result<()>> + Send;
    fn body_limit(route: usize) -> Option<usize>;
    // + static tables: shell, assets, templates (dev)
}
```

`handle` calls `before` from `src/hooks.rs`, then is a single `match` over the route id, so the whole server is monomorphized with the app. No handler trait objects. (`provide` and `cx.set` values are the one `dyn Any`: a lookup by type, off the hot path unless used.)

Less Rust in templates:

- `Data` fields are in scope: `{count}` for `{data.count}`.
- `class:won={data.won}` toggles a class on the server.
- `<a {href}>` is `href={href}`.
- An `Option` attribute (`aria-current={current}`) is left out when `None`.
- `#[derive(Json)]` gives JSON without serde: an endpoint returns the value, or `Response::json_of(&value)`.

## What `wisp build` Does

`wisp_build::run()` (in the app's `build.rs`):

1. Walks `src/routes`, builds the route table, sorts by priority, rejects conflicts.
2. Parses every `.wisp` file (routes and `src/components`) into a node list. Errors are `file:line:col: msg`. A top `---` block is cut off first, its lines left blank so markup keeps its line numbers, and split by the same lexer into items and statements.
3. Scans `+page.rs`, `+layout.rs`, `+server.rs`, the blocks' items, `src/hooks.rs` and the app's `src/NAME.rs` modules with a tiny Rust lexer for `fn load`, `#[action] ... fn name`, HTTP-method functions, hooks and `const BODY_LIMIT`. From each signature it reads: async or not, takes `cx` (or, for an action, uses it without taking it), which inputs it reads by name, returns a `Result`, returns a `Response`.
4. Writes `$OUT_DIR/wisp.rs`: a module per user file that `include!`s it after `use wisp::prelude::*`, with a `__call` module of shims that read inputs and adapt returns (so items need not be `pub`), and the template it feeds; one render function per template, the router `match`, `handle`, asset tables.
   - A `load`'s `Data` leaves its module in a public box (`__call::Loaded`) that only that module's template opens (a private type cannot travel on its own).
   - A block's statements need no box: they start the page's `async` render function, and the markup is a closure after them that layouts call, reading their locals with rustc-inferred types.
   - Each block line carries a `// file.wisp:line` comment, which `wisp dev` uses to retell rustc's errors against the file.

Release builds embed `static/` and the built CSS in the binary with a content hash, served `Cache-Control: immutable` under `?v=hash` URLs.

Because the build sees every route and template:

- **Baked pages.** A page whose output is the same for every request (no load, statements or `+page.js` in it or its layouts; holes that are literals; components whose props are literals or literal defaults; `{#if}` on those) is one `static` in the binary: status line, `content-type`, `content-length`, ETag, whole document. Answering is two copies and the date; `if-none-match` with its ETag is a 304 without hashing a byte. Hooks still run first. Dev mode renders it (`wisp dev` swaps templates without a build), and so does a status `before` set.
- **Folded text.** In release, text and literal holes next to each other are one `push_str`: `<p title={"a"}>{"<b>"}</p>` is `<p title="a">&lt;b&gt;</p>`, escaped at build time. Integers, floats and `bool` are written unescaped (they cannot hold markup).
- **Router.** A path with no parameter is matched whole, by length then bytes (no other matching route can come first). Only the rest split the path, into an array as deep as the deepest of them, parameters as slices.

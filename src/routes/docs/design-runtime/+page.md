---
title: Runtime
description: The server, request handling, drivers and the single request entry point.
group: Design
order: 21
---

- `wisp::main!()` is `wisp::app!()` plus a `main` that calls
  `wisp::run::<App>()`; an app that sets things up first writes that `main`
  itself.
- `wisp::run::<App>()` serves on `$HOST:$PORT` (default 3000), thread per
  core: one worker per CPU (`$WISP_THREADS`), each a single-threaded tokio
  runtime with its own I/O driver, and the main thread accepting connections
  and handing them out in turn. A connection lives on one thread, so the
  request path never wakes another thread. A multi-thread tokio runtime
  funnels every socket event through one driver; measured, it left more than
  half the cores idle at under half the throughput (bench/README.md). The
  tradeoff: no work stealing, so a handler that blocks its thread stalls that
  thread's connections. Dev builds log any handler that holds its thread for
  100 ms or more in one go, with what to use instead.
- On Linux 6.1 and later each worker has an io_uring of its own
  (`crates/wisp/src/uring.rs`) and a listener of its own on the same port
  (`SO_REUSEPORT`: the kernel spreads connections, no thread hands them
  out). One `io_uring_enter` per turn of a worker submits every response
  its connections queued since the last turn and runs the completions that
  came in meanwhile (`DEFER_TASKRUN`), in place of a `recv` and a `send`
  per request. Receives stay armed for a connection's life (multishot, into
  buffers the ring lends back and forth), and accepts are one multishot
  request per worker. The ring is one more thing tokio's epoll waits on
  (through an eventfd), so handlers await timers, channels and database
  drivers as before; a WebSocket is handed to a tokio socket. At start, a
  throwaway ring receives and sends once through the workers' code, with a
  buffer ring, and one line on stderr (`wisp: io: …`) says which I/O runs
  and why not better. Where io_uring does not work (an older kernel, a
  container's seccomp profile, the `io_uring_disabled` sysctl, some 6.8
  kernels that refuse buffer rings; buffers provided per call instead
  measured slower than epoll) each worker runs the same way on an epoll of
  its own (`crates/wisp/src/epoll.rs`), its
  sockets in it edge-triggered from accept to close; a connection
  receives and sends by itself (one `recv` and one `send` a request), and
  only a send the socket has no room for is left to the driver. A
  connection is a task, but when its socket brings a request, the driver
  polls the connection's future itself, with the task's waker: a request
  whose handler does not wait is received, answered and sent without the
  scheduler, and one that waits wakes the task as usual. Which routes
  never wait is worked out at build; an `async fn before` in hooks.rs
  runs before every route, so it takes the fast path off all of them:
  keep it sync. Receive
  deadlines and stalled sends are one pass a second over the worker's
  connections, not a timer each.
  `WISP_IO=epoll` asks for that. Other systems accept on the main thread
  and hand connections out, on tokio's sockets.
- Settings, all from the environment:

  | Setting                 | What it does                                                       |
  |-------------------------|--------------------------------------------------------------------|
  | `PORT`, `HOST`          | Where to listen: 3000, on 127.0.0.1 in dev and 0.0.0.0 otherwise   |
  | `WISP_DEV`              | Dev mode: `on` in debug builds, `off` in release (5xx details, `static/` from disk, dev log) |
  | `WISP_THREADS`          | Worker threads, one per CPU by default                             |
  | `WISP_BODY_LIMIT`       | The largest request body (`1048576`, `512KB`, `10MB`); 1 MB by default |
  | `WISP_SECRET`           | Signs cookies; at least 32 characters                              |
  | `WISP_SECRET_OLD`       | The secret before, still accepted on cookies it signed (rotation)  |
  | `ORIGIN`                | The site's address (`https://example.com`), for a proxy that does not pass `Host` on |
  | `WISP_CLIENT_IP_HEADER` | The header the proxy puts the client's address in, for `cx.client_ip()` |
  | `WISP_MAX_CONNS`        | Open connections, WebSockets included, before new ones get a 503; 10000 by default, 0 for no cap |
  | `WISP_IO`               | Linux: `epoll` for an epoll per worker instead of io_uring; `uring` to fail at start, saying why, where io_uring does not work |

  They are strict: one that is set but not valid stops the server with a
  message, rather than falling back to a default. `HOST` takes an IP address
  or a name (`localhost`). A port in use, or one that needs privileges, is a
  failure with what to do.
- Behind a proxy: form posts are checked against `Host` or the proxy's
  `X-Forwarded-Host` (a page on another site cannot set that header), or
  `ORIGIN` when it is set; the first refused post logs how to fix a proxy
  that changes `Host`. `cx.client_ip()` trusts only the header
  `WISP_CLIENT_IP_HEADER` names (for `x-forwarded-for`, the entry the proxy
  added), and is the peer's address otherwise.
- On SIGTERM (how systemd, Docker and Kubernetes stop a server) or Ctrl+C,
  `run` stops accepting, answers the requests under way with
  `connection: close`, waits for the responses the drivers are still
  sending, closes idle connections (a client retries on a new one), and
  returns after at most 10 s, or at a second signal.
- Under `wisp dev` the app holds a pipe from the CLI as its stdin and exits
  when it closes, so a killed `wisp dev` never leaves an app on the port.
- The io_uring and epoll drivers are the `unsafe` modules of a native
  build: the ring's setup, the memory it shares with the kernel, and the
  socket calls std has no word for, each block with why it holds. An earlier io_uring
  prototype, which waited in `io_uring_enter` and had no deferred task work,
  measured level with plain tokio (bench/README.md). On Windows (a
  development platform for Wisp apps) tokio waits on sockets through AFD
  polls, which costs about 3 µs a request more than a completion port
  would; not worth `unsafe`.
- `wisp::serve::<App>(addr)` is the async form, for apps that must own their
  runtime. It runs until its future is dropped.
- One task per connection. `Cx` owns the connection's read buffer; the task also
  owns a write buffer and an `Out { head, body }` pair of `String`s, all reused
  across requests. A connection holds them only while it has a request: an
  idle one (tokio's or the epoll's; not yet the ring's), a WebSocket and a
  streamed response give them back to the thread's pool, so an idle
  keep-alive connection costs about 4 KB on Windows, its task and socket.
  A wakeup with nothing to read (tokio on Windows says every new socket
  is readable) gives them back again rather than waiting in a read.
- HTTP/1.1 with keep-alive and pipelining: every complete request in the read
  buffer is answered into the write buffer, then one `write_all`.
- Requests are parsed in place (`httparse`) and recorded in `Cx` as byte spans
  into its buffer, so `Cx` has no lifetime and handlers take `&mut Cx`.
- Limits: 16 KB of headers, 100 headers, a 1 MB body (`WISP_BODY_LIMIT`, or
  a route's `BODY_LIMIT`, checked against `Content-Length` before any of the
  body is read), 10 s to receive a request's head and then 10 s for each
  part of its body (an upload may take minutes as long as it keeps coming),
  60 s keep-alive idle, 30 s for a client to take any of a response. The
  buffer for a body grows as it arrives, at most 1 MB ahead: a large
  `Content-Length` alone allocates nothing. A refused request is answered,
  the sending side closed, and what the client still sends read and
  dropped for up to 2 s (and 1 MB), so the close does not reset the
  connection before the client has read why. On the wire, HTTP/1.1 without
  `Host`, or any request with two, → 400 (RFC 9112 §3.2); an absolute-form
  target (`GET http://host/x`, as a proxy sends) is its path, with its host
  as `Host` (§3.2.2); `Expect: 100-continue` is answered only to HTTP/1.1.
  Out of descriptors, accepting pauses 50 ms at a time, logged once a
  second. These deadlines and buffer rules are one module of plain
  functions (`crates/wisp/src/policy.rs`) that tokio's sockets, the epoll,
  the ring and the epoll driver's own answers all call, tested there on a
  made-up clock.
- Chunked request bodies are read, strictly: `Transfer-Encoding: chunked`
  alone (any other coding → 501), hex sizes of at most 16 digits, CRLF line
  ends, extensions and trailers skipped but bounded, and framing may not
  more than double a body's size. The data is moved together in place, so
  `cx.body()` is one slice either way. `Content-Length` with
  `Transfer-Encoding`, two `Transfer-Encoding`s, or chunked HTTP/1.0 → 400.
- A log line that cannot be written (stderr's reader gone) is dropped rather
  than panicking.
- `Date` is cached per thread and reformatted once per second.
- A panic in a handler becomes a 500 for that request; the connection survives.
- HTTP/2, TLS and compression belong to the reverse proxy / CDN (Caddy, nginx,
  Cloudflare). This keeps the binary small and the hot path simple. (Or run
  Wisp as a tower service under hyper or axum: [embed.md](/docs/embed).)

## One request entry point

The built-in server is one front end. `respond` decides an answer as a
`Reply { status, headers, body }`; the HTTP/1.1 writer adds `content-length`,
`date` and `connection`. Everything else calls the same code:

- `wisp::prepare::<A>()` runs `init` and sets what a request needs.
- `wisp::handle::<A>(Request) -> Reply` answers one request in process.
- `wisp::test::client::<A>()` is `handle` with cookies, for tests.
- `wisp::test::browser::<A>()` (feature `browser`) is the built-in server on
  a free port, driven in headless Chrome or Edge over the DevTools protocol
  by a small blocking WebSocket client (`crates/wisp/src/test/browser.rs`).
- `wisp::tower::service::<A>()` (feature `tower`) is a `tower::Service`.
- `wisp build --static` runs `handle` for each page and writes files.
- `wisp build --target` compiles the same code to WebAssembly
  (`crates/wisp/src/edge.rs`), driven by a small JS bridge: no wasm-bindgen.
  A path whose answer cannot change (a baked page, a trailing-slash
  redirect) is marked `const` by the app, in an app with no `before`, `after`
  or `reroute` hook, when it read no header but `if-none-match` and
  `x-wisp-error` and had no query. The bridge's web `fetch` keeps the first
  answer and its 304 and replays them (GET, HEAD, `if-none-match`) without
  entering the wasm; `tests/platform/tests/fast.rs` pins them to native's.

Every path uses the same request parser and limits. See [embed.md](/docs/embed)
and [deploy.md](/docs/deploy).

## Less Rust boilerplate in templates

- `Data` fields are in scope: `{count}` for `{data.count}`.
- `class:won={data.won}` toggles a class on the server.
- `<a {href}>` is `href={href}`.
- An `Option` attribute (`aria-current={current}`) is left out when `None`.
- `#[derive(Json)]` for JSON without serde: an endpoint returns the value,
  or `Response::json_of(&value)` wraps it.

Generated code implements one trait:

```rust
pub trait App: 'static {
    fn init() -> impl Future<Output = Result<()>>;
    fn handle(route: Option<usize>, cx: &mut Cx, out: &mut Out) -> impl Future<Output = Result<()>> + Send;
    fn body_limit(route: usize) -> Option<usize>;
    // + static tables: shell, assets, templates (dev)
}
```

`handle` calls `before` from `src/hooks.rs`, then is a single `match` over
the route id, so the whole server is monomorphized with the app. There are
no handler trait objects anywhere. (Values given to `provide` and `cx.set`
are the one place with `dyn Any`: a lookup by type, off the hot path unless
the app uses them.)

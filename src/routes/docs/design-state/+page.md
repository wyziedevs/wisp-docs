---
title: Hooks, State and Streaming
description: Learn Wisp hooks, per-request state and values, and how to stream a response or a whole page with the {#await} block while sharing state with client code.
group: Design
order: 15
---

## Hooks and State

`src/hooks.rs` holds what runs outside any one route:

```rust
pub struct User(pub String);

/// Once, before the server listens. A failure stops it with the reason.
async fn init() -> Result<()> {
    wisp::provide(Db::connect(&std::env::var("DATABASE_URL")?).await?);
    Ok(())
}

/// Before every page, action and endpoint (and 404), not static files.
fn before(cx: &mut Cx) -> Result<()> {
    cx.set_header("x-frame-options", "DENY");
    if let Some(name) = cx.signed_cookie("user") {
        let user = User(name.to_string());
        cx.set(user);
    }
    if cx.path().starts_with("/admin") && cx.get::<User>().is_none() {
        return redirect("/login");
    }
    Ok(())
}
```

- `before` returns nothing, `Result<()>`, a `Response` (sent instead of the route), or `Option<Response>` (a CORS preflight, a maintenance page). Its errors and redirects are the route's. Headers it sets stay even when the route fails, so security headers reach error pages.
- `init` takes no `cx` (no request yet). It runs on the accepting thread, whose runtime runs until exit, so what it connects (a pool) keeps being driven.
- `src/hooks.rs` is `crate::hooks`: routes can use its `pub` types; no `use` lines needed. The build checks it: `init` and `before` must be shaped as above, any other `pub fn` is a mistake (a typo like `befor` would never run; a private one is a helper), and `main.rs` must not declare `mod hooks`.

## Values

<div class="table-wrap">

| API | What it does |
|---|---|
| `wisp::provide(value)` | makes a value (pool, client) available everywhere as `wisp::state::<T>()`; a never-provided type panics with its name (found by the first request) |
| `static X: Shared<Vec<Todo>> = Shared::new(Vec::new());` | in-memory value every request shares: `X.lock().push(todo)`. A `Mutex` without `unwrap` (a panic while held leaves the value as it was); do not hold the guard across `.await` |
| `static X: Table<Todo> = Table::new();` | rows under ids it gives |
| `Table::saved("todos")` | also kept in the app's store (log files in `WISP_DATA`, or any database via `wisp::Store`), survives restarts |
| `#[derive(Rest)]` | the type has a saved table, `Note::table()`, which a `+server.rs` serves (see [APIs and platforms](/docs/api/)) |
| `cx.set(value)` / `cx.get::<T>()` | hand a value along one request (`before` finds the user, pages read it) |
| `cx.take::<T>()` | moves it out, so it need not be `Clone` |
| `cx.bearer()` | token of an `Authorization: Bearer` header |
| `cx.host()` | the `Host` |
| `cx.delete_cookie(name)` | removes a cookie |
| `cx.flash("Saved")` | message for the next page (after a `redirect`, say); `{@flash}` in a page or layout shows it once (`cx.flashed()` in a block reads it; `cx.flash_message()` is the `&Cx` form for markup, `None` when there is none or the page has no `{@flash}`) |
| `cx.after(\|\| ...)` | runs once the handler is through, on the connection's thread when next free (`wisp::spawn`, then a yield): a log line, a `revalidate_tag`. Costs nothing on a request that does not call it. At the edge it is `wisp::spawn`, so the host keeps the instance alive (`waitUntil` on Cloudflare) |

</div>

`Table` methods: `add(todo)` returns the id; `get(id)`, `all()`, `find(|t| ...)` return copies as `Row { id, value }` (reads as its value: `{todo}`, `todo.title`, `todo.id`); `update(id, |t| t.done = true)`; `remove(id)`.

## Streaming

```rust
// src/routes/clock/+server.rs
fn get() -> Response {
    Response::events(|events| async move {
        loop {
            events.event(&now()).await?;
            wisp::sleep(Duration::from_secs(1)).await;
        }
    })
}
```

- `Response::stream(content_type, |body| async move { ... })`: the closure writes the body, in a task of its own, with a `Sender`. Each `send` goes out at once (chunked on HTTP/1.1); the body ends when the closure returns.
- `Response::events(|events| ...)` is the same for server-sent events (uncached, unbuffered by proxies). `Sender::event` writes one event whatever lines it has. A page listens with `listen(url, ...)` or `new EventSource(url)`.
- A send fails once the client has gone, so `?` stops the closure. On server stop, open streams end properly.

## Streaming a Page: `{#await}`

```html
<h1>{user.name}</h1>
{#await stats(user.id)}
  <p>Counting…</p>
{:then s}
  <p>{s.posts} posts</p>
{:catch e}
  <p>No stats: {e}</p>
{/await}
```

The page goes out at once with each `{#await}`'s pending markup in a `<wisp-await>`. The response stays open (chunked); as each future finishes, its `{:then}` or `{:catch}` follows after `</html>` as `<div data-wisp-await="K">...</div>` plus a one-line script that moves it into place.

- Answers go out in completion order; a quick one never waits for a slow one.
- Without JS the answers stay at the end of the page. wisp.js places them itself on navigation (and in `wisp dev` reloads). The inline script's hash is in the CSP like any other.
- For gzip clients the stream is gzipped a piece at a time, each flushed, so the page shows before the answers (other pages are left to a proxy, which may hold a stream back to compress it).

Rules:

- The expression is a future, not awaited: `stats(id)`, `async { ... }`. It runs after the page is sent, so it is `Send + 'static`: it owns what it reads (no borrowed locals), as does each branch, which also sees statics and the value.
- `{:then v}` gets a `Result`'s `Ok` value, or any other value as is. `{:catch e}` gets an `Err` as text (a `wisp::Error`'s message). `{:then}` and `{:catch}` may omit the name, or the branch.
- A branch renders after the request: no `cx` (build error saying so; read what it needs into the future first). A form's fields in it show their own values, as in a component.
- Components in a branch start with the page's: their instances come with the answer, numbered on from the page's, and join its list, so live.js (runs once the response has ended) starts them all, islands as they say.
- The page's own browser code (`{:x}`, `on:`, `bind:`, browser blocks) cannot go in a branch (build error at the await's line): its instance has started without it.
- A future that fails with no `{:catch}`, panics, or is not done within `WISP_HANDLER_TIMEOUT` (whatever its branches) shows `Something went wrong`. None of it touches the worker or the rest of the response. A client that leaves stops the futures.
- Only a page's own markup awaits: not a layout, component, error page, snippet, `<head>`, attribute, browser block or another `{#await}`. A page with `CACHE`, or drawn by the browser (`SSR = false`), is a build error. `PRERENDER`, `--static` and `--spa` wait for every answer and write it into the file.
- Chosen at build, per page. A page without `{#await}` is built and answered as before: one buffered write with `content-length`, no extra branch, nothing in `Out`. Deferred answers wait in a thread-local list only an await page touches.

## Client Code

Browser reactivity is in [Browser code](/docs/client/): a bare `<script>` per file, directives (`on:`, `bind:`, `:attr`, `class:`, `use:`, `transition:`), `{:expr}` holes, client `{:#if}` and `{:#each}`, client components, stores, a client router and `use:enhance`.

- The build tokenizes the script (`wisp-build/src/js.rs`), finds which Rust values it uses, and sends only those as JSON (`wisp::Json`).
- `live.js` (loaded only on pages with client code) runs it. `wisp.js` does forms, the morph and the router. No `eval`, no `with`; nothing is required with JS off.
- Dispatching `wisp:refresh` on the document morphs the current URL's page in again.
- Dev code lives in `wisp-dev.js`, served and linked only by debug builds, so none of it ships in production pages.

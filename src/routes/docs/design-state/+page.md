---
title: Hooks, state and streaming
description: Hooks, per-request state and values, streaming and the await block.
group: Design
order: 18
---

## Hooks, state and values for one request

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

- `before` may return nothing (or `Result<()>`), or a `Response` to send
  instead of the route (or `Option<Response>`: a CORS preflight, a
  maintenance page). Its errors and redirects are the route's would be.
  Headers it sets stay on the response even when the route fails, so
  security headers reach error pages too.
- `init` takes no `cx`: there is no request yet. It runs on the thread that
  accepts connections, whose runtime runs until the process ends, so what it
  connects (a pool) keeps being driven.
- `wisp::provide(value)` makes a value (a database pool, a client) available
  everywhere as `wisp::state::<T>()`. A type that was never provided panics
  with its name: a missing line at startup, found by the first request.
- `static TODOS: Shared<Vec<Todo>> = Shared::new(Vec::new());` is a value
  in memory that every request shares: `TODOS.lock().push(todo)`. A
  `Mutex` without the `unwrap` (a panic while it was held leaves the value
  as it was); do not hold the guard across an `.await`.
- `static TODOS: Table<Todo> = Table::new();` keeps rows under ids it
  gives: `TODOS.add(todo)` returns the id, `get(id)`, `all()` and
  `find(|t| …)` return copies as `Row { id, value }` (which reads as its
  value: `{todo}`, `todo.title`, `todo.id`), `update(id, |t| t.done = true)`
  and `remove(id)` change it. `Table::saved("todos")` also keeps them in
  the app's store (log files in `WISP_DATA`, or any database through
  `wisp::Store`), so they are there after a restart. A `#[derive(Rest)]`
  type has a saved one of its own, `Note::table()`, which a `+server.rs`
  serves (see [api.md](/docs/api)).
- `cx.set(value)` hands a value along the rest of one request, and
  `cx.get::<T>()` reads it: `before` finds the user once, every page reads it.
  `cx.take::<T>()` moves it out, so it need not be `Clone`.
- `cx.bearer()` is the token of an `Authorization: Bearer` header, `cx.host()`
  the `Host`, and `cx.delete_cookie(name)` removes a cookie.
- `cx.after(|| …)` runs a closure once the handler is through, on the
  connection's thread when it is next free (`wisp::spawn`, then a yield), for
  a log line or a `revalidate_tag` the visitor should not wait for. It adds
  nothing to a request that does not call it, and nothing to the request
  path. At the edge it is `wisp::spawn`, so the host keeps the instance
  alive until it is done (`waitUntil` on Cloudflare).
- `cx.flash("Saved")` leaves a message for the next page the visitor sees
  (after a `redirect`, say), whose `load` reads it once with `cx.flashed()`.
- `src/hooks.rs` is `crate::hooks`, so routes can use its `pub` types. Like
  a route file it needs no `use` lines. The build checks it: `init` and
  `before` are shaped as above, any other `pub fn` is a mistake (a typo like
  `befor` would never run; a private one is a helper, and rustc warns when
  nothing calls it), and `main.rs` must not declare `mod hooks` itself.

## Streaming

`Response::stream(content_type, |body| async move { … })` returns a
response whose body the closure writes, in a task of its own, with a
`Sender`: each `send` goes out at once (chunked on HTTP/1.1), and the body
ends when the closure returns. `Response::events(|events| …)` is the same
for server-sent events, uncached and unbuffered by proxies, and
`Sender::event` writes one event whatever lines it has; a page listens with
`listen(url, …)` or `new EventSource(url)`. A send fails once the client
has gone, so `?` on it stops the closure. When the server stops, open
streams end properly.

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

## Streaming a page: `{#await}`

A slow part of a page need not hold the rest back:

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

The page goes out at once, each `{#await}`'s pending markup in place inside
a `<wisp-await>`. The response stays open (chunked), and as each future is
done its `{:then}` or `{:catch}` follows, after `</html>`, as
`<div data-wisp-await="K">…</div>` and a one-line script that moves it into
place. Answers go out in the order they come, so a quick one never waits
for a slow one. Without JS the answers stay at the end of the page, where
the browser shows them. wisp.js puts them in place itself when it navigates
to the page (and in `wisp dev`'s reloads), and the inline script has its
hash in the CSP like any other. For a client that takes gzip the stream is
gzipped a piece at a time, each piece flushed, so the page still shows
before the answers (other pages are left to a proxy; a proxy may hold a
stream back to compress it).

- The expression is a future, not awaited: `stats(id)`, `async { … }`. It
  runs after the page is sent, so it is `Send + 'static`: it owns what it
  reads (no borrowed locals), as does each branch, which also sees statics
  and the value. `{:then v}` gets a `Result`'s `Ok` value or any other
  value as it is; `{:catch e}` gets an `Err` as text (a `wisp::Error`'s
  message). `{:then}` and `{:catch}` may leave out the name, or the branch.
- A branch renders after the request, so it has no `cx` (a build error that
  says so: read what it needs before, into the future), and a form's fields
  in it show their own values, as in a component.
- Components in a branch start with the page's: their instances come with
  the answer, numbered on from the page's, and join the page's list, so
  live.js (which runs once the response has ended) starts them all, islands
  as they say. The page's own browser code (`{:x}`, `on:`, `bind:`, browser
  blocks) can't go in a branch: its instance has started without it. That
  is a build error at the await's line.
- A future that fails with no `{:catch}`, panics, or is not done within
  `WISP_HANDLER_TIMEOUT` (whatever its branches) shows `Something went
  wrong`. None of it touches the worker or the rest of the response. A
  client that leaves stops the futures.
- Only a page's own markup awaits: not a layout, component, error page,
  snippet, `<head>`, attribute, browser block or another `{#await}`. A page
  with `CACHE`, or drawn by the browser (`SSR = false`), is a build error.
  `PRERENDER`, `--static` and `--spa` wait for every answer and write it
  into the file.
- The choice is made at build, per page. A page without `{#await}` is built
  and answered exactly as before: one buffered write with its
  `content-length`, no extra branch on the way, and nothing of it in `Out`.
  The answers a render defers wait in a thread-local list that only an
  await page touches.

## Client code

Reactivity in the browser is in [client.md](/docs/client). In short: a bare
`<script>` per file, directives (`on:`, `bind:`, `:attr`, `class:`, `use:`,
`transition:`), `{:expr}` holes, client `{:#if}` and `{:#each}`, client
components, stores, a client router and `use:enhance`. The build tokenizes the
script (`wisp-build/src/js.rs`), finds which Rust values it uses, and sends
only those as JSON (`wisp::Json`). `live.js` (loaded only on pages that have
client code) runs it; `wisp.js` does forms and the router. No `eval`, no
`with`, nothing is required with JavaScript off.

`wisp.js` does the morph, the router and forms. Dispatching `wisp:refresh`
on the document morphs the current URL's page in again. Dev code lives in `wisp-dev.js`, which only debug builds serve
and link, so none of it ships in production pages.

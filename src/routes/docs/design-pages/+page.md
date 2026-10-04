---
title: Page logic
description: A page's Rust block, loads, actions and how the markup reads them.
group: Design
order: 12
---

A page's Rust goes at the top of its `.wisp`, between two `---` lines:

```html
<!-- src/routes/blog/[slug]/+page.wisp -->
---
let post = db::post(&slug).await.or_404()?;

#[action]
async fn like(id: i64) {
    db::like(id).await?;
}
---
<head><title>{post.title}</title></head>
<h1>{post.title}</h1>
<form method="post" action="?/like"><button name="id" value={post.id}>Like</button></form>
```

- The block holds items (`fn`, `struct`, `use`, `static`, `const`, `impl`,
  `#[action]`s...), which go in the page's module, and statements, which
  are its load: they run for each request, before the markup renders, and
  the markup reads their names (`post`). They run in an `async` function
  that returns a `Result`, so `.await`, `?`, `return redirect("/")` and
  `return error(404, "…")` work in them. `cx` is there (`&mut Cx`), and each
  route parameter the file names is a local: `slug: String` for `[slug]`
  and `[...rest]`, `id: u64` for `[id=int]`, `Option<String>` (or
  `Option<u64>`) for `[[lang]]`. A page with no Rust at all reads them too:
  `<h1>{slug}</h1>`.
- The markup also sees `cx` (`&Cx`) in any page, layout or error page:
  `{cx.path()}`, `value={cx.input("email")}`.
- A `+page.rs` beside the `.wisp` is the other way to write the same page:
  a `load` that returns a `Data` struct (whose fields the markup reads by
  name), and the actions. A block may also hold exactly what a `+page.rs`
  would, `fn load` and `struct Data` included, but not a `fn load` and
  statements, and a page cannot have both a block and a `+page.rs`: the
  build says which line to move. A `+layout.wisp` takes a block the same
  way; its statements run while the layout renders, so they take `cx` as
  `&Cx` and cannot await or use `?` (a `+layout.rs` `load` can). Components
  and error pages take none.
- Build and type errors in a block point at the `.wisp` file and line. A
  block's text is part of the file's shape: editing it compiles again, while
  editing the markup still swaps in without a compile.

```rust
// The same page as src/routes/blog/[slug]/+page.rs:
struct Data {
    post: Post,
}

async fn load(slug: String) -> Result<Data> {
    let post = db::post(&slug).await.or_404()?;
    Ok(Data { post })
}
```

- A route file needs no `use` lines and no `pub`. Wisp includes it into a
  module of its own with `wisp::prelude` in scope (`Cx`, `Response`,
  `Result`, `error`, `redirect`, `#[action]`, the derives, ...), and its
  template is compiled inside that module, so it reads private types and
  fields. `pub` still works, and so do `use` lines (an explicit
  `use wisp::prelude::*` replaces the one Wisp adds), and `//!` docs and
  `#![…]` attributes at the top of the file. Files with CRLF line endings
  or a byte order mark build the same as any other.
- `load` is found by name, actions by the `#[action]` marker. Nothing else in the
  file is reachable from HTTP. This is deliberate: a helper function must
  never become an endpoint by accident.
- Signatures are as short as the function allows. `load`, actions and
  `+server.rs` endpoints may be `fn` or `async fn`; take `cx: &mut Cx`,
  `cx: &Cx` or no `cx`; and return their value (`Data`, `()`, `Response`)
  either plain or in a `Result` (`Result` alone is `Result<()>`). The build
  reads which from the signature and generates the matching call; rustc
  checks the types. An `#[action]` whose body uses `cx` without taking it
  gets it (`#[action]` adds `cx: &mut Cx`), so a counter's action is
  `#[action] fn increment() { cx.set_cookie("n", n + 1) }`.
- Every other parameter is an input, read from the request by its name: a
  route parameter of that name first, then the form a POST, PUT or PATCH
  sends, then the URL's query. The type says how. `T` must be there and be
  a `T` (any `FromStr`): missing is a 400 that says which field (a 422 by
  it from a JSON body, and a body that is not JSON a 400 that says where),
  sent but not a `T` a 422 by the field (a 400 from the query), and a route
  parameter that is not one a 404. `Option<T>` is `None` when
  it is missing or blank, `bool` is a checkbox (sent at all, and not
  `false`, `off` or `0`), `Vec<T>` is every value of a repeated field, and
  `&str` borrows a `String`. So `fn load(slug: String)`,
  `fn load(q: Option<String>, page: Option<u32>)` and
  `#[action] fn add(text: String, done: bool)` need no `cx` at all.
  `cx.form()` still reads anything else, files too, and `cx.input(name)`
  finds any one by name the same way (in a block's statements, say).
- `fn entries() -> Vec<…>` in a page under `[params]` lists the pages
  `wisp build --static` writes (see [deploy.md](/docs/deploy)).
- The build checks, against the file, that `load` returns `Data` (plain or
  in a `Result`), that every parameter but `cx` has a plain name, and that
  `#[action]` (by any path, `wisp::action` too) marks only top-level
  functions of a page.
- Errors: `?` on any `std::error::Error` gives a 500 (details only in dev).
  `return error(404, "…")` stops with that status and message, and
  `return redirect("/…")` with a 303; both are `Err`s, so they end a
  function that returns a `Result`. `Error::new(status, "…")` is the error
  itself, and `Error::redirect(status, "/…")` takes another status. Before
  `error()` returned the `Result`, code wrote `Err(error(..))`: that is now
  a `Result` inside an `Err`, so the build stops with the line and says to
  write `return error(..)` (or `Error::new` where an `Error` is wanted, as
  in `ok_or` and `map_err`).
  `Option::or_404()` is the common shortcut.
- An action returns nothing (or `Result<()>`), and then the page renders. It
  may instead return a `Response` (a CSV export, a file), sent in place of
  the page, or an `Option<Response>` to do that only sometimes.
- A form that fails validation: the action returns `invalid(field,
  problem)`, and the page renders again, as a 422, with the form still
  there: each of its inputs shows what was typed and what is wrong with it
  (see [Actions](/docs/design-forms#actions-and-wispjs)); a parameter whose type does not
  parse (`email: Email`, `age: u8`) is the same 422 by field; an action
  written without `->` returns `Result`, so it may end in `redirect(..)`;
  `{cx.problem(field)}` places one field's message elsewhere, and
  `cx.input(field)` reads what was sent. (Any
  other error from an action shows the error page.)

  ```html
  ---
  #[action]
  fn signup(name: String, email: Email) {
      if name.trim().is_empty() {
          return invalid("name", "Tell us your name");
      }
      redirect("/welcome")
  }
  ---
  <form action="?/signup">
    <input name="name">
    <input name="email">
  </form>
  ```

  For more than a message, `cx.fail(status, value)` keeps any value for the
  load, which takes it with `cx.take()`.
- `const BODY_LIMIT: usize = 20 * wisp::MB;` in a page or a
  `+server.rs` sets the largest body that route takes (the default is 1 MB,
  or `WISP_BODY_LIMIT`). A larger one is refused with a 413 as soon as its
  head arrives. The build checks that it is a `usize`, set once per route,
  and not in a layout, where it would do nothing.
- `const CACHE: u32 = 60;` in a page or a `+server.rs` keeps what a GET
  answers, as the bytes sent, for 60 seconds: a news page that changes a
  few times a minute renders once a minute per worker instead of once a
  request (Next.js calls it `revalidate`). The rules, which make it safe to
  add to any page that reads only its URL:
  - Each worker thread keeps its own, by `Host`, path and query, with no
    lock. A new process (a deploy) starts with none; a write does not clear
    it (it is kept for its time, like any cache).
  - A request with a `cookie` or `authorization` header is answered by a
    render, and nothing is kept from it: its cookie could make the page its
    own. `const CACHE_PUBLIC: u32 = 60;` instead shares the kept answer with
    those requests too, for a page that is the same for everyone.
  - Only a 200 is kept, and never one that sets a cookie or has a
    `cache-control` of `private` or `no-store`: a page can make one answer
    its own that way. What the page or endpoint set in headers is kept with
    it.
  - `before` in `src/hooks.rs` and a `+server.rs`'s `before` still run on
    every request, before the answer is looked for, so a guard or a header
    they set applies as ever.
  - A kept answer has an ETag: a client that sends it back gets a 304.
  - A page that reads a header (`accept-language`, a custom one) varies by
    it: do not `CACHE` it. Dev mode keeps nothing. At most 8 MB of answers
    a worker; past that the stale ones go, and a flood of new query strings
    costs renders, never memory.

  The build checks that it is a `const` `u32`, one of the two names, set
  once per route, and not in a layout.
- Three more consts beside `CACHE`, none costing a request that does not use
  them (they fold away; the hit path is the same code):
  - `const CACHE_STALE: u32 = 600;` is stale-while-revalidate: for 600 s
    after the answer is old, it is still sent at once, and the first request
    that finds it so makes a new one in the background (the app's own
    `handle`, as a GET from peer port 0, which a client never has), so no
    visitor waits for a render and a burst makes one. Single-flight per
    worker: workers do not share what they keep, so each refreshes for
    itself, once. A refresh that errors keeps the old answer and is tried
    again by the next request, until the window ends.
  - `const CACHE_TAGS: &[&str] = &["posts"];`, or `cx.cache_tag("post-7")`
    in a handler, names what is kept. `wisp::revalidate_tag("posts")` drops
    every answer under it on every worker before it next answers from what
    it keeps (as `uncache` does for paths). Each worker has a tag-to-keys
    index written only when a tagged answer is kept and when a tag is
    dropped; a lookup never touches it.
  - Draft mode: `cx.enter_draft()` (call it from an endpoint of your own
    that checks who may; `cx.exit_draft()` ends it) sets the signed cookie
    `wisp-draft`, and `cx.draft()` says whether the request has it. For a
    `CACHE_PUBLIC` route a draft request is never answered from what is
    kept, nor is its answer kept: the check runs only on that route's hit
    branch, behind "has a cookie", in a cold function. A `CACHE` route
    already renders for any request with a cookie. A page the build baked
    whole reads nothing of the request, so it has no draft.
- A page that reads nothing of the request needs no `CACHE`: when it and
  its layouts have no load, statements or `+page.js`, and every hole in them
  is a literal or a component's prop given as one (`<Card title="Hi" />`,
  `{#if featured}` on a flag), the build writes the whole response into the
  binary (see [Build](/docs/design-build#build)).
- A `+server.rs` method answers with the `Response` it returns; with any
  other value, that value as JSON (`#[derive(Json)]`); with nothing, a 204.
  An `Option<Response>` that is `None` is a 404. `body: T` (a type other
  than a string) is the JSON body read as a `FromJson` type, and an error
  on a request under `/api`, or one that sent or asks for JSON, is answered
  as JSON: see [api.md](/docs/api).

---
title: Pages and Templates
description: Learn how a Wisp page's Rust block works: signatures and inputs, loads, actions, validation, errors, limits, caching and accessibility lints.
group: Design
order: 11
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

## The Block

- Items (`fn`, `struct`, `use`, `static`, `const`, `impl`, `#[action]`...) go in the page's module. Statements are its load: they run per request before the markup renders, and the markup reads their names (`post`).
- Statements run in an `async` function returning a `Result`: `.await`, `?`, `return redirect("/")`, `return error(404, "…")` work. `cx` is `&mut Cx`. Each route param is a local: `slug: String` for `[slug]` and `[...rest]`, `id: u64` for `[id=int]`, `Option<String>` (or `Option<u64>`) for `[[lang]]`. A page with no Rust reads them too: `<h1>{slug}</h1>`.
- Markup in any page, layout or error page sees `cx` (`&Cx`): `{cx.path()}`, `value={cx.input("email")}`.
- `+page.rs` is the other way: `load` returning a `Data` struct (markup reads its fields by name), plus actions. A block may hold exactly what a `+page.rs` would (`fn load` and `struct Data` included), but not a `fn load` and statements; a page cannot have both a block and a `+page.rs` (the build says which line to move).
- `+layout.wisp` takes a block too; its statements run while the layout renders, take `cx` as `&Cx`, and cannot await or use `?` (a `+layout.rs` `load` can). Components and error pages take none.
- Errors in a block point at the `.wisp` file and line. Editing a block compiles again; editing markup still swaps in without a compile.
- A route file needs no `use` and no `pub`: it is included in its own module with `wisp::prelude` in scope (`Cx`, `Response`, `Result`, `error`, `redirect`, `#[action]`, the derives...), and its template is compiled inside it, so it reads private types and fields. `pub`, `use` (an explicit `use wisp::prelude::*` replaces Wisp's), `//!` docs and `#![…]` attributes still work. CRLF and byte order marks are fine.
- `load` is found by name, actions by `#[action]`; nothing else is reachable from HTTP, so a helper never becomes an endpoint by accident.
- `fn entries() -> Vec<…>` in a page under `[params]` lists the pages `wisp build --static` writes ([deploy](/docs/deploy/)).
- The build checks that `load` returns `Data` (plain or in a `Result`), that every parameter but `cx` has a plain name, and that `#[action]` (by any path, `wisp::action` too) marks only top-level functions of a page.

## Signatures and Inputs

- `load`, actions and `+server.rs` endpoints may be `fn` or `async fn`; take `cx: &mut Cx`, `cx: &Cx` or none; return their value (`Data`, `()`, `Response`) plain or in a `Result` (`Result` alone is `Result<()>`). The build reads which from the signature; rustc checks types.
- An `#[action]` whose body uses `cx` without taking it gets `cx: &mut Cx`: `#[action] fn increment() { cx.set_cookie("n", n + 1) }`.
- Every other parameter is an input, read by name: route param first, then the form of a POST, PUT or PATCH, then the URL query.

Type | Behavior
---|---
`T` (any `FromStr`) | Required. Missing: 400 naming the field (422 from a JSON body; a non-JSON body is a 400 saying where). Sent but not a `T`: 422 by field (400 from the query). A route param that is not one: 404
`Option<T>` | `None` when missing or blank
`bool` | Checkbox: sent at all and not `false`, `off` or `0`
`Vec<T>` | Every value of a repeated field
`&str` | Borrows a `String`

So `fn load(q: Option<String>, page: Option<u32>)` and `#[action] fn add(text: String, done: bool)` need no `cx`. `cx.form()` reads anything else, files too; `cx.input(name)` finds one by name the same way (in a block's statements, say).

## Errors, Actions, Validation

- `?` on any `std::error::Error` is a 500 (details only in dev). `return error(404, "…")` stops with that status and message; `return redirect("/…")` is a 303. Both are `Err`s, so they end a function returning a `Result`. `Error::new(status, "…")` is the error itself (for `ok_or`, `map_err`); `Error::redirect(status, "/…")` takes another status. `Err(error(..))` is a build error telling you to write `return error(..)`. `Option::or_404()` is the shortcut; `or_status(409)` on an `Option` or `Result` (the `OrStatus` trait, in the prelude) takes any status.
- An action returns nothing (or `Result<()>`) and the page renders; or a `Response` (CSV, a file) sent instead of the page; or an `Option<Response>` to do that sometimes.
- Validation: the action returns `invalid(field, problem)`; the page renders again as a 422 with the form still there, each input showing what was typed and what is wrong ([Actions](/docs/design-forms/)). A param that does not parse (`email: Email`, `age: u8`) is the same 422 by field. An action written without `->` returns `Result`, so it may end in `redirect(..)`. `{cx.problem(field)}` places one message elsewhere; `cx.input(field)` reads what was sent. Any other error shows the error page. For more than a message, `cx.fail(status, value)` keeps a value for the load, which takes it with `cx.take()`.

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

- `+server.rs` method: the `Response` it returns; any other value as JSON (`#[derive(Json)]`); nothing is a 204; `Option<Response>` `None` is a 404. `body: T` (not a string) is the JSON body read as a `FromJson` type. An error on a request under `/api`, or one that sent or asks for JSON, is answered as JSON ([api](/docs/api/)).

## Limits and Caching

`const BODY_LIMIT: usize = 20 * wisp::MB;` in a page or `+server.rs`: largest body the route takes (default 1 MB, or `WISP_BODY_LIMIT`); larger is a 413 as soon as its head arrives.

`const CACHE: u32 = 60;` in a page or `+server.rs` keeps a GET's answer, as the bytes sent, for 60 seconds (Next.js: `revalidate`). Safe on any page that reads only its URL:

- Per worker thread, by `Host`, path and query, no lock. A new process starts with none; a write does not clear it.
- A request with a `cookie` or `authorization` header is rendered and nothing is kept from it. `const CACHE_PUBLIC: u32 = 60;` shares the kept answer with those requests too, for pages the same for everyone.
- Only a 200 is kept, never one that sets a cookie or has `cache-control` of `private` or `no-store`. The page's headers are kept with it.
- `before` in `src/hooks.rs` and a `+server.rs`'s `before` run on every request, before the lookup.
- A kept answer has an ETag; a client sending it back gets a 304.
- A page that reads a header (`accept-language`, a custom one) varies by it: do not `CACHE` it. Dev keeps nothing. At most 8 MB per worker; past that stale ones go, so a flood of query strings costs renders, never memory.

Three more consts cost nothing for requests that do not use them (they fold away):

Name | What it does
---|---
`const CACHE_STALE: u32 = 600;` | Stale-while-revalidate: for 600 s after the answer is old it is still sent at once, and the first request finding it so refreshes it in the background (the app's own `handle`, as a GET from peer port 0, which a client never has). Single-flight per worker. A failed refresh keeps the old answer and is retried by the next request until the window ends
`const CACHE_TAGS: &[&str] = &["posts"];` or `cx.cache_tag("post-7")` | Names what is kept. `wisp::revalidate_tag("posts")` drops every answer under it on every worker before it next answers (as `uncache` does for paths). A tag-to-keys index is written only when a tagged answer is kept or a tag dropped; lookups never touch it
Draft mode | `cx.enter_draft()` (from your own endpoint that checks who may; `cx.exit_draft()` ends it) sets the signed cookie `wisp-draft`; `cx.draft()` reports it. On a `CACHE_PUBLIC` route a draft request is never answered from, nor stored in, the cache (checked only on the hit branch, behind "has a cookie", in a cold function). A `CACHE` route already renders for any cookie. A baked page has no draft

The build checks that each is a `const` `u32` of one of the names, set once per route, not in a layout (`BODY_LIMIT`: a `usize`, same rules).

A page reading nothing of the request needs no `CACHE`: when it and its layouts have no load, statements or `+page.js`, and every hole is a literal or a component prop given as one (`<Card title="Hi" />`, `{#if featured}` on a flag), the build writes the whole response into the binary ([Build](/docs/design-runtime/)).

## Accessibility

The parser lints each template. `wisp check`, `wisp dev` (each build and template swap) and `wisp build` print warnings (`! src/routes/+page.wisp:4: <img> has no alt: … (a11y-img-alt)`); `cargo build` prints `cargo::warning`s. They never stop a build. `<!-- wisp-ignore a11y-img-alt -->` on the line before an element silences that lint (several names may follow). A value set by an expression (`alt={x}`, `:alt="x"`, `{...attrs}`) counts as set.

Name | Warns about
---|---
`img-alt` | `<img>` without `alt` (`alt=""` is fine)
`click-events` | `on:click` on a non-interactive element (not a custom element like `<sl-button>`) without both a `role` and a key handler (`on:keydown`)
`input-label` | `<input>`, `<select>`, `<textarea>` with no wrapping `<label>`, no `id` (for `<label for>`), no `aria-label`/`aria-labelledby`/`title` (hidden and button types exempt)
`link-name` | `<a href>` with no text, `<img alt>`, `aria-label` or `title`
`label-control` | `<label>` with no `for` and no control inside
`anchor-href` | `<a>` without `href`, or `href="#"`
`autofocus` | `autofocus`
`heading-order` | a heading more than one level below the one before it in the file
`button-name` | `<button>` with no text, `aria-label`, `aria-labelledby` or `title`
`tabindex` | `tabindex` above 0
`aria-attr` | an `aria-*` name ARIA does not have

Client API (`beforeNavigate`, `afterNavigate`, `onNavigate`, `preloadData`, `preloadCode`, `invalidate(key)`, `updated`) and link attributes `data-wisp-noscroll`, `-keepfocus`, `-replacestate` live in wisp.js and live.js only: `wisp:navigate` is cancelable, `wisp:leave` collects what `onNavigate` waits for, `wisp:preload` reuses the hover prefetch, `updated` is set when a fetched page names another `wisp.js?v=`. `depends` is in the browser's `+page.js` `load` (the server renders pages whole, nothing to skip). Nothing is added to a request.

The rest is CSS, the client script and the starters, adding nothing to a request:

- A navigation moves focus to the `<h1>` and says the title in an `aria-live` region.
- View transitions and `--change` (every component's transition time) go to nothing under `prefers-reduced-motion`; `tokens.css` turns lines and quiet text up under `prefers-contrast: more`.
- Starters carry a skip link (`.skip`, `<main id="main">`), `:focus-visible` rings, 44px buttons on coarse pointers, `forced-colors` borders, `viewport-fit=cover` with `env(safe-area-inset-*)`, `100dvh`, fluid `clamp()` tokens (`--wisp-step-0..3`, `--wisp-space-s..xl`).
- `Dialog` and `Menu` are native `<dialog>` and popover (focus trap, Escape, focus returned); `Input`, `Textarea`, `Select` set `aria-invalid` and `aria-describedby` from `problem`/`hint`; `Card` answers its own width with `@container`. Phones: [client](/docs/client-router/).

Template syntax, components, snippets and scoped styles: [Template syntax and styles](/docs/design-syntax/).

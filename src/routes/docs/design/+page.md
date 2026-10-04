---
title: Design and Files
description: Principles, dependency budget, workspace, the files of an app, routes and Markdown pages.
group: Design
order: 10
---

Wisp is a fast, fun web framework for Rust: server-rendered HTML, file routes, `.wisp` templates, form actions without a client framework, one binary. This page is the contract for v0; when code and doc disagree, fix one.

## An App

```
my-app/
  Cargo.toml          deps: wisp; build-deps: wisp-build
  build.rs            fn main() { wisp_build::run() }
  src/main.rs         wisp::main!();
  src/app.html        document shell with %wisp.head% and %wisp.body%
  src/app.css         optional; Tailwind if it contains @import "tailwindcss"
  src/app.scss        optional; Sass, instead of src/app.css
  postcss.config.*    optional; PostCSS (node) after either, or on src/app.css
  package.json        optional; npm packages (`wisp add`), for bare imports
  src/hooks.rs        optional; `init` at start, `before` every request
  src/components/...  optional; Card.wisp is <Card>
  src/routes/...      pages
  src/db.rs           optional; any src/NAME.rs is the module `NAME`
  static/...          served as-is at /
```

Each `src/NAME.rs` (not `main.rs`, `lib.rs`, `hooks.rs`) is the module `crate::NAME` with no `mod` line, prelude in scope like a route file. Routes, `---` blocks, templates and `hooks.rs` reach it as `NAME` (`db::find(id)`). A file that `main.rs` or `lib.rs` declares (`mod db;`) is left to them.

## Routes

Directory names are URL segments; files starting with `+` are route files.

File | Meaning
---|---
`+page.wisp` | The page: markup after an optional `---` block of Rust
`+page.md` | A Markdown page instead; so is each `x.md`, at `x`
`+page.rs` | Instead of the block: `load` and `#[action]` functions
`+layout.wisp` | Wraps this page and all below it; `<slot />` or `{@render children()}`
`+layout.rs` | Instead of a block: `load` for the layout
`+error.wisp` | Errors below this directory; gets `status`, `message` (a sentence about the status when the error says no more than its name)
`+page.js` | Optional. `load({ data, url, params, route, fetch })` in the browser
`+server.rs` | `get`/`post`/`put`/`patch`/`delete` endpoints; one taking an `id` the path lacks serves `/[id]` below, and `list` is then the folder's GET. A `#[derive(Rest)]` type in it is served whole ([api](/docs/api))

Segments: `blog` (static), `[slug]` (param), `[[lang]]` (optional), `[...rest]` (rest, may be empty), `(group)` (not in the URL).

A param may name a matcher, `[id=int]`, `[[lang=locale]]`: `src/params/<name>.rs` with `fn matches(s: &str) -> bool`, given the decoded segment. `int` (ASCII digits fitting a `u64`) is built in. A refused segment goes on to the next route, so `/[id=int]` and `/[slug]` coexist. An unknown matcher is a build error.

```rust
// src/params/locale.rs
fn matches(s: &str) -> bool {
    matches!(s, "en" | "fr" | "de")
}
```

- Priority, left to right: static > param with matcher > param > optional with matcher > optional > rest. Two matchers in one place are tried in name order.
- Two routes with the same pattern are a build error. `/about/` redirects (308) to `/about`.
- Other build errors: a `.wisp`, `page.rs`, `layout.rs` or `server.rs` under `src/routes` without its `+`; a top-level `_app` or `_wisp` directory (Wisp's own); a `(group)` not exactly one name in parentheses; a route deeper than 32 segments. Editor swap and backup files are skipped.

### Trailing Slash

`/about/` gets a 308 to `/about`, query kept. `wisp::trailing_slash(Always)` in `init` flips it (`/about` to `/about/`, GET and HEAD of pages; endpoints and paths with a `.` in the last segment are left alone); `Ignore` serves both. The other form is matched only after no route matched, so the default costs nothing. The build warns of a literal `href="/…"` in a template the setting would redirect.

### Sitemap, Robots, Feed, Og

`/sitemap.xml` and `/robots.txt` are made from the route tree, answered only for a GET no route and no file matched. A file of the same name in `static/`, or a route, wins.

- The sitemap lists pages with known addresses (no params, or `entries()` as for `--static`; optional ones left out), minus pages in a `(private)` group and pages with `<meta name="robots" content="noindex">` (Markdown: `noindex: true`).
- Addresses start with `SITE_URL` (env), else the request's scheme and host (`x-forwarded-proto`, else https; http for localhost).
- `robots.txt` allows everything and names the sitemap.
- `/feed.xml`: Atom feed of Markdown pages with a `date` field, newest first; title `SITE_TITLE`, else the host; a page's `description` is its summary; none without a dated page.
- `wisp build --static` writes all three (the sitemap and robots when `SITE_URL` is set).
- `wisp::og(title, description, image)` gives escaped Open Graph and Twitter card tags: `{@html wisp::og("Hello", "A first post", "/cover.png")}`.
- Image `"auto"` with a literal title and description: `wisp build` (`og.rs` in the CLI, drawing in `wisp-shared`'s `og.rs`) writes `static/og/<slug>.svg`, 1200 by 630, with title, description and app name in `src/app.css`'s `--bg`, `--ink`, `--accent` (else Wisp's). It is SVG because nothing in Wisp's dependencies rasterizes, and X and Facebook want PNG: convert in CI (`rsvg-convert -o static/og/x.png static/og/x.svg`, or resvg) and pass `"/og/x.png"`. The opt-in `og-png` feature on `wisp` and `wisp-cli` renders each picture to a PNG with `resvg` (system fonts) and names that. A non-literal title (a database row) needs your own image.

## Markdown Pages

`+page.md` and each `x.md` (a page at `x`) is turned into markup at build time by `pulldown-cmark` (CommonMark, tables, strikethrough, task lists, footnotes), then compiled like a `.wisp` page. The folder's layouts wrap it; with no Rust in it, it is baked. Each heading gets an id from its text, GitHub style (`## Install and Run` is `#install-and-run`, a repeat gets `-2`), so section links work with no JavaScript.

```markdown
---
title: Hello
layout: Post
date: 2026-10-01
---
Text, and a component:

<Card title="x">

**Markdown** inside, between blank lines.

</Card>
```

- Front matter is `name: value` lines (quotes optional). `title` (else the first `# heading`) is the `<title>`, unless a layout above writes one: that layout reads it from `wisp::pages` and can wrap it (`Wisp: {title}`).
- `layout` names a component in `src/components` showing the page as its children; it gets each field its `{@props}` declare (`&str`/`String`, `bool`, a number, `Option` of one). A required field the page lacks, or a wrong type, is a build error.
- `noindex: true` adds `<meta name="robots" content="noindex">`.
- `{`/`}` in text and code become `&#123;`/`&#125;`, so no hole comes from them; raw HTML (components) is the template's own.
- Fenced code is highlighted at build time by `wisp-build` (rust, js/ts, html, wisp, css, json, bash; a `wisp` block, or an `html` one that opens with `---`, shows its Rust block and its `{expressions}` as Rust) as `<span class="hl-k|s|c|n|t|a">` (keyword, string, comment, number, type or tag, attribute) in `<pre><code class="language-x">`. Your CSS colors them; other languages keep the class, unhighlighted.
- `wisp::pages("blog")` gives a folder's `MdPage`s (`path`, `title`, `get("date")`), newest `date` first: `{#each wisp::pages("blog") as p}<a href={p.path}>{p.title}</a>{/each}`. A `static` slice the build wrote: no I/O, no allocation.

## Config Rules

`redirects`, `rewrites` and `headers` in `[package.metadata.wisp]` (Cargo.toml) are lists of strings, as Next.js's next.config has them. The build checks and bakes them into tables; the server reaches them only through the consts `App::REDIRECTS`, `REWRITES`, `HEADERS`, so an app with none runs no code for them. A pattern is a route's: text, `[name]`, a last `[...name]`. Anything malformed fails the build, naming the entry.

Rule | Form | Behavior
---|---|---
`redirects = ["/old/[id] /new/[id] 301"]` | `from to [status]` | 308 by default. `to` is an app path (under the base path, query kept) or `http(s)://` URL. Checked first in `before_routes`, after Wisp's `/_` paths
`rewrites = ["/g/[...p] /docs/[...p]"]` | `from to` | Served by that route (named by its pattern as is, no matcher or optional segment; its params are `[name]`s of `from`), address kept. Only for a path no route matches and no app file serves, in `find`'s miss path
`headers = ["/api/[...p] x-a: b"]` | `pattern name: value` | Set on every reply of a matching path, replacing the reply's own, in `tag`

## Principles

In order: ultra fast, cheap, durable, flexible; developer happiness last.

1. **Cheap** means app code in as few tokens as possible: AI writes most code, so a developer picks the framework whose apps run fastest, cost the fewest tokens, keep working and bend furthest. A convention beats a line of setup, one file beats two, a name the build can infer is not written. [tokens](/docs/tokens) measures it; [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole language in one page.
2. **Durable**: every fast path is proven at startup and falls back; nothing after startup takes the process down.
3. **Fast by construction**: templates compile to straight-line `push_str` calls, routes to one `match`, buffers are reused per connection. No boxing, no dynamic dispatch, no hot-path allocation after warm-up.
4. **Minimal dependencies.** Each new one needs a written reason here.
5. **Boring code**: plain functions and data; abstractions only where they remove more code than they add; invariants asserted.
6. **Safe**: no `unsafe` in Wisp or its generated code (workspace lint `forbid`; the benchmark runner, which pins processes to CPUs through the OS, sets its own).
7. **Mistakes fail early, in the user's file**: the build checks what it can and says where and what to do (a private `load`, an `#[action]` in the wrong place, `page.wisp` without its `+`, a block leaving a tag open in one branch). rustc only points at code the user wrote.
8. **Fast dev loop**: editing markup never waits for `cargo`; editing Rust rebuilds only the app crate.
9. **Works without JavaScript**: forms and links are real; `wisp.js` enhances, never required.

## Dependency Budget

Crate | Used by | Why
---|---|---
tokio | wisp | Async runtime; the DB/client ecosystem assumes it
httparse | wisp | Zero-dep, fuzzed HTTP/1.x header parser (hyper's)
bytes, http, http-body, tower-service | wisp, feature `tower` only | Tower vocabulary types so Wisp can be a service. Off by default
pulldown-cmark | wisp-build | Markdown at build time; compliant, fast, only its HTML writer on. The runtime gets nothing

The build crate and CLI depend on std and `pulldown-cmark` only.

- Not used by default: hyper, axum, tower, serde, a TOML parser, `notify`, `syn`/`quote`.
- Written ourselves: the HTTP/1.1 connection loop, URL/form decoding, multipart, HTML escaping, the HTTP date, the template compiler, a polling file watcher, the dev proxy of events.
- Signed cookies: SHA-256 and HMAC in about a hundred lines in `crates/wisp/src/sign.rs`, fixed algorithms with published vectors (FIPS 180-4, RFC 4231) its tests check, and a constant-time compare. Anything that encrypts would use a vetted crate; we write no ciphers.
- JSON: a fixed grammar (RFC 8259), so `crates/wisp/src/json.rs` has a strict parser for request bodies and `FromJson` with its checks, and `live.rs` writes JSON ([api](/docs/api)). Apps wanting serde still use it (`serde_json::from_slice(cx.body())`, `Response::json(serde_json::to_string(&x)?)`).
- Apps bring their own crates for a database driver, mailer, HTTP client.

## Workspace

```
crates/wisp        runtime: HTTP server, Cx, escaping, assets, dev hooks
crates/wisp-build  compiler: route scan, .wisp parser, codegen (from build.rs)
crates/wisp-shared what runtime, compiler and browser agree on: contexts.rs, protocol.rs, client/*.js
crates/wisp-macros #[action], #[derive(Cookie)], #[derive(Json)], #[derive(FromJson)] (proc macros; no deps but wisp-build, for `#[validate]`'s rules)
crates/wisp-cli    `wisp new | dev | build | check | lsp | mcp | update-docs`; deploy targets
editors/           VS Code and Zed extensions, tree-sitter grammar, Prettier plugin; README per editor
examples/demo      the demo app, also `wisp new`'s demo template
examples/api       a JSON API, also `wisp new --api`
tests/app          an app using every feature, and its tests
tests/agents       every Rust and HTML snippet of AGENTS.md, compiled
bench/             the same app in other stacks, load generator, runner (bench-run)
```

---
title: Files and routes
description: The files of a Wisp app, routes, Markdown pages and the folder conventions.
group: Design
order: 11
---

## An app

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

Each `src/NAME.rs` (but `main.rs`, `lib.rs` and `hooks.rs`) is a module of
the app with no `mod` line: Wisp compiles it as `crate::NAME`, with the
prelude in scope like a route file, and route files, `---` blocks, templates
and `src/hooks.rs` reach it as plain `NAME` (`db::find(id)`). A file that
`main.rs` or `lib.rs` declares itself (`mod db;`) is left to them, as
ordinary Rust.

## Routes

Directory names are URL segments. Files that start with `+` are route files.

| File           | Meaning                                                           |
|----------------|-------------------------------------------------------------------|
| `+page.wisp`   | The page at this path: markup, after an optional `---` block of Rust. |
| `+page.md`     | A Markdown page instead (see below); so is each `x.md`, at `x`. |
| `+page.rs`     | Optional, instead of the block: `load` and `#[action]` functions. |
| `+layout.wisp` | Wraps this page and every page below it. `<slot />` or `{@render children()}`. |
| `+layout.rs`   | Optional, instead of a block: `load` for the layout.              |
| `+error.wisp`  | Rendered for errors below this directory. Gets `status`, `message` (a sentence about the status when the error says no more than its name). |
| `+page.js`     | Optional. `load({ data, url, params, route, fetch })` in the browser. |
| `+server.rs`   | `get`/`post`/`put`/`patch`/`delete` endpoints; one that takes an `id` the path has not serves `/[id]` below, and `list` is then the folder's GET. A `#[derive(Rest)]` type in it is served whole ([api.md](/docs/api)). |

Segment syntax: `blog` (static), `[slug]` (param), `[[lang]]` (optional),
`[...rest]` (rest, may be empty), `(group)` (not part of the URL).

A param may name a matcher: `[id=int]`, `[[lang=locale]]`. A matcher is
`src/params/<name>.rs` with `fn matches(s: &str) -> bool`, given the
decoded segment; `int` (ASCII digits that fit a `u64`) is built in. A segment the matcher
refuses goes on to the next route, so `/[id=int]` and `/[slug]` can live
side by side. Naming a matcher that does not exist is a build error.

```rust
// src/params/locale.rs
fn matches(s: &str) -> bool {
    matches!(s, "en" | "fr" | "de")
}
```

Priority when several routes match: static segment > param with a matcher >
param > optional with a matcher > optional > rest, compared left to right
(two matchers in one place are tried in name order). Two routes that
resolve to the same pattern are a build error. `/about/` redirects (308)
to `/about`.

Also build errors: a `.wisp` file (or `page.rs`, `layout.rs`, `server.rs`)
under `src/routes` without its `+`, which would otherwise be ignored; a
top-level `_app` or `_wisp` directory, which Wisp's own files use; a
`(group)` that is not exactly one name in parentheses; a route deeper than
32 segments. Editors' swap and backup files are skipped.

`/sitemap.xml` and `/robots.txt` are made from the route tree, at no cost
to other requests: they are answered only for a GET that no route and no
file matched. The sitemap lists each page whose addresses are known (no
parameters, or `entries()`, as for `--static`; optional ones left out),
leaving out pages in a `(private)` group and pages whose markup has `<meta
name="robots" content="noindex">` (a Markdown page's `noindex: true`).
Addresses start with `SITE_URL` (env), else the request's scheme and host
(`x-forwarded-proto`, else https, http for localhost). `robots.txt` allows
everything and names the sitemap. A file of the same name in `static/`, or
a route, is served instead. `wisp build --static` writes both when
`SITE_URL` is set.

`/feed.xml` is made the same way: an Atom feed of the Markdown pages with
a `date` front matter field, newest first (title `SITE_TITLE`, else the
host; a page's `description` field is its summary); none without a dated
page; `--static` writes it too. `wisp::og(title, description, image)` is
the Open Graph and Twitter card tags of a page's head, escaped:
`{@html wisp::og("Hello", "A first post", "/cover.png")}`. With the image
`"auto"` (with the opt-in `og-png` feature on `wisp` and `wisp-cli`, which
renders each picture to a PNG with `resvg`, system fonts, and names that)
and a literal title and description, `wisp build` (`og.rs` in the
CLI, drawing in `wisp-shared`'s `og.rs`) writes `static/og/<slug>.svg`: 1200
by 630, title, description, the app's name, in `src/app.css`'s `--bg`, `--ink`
and `--accent` (else Wisp's). It is SVG because nothing in Wisp's dependencies
rasterizes, and X and Facebook want PNG: convert it in CI (`rsvg-convert -o
static/og/x.png static/og/x.svg`, or resvg) and pass `"/og/x.png"` as the image.
A title that is not a literal (a database row) needs an image of your own.

## Markdown pages

`+page.md`, and each `x.md` in a route folder (a page at `x`), is turned
into markup at build time by `pulldown-cmark` (CommonMark, tables,
strikethrough, task lists, footnotes), then compiled like a `.wisp` page:
the folder's layouts wrap it, and with no Rust in it, it is baked.

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

- Front matter is `name: value` lines (quotes optional). `title` (else the
  first `# heading`) is the `<title>`. `layout` names a component in
  `src/components` that shows the page as its children; it gets each field
  its `{@props}` declare (`&str`/`String`, `bool`, a number, `Option` of
  one). A field it requires that the page lacks, or a value of the wrong
  type, is a build error. `noindex: true` adds `<meta name="robots"
  content="noindex">`.
- `{`/`}` in text and code are written as `&#123;`/`&#125;`, so no hole
  comes from them; raw HTML (components) is the template's own.
- Fenced code is highlighted at build time by a small highlighter in
  `wisp-build` (rust, js/ts, html, css, json, bash): `<span
  class="hl-k|s|c|n|t|a">` (keyword, string, comment, number, type or tag,
  attribute) in `<pre><code class="language-x">`. The app's CSS colors
  them; other languages keep the class, unhighlighted.
- `wisp::pages("blog")` gives the `MdPage`s (`path`, `title`,
  `get("date")`) of a folder's Markdown pages, newest `date` first, for an
  index page: `{#each wisp::pages("blog") as p}<a href={p.path}>{p.title}</a>{/each}`.
  It is a `static` slice the build wrote: no I/O, no allocation.

Trailing slash: a page's address is `/about` and `/about/` gets a 308 to
it, the query kept. `wisp::trailing_slash(Always)` in `init` turns that
round (`/about` → `/about/`, for GET and HEAD of pages; endpoints and
paths with a `.` in their last segment are left as asked), and `Ignore`
serves both. The other form is matched only after its own path matched
no route, so the default costs nothing. The build warns of a literal
`href="/…"` in a template that the setting would redirect.

Config rules: `redirects`, `rewrites` and `headers` in `[package.metadata.wisp]`
(Cargo.toml), lists of strings, as Next.js's next.config has them. The build
checks them and bakes them into tables; the server calls in only through the
consts `App::REDIRECTS`, `REWRITES` and `HEADERS`, so an app with none runs no
code for them. A pattern is a route's: text, `[name]`, a last `[...name]`.
`redirects = ["/old/[id] /new/[id] 301"]`: `from to [status]` (308 by default),
`to` a path of the app (under the base path, the query kept) or an
`http(s)://` URL; checked first in `before_routes`, after Wisp's own `/_`
paths. `rewrites = ["/g/[...p] /docs/[...p]"]`: the request is served by that
route (named by its pattern as is, no matcher or optional segment; its
parameters are `[name]`s of `from`), the address kept; tried only for a path no
route matches and no file of the app serves, in `find`'s miss path, so a
matched path pays nothing. `headers = ["/api/[...p] x-a: b"]` set on every
reply of a matching path, replacing the reply's own, in `tag`. Anything
malformed fails the build, naming the entry.

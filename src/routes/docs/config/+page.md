---
title: Knobs, Features and Settings
description: The const knobs, Cargo.toml metadata keys, cargo features and the smaller public types.
group: Reference
order: 82
---

## Const Knobs

A `const` in a page's `---` block, `+page.rs`, `+server.rs` or a layout. The build reads them; nothing runs per request that you did not ask for.

<div class="table-wrap">

| Knob | What it does |
|---|---|
| `const CACHE: u32 = 60;` | keep a GET's answer 60 s per worker (ETag, 304); never with cookies or `authorization`; not in dev |
| `const CACHE_PUBLIC: u32 = 60;` | like `CACHE`, for every request |
| `const CACHE_STALE: u32 = 600;` | seconds past `CACHE` the old answer is sent while one request renews it |
| `const CACHE_TAGS: &[&str] = &["posts"];` | names for the answer; `wisp::revalidate_tag("posts")` drops it |
| `const RATE_LIMIT: u32 = 60;` | requests a minute per client address, then 429 (page, `+server.rs` or `src/hooks.rs`) |
| `const CORS: &str = "*";` | the same as `cx.cors("*")?` before the handler |
| `const CSRF: bool = false;` | opt out of the cross-site refusal of POST, PUT, PATCH, DELETE |
| `const TIMEOUT: u32 = 5;` | 503 after 5 seconds |
| `const MIDDLEWARE: &[&str] = &["auth"];` | run those functions of `src/middleware.rs` first; an `Err` answers |
| `const SIGNED_IN: bool = true;` | in a layout: its pages and actions are for members (303 to sign in, 401 for JSON) |
| `const PRERENDER: bool = true;` | render at build; `fn entries()` lists params |
| `const SSR: bool = false;` | the browser draws the page |
| `const BODY_LIMIT: usize = 20 * wisp::MB;` | largest body the route takes (413 past it; 1 MB) |
| `const RUNTIME: wisp::Runtime = wisp::Runtime::Edge;` | on `--target vercel` or `netlify`, also an edge function |

</div>

## [package.metadata.wisp]

Lists of strings in `Cargo.toml`, checked and baked at build.

<div class="table-wrap">

| Key | What it does |
|---|---|
| `base = "/app"` | serve under a base path (`WISP_BASE`) |
| `redirects = [...]` | `"from to [status]"` (308 by default; [design](/docs/design)) |
| `rewrites = [...]` | serve one path from another |
| `headers = [...]` | headers by path |
| `i18n = [...]` | locale routing: `default`, `prefix`, `domain`, `missing` ([translations](/docs/design-tooling)) |
| `use = [...]` | plugin crates the build loads |
| `extends = ["../base"]` | layers: an app's layout, components and static files under yours |

</div>

## Cargo Features

<div class="table-wrap">

| Feature | What it does |
|---|---|
| `tls` (wisp) | `https://` for `wisp::fetch` (rustls, no OpenSSL) |
| `h2` (wisp) | HTTP/2 with prior knowledge (h2c) on the built-in server |
| `img` (wisp) | `wisp::img::serve`: `/_img?src=&w=&q=` resizes a picture of `static/` |
| `og-png` (wisp and wisp-cli) | PNG Open Graph pictures for `wisp::og(.., "auto")` |
| `tower` (wisp) | the app as a Tower service ([embed](/docs/embed)) |
| `browser` (wisp) | `wisp::test::browser`: tests in headless Chrome or Edge |
| `types` (wisp) | used by `wisp check --types`; never in a served build |
| `avif` (wisp-cli) | AVIF widths for images in `wisp build`, beside WebP |

</div>

## Smaller Public Types

<div class="table-wrap">

| Name | What it is |
|---|---|
| `Channel`, `Subscription` | `wisp::channel(name)` and what its `subscribe()` receives |
| `Queue` | a named job queue from `wisp::queue` |
| `SpanGuard` | from `wisp::span`; the span ends when it drops |
| `TrailingSlash` | `Always`, `Never`, `Ignore` for `wisp::trailing_slash` |
| `Prefix` | `Optional`, `Always`, `AsNeeded`: what `wisp::prefix()` returns |
| `AsDate` | what `format_date` takes: epoch seconds, `"2026-10-04"` or `(y, m, d)` |
| `Resource` | the trait `#[derive(Rest)]` implements |
| `ClientModule`, `ExportRoute` | made by the generated code; apps do not write them |

</div>

`wisp::native_name("fr")` is a locale's name in its own language (`Français`).

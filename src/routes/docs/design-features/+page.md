---
title: Parity Features
description: See how Wisp covers what a server framework is expected to have: base path, hooks, routing options, client features, slots, intercepting routes, build tools, fonts.
group: Design
order: 19
---

All build-time, a const or a cold path: a request that uses none of them runs no code for them (`on_driver` and `dispatch` in `http.rs` only gained const-gated branches).

<div class="table-wrap">

| Feature | How |
|---|---|
| Base path | `WISP_BASE=/app` |
| Hooks | `report`, `reroute`, `wisp::on_fetch` |
| Layout reset | `+page@.wisp`, `+page@group.wisp` |
| Layout options | `CACHE`, `CACHE_PUBLIC`, `SSR`, `PRERENDER` in a layout |
| Endpoint CSRF | automatic; `const CORS` or `const CSRF: bool = false;` opts out |
| Browser env | `env.PUBLIC_X` |
| Typed routes | generated `pub mod routes` |
| Script strategies | `type="wisp/idle"`, `wisp/interaction` |
| Web vitals | `<meta name="wisp-vitals" content="/path">` |
| Bundle analyzer | `wisp build --analyze` |
| Fonts | `src/fonts.txt` |
| Layers | `extends = ["../base"]` |
| Middleware | `const MIDDLEWARE: &[&str] = &["auth"];` |
| Loading views | `+loading.wisp` |
| Slots | `@name` folders |
| Intercepting routes | `(.)`, `(..)`, `(...)` in a slot |
| Version skew | `<meta name="wisp-build">`, `wisp:stale` |

</div>

## Base Path

`WISP_BASE=/app` (cargo env, or `base = "/app"` under `[package.metadata.wisp]` for `wisp build`; `wisp dev` always serves at `/`) is compiled into `wisp-shared` (`protocol::BASE`, set by a `build.rs`), so every crate sees one const.

- `parse` takes it off the path span (`under_base`, cold, built only with a base; `/app` alone is `/`), so routes, assets, `cx.path()` and `/_wisp/*` are as without.
- What Wisp writes has it: the `protocol` URL consts (`/_app/...`, assets' `url`, JS imports), static `href`/`src`/`action`/`poster`/`formaction` values starting with one `/` in templates and the shell (`template::under_base`), `Error::redirect`, the trailing-slash 308, `Location` of a created row, the sitemap, `routes::`.
- Matching uses `protocol::route::*` (no base); generated `asset()` and `client_module()` match the base-less path. wisp.js reads the base from its own script URL.
- Not covered: a dynamic `href={x}` (use `routes::` or `wisp::based`), cookies' `Path`, the service worker and manifest.

## Hooks (`src/hooks.rs`)

- `report(cx, err)` is `handleError`: sync, every 5xx, const `REPORT`.
- `reroute(path) -> &str` is const-gated (`REROUTE`): `find` asks it for the path to route by; returns a part of the request path (or a path with no parameters).
- `wisp::on_fetch(f)` (once, in `init`) is `handleFetch`: `wisp::fetch` calls it before a request goes out. The edge build's `fetch` does not.
- No hook is on a path that has none.

## Routing and Options

- **Layout reset.** `+page@.wisp` has no layouts above it. `+page@group.wisp` has those down to the `group` (or `(group)`) directory's `+layout.wisp` (`routes.rs`: `Route::page_file`, `layouts`).
- **Layout options.** `CACHE`/`CACHE_PUBLIC`, `SSR` and `PRERENDER` in a layout apply to its pages (`Project::layout_opts`). The nearest layout wins; a page's own const wins over all. The cache refers to the layout's module in the generated arm, so the request does what a page's own `CACHE` does. A layout's `RATE_LIMIT`, `CORS` and `TIMEOUT` still do nothing and are errors. `trailing_slash` is the app's, not a page's.
- **Endpoint CSRF.** A `+server.rs` handler for post/put/patch/delete starts with `rt::check_origin` (one header compare, only on those methods), the check actions have. `const CORS` or `const CSRF: bool = false;` in the file leaves it out.
- **Env.** Browser code reads `env.PUBLIC_X`, inlined at build. Any other name is a build error (`js::public_env`), so a secret cannot reach the browser.
- **Typed routes.** The build writes `pub mod routes` (re-exported by `__mods`): a function per route named from its pattern (`/` is `home`, `/blog/[slug]` is `blog_slug`, `_2` for a taken name). Each parameter is `impl Display` (optional ones `Option<..>`), percent-encoded (`rt::path_param`; a rest parameter keeps its `/`).
- **Named middleware.** `const MIDDLEWARE: &[&str] = &["auth"];` in a page, `+server.rs` or `+layout` is checked against `src/middleware.rs` (a `pub fn` per name) and written by `middleware()` in codegen into the same statements `RATE_LIMIT` and `CORS` make: the page's or layout's `__guard`, the endpoint's `before`. They run first, so no dispatch changed (`http.rs` untouched) and a route naming none has nothing extra. `src/hooks.rs`'s `before` is the global one; `MIDDLEWARE` there is an error.

## Client Features

- **Script strategies.** `<script src type="wisp/idle">` and `wisp/interaction` are inert to the browser (and to the navigation morph, which only re-creates `module`/`javascript` ones). `lazy()` in wisp.js, run by `wake()`, makes the real `<script>` on idle or on the first pointer, key or scroll. Plain `<script src>` and `defer` need no code. About 270 bytes gzipped.
- **Web vitals.** Opt-in with `<meta name="wisp-vitals" content="/path">`. wisp.js watches LCP, layout shifts and event timing with `PerformanceObserver` and sends one `sendBeacon` on `visibilitychange` hidden. Server side it is an ordinary route. About 430 bytes gzipped.
- **Loading views.** `+loading.wisp` (a known route file; `Tree::loading` holds its folder's pattern) is read by `loading.rs` and written into the shell's head as `<script type="application/json" id="wisp-loading">[[prefix,html]]`: static bytes in every page of an app that has one, nothing otherwise. It does not run, so no CSP hash. `wait()` in wisp.js, before the fetch of a navigation not fetched ahead and not a pop, finds the deepest prefix that `fit` (the SPA fallback's matcher) accepts and fills `<main>`. Streaming `{#await}` needs none of it (it is for the whole page; a streamed page is read whole by a client navigation). About 290 bytes gzipped.
- **Version skew.** A release build puts `<meta name="wisp-build" content=ID>` in the shell (a hash of templates and Rust: baked, nothing per request). wisp.js compares it with the page a navigation fetched, as it does `wisp.js?v=` (which only changes with the runtime), and sends `wisp:stale` (the `updated` store).

## Slots and Intercepting Routes

**Slots (parallel routes).** A `@name` folder with a `+page.wisp` beside a `+layout.wisp` is an ordinary route at `/dir/@name` (no router change) that the layout draws.

- `Tree::slots` records it. The layout's `render` gets a `name: &dyn Fn(&mut Out)` parameter; `{@render name()}` calls it (a non-local snippet, so the template needed nothing).
- `wrap_layouts` passes `|o| page_K::render(o, cx, &sK)`, where `serve_page_N` loaded `sK` (the slot's `+page.rs`) after the layouts' own loads.
- A slot page cannot have statements (its render is sync inside a sync layout).
- Every page below the layout draws it; a layout with no slot has the signature it had.

**Intercepting routes.** `(.)`, `(..)`, `(...)` before a segment inside a slot (`Tree::intercepts`, from the route's segments; only `+page@.wisp`, so the page has no layouts) name the route it intercepts.

- The slot a route intercepts into is wrapped in `<div data-wisp-cut='[[target, own URL]]'>` (only that layout's pages carry it, nothing in the shell).
- `cut()` in wisp.js, on a click whose URL fits a target of an element the page has, fetches the own URL, puts its `<body>` in the element and pushes the target's URL.
- The page stays; `history.back()` closes it (the pop morphs the old page's empty slot back). A load of the URL is the route's own page.
- About 310 bytes gzipped, none of it run on a page with no such element.

## Build Tools

- **Bundle analyzer.** `wisp build --analyze` (`analyze.rs` in the CLI, `codegen::analyze`) reads the app like a release build, builds nothing, and for each page route sums the files that page loads as served: wisp.js and live.js minified, its templates' modules and static imports, app.css, the `static/` `.wasm` files its JavaScript names. Raw and gzipped, largest first, with the files of the heaviest. Gzip is counted with Wisp's own compressor (fixed Huffman, hash-chain matcher), without writing the bits.
- **Layers.** `extends = ["../base"]` beside `use` in `[package.metadata.wisp]` (`plugins.rs`): a path or a dependency with an app's layout.
  - Its `src/routes` and `src/components` are copied as a plugin's are (`(layer_<dir>)` group, `components/layer_<dir>/`, git-ignored, kept in step, stale ones removed), minus a route file the app has at the same path and a component it has by name.
  - `static/` is listed after the app's own in `static_files` (the app's URL wins).
  - `src/app.css` goes first in `app.css` (`join_styles`; plain CSS, no Sass or Tailwind pass).
  - A layer's root `+layout.wisp` wraps only the layer's own pages (it sits in the group).
  - All build-time: an app with no `extends` runs none of it.

## Fonts

`src/fonts.txt` (`wisp_shared::fonts`): a line per font file in `static/fonts`, or `google` and weights, which is the opt-in to download.

- Download (`fonts.rs` in the CLI, once): the Latin subset as WOFF2, plus a TrueType copy in `.wisp/fonts` for metrics. A failure only warns.
- The build puts first in `app.css` (`join_styles`, so dev too): an `@font-face` per file with `font-display: swap`; per family a fallback face (`size-adjust`, `ascent-override`, `descent-override`, `line-gap-override` from the font's `hhea` and `OS/2`, over Arial, Times New Roman or Courier New's average width); and `--font-<name>`.
- A `preload` link per WOFF/WOFF2 goes at the start of the shell's head.
- Metrics are read from TrueType and OpenType files only (WOFF2 is brotli, which Wisp has no decoder for). A local `.woff2` gets the swap and the preload, and its fallback face when `.wisp/fonts/<name>.ttf` exists.

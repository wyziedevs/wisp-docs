---
title: Parity features
description: What a server framework is expected to have, and what Wisp does for each.
group: Design
order: 20
---

All build-time, a const or a cold path: a request that uses none of them runs
no code for them (`on_driver` and `dispatch` in `http.rs` only gained const-gated
branches).

- **Base path.** `WISP_BASE=/app` (cargo env, or `base = "/app"` under
  `[package.metadata.wisp]` for `wisp build`; `wisp dev` always serves at `/`)
  is compiled into `wisp-shared` (`protocol::BASE`, a `build.rs` sets it), so
  every crate sees one const. `parse` takes it off the path span (`under_base`,
  cold, and only built with a base: `/app` alone is `/`), so routes, assets,
  `cx.path()` and the `/_wisp/*` paths are as without. What Wisp writes has it:
  the `protocol` URL consts (`/_app/...`, assets' `url`, JS imports), static
  `href`/`src`/`action`/`poster`/`formaction` values that start with one `/`
  in templates and the shell (`template::under_base`), `Error::redirect`, the
  trailing-slash 308, `Location` of a created row, the sitemap, `routes::`.
  Matching uses `protocol::route::*` (no base) and the generated `asset()`
  and `client_module()` match the base-less path. wisp.js reads the base from
  its own script URL. Not covered: a dynamic `href={x}` (use `routes::` or
  `wisp::based`), cookies' `Path`, the service worker and manifest.
- **Hooks** (`src/hooks.rs`). `report(cx, err)` is `handleError`: sync, every
  5xx, a const (`REPORT`). `reroute(path) -> &str` is const-gated (`REROUTE`):
  `find` asks it for the path to route by; it returns a part of the request
  path (or a path with no parameters). `wisp::on_fetch(f)` (once, in `init`)
  is `handleFetch`: `wisp::fetch` calls it before a request goes out; the edge
  build's `fetch` does not. No hook is on a path that has none.
- **Layout reset.** `+page@.wisp` is a page with no layouts above it,
  `+page@group.wisp` one with those down to the `group` (or `(group)`)
  directory's `+layout.wisp`, in `routes.rs` (`Route::page_file`, `layouts`).
- **Options.** `CACHE`/`CACHE_PUBLIC`, `SSR` and `PRERENDER` in a layout are
  its pages' (`Project::layout_opts`; the nearest layout wins, a page's own
  const wins over all; the cache refers to the layout's module in the
  generated arm, so the request does what a page's own `CACHE` does). A
  layout's `RATE_LIMIT`, `CORS` and `TIMEOUT` still do nothing and are
  errors. `trailing_slash` is the app's, not a page's.
- **CSRF for endpoints.** A `+server.rs` handler for post/put/patch/delete
  starts with `rt::check_origin` (one header compare, only on those methods),
  the check actions have; `const CORS` or `const CSRF: bool = false;` in the
  file leaves it out.
- **Env.** Browser code reads `env.PUBLIC_X`, inlined at build; any other name
  is a build error (`js::public_env`), so a secret cannot reach the browser.
- **Typed routes.** The build writes `pub mod routes` (re-exported by
  `__mods`): a function per route, named from its pattern (`/` is `home`,
  `/blog/[slug]` `blog_slug`, `_2` for a name taken), taking each parameter
  as `impl Display` (optional ones `Option<..>`), percent-encoding it
  (`rt::path_param`; a rest parameter keeps its `/`).
- **Script strategies.** `<script src type="wisp/idle">` and `wisp/interaction`
  are inert to the browser (and to the navigation morph, which only re-creates
  `module`/`javascript` ones); `lazy()` in wisp.js, run by `wake()`, makes
  the real `<script>` on idle or on the first pointer, key or scroll. Plain
  `<script src>` and `defer` need no code. About 270 bytes gzipped.
- **Web vitals.** Opt-in by `<meta name="wisp-vitals" content="/path">`: wisp.js
  watches LCP, layout shifts and event timing with `PerformanceObserver` and
  sends one `sendBeacon` on `visibilitychange` hidden. Server side it is an
  ordinary route. About 430 bytes gzipped.
- **Bundle analyzer.** `wisp build --analyze` (`analyze.rs` in the CLI, `codegen::analyze`)
  reads the app like a release build, builds nothing, and for each page route
  sums the files that page loads as served (wisp.js and live.js minified, its
  templates' modules and their static imports, app.css, the `static/` `.wasm`
  files its JavaScript names), raw and gzipped, sorted largest first, with the
  files of the heaviest. The gzip size is counted with Wisp's own compressor
  (fixed Huffman, a hash-chain matcher), without writing the bits.
- **Fonts.** `src/fonts.txt` (`wisp_shared::fonts`): a line per font file in
  `static/fonts`, or `google` and weights, which is the opt-in to download
  (`fonts.rs` in the CLI, once, the Latin subset as WOFF2 plus a TrueType copy
  in `.wisp/fonts` for metrics; a failure only warns). The build puts first in
  `app.css` (`join_styles`, so dev too) an `@font-face` per file with
  `font-display: swap`, per family a fallback face (`size-adjust`,
  `ascent-override`, `descent-override`, `line-gap-override` from the font's
  `hhea` and `OS/2` over Arial, Times New Roman or Courier New's average width)
  and `--font-<name>`; and a `preload` link per WOFF/WOFF2 at the start of the
  shell's head. Metrics are read from TrueType and OpenType files only (WOFF2
  is brotli, which Wisp has no decoder for): a local `.woff2` gets the swap
  and the preload, and its fallback face when `.wisp/fonts/<name>.ttf` exists.
- **Layers.** `extends = ["../base"]` beside `use` in `[package.metadata.wisp]`
  (`plugins.rs`): a path or a dependency with an app's layout. Its `src/routes`
  and `src/components` are copied as a plugin's are (`(layer_<dir>)` group,
  `components/layer_<dir>/`, git-ignored, kept in step, stale ones removed),
  minus a route file the app has at the same path and a component it has by
  name; `static/` is listed after the app's own in `static_files` (the app's
  URL wins); `src/app.css` goes first in `app.css` (`join_styles`, plain CSS,
  no Sass or Tailwind pass over it). A layer's root `+layout.wisp` wraps only
  the layer's own pages (it sits in the group). All build-time: an app with no
  `extends` runs none of it.
- **Named middleware.** `const MIDDLEWARE: &[&str] = &["auth"];` in a page,
  a `+server.rs` or a `+layout` is checked against `src/middleware.rs` (a `pub fn`
  by each name) and written by `middleware()` in codegen into the same
  statements `RATE_LIMIT` and `CORS` make: the page's or layout's `__guard`,
  the endpoint's `before`. They are the first thing the request runs, so no
  dispatch changed (`http.rs` is untouched) and a route that names none has
  nothing extra. `src/hooks.rs`'s `before` is the global one; `MIDDLEWARE`
  there is an error.
- **Loading views.** `+loading.wisp` (a known route file; `Tree::loading` holds
  its folder's pattern) is read by `loading.rs` and written into the shell's
  head as `<script type="application/json" id="wisp-loading">[[prefix,html]]`,
  so it is static bytes in every page of an app that has one and nothing
  otherwise; it does not run, so no CSP hash. `wait()` in wisp.js, before the
  fetch of a navigation not fetched ahead and not a pop, finds the deepest
  prefix that `fit` (the SPA fallback's own matcher) accepts and fills `<main>`.
  Streaming `{#await}` needs none of it: it is for the whole page, and a
  streamed page is read whole by a client navigation. About 290 bytes gzipped.
- **Slots (parallel routes).** A `@name` folder with a `+page.wisp` beside a
  `+layout.wisp` is an ordinary route at `/dir/@name` (no router change) that
  the layout draws: `Tree::slots` records it, the layout's `render` gets a
  `name: &dyn Fn(&mut Out)` parameter, `{@render name()}` calls it (a
  non-local snippet, so the template needed nothing), and `wrap_layouts`
  passes `|o| page_K::render(o, cx, &sK)` where `serve_page_N` loaded `sK` (the
  slot's `+page.rs`) after the layouts' own loads. A slot page cannot have
  statements (its render is sync inside a sync layout). Every page below the
  layout draws it; a layout with no slot has the signature it had.
- **Intercepting routes.** `(.)`, `(..)`, `(...)` before a segment inside a
  slot (`Tree::intercepts`, from the route's segments; only `+page@.wisp`, so
  the page has no layouts) name the route it intercepts. The slot a route
  intercepts into is wrapped in `<div data-wisp-cut='[[target, own URL]]'>`
  (only that layout's pages carry it, nothing in the shell); `cut()` in
  wisp.js, on a click whose URL fits a target of an element the page has,
  fetches the own URL, puts its `<body>` in the element and pushes the
  target's URL. The page stays, `history.back()` closes it (the pop morphs the old
  page's empty slot back), and a load of the URL is the route's own page.
  About 310 bytes gzipped, none of it run on a page with no such element.
- **Version skew.** A release build puts `<meta name="wisp-build" content=ID>`
  in the shell (a hash of templates and Rust: baked, nothing per request).
  wisp.js compares it with the page a navigation fetched, as it does
  `wisp.js?v=` (which only changes with the runtime), and sends `wisp:stale`
  (the `updated` store).

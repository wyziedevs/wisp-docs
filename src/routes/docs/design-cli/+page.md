---
title: CLI, Dev Loop and Security
description: How the Wisp CLI works: wisp new, the wisp dev loop with CSS tools, npm imports and template hot swap, wisp fmt, security defaults, CSP, and project milestones.
group: Design
order: 17
---

```bash
wisp new my-app     # prompts, or flags
cd my-app
wisp dev            # hot swap, live errors
wisp fmt            # format .wisp files
wisp build          # release binary
```

Agents (`wisp mcp`, `wisp update-docs`) and editors (`wisp lsp`): [AI agents and editors](/docs/design-editors/).

## `wisp new`

`wisp new [name]` asks where the app goes, which template (Demo: home page with a counter, an about page and Wisple, a word game on form actions; Minimal: one page, a layout and an error page), whether to add Tailwind, whether to create a git repo (yes unless the app lands inside one, like `cargo new`), and whether to download and compile dependencies now. Prompts are plain lines on std, not a cursor menu.

<div class="table-wrap">

| Flag | Answers |
|---|---|
| `--template` | which template |
| `--[no-]tailwind` | Tailwind |
| `--[no-]git` | git repo |
| `--[no-]install` | fetch and compile now |
| `--yes` | all defaults (also when there is no terminal) |

</div>

- Never writes into a directory with anything in it. Refuses a name Cargo would reject or that collides with Wisp's crates (`build`, `deps`, `test`, `wisp`...).
- An app created inside another Cargo workspace gets an empty `[workspace]` table, so it builds alone.
- Until Wisp is on crates.io, apps depend on it by path when `wisp` was built from a clone (`cargo install --path crates/wisp-cli`; changes reach them at once), and on https://wisp.ar0.eu (the repository) when installed with `cargo install --git`.
- The demo template is `examples/demo`, read with `include_str!`, so they cannot drift. A published crate has no `examples`, so build.rs copies them to `crates/wisp-cli/templates/vendor` whenever they are there and differ (a build in the repo refreshes it; commit the result); a build without them reads that copy.
- With Tailwind, the template's styles go in `@layer base` after the import, so utilities still win.

## `wisp dev`

One std-only process. `wisp dev [--port <n> | --port=<n> | -p <n>]`; anything else is an error with the usage.

- **Watching.** Polls mtimes of `src/`, `static/`, `Cargo.toml`, `build.rs`, `package.json` and `postcss.config.*` every 50 ms (no `notify`). Dot folders (except `static/.well-known`), `target` and `node_modules` are skipped; top-level files are read from one folder listing, symlinks followed. Editors' swap, backup and lock files are ignored; a file settles once it is quiet for 25 ms, and a burst settles for at most a second. Only a modified template swaps in; a template added, removed or renamed, or any `.rs` or `Cargo.toml` change, is a compile.
- **Port.** The app gets `HOST=127.0.0.1` unless `HOST` is set; the printed address is the one shown and used for hot swaps (port 0 works). A port in use moves the first start to the next free one, up to 20 more (the app binds it itself, `WISP_PORT_TRIES`, so nothing can take it between), with a line saying so. `wisp build` servers never move.
- **Build and restart.** Builds with `cargo build` (the first build, and any change that is not a `.rs` or `.wisp` file under `src`: `Cargo.toml`, `.env`, `package.json`, `static/`, `src/app.html`), copies the exe to `.wisp/run/` (so the next build can overwrite the original while the old server serves), restarts it. Ready when the app prints its `listening on` line: the CLI reads the app's stdout rather than polling (a refused connect takes 2 s on Windows). Output is read as bytes until the pipe closes, so a non-UTF-8 line never cuts the app off.
- **Rust edits skip cargo (Windows).** Cargo's own start and the build script's run cost about 0.15 s on a small app and 0.3 s on a large one, and the build script only repeats what `wisp dev` has just generated. So the CLI runs `cargo build` as cargo's `RUSTC_WRAPPER` the first time (itself, `wisp <rustc> <args>`), which records how cargo ran rustc for the app's binary (arguments, the `CARGO_PKG_*` and `OUT_DIR` variables, no other environment) to `.wisp/run/rustc`. Later saves of the app's own `.rs` and `.wisp` files write the generated code to `OUT_DIR/wisp.rs` and run that rustc command again: same incremental cache, same arguments, output read as rustc's JSON like cargo's. It falls back to cargo, which also records again, when the app has plugins or `extends`, a `src/lib.rs`, a `build.rs` other than `wisp_build::run()`, a rustc wrapper (`RUSTC_WRAPPER`, or `rustc-wrapper` in a cargo config), when a change is anything else, and when a failure names none of the app's files. `WISP_DEV_CARGO=1` always uses cargo. On Linux and macOS this is off and every build is cargo's: it is untested there, and `WISP_DEV_DIRECT=1` turns it on as an experiment. On Windows the replay links with the `rust-lld` that ships with rustc (`-C linker=rust-lld`), about 0.1 s faster than `link.exe`; a link that fails is tried again with the default linker, and not tried with `rust-lld` again. cargo's fingerprints are not updated, so the first cargo build after a session of such saves compiles the app once more. Measured on Windows 10 (medians of two runs of 12 saves of one `.rs` string or `.wisp` header, 16 jobs, from the CLI's own "Rebuilt in" and a trace of the same line): the demo app 0.75 s with cargo, 0.58 s without; a four-route app with auth and uploads 0.72 s, 0.54 s; the demo with 20 more copies of its largest route (21 routes, 7,000 lines of generated Rust) 1.24 s, 0.92 s. The rest is rustc itself: it reads the whole crate again on every edit (about 0.5 s of the large app's, with nothing changed), then links.
- **Saves that change no code build nothing.** A `.rs` file saved with the same tokens in the same places (a comment edited, spacing at a line's end; doc comments, every character of a literal and each token's line and column count, since `line!()` and panic locations show them) prints `no code changed`, and the running app stays, state and all. Only after a build that succeeded: a failed one is built again.
- **Children die with the CLI.** The app's stdin is a pipe the CLI holds; when it closes (however `wisp dev` ends, even `kill -9`) the app exits (`exit_with_parent`), freeing the port. A CSS watcher runs under `wisp __child <exe> <args...>`, which kills the tool then.
- **Reload.** Serves a Server-Sent Events stream on its own port. Browsers stay connected across restarts and are told to morph/reload once the new app is ready.
- **Output.** Cargo progress on the first build, then one line per change (`~ src/routes/+page.wisp  swapped in 0ms`, `✓ Rebuilt in 0.3s`). Compiler errors have paths relative to the app and no generated module names (`Data`, not `page_3::Data`). An error rustc finds in template-generated code is retold against the template's line; an action that returns a value is caught before compiling, against `+page.rs`.
- **Request log.** The app logs each request in dev (`GET /nope  404  0.1ms`, yellow 4xx, red 5xx) and a handler's panic once, with where; the error dialog shows that panic's message and `file:line`. Release builds log only 5xx and answer a panic with the plain 500.

### CSS Tools

<div class="table-wrap">

| Setup | What runs |
|---|---|
| `src/app.css` imports Tailwind | Tailwind standalone `--watch` into `.wisp/app.css` |
| `src/app.scss` exists | Dart Sass (standalone, pinned in `~/.wisp/bin`, `$WISP_SASS` overrides) `--watch` |
| a `postcss.config.*` | the tool writes `.wisp/pre.css`; the app's `node_modules/postcss-cli` (run by `node`, no npx) `--watch` makes `.wisp/app.css` of it (or of a plain `src/app.css`) |
| none | `src/app.css` served as written |

</div>

A watcher makes the first build itself; adding or removing `src/app.scss` or a `postcss.config.*` replaces the watchers. `wisp build` runs each once, minified (`--minify`, `--style=compressed`).

### npm Imports

Bare imports (`'canvas-confetti'`) are npm packages. `package.json` pins exact versions (`wisp add`). Dev imports `https://esm.sh/pkg@v?target=es2022`. A release build serves `.wisp/npm`, which `wisp build` fills from esm.sh before compiling: the modules `wisp check` finds imported and what they import, a level at a time, 16 at once, only those missing. Each is saved with imports pointed at `/_app/c/npm/`, and an import of esm.sh's re-export stub at the module it re-exports. The build embeds the files (`include_str!`); paths name versions, so they are cached for good without `?v=`.

### Template Hot Swap

In debug builds every static HTML chunk of every template is read through a table (`wisp::dev::chunk`) instead of being a literal. On a `.wisp` save the CLI re-parses the file. If its shape (holes, blocks, expressions, everything except static text) is unchanged, it POSTs the new chunks to the app (`/_wisp/dev/swap`, loopback only) and the browser morphs: no compile. If the shape changed, it is a normal rebuild. Release builds have no table.

- App template build tuning: `debug = "line-tables-only"`, dependencies at `opt-level = 1`.
- Targets: markup edit visible < 100 ms; Rust edit visible within 3 s (small app). Measured on the demo (Windows, Ryzen 7800X3D): a text edit swaps in under 1 ms and is served about 85 ms after the save (mostly the 50 ms poll); an expression or `.rs` edit rebuilds and restarts in 0.3 s.

## `wisp fmt`

`wisp fmt [paths]` formats `.wisp` files. `--check` lists the unformatted and fails (`wisp check` warns of them). `wisp fmt --stdin [path]` formats stdin to stdout (`path` for the edition), for editors and `editors/prettier-plugin-wisp`.

- Element tree and template blocks: two spaces a level. Attribute values double-quoted. A start tag that begins its line goes on one line or, past 100 columns, an attribute a line.
- The `---` block goes through rustfmt inside a wrapper fn, with the edition of the nearest `Cargo.toml` (the workspace's when inherited; 2024 without one), as `cargo fmt` would.
- `<script>` is re-indented only. `<style>` gets a declaration a line when it has no strings, comments or `url(`.
- Text, holes, `<pre>` and `<textarea>` are never touched.
- Markup that does not balance, or would not parse to the same template, is left as written. Formatting twice equals formatting once.

## CLI Older Than the App

When the installed `wisp` is older than the app's `wisp` crate (the CLI's stamp against the app's), app commands print a warning on stderr first. In a terminal it asks `Continue anyway? [y/N]`; the default N exits with 1. In CI or a pipe it warns and continues. `WISP_NO_UPDATE_CHECK=1` silences it. Without git, the stamp check stays silent.

```bash
cargo install wisp-web --force  # crates.io install
cargo install --path <checkout>/crates/wisp-cli --force  # path checkout
```

## Security

- **Escaping.** On by default; `{@html}` is the only raw output. Component props are typed Rust values, escaped where shown like any other.
- **Actions.** Opt-in (`#[action]`), same-origin checked, only form fields: no client-supplied type names or serialized state (Livewire CVE-2025-54068 class).
- **Signed cookies.** The signature binds the cookie's name and value, compared in constant time. `WISP_SECRET` under 32 characters stops the server at start.
- **Dev endpoints.** Only in debug builds, only answering loopback peers with a loopback `Host` (a DNS-rebinding page is refused), and the template swap also needs the `x-wisp-dev` header the CLI sends, which a cross-site page cannot add. Behind a proxy on the same machine every peer is loopback: never serve a debug build. Dev mode on a non-loopback address says so at start.
- **Live URL attributes** (`href={:x}`, `:src="x"`) block `javascript:` and `vbscript:` on the server's first paint and in the browser, as `href={x}` does. URL attributes whose scheme an expression decides are checked where they end: `javascript:` never reaches a page. wisp.js never follows a `javascript:` redirect or `goto`, and saves a posted form's attachment instead of opening it as a page of this site.
- **Limits.** Request size and time limits as in [Runtime and build](/docs/design-runtime/); no request smuggling surface (strict chunked parsing, CL+TE rejected).
- **Connections.** At most `WISP_MAX_CONNS` (10000) open, WebSockets included; past it a new one gets a 503 and is closed before it costs a task.
- **CSP.** Pages and error pages carry a `content-security-policy` (below).
- **Tests.** `examples/demo/tests/http.rs` runs the demo's binary and sends malformed, oversized, smuggling and cross-site requests, path traversal attempts and junk cookies, checking every answer and that the server keeps answering. `tests/app` uses what the demo does not (hooks, state, components, uploads, signed cookies, chunked bodies, body limits, streamed responses); its `tests/http.rs` checks each on the wire.

### Content Security Policy

Every page and error page (rendered, baked or kept by `CACHE`) gets:

```http
content-security-policy: default-src 'self'; script-src 'self' 'sha256-…';
  style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;
  connect-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'
```

- Wisp's own scripts are files (`wisp.js`, `live.js`, modules under `/_app/c/`); its JSON data block runs nothing.
- The only inline scripts are the app's (`<script defer>...</script>` in a template, or in `src/app.html`). No hole can go in one, so the build hashes each and `script-src` lists the hashes. An inline script edited in dev takes a build, for its hash.
- No nonce: the header is one string made after `init`, so a page costs one more header line, a baked or `CACHE` page stays bytes made before, and scripts wisp.js runs after a navigation pass (a nonce would be the first page's).
- Dev mode adds `https://esm.sh` (npm modules) to `script-src` and `connect-src`, and `wisp dev`'s reload events to `connect-src`.
- `wisp::csp("img-src 'self' https://cdn.example; font-src https://f.example")` in `init`: each directive replaces the default of its name, or is added. `script-src` keeps the hashes (unless it has `'unsafe-inline'`, which a hash would turn off). `wisp::csp_off()` sends none, for an app that sets its own.
- Not covered: endpoints and `Response::html` (not pages), `/_wisp/docs`, and `wisp build --static` (files have no headers; the host sets them). A script put in by `{@html}` or an `onclick="..."` attribute does not run; use a file, or `on:click`.

## Non-Goals and Milestones

No homegrown auth, ORM or job system, now or later. Wisp gives the tools (cookies, sessions, the `Store` trait, hooks, `wisp::spawn` from `init`) and the app builds on them. Integrations wire in existing, maintained crates (a recipe in `add/`; `wisp add sqlite` scaffolds the glue). Also out: Windows services. (HTTP/2 in process is the opt-in `h2` feature: h2c only.)

1. **Core**: routes, layouts, templates, load, actions, errors, static files, `wisp.js` morph, `wisp dev` with hot swap. (done)
2. **Measure**: req/s and latency against Rust and Node frameworks on the same machine ([Benchmarks](/docs/benchmarks/)). (in progress: more stacks and the dev-loop timings are still to come)
3. **Flexible**: hooks, state, components, uploads, signed cookies, streaming, body limits, proxies. (done)
   **Reactive and everywhere**: client scripts, router, tower, static export, Docker, edge targets. (done)
4. **v0.2**: link boosting (the client router) and a docs site built with Wisp (this one). (done)

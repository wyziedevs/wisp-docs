---
title: The CLI and the dev loop
description: wisp new, the dev loop, AI agents support and editors.
group: Design
order: 23
---

## `wisp new`

`wisp new [name]` asks where the app goes, which template (Demo: a home page
with a counter, an about page and Wisple, a word game built on form actions;
Minimal: one page, a layout and an error page), whether to add Tailwind,
whether to create a git repository (yes unless the app lands inside one, like
`cargo new`), and whether to download and compile dependencies now. Every
question has a flag (`--template`, `--[no-]tailwind`, `--[no-]git`,
`--[no-]install`); `--yes`, or no terminal to ask on, takes the defaults.
The prompts are plain lines on std, not a cursor-driven menu.

It never writes into a directory that has anything in it, and refuses a
name Cargo would reject or that would collide with Wisp's own crates
(`build`, `deps`, `test`, `wisp`...). An app created inside another Cargo
workspace gets an empty `[workspace]` table, so it builds on its own.

Until Wisp is on crates.io, apps depend on it by path when `wisp` was built
from a clone (`cargo install --path crates/wisp-cli`), so changes to Wisp
reach them at once, and on https://github.com/wyziedevs/wisp when it was
installed with `cargo install --git`.

The demo template is `examples/demo` itself, read with `include_str!`, so the
two cannot drift. A published crate has no `examples` beside it, so build.rs
copies them into `crates/wisp-cli/templates/vendor` whenever they are there
and differ (a build in the repo refreshes it; commit the result), and a build
without them reads that copy. With Tailwind, the template's styles go in `@layer base`
after the import, so utility classes still win over them.

## AI agents

Every app is written with AGENTS.md, the whole reference in one short page,
and a pointer to it for each agent that reads a file of its own:
`CLAUDE.md`, `.github/copilot-instructions.md` and `.cursor/rules/wisp.mdc`.
The app's AGENTS.md is the repository's (embedded at build time through
the vendor copy, so it never drifts) less its part for work on Wisp, and
ends with a line after which the app's own notes go. `wisp update-docs`
brings it up to the installed Wisp, keeping those notes, and writes any
pointer file that is missing (one that is there is the app's).

Every Rust and HTML snippet in AGENTS.md is in `tests/agents`, an app in
the workspace, so building the workspace compiles them; its test fails
when one is missing there. `llms.txt` (llmstxt.org) links the docs, and
`llms-full.txt` is AGENTS.md and the client, api, deploy and embed docs in one file, written by a
wisp-cli test that fails when it was stale.

`wisp mcp` is a Model Context Protocol server over stdio (JSON-RPC 2.0, a
message a line, `wisp_shared::json`), for the app in the current folder:

| Tool | Answers |
|---|---|
| `wisp_docs(topic)` | the AGENTS.md or docs sections about the topic; no topic lists them |
| `wisp_check()` | `{"ok":true}` or `{"ok":false,"errors":[{file,line,col,message}]}` |
| `wisp_routes()` | each route's pattern, folder, params, page, actions and endpoints |
| `wisp_components()` | each component's name, file and props (type, default) |
| `wisp_new_route(path, kind)` | writes `+page.wisp` (default), `+layout.wisp`, `+error.wisp` or `+server.rs`; never overwrites |

Setup, in the app's folder:

- Claude Code: `claude mcp add wisp -- wisp mcp`
- Cursor: `.cursor/mcp.json` with
  `{"mcpServers":{"wisp":{"command":"wisp","args":["mcp"]}}}`
- VS Code: `code --add-mcp '{"name":"wisp","command":"wisp","args":["mcp"]}'`,
  or `.vscode/mcp.json` with
  `{"servers":{"wisp":{"type":"stdio","command":"wisp","args":["mcp"]}}}`

## Dev loop

`wisp dev` is one std-only process:

- Polls `src/`, `static/`, `Cargo.toml`, `build.rs`, `package.json` and
  `postcss.config.*` mtimes every 50 ms (no `notify`). Editors' swap, backup and lock files
  are ignored, and a burst of changes settles for at most a second.
- `wisp dev [--port <n> | --port=<n> | -p <n>]`; anything else is an error
  with the usage. The app gets `HOST=127.0.0.1` unless `HOST` is set, and the
  address it prints is the one shown and used for hot swaps (port 0 works).
  A port in use moves the first start on to the next free one, up to 20 more
  (the app binds it itself, `WISP_PORT_TRIES`, so nothing can take it between),
  with a line saying so; `wisp build` servers never move.
- Runs Tailwind standalone `--watch` into `.wisp/app.css` if `src/app.css`
  imports Tailwind, or Dart Sass (standalone, pinned in `~/.wisp/bin`,
  `$WISP_SASS` overrides) `--watch` if `src/app.scss` exists; with a
  `postcss.config.*`, the tool writes `.wisp/pre.css` and the app's
  `node_modules/postcss-cli` (run by `node`, no npx) `--watch` makes
  `.wisp/app.css` of it (or of a plain `src/app.css`). Otherwise
  `src/app.css` is served as written. A watcher makes the first build
  itself; adding or removing `src/app.scss` or a `postcss.config.*`
  replaces the watchers. `wisp build` runs each once, minified
  (`--minify`, `--style=compressed`).
- Every child of `wisp dev` dies when its stdin, a pipe `wisp dev` holds,
  closes: however `wisp dev` ends, even killed, the system closes it. The
  app exits by itself (`exit_with_parent`); a CSS watcher runs under
  `wisp __child <exe> <args…>`, which kills the tool at that point.
- Bare imports (`'canvas-confetti'`) are npm packages: `package.json`
  pins them to exact versions (`wisp add`), dev imports
  `https://esm.sh/pkg@v?target=es2022`, and a release build serves
  `.wisp/npm`, which `wisp build` fills from esm.sh before compiling: the
  modules `wisp check` finds imported and what they import, a level at a
  time, 16 at once, only those not there yet. Each is saved with its
  imports pointed at `/_app/c/npm/`, and an import of esm.sh's re-export
  stub at the module it re-exports. The build embeds the files
  (`include_str!`); their paths name their versions, so they are cached
  for good without a `?v=`.
- Builds with `cargo build`, copies the exe to `.wisp/run/` (so the next build can
  overwrite the original while the old server keeps serving), then restarts it.
  The app is ready when it prints its `listening on` line; the CLI reads the
  app's stdout rather than polling the port (a refused connect takes 2 s to
  fail on Windows). Output is read as bytes until the pipe closes, so a line
  that is not UTF-8 never cuts the app off. The app's stdin is a pipe the
  CLI holds: if the CLI dies, even by `kill -9`, the app sees it close and
  exits, freeing the port.
- Serves a Server-Sent Events stream on its own port. Browsers stay connected
  across app restarts and are told to morph/reload once the new app is ready.
- Shows only what matters: cargo's progress on the first build, then one line
  per change (`~ src/routes/+page.wisp  swapped in 0ms`, `✓ Rebuilt in
  0.3s`). Compiler errors come through with paths relative to the app and
  without the generated modules' names (`Data`, not `page_3::Data`). An error
  rustc finds in generated code that came from a template is retold against
  the template's own line, and an action that returns a value is caught
  before compiling, against `+page.rs`.
- The app logs each request under those lines in dev (`GET /nope  404
  0.1ms`, yellow for a 4xx, red for a 5xx), and a handler's panic once, with
  where it happened. Release builds log only 5xx errors.

Template hot swap: in debug builds every static HTML chunk of every template is
read through a table (`wisp::dev::chunk`) instead of being a literal. On a
`.wisp` save the CLI re-parses the file; if its *shape* (holes, blocks,
expressions, everything except static text) is unchanged, it POSTs the new
chunks to the app (`/_wisp/dev/swap`, loopback only) and the browser morphs.
No compile. If the shape changed, it is a normal rebuild. Release builds have
no table: chunks are literals.

Rust build tuning shipped in the app template: `debug = "line-tables-only"`,
dependencies at `opt-level = 1`.

Targets: markup edit → visible < 100 ms. Rust edit → visible ≤ 3 s (small app).
Measured on the demo (Windows, Ryzen 7800X3D): a text edit is swapped in under
1 ms and served about 85 ms after the save (mostly the 50 ms poll); an
expression or `.rs` edit rebuilds and restarts in 0.3 s.

`wisp fmt [paths]` formats `.wisp` files (`--check` lists the unformatted
and fails; `wisp check` warns of them): the element tree and template blocks
two spaces a level, attribute values double-quoted, a start tag that begins
its line on one line or, past 100 columns, an attribute a line; the `---`
block through rustfmt inside a wrapper fn, with the edition of the nearest
`Cargo.toml` (the workspace's when inherited; 2024 without one), as
`cargo fmt` would; `<script>`
re-indented only; `<style>` a declaration a line when it has no strings,
comments or `url(`. Text, holes, `<pre>` and `<textarea>` are never touched.
Markup that does not balance, or that would not parse to the same template,
is left as written; formatting twice equals formatting once.
`wisp fmt --stdin [path]` formats stdin to stdout (`path` for the edition),
for editors and `editors/prettier-plugin-wisp`.

## Editors

`wisp lsp` is a language server over stdio, in the CLI: JSON-RPC framed by
hand, `wisp_shared::json` for parsing, no new dependency. Each file's app is
the nearest folder above it with `Cargo.toml` and `build.rs`.

- Problems: on open and every change, the buffer goes through the build's own
  parser and checks (`wisp_build::ide::check_file`: `---` block, template,
  component props against `src/components` as last read). On open and save,
  the whole app is checked from disk as `wisp check` does, and its problem
  shows in its file, open or not. One problem per file, as the compiler stops
  at the first. A panic in a request is answered as an error; the server
  goes on.
- Hover: a component's `{@props}`, a prop's type and default, directive and
  block docs, a route param's type, the `const` knobs (`CACHE`, `RATE_LIMIT`,
  `SSR`, ...), `<form fields>`, `action="?/x"`, `use:enhance` and the
  `data-wisp-*` attributes (tables in `lsp.rs`; a test fails when the
  reference shows one they lack). Rust items carry `///` docs
  (`#![deny(missing_docs)]` in `wisp`) for rust-analyzer.
- Go to definition: `<Card>` → its file, `'$lib/x.js'` → `src/lib/x.js`, a
  literal `href="/x"` → the route's `+page.wisp` (or `+page.rs`, `+server.rs`).
- Completion: components (with their required props), props, directives,
  `on:` events and modifiers, `{#…}` / `{:#…}` blocks, route paths in `href`.
- Formatting: `fmt.rs` on the buffer, answered as one edit of the whole
  text (none when it is formatted).

`editors/vscode` is a small extension: a TextMate grammar (HTML; Rust in the
block and `{…}`; JavaScript in `<script>`, directive values and `{:…}`; CSS in
`<style>`), snippets, format on save, **Wisp: Restart server**, and a client
(`vscode-languageclient`) that starts `wisp lsp`.

`editors/tree-sitter-wisp` is a tree-sitter grammar with the same embedding
through injections, no external scanner: flat tags (markup that does not
balance still parses), nested template blocks, code left whole. Neovim,
Helix and Zed (`editors/zed`) use it; `editors/README.md` has each editor's
setup, JetBrains, Sublime and Emacs included.

Follow-up: cheap Rust checks inside the `---` block (rust-analyzer covers
`.rs` files only).

## CLI older than the app

When the installed `wisp` is older than the app's `wisp` crate, the app commands print a warning on stderr (the CLI's stamp against the app's) before they run. In a terminal it asks `Continue anyway? [y/N]`, and the default, N, exits with 1. In CI or a pipe it prints the warning and continues. `WISP_NO_UPDATE_CHECK=1` silences it. Without git, the stamp check stays silent.

To fix it, update the CLI:

```bash
cargo install wisp-cli --force
cargo install --path <checkout>/crates/wisp-cli --force
```

The first is for a registry install, the second for a path checkout of Wisp.


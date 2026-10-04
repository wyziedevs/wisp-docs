---
title: Build
description: What wisp build does, step by step.
group: Design
order: 22
---

`wisp_build::run()` (in the app's `build.rs`):

1. Walks `src/routes`, builds the route table, sorts by priority, rejects conflicts.
2. Parses every `.wisp` file (routes and `src/components`) into a node list.
   Errors are `file:line:col: msg`. A `---` block at the top is cut off
   first, with its lines left blank so the markup keeps its line numbers,
   and split by the same lexer into its items and its statements.
3. Scans `+page.rs`/`+layout.rs`/`+server.rs`, the blocks' items,
   `src/hooks.rs` and the app's `src/NAME.rs` modules with a tiny
   Rust lexer for `fn load`, `#[action] … fn name`, HTTP-method functions,
   hooks and `const BODY_LIMIT`, and reads from each signature whether it is
   async, takes `cx` (or, for an action, uses it without taking it), which
   inputs it reads by name, returns a `Result` and returns a `Response`.
4. Writes `$OUT_DIR/wisp.rs`: a module per user file, which `include!`s it
   after `use wisp::prelude::*` and holds a `__call` module of small shims
   that read inputs and adapt what the function returns (so the file's items
   need not be `pub`), and the template it feeds; one render function per
   template, the router `match`, `handle`, and asset tables. A `load`'s
   `Data` leaves its module in a public box (`__call::Loaded`) only that
   module's template opens, since a private type cannot travel on its own.
   A block's statements need no box: they are the start of the page's
   render function, which is `async`, and the markup is a closure after
   them that the layouts call, so it reads their locals with the types rustc
   infers. Each line of a block is written with a `// file.wisp:line`
   comment, which `wisp dev` uses to tell rustc's errors against the file.

Release builds embed `static/` and the built CSS into the binary with a content
hash, served with `Cache-Control: immutable` under `?v=hash` URLs.

The build sees every route and template, and uses that:

- A page whose output is the same for every request (no load, statements or
  `+page.js` in it or its layouts; holes that are literals, components whose
  props are literals or their literal defaults, `{#if}` on those) is baked:
  its status line, `content-type`, `content-length`, ETag and whole document
  are one `static` in the binary. Answering it is two copies and the date;
  `if-none-match` with its ETag is a 304 without hashing a byte. Hooks still
  run first. Dev mode renders it, since `wisp dev` swaps templates without a
  build, and so does a status `before` set.
- In a release build, text and literal holes next to each other are one
  `push_str`: `<p title={"a"}>{"<b>"}</p>` is `<p title="a">&lt;b&gt;</p>`,
  escaped at build time. Integers, floats and `bool` are written without
  escaping: they cannot hold markup.
- The router matches a path with no parameter in it whole, by its length
  and then its bytes (no other route that matches it can come first); only
  the rest split the path, into an array as deep as the deepest of them,
  with parameters as slices of the path.

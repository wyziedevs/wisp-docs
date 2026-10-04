---
title: Design
description: The principles, dependency budget and workspace layout behind Wisp.
group: Design
order: 10
---

Wisp is a fast, fun web framework for Rust. Server-rendered HTML, file-based
routes, `.wisp` templates, form actions that update the page without a client
framework, and a single binary to deploy.

This document is the contract for v0. When code and doc disagree, fix one of them.

## Principles

1. **Ultra fast, then cheap, then durable, then flexible; developer happiness
   last.** Cheap means app code in as few tokens as possible: AI writes most
   code now, so a developer picks the framework whose apps run fastest, cost
   the fewest tokens to write, keep working and bend furthest. Durable means
   every fast path is proven at startup and falls back, and nothing after
   startup takes the process down. Every feature is judged
   first by what it costs the app's code: a convention beats a line of
   setup, one file beats two, and a name the build can infer is not written.
   [tokens.md](/docs/tokens) measures it against other frameworks, and
   [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md) is the whole language in one short page.
2. **Fast by construction.** Templates compile to straight-line `push_str` calls.
   Routes compile to one `match`. Buffers are reused per connection. No boxing,
   no dynamic dispatch, no allocation on the hot path after warm-up.
3. **Minimal dependencies.** The runtime depends on `tokio` and `httparse`. The
   build crate and CLI depend on nothing but std (and `pulldown-cmark`, for
   Markdown pages at build time). Every new dependency needs a
   written reason in this file.
4. **Boring code.** Plain functions and plain data. Abstractions only where they
   remove more code than they add. Invariants are asserted, not assumed.
5. **Safe.** No `unsafe` anywhere in Wisp or in the code it generates; the
   workspace lint is `forbid`. (The benchmark runner, which pins processes to
   CPUs through the OS, is the one crate that sets its own.)
6. **Mistakes fail early, in the user's own file.** Whatever the build can
   check, it checks, and says where and what to do: a private `load`, an
   `#[action]` in the wrong place, `page.wisp` without its `+`, a block that
   leaves a tag open in one branch. rustc should only ever point at code the
   user wrote.
7. **Fast dev loop.** Editing markup never waits for `cargo`. Editing Rust
   rebuilds only the app crate.
8. **Works without JavaScript.** Forms are real forms and links are real links.
   `wisp.js` enhances them; it is never required.

## Dependency budget

| Crate       | Used by        | Why it exists                                                      |
|-------------|----------------|--------------------------------------------------------------------|
| tokio       | wisp           | Async runtime; the entire DB/client ecosystem assumes it.          |
| httparse    | wisp           | Zero-dep, fuzzed HTTP/1.x header parser (the one hyper uses).      |
| bytes, http, http-body, tower-service | wisp, feature `tower` only | The vocabulary types of the tower ecosystem, so Wisp can be a service. Off by default. |
| pulldown-cmark | wisp-build | Markdown pages, rendered at build time. CommonMark has many edge cases; this parser is compliant, among the fastest, and only its HTML writer is on. The runtime gets nothing. |

Deliberately *not* used by default: hyper, axum, tower, serde, a TOML parser, `notify`,
a proc-macro stack (`syn`/`quote`). Things we write ourselves instead: the
HTTP/1.1 connection loop, URL/form decoding, multipart parsing, HTML
escaping, the HTTP date, the template compiler, a polling file watcher, the
dev proxy of events.

Signed cookies need SHA-256 and HMAC, which `crates/wisp/src/sign.rs` has
in about a hundred lines: fixed algorithms with published test vectors
(FIPS 180-4, RFC 4231), which its tests check, and a comparison that takes
the same time wherever the signatures differ. That keeps the runtime at two
dependencies. Anything that encrypts would use a vetted crate; we do not
write ciphers.

JSON is the same kind of thing: a fixed grammar (RFC 8259), so
`crates/wisp/src/json.rs` has a strict parser for request bodies and
`FromJson` with its checks, and `live.rs` writes JSON out
([api.md](/docs/api)). Apps that want serde still use it
(`serde_json::from_slice(cx.body())`, `Response::json(serde_json::to_string(&x)?)`).

Apps bring their own crates for everything else: a database driver, a
mailer, an HTTP client.

## Workspace

```
crates/wisp        runtime: HTTP server, Cx, escaping, assets, dev hooks
crates/wisp-build  compiler: route scan, .wisp parser, codegen (used from build.rs)
crates/wisp-shared what runtime, compiler and browser agree on: contexts.rs, protocol.rs, client/*.js
crates/wisp-macros #[action], #[derive(Cookie)], #[derive(Json)] and #[derive(FromJson)] (proc macros; no deps but wisp-build, for `#[validate]`'s rules)
crates/wisp-cli    `wisp new | dev | build | check | lsp | mcp | update-docs`; deploy targets
editors/           VS Code and Zed extensions, tree-sitter grammar, Prettier plugin; README per editor
examples/demo      the demo app, which is also `wisp new`'s demo template
examples/api       a JSON API, which is also `wisp new --api`
tests/app          an app that uses every feature, and the tests that run it
tests/agents       every Rust and HTML snippet of AGENTS.md, compiled
bench/             the same app in other stacks, load generator, runner (bench-run)
```

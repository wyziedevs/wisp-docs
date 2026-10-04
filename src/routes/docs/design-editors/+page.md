---
title: AI Agents and Editors
description: Use Wisp with AI agents and editors through AGENTS.md, the wisp mcp server and the wisp lsp language server, with setup notes for the editors that Wisp supports.
group: Design
order: 18
---

```bash
claude mcp add wisp -- wisp mcp    # Claude Code
wisp update-docs                   # refresh AGENTS.md to the installed Wisp
```

## AI Agents

Every app is written with `AGENTS.md`, the whole reference in one short page, and a pointer to it for each agent that reads a file of its own: `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/wisp.mdc`.

- The app's AGENTS.md is the repository's (embedded at build time via the vendor copy, so it never drifts) less its part for work on Wisp, and ends with a line after which the app's own notes go.
- `wisp update-docs` brings it up to the installed Wisp, keeping those notes, and writes any pointer file that is missing (an existing one is the app's).
- Every Rust and HTML snippet in AGENTS.md is in `tests/agents`, an app in the workspace, so building the workspace compiles them; its test fails when one is missing there.
- `llms.txt` (llmstxt.org) links the docs. `llms-full.txt` is AGENTS.md and the client, api, deploy and embed docs in one file, written by a wisp-cli test that fails when it was stale.

### `wisp mcp`

A Model Context Protocol server over stdio (JSON-RPC 2.0, a message a line, `wisp_shared::json`), for the app in the current folder:

<div class="table-wrap">

| Tool | Answers |
|---|---|
| `wisp_docs(topic)` | the AGENTS.md or docs sections about the topic; no topic lists them |
| `wisp_check()` | `{"ok":true}` or `{"ok":false,"errors":[{file,line,col,message}]}` |
| `wisp_routes()` | each route's pattern, folder, params, page, actions and endpoints |
| `wisp_components()` | each component's name, file and props (type, default) |
| `wisp_new_route(path, kind)` | writes `+page.wisp` (default), `+layout.wisp`, `+error.wisp` or `+server.rs`; never overwrites |

</div>

Setup, in the app's folder:

- Claude Code: `claude mcp add wisp -- wisp mcp`
- Cursor: `.cursor/mcp.json` with `{"mcpServers":{"wisp":{"command":"wisp","args":["mcp"]}}}`
- VS Code: `code --add-mcp '{"name":"wisp","command":"wisp","args":["mcp"]}'`, or `.vscode/mcp.json` with `{"servers":{"wisp":{"type":"stdio","command":"wisp","args":["mcp"]}}}`

## `wisp lsp`

A language server over stdio, in the CLI: JSON-RPC framed by hand, `wisp_shared::json` for parsing, no new dependency. Each file's app is the nearest folder above it with `Cargo.toml` and `build.rs`.

<div class="table-wrap">

| Feature | What it does |
|---|---|
| Problems | On open and every change the buffer goes through the build's own parser and checks (`wisp_build::ide::check_file`: `---` block, template, component props against `src/components` as last read). On open and save the whole app is checked from disk as `wisp check` does, and its problem shows in its file, open or not. One problem per file (the compiler stops at the first). A panic in a request is answered as an error; the server goes on. |
| Hover | A component's `{@props}`, a prop's type and default, directive and block docs, a route param's type, the `const` knobs (`CACHE`, `RATE_LIMIT`, `SSR`, ...), `<form fields>`, `action="?/x"`, `use:enhance`, the `data-wisp-*` attributes, Rust attributes in a block (`#[action]`, `#[model]`, `#[validate(..)]` and each rule, `#[derive(Rest)]`, `#[rest(..)]`, `#[json(..)]`, `#[unique]`) (tables in `lsp.rs`; a test fails when the reference shows one they lack). Rust items carry `///` docs (`#![deny(missing_docs)]` in `wisp`) for rust-analyzer. |
| Go to definition | `<Card>` to its file, `'$lib/x.js'` to `src/lib/x.js`, a literal `href="/x"` to the route's `+page.wisp` (or `+page.rs`, `+server.rs`) |
| Completion | Components (with required props), props, directives, `on:` events and modifiers, `{#...}` / `{:#...}` blocks, route paths in `href`, `#[` attributes in a block |
| Formatting | `fmt.rs` on the buffer, one edit of the whole text (none when formatted) |

</div>

Follow-up: cheap Rust checks inside the `---` block (rust-analyzer covers `.rs` files only).

## Editors

- `editors/vscode`: a small extension. TextMate grammar (HTML; Rust in the block and `{...}`; JavaScript in `<script>`, directive values and `{:...}`; CSS in `<style>`), snippets, format on save, **Wisp: Restart server**, and a client (`vscode-languageclient`) that starts `wisp lsp`.
- `editors/tree-sitter-wisp`: a tree-sitter grammar with the same embedding through injections, no external scanner: flat tags (markup that does not balance still parses), nested template blocks, code left whole. Neovim, Helix and Zed (`editors/zed`) use it.
- `editors/README.md` has each editor's setup, JetBrains, Sublime and Emacs included.
- `editors/prettier-plugin-wisp` formats through `wisp fmt --stdin`.

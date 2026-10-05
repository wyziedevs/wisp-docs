---
title: CLI Reference
description: The full reference for the wisp command line tool, listing every command, subcommand and flag in one table, plus the options for wisp new and CLI version notes.
group: Reference
order: 80
---

`wisp --help` prints the same list. App commands run from the app's folder.

## Commands

<div class="table-wrap">

| Command | What it does |
|---|---|
| `wisp new [name]` | create an app; asks a few questions, the options below answer them |
| `wisp dev [--port\|-p <n>]` | run the app, rebuild and reload on every save (port 3000) |
| `wisp build` | one release binary with CSS and static files inside |
| `wisp build --sourcemap` | the same, with source maps for browser code |
| `wisp build --analyze` | each route's JS, CSS and wasm bytes, raw and gzipped; builds nothing |
| `wisp build --static [--out dist]` | the pages as plain files, for any static host |
| `wisp build --spa [--out dist]` | the same, and `index.html` draws the `SSR = false` pages |
| `wisp build --docker [--force]` | write a `Dockerfile` and `.dockerignore` |
| `wisp build --target\|-t <host> [--edge] [--out\|-o <dir>]` | a folder for cloudflare, pages, deno, vercel, netlify, node, bun or lambda; `--edge` uses edge functions on vercel or netlify |
| `wisp build --client ts [--out client.ts]` | a typed TypeScript client of the `+server.rs` endpoints |
| `wisp openapi [-o\|--out openapi.json]` | print the OpenAPI 3.1 document, or write it |
| `wisp openapi --check` | fail if the committed file is stale (CI) |
| `wisp check [--types]` | check routes and templates without compiling; `--types` runs `tsc` too |
| `wisp test [--browser] [args]` | `cargo test` with its args; `--browser` runs browser tests too |
| `wisp fmt [paths]` | format `.wisp` files (markup, the `---` block, scripts, styles) |
| `wisp fmt --check` | name unformatted files and fail if any |
| `wisp fmt --stdin [path]` | format stdin to stdout, as the file at path (editors) |
| `wisp routes` | each route's methods, URL and file |
| `wisp new-route <path> [page\|server\|rest]` | write a page, endpoint or REST resource |
| `wisp deploy init <host> [--force]` | a GitHub Actions workflow that deploys on push |
| `wisp deploy init fly\|render\|railway [--force]` | that host's config (and a `Dockerfile`) |
| `wisp add <pkg>[@version]` | add an npm package to `package.json`; no Node needed |
| `wisp add [name] [--force]` | apply the recipe `add/<name>/recipe`; no name lists them |
| `wisp remove <pkg>` | take an npm package out |
| `wisp ui add <name…> [--force]` | copy components (button, dialog, tabs…) into `src/components` |
| `wisp ui list` | the components `wisp ui add` has |
| `wisp service install\|uninstall\|start\|stop\|status` | run the release binary as a systemd, launchd or Windows service; `--name`, `--user`, `--port`, `--dry-run` |
| `wisp lsp` | the language server, over stdio |
| `wisp update-docs` | bring `AGENTS.md` up to this Wisp |
| `wisp mcp` | docs, routes, components and checks for AI agents (MCP, stdio) |
| `wisp --help` | this list (`-h`, `help`) |
| `wisp --version` | the version (`-V`) |

</div>

## Options for Wisp New

<div class="table-wrap">

| Option | What it does |
|---|---|
| `-t, --template demo\|minimal\|api` | an app to learn from, one empty page, or a JSON API (also `--api`) |
| `--tailwind`, `--no-tailwind` | add Tailwind CSS, or leave it out |
| `--git`, `--no-git` | create a git repository, or not |
| `--install`, `--no-install` | download and compile dependencies now, or later |
| `-y, --yes` | take the defaults for anything not given |

</div>

## CLI Older than the App

App commands warn on stderr when the installed `wisp` is older than the app's `wisp` crate, and in a terminal ask before going on. `WISP_NO_UPDATE_CHECK=1` silences it. More: [CLI, dev loop and security](/docs/design-cli/).

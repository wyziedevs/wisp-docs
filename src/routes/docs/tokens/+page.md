---
title: Tokens
description: What an app costs to write in AI tokens, measured against other stacks.
group: Project
order: 70
---

Most app code is written by AI, so an app's cost is measured in tokens, and keeping it low is a Wisp principle ([design](/docs/design)). Run `cargo run -q -p wisp-tokens --release` for the numbers. The four-app comparison against six frameworks: [Tokens, app by app](/docs/tokens-apps).

## Five Features, Counted by `wisp-tokens`

`bench/tokens/apps` holds the same five features as a complete app in each stack:

- a list page loading its data
- a contact form (name 1 to 50 characters, a valid email; a 422 that shows each problem and keeps what was typed, else a redirect)
- a JSON endpoint of the list
- a layout with a nav
- a live search filtered in the browser

`cargo run -p wisp-tokens` counts them (method below, in `bench/tokens/src/main.rs`, with characters / 4 beside it). A `@feature NAME` comment says whose its lines are; a file without one, as a generator writes it, is not counted, nor the `[package]` table `cargo new` writes. The Wisp app builds with the workspace, and its tests check each feature.

| Stack | list | form | api | layout | search | data | setup | total | chars / 4 | files |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **Wisp** | 58 | 89 | 31 | 60 | 111 | 115 | 0 | **464** | 283 | 6 |
| SvelteKit 2 | 128 | 470 | 57 | 83 | 192 | 72 | 0 | 1002 | 644 | 9 |
| Next.js 15 | 107 | 439 | 44 | 108 | 241 | 71 | 0 | 1010 | 725 | 8 |
| Axum 0.8 + askama | 145 | 553 | 29 | 104 | 217 | 123 | 285 | 1456 | 1020 | 7 |
| Actix Web 4 + tera | 164 | 565 | 46 | 104 | 237 | 123 | 292 | 1531 | 1061 | 7 |

Wisp's `data` is longer than JavaScript's: a Rust type with its fields' types and `pub`s. Everything else is shorter, the form most of all. Of what is left, 60 tokens are file paths, 115 the Rust type and data, and the rest is markup every stack writes.

## A Real App: Auth, CRUD, Upload, Live, a Component

`bench/tokens/real` is sign up and in, a posts table with validation, edit, delete, pages and live refresh, an avatar upload and a toggle component: 10 files, **995** tokens in Wisp, 3.4x less than SvelteKit 3 and 3.2x less than Next.js 15. Its tests check every feature.

## Method

Counted: every file a developer (or an agent) writes by hand, beyond what the framework's generator gives, plus each file's path (writing a file means naming it, so two files cost more than one). Manifests (`Cargo.toml`, `package.json`, `Gemfile`) are left out everywhere. For Rails the generator commands are counted, since the agent must write them, and the lines it adds or changes in generated files. Rails' api is `rails g scaffold` in an `--api` app, which writes the controller; the same api written by hand is the last row.

There is no tokenizer offline, so the count estimates a BPE code tokenizer (cl100k-like):

- a newline with its indentation is 1 token; spaces join the word after them
- identifiers split at `_` and camelCase humps, each part 1 token up to 8 letters and 1 per 6 after that
- digits 1 per 3
- common operators (`::` `->` `=>` `==` `</` `/>` `{{` `<%=` ...) 1; any other punctuation character 1

Characters / 4, the usual rule of thumb, ranks the frameworks the same way.

Competitor versions: SvelteKit 2 with Svelte 5 runes and `use:enhance`; Next.js 15 app router with server actions and `useActionState`; Nuxt 3 with server routes and `useFetch`; Axum 0.8 with maud and serde; FastAPI with Jinja2 and pydantic; Rails 8 with Active Record. The Wisp versions are built by a script, so every counted line compiles. The competitors' sources, `count.py` and `verify.py` are kept out of the repository, so its size stays Wisp's own.

---
title: Tokens
description: What an app costs to write in AI tokens, measured against other stacks.
group: Project
order: 70
---

Most app code is written by AI, so an app's cost is measured in tokens, and keeping it low is a Wisp principle ([design](/docs/design)). Run `cargo run -q -p wisp-tokens --release` for the numbers. The four-app comparison against six frameworks: [Tokens, app by app](/docs/tokens-apps).

## Five features, counted by `wisp-tokens`

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
| Wisp, before the sugar round | 60 | 118 | 35 | 60 | 106 | 115 | 0 | 494 | 298 | 6 |
| Wisp, before this round | 74 | 127 | 35 | 60 | 120 | 115 | 0 | 531 | 321 | 6 |
| Wisp, two rounds ago | 74 | 149 | 35 | 60 | 134 | 115 | 0 | 567 | 341 | 6 |
| SvelteKit 2 | 128 | 396 | 57 | 83 | 192 | 72 | 0 | 928 | 596 | 9 |
| Next.js 15 | 107 | 363 | 44 | 108 | 241 | 71 | 0 | 934 | 674 | 8 |
| Axum 0.8 + askama | 145 | 455 | 29 | 104 | 217 | 123 | 257 | 1330 | 924 | 7 |
| Actix Web 4 + tera | 164 | 519 | 46 | 104 | 237 | 123 | 264 | 1457 | 994 | 7 |

Wisp's `data` is longer than JavaScript's: a Rust type with its fields' types and `pub`s. Everything else is shorter, the form most of all. Of what is left, 60 tokens are file paths, 115 the Rust type and data, and the rest is markup every stack writes.

## What the last rounds cut

Each cut makes the code say less of what the framework knows, not say it more tersely.

| Was | Now | Saves |
|---|---|---|
| `---` `let items = db::items().await;` `---`, then `{#each items as item}` | `{#each db::items().await as item}`: an `.await` in a page's markup, outside any block, runs before the page renders | 14 on the list |
| `data.items.filter((i) => i.name.toLowerCase().includes(q.toLowerCase()))` | `items.filter((i) => matches(i.name, q))`: a page's Rust names are browser values by name, and `matches` is the case-blind test | 14 on the search |
| `#[validate(email)] email: String` | `email: Email`: a parameter's type checks it, and one that does not parse is a 422 by field | 7 |
| `fn default(..) -> Result { …; redirect("/") }`, `Ok(())` at the end | `fn default(..) { …; redirect("/") }`: an action without `->` returns `Result` | 2, and `Ok(())` |
| `{cx.problem("name")}` after each input | an action form's input shows its own problem after it, `<small class="problem">…</small>`; a file that writes `cx.problem` places them itself | 11 per input |
| a `<form method="post">` (to `default`) kept nothing | it keeps what was typed, as a `?/name` form does | `value={cx.input("x")}` per input |
| `<script>let q = ''</script>` for `bind:value="q"` | a bound name nothing declares is declared by the binding, as state | the script |

An action form's page is now baked whole when nothing else in it reads the request: what was typed and what was wrong are never there on a GET.

## A real app: auth, CRUD, upload, live, a component

`bench/tokens/real` is sign up and in, a posts table with validation, edit, delete, pages and live refresh, an avatar upload and a toggle component: 10 files, **995** tokens in Wisp (was 1160), 3.4x less than SvelteKit 3 and 3.2x less than Next.js 15. Its tests check every feature. This round's cuts:

| Was | Now | Saves |
|---|---|---|
| `#[action]` on each action | left out for a lone `fn default` and each fn the markup posts to (`?/name`) | 3 each |
| `<form method="post" fields>` | `<form fields>`: posts to `fn default` | 4 |
| two inputs and a textarea, each `aria-label="x" name="x"` | `<form fields><button>Save</button></form>`; `body`, `message`, `bio`… are textareas | 30 |
| an edit form with `value={post.title}` per input | `<form fields={post}>` starts each field from `post` | 35 |
| `POSTS.update(id, ..)` with a closure that assigns the post | `POSTS.set(id, post)` | 6 |
| `cx.login(&USERS, ..)`, `cx.signup(&USERS, ..)`, `cx.user(&USERS)` | the table is the lone account table of `src/db.rs` | 3 each |
| `<script>let open = false</script>` for `open = !open` | a handler that toggles or counts a name nothing declares declares it | 11 |

## Method

Counted: every file a developer (or an agent) writes by hand, beyond what the framework's generator gives, plus each file's path (writing a file means naming it, so two files cost more than one). Manifests (`Cargo.toml`, `package.json`, `Gemfile`) are left out everywhere. For Rails the generator commands are counted, since the agent must write them, and the lines it adds or changes in generated files. Rails' api is `rails g scaffold` in an `--api` app, which writes the controller; the same api written by hand is the last row.

There is no tokenizer offline, so the count estimates a BPE code tokenizer (cl100k-like):

- a newline with its indentation is 1 token; spaces join the word after them
- identifiers split at `_` and camelCase humps, each part 1 token up to 8 letters and 1 per 6 after that
- digits 1 per 3
- common operators (`::` `->` `=>` `==` `</` `/>` `{{` `<%=` ...) 1; any other punctuation character 1

Characters / 4, the usual rule of thumb, ranks the frameworks the same way.

Competitor versions: SvelteKit 2 with Svelte 5 runes and `use:enhance`; Next.js 15 app router with server actions and `useActionState`; Nuxt 3 with server routes and `useFetch`; Axum 0.8 with maud and serde; FastAPI with Jinja2 and pydantic; Rails 8 with Active Record. The Wisp versions are built by a script, so every counted line compiles. The competitors' sources, `count.py` and `verify.py` are kept out of the repository, so its size stays Wisp's own.

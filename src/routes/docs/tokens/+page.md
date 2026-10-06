---
title: Tokens
description: See what a Wisp app costs to write in AI tokens, counted by wisp-tokens for five features and a real app, and compared with other web stacks and their methods.
group: Project
order: 90
---

An AI reads and writes code by the token, so an app's cost is measured in tokens, and keeping it low is a Wisp principle ([Design and files](/docs/design/)). Run `cargo run -q -p wisp-tokens --release` for the numbers.

## Five Features, Counted by `wisp-tokens`

`bench/tokens/apps` holds the same five features as a complete app in each stack:

- a list page loading its data
- a contact form (name 1 to 50 characters, a valid email; a 422 that shows each problem and keeps what was typed, else a redirect). Every stack checks the same rules with Wisp's messages, word for word: a name of 1 to 50 characters, counted as characters ("must have at least 1 character", "must have at most 50 characters"), and the browser's own email rule, the HTML spec's valid email address ("must be an email address"); a missing field is a 400, and the name input carries `pattern="[\s\S]{0,50}"`, which counts characters as the server does. Wisp's rules are built in; the other stacks write them by hand. What is left differs only where a stack cannot do otherwise: Next.js server actions answer 200, not 422, and a missing field is a 500 there; Axum's form extractor answers a missing field with 422; Wisp also takes an email domain with non-ASCII letters or a label longer than 63 characters, as Firefox sends them, which the HTML spec's pattern refuses
- a JSON endpoint of the list
- a layout with a nav
- a live search filtered in the browser

`cargo run -p wisp-tokens` counts them (method below, in `bench/tokens/src/main.rs`, with characters / 4 beside it). A `@feature NAME` comment says whose its lines are; a file without one, as a generator writes it, is not counted, nor the `[package]` table `cargo new` writes.

The Node apps: Nuxt is file routes, server routes in `server/api` and `useFetch`, the form posting with `$fetch`; Express renders EJS views with a shared header and footer and a small script for the search; React is a Vite app with React Router, `useState` and `fetch`, over a small Express API. Their generated `package.json`, `nuxt.config.ts` and `index.html` are not counted; the proxy line added to `vite.config.js` is. The Wisp app builds with the workspace, and its tests check each feature.

<TokenGrid />

Wisp's `data` (108) is longer than SvelteKit's, Next.js's, Nuxt's and Express's (69 to 72): a Rust type with its fields' types. Most of the rest is shorter, the form most of all; the exceptions are `api`, where Nuxt (22) and Axum (29) are shorter than Wisp (31), and `setup`, where Wisp counts 44 and SvelteKit, Next.js and Nuxt count 0. Against Wisp's total, Nuxt is 2.2 times, SvelteKit 2.4, Next.js 2.4, Express 2.9, React 3.4, Axum 3.8 and Actix 3.9. Of what is left, 108 tokens are the Rust type and data, and the rest is markup every stack writes.

## A Real App: Auth, CRUD, Upload, Live, a Component

`bench/tokens/real` is sign up and in, a posts table with validation, edit, delete, pages and live refresh, an avatar upload and a toggle component: <Stat k="files.real.wisp" /> files, **<Stat k="real.wisp" />** tokens in Wisp, <Stat k="x.real.sveltekit" />x less than SvelteKit and <Stat k="x.real.next" />x less than Next.js. The Wisp app has tests for every feature (`bench/tokens/real/wisp/src/tests.rs`); the SvelteKit and Next.js apps have none, so their behavior is checked by reading, not by tests.

## Method

Counted: every file a developer (or an agent) writes by hand, beyond what the framework's generator gives, plus each file's path (writing a file means naming it, so two files cost more than one). Manifests and configs count as `setup` for every stack, by the lines a developer adds beyond what the stack's generator writes (Wisp <Stat k="setup.wisp" /> for its `Cargo.toml`, Axum's and Actix's `[dependencies]`, Express's and React's `package.json` and server setup); the generated parts are left out. `cargo run -p wisp-tokens` lists each stack's counted and skipped files.

What this favors: Wisp ships the form rules, the validation messages and the form markup (`<form fields />`), so most of the gap in `form` is work the other stacks write by hand or take from a library. That is the point of a batteries-included design, but read the totals as "what an app author writes", not as equal work by each framework. Only the Wisp apps have tests (`src/tests.rs`); the other stacks' apps are written to the same behavior and reviewed by hand, not checked by a test.

There is no tokenizer offline, so the count estimates a BPE code tokenizer (cl100k-like):

- a newline with its indentation is 1 token; spaces join the word after them
- identifiers split at `_` and camelCase humps, each part 1 token up to 8 letters and 1 per 6 after that
- digits 1 per 3
- common operators (`::` `->` `=>` `==` `</` `/>` `{{` `{%` ...) 1; any other punctuation character 1

Characters / 4, the usual rule of thumb, ranks the frameworks the same way.

Competitor versions: SvelteKit 2 with Svelte 5 runes and `use:enhance`; Next.js 15 app router with server actions and `useActionState`; Nuxt 4 with server routes and `useFetch`; Express 5 with EJS; React 19 with Vite and an Express API; Axum 0.8 with askama; Actix Web 4 with tera. The Wisp versions are built by a script, so every counted line compiles. Every competitor app's source is in `bench/tokens/apps`.

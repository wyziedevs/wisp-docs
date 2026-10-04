---
title: Recipes, the kit and styles
description: Recipes, the component kit, scoped styles and accessibility lints.
group: Design
order: 14
---

## Recipes: `wisp add <name>`

A recipe is the app's own, in `add/<name>/`: Wisp ships none and has no
runtime part in it. `wisp add` lists the recipes, `wisp add sqlite` applies
one; a name with no recipe is an npm package, as before.
`add/<name>/recipe` is lines of `dep` (a line for `[dependencies]`), `env` (a
line for `.env.example`), `file <path>` (copies `add/<name>/<path>` to
`<path>`), `note` (printed after); `#` comments. Nothing runs and nothing is
downloaded. It is idempotent: a crate or key already there is skipped, a file
already there stays unless `--force`, a path outside the app is refused, and
every file is checked before any is written. A recipe wires in an existing
crate; the app never gets homegrown database or auth code. Example, sqlx
and SQLite:

```text
# add/sqlite/recipe
dep sqlx = { version = "0.8", default-features = false, features = ["runtime-tokio", "sqlite"] }
env DATABASE_URL=sqlite://app.db?mode=rwc
file src/db.rs
file src/routes/api/time/+server.rs
note Call crate::db::open().await? in init (src/hooks.rs), then GET /api/time.
```

```rust
// add/sqlite/src/db.rs: `pub` items of src/db.rs are in every route
pub type Pool = sqlx::SqlitePool;
pub async fn open() -> Result {
    let url = wisp::env("DATABASE_URL").or_status(500)?;
    wisp::provide(Pool::connect(&url).await?);
    Ok(())
}
pub fn pool() -> &'static Pool { wisp::state::<Pool>() }

// add/sqlite/src/routes/api/time/+server.rs
async fn get() -> Result<Response> {
    let (now,): (String,) = sqlx::query_as("select datetime('now')").fetch_one(pool()).await?;
    Ok(Response::text(now))
}
```

More, each `add/<name>/recipe` (the files it names beside it):

```text
# add/postgres: db.rs as above with sqlx::PgPool and `now()::text`
dep sqlx = { version = "0.8", default-features = false, features = ["runtime-tokio", "tls-rustls", "postgres"] }
env DATABASE_URL=postgres://user:pass@localhost/app
file src/db.rs

# add/redis: src/cache.rs does wisp::provide(redis::Client::open(url)?)
dep redis = { version = "0.27", features = ["tokio-comp"] }
env REDIS_URL=redis://127.0.0.1/
file src/cache.rs

# add/redis-store: src/store.rs is `impl wisp::Store` over redis (HSET/HDEL on a
# hash per table, HGETALL to load), and init calls wisp::store(RedisStore::new(url))
dep redis = { version = "0.27", features = ["tokio-comp"] }
env REDIS_URL=redis://127.0.0.1/
file src/store.rs

# add/kv-store: src/store.rs is `impl wisp::Store` over a KV's REST API
# (a key per row, `table/id`), with `changes` from a list of recent keys
env KV_URL=https://example.invalid/kv
file src/store.rs

# add/tailwind: src/app.css is `@import "tailwindcss";`
file src/app.css
note Wisp builds app.css with Tailwind when it imports it.
```

Wisp does not ship or maintain integrations: recipes are yours, to write,
change and share as folders.

## A component kit: `wisp ui add`

```sh
wisp ui list                     # what there is
wisp ui add button dialog tabs   # into src/components, with stories
```

`wisp ui add` copies components into `src/components`: the source is in the
CLI, the copy is the app's, to change as it likes. A file already there is
the app's and stays; `--force` writes over it. Each comes with a
`Name.stories.wisp` for the workshop at `/_wisp/components`.

| Component | Use | Browser code |
|---|---|---|
| `Button` | `<Button variant="secondary" kind="submit">Save</Button>`; `href` makes it a link | none |
| `Badge` | `<Badge tone="success">Paid</Badge>` | none |
| `Card` | `<Card title="Tea">…</Card>` | none |
| `Input`, `Textarea` | `<Input label="Email" name="email" kind="email" hint="…" problem={p} />` | none |
| `Checkbox`, `Switch` | `<Switch label="Dark" name="dark" checked />` (a checkbox, `role="switch"`) | none |
| `Select` | `<Select label="Drink" name="drink"><option>Tea</option></Select>` (native) | none |
| `Accordion` | `<Accordion title="Q" group="faq">A</Accordion>` (`<details name>`) | none |
| `ClientOnly` | `<ClientOnly fallback="Loading…"><Chart /></ClientOnly>`: the server sends the fallback, the children wait in an inert `<template>` and are drawn on mount | `onMount` |
| `Dialog` | `<Dialog id="d" title="Sure?" trigger="Delete">…</Dialog>` (`<dialog>`, `commandfor`) | none |
| `Menu` | `<Menu id="m" label="Actions"><button role="menuitem">Edit</button></Menu>` (popover) | arrow keys |
| `Tabs` | `<Tabs id="t" labels={["A", "B"]}><div>…</div><div>…</div></Tabs>` | arrow keys |
| `Tooltip` | `<Tooltip id="tip" text="Saves it"><button>Save</button></Tooltip>` | `aria-describedby`, Escape |
| `Toast` | `<Toast message={flash.unwrap_or_default()} />` in the layout; scripts send `dispatchEvent(new CustomEvent('toast', { detail: 'Saved' }))` | the list |

- Props are typed, as any component's. Styles are scoped and read the
  demo's tokens with fallbacks (`var(--accent, #896ce0)`, `--panel`,
  `--line`, `--ink`, `--radius`…), so an app's `:root` restyles them all;
  `--danger`, `--success` and `--warning` are read the same way.
- Native elements first (`<dialog>`, `popover`, `<details>`, `<select>`,
  checkboxes): the browser's keyboard, focus and screen reader support,
  and no JavaScript for ten of the fifteen. The rest follow the WAI-ARIA
  patterns. A test builds all of them with no accessibility warnings.

## Scoped styles

```html
<h1>Hi</h1>
<style>
  h1, .lead { color: rebeccapurple }
  :global(body) { margin: 0 }
</style>
```

- A `<style>` without attributes in a page, layout or component is that
  file's: every element it writes gets `class="w-xxxxxx"` (six letters or
  digits from a hash of its path), and each selector gets `.w-xxxxxx` on its
  last compound that is not `:global(…)`, before any pseudo-class or
  pseudo-element: `.card p:hover` → `.card p.w-xxxxxx:hover`. Ancestors
  may come from anywhere (a layout, `<html class="dark">`); the element
  styled is this file's. A component's elements are its own, not the page's.
- `:global(x)` is `x`, unscoped. A `<style>` with any attribute
  (`<style global>`, `media="print"`) is copied as written. `@media`,
  `@supports`, `@container`, `@layer` and nesting (`&:hover`, `h2 {}` in a
  rule) are scoped inside; `@keyframes`, `@font-face` and their names stay
  global. `@import` is a build error: it goes in `src/app.css`.
- It goes at the top level (not in a block, `<template>` or `<head>`), and
  a file may have several. The class is not put on `<html>`, `<head>`,
  `<body>`, `<title>`, `<meta>`, `<link>`, `<base>`, `<script>`, `<style>`
  or `<template>`; a `class` the browser sets (`class={:x}`) keeps it.
- The CSS is appended to `/_app/app.css`, after the app's own: no other
  request. A release build embeds it; a dev build reads it from
  `.wisp/scoped.css`, which `wisp dev` rewrites on a template save and the
  browser swaps in like any CSS change, no compile.
- Cost: the class's bytes on each element, nothing at run time.

## Accessibility warnings

The parser lints each template as it reads it. `wisp check`, `wisp dev`
(on each build and template swap) and `wisp build` print them as
warnings (`! src/routes/+page.wisp:4: <img> has no alt: … (a11y-img-alt)`);
a plain `cargo build` prints them as `cargo::warning`s. They never stop a
build.

| Name | Warns about |
|---|---|
| `img-alt` | `<img>` without `alt` (`alt=""` is fine: decorative) |
| `click-events` | `on:click` on an element that is not interactive (nor a custom element, `<sl-button>`), without both a `role` and a key handler (`on:keydown`) |
| `input-label` | `<input>`, `<select>` or `<textarea>` with no `<label>` around it, no `id` (for a `<label for>`), no `aria-label`/`aria-labelledby`/`title` (hidden and button types are exempt) |
| `link-name` | `<a href>` with no text, `<img alt>`, `aria-label` or `title` |
| `label-control` | `<label>` with no `for` and no control inside |
| `anchor-href` | `<a>` without `href`, or `href="#"` |
| `autofocus` | `autofocus` |
| `heading-order` | a heading more than one level below the one before it in the file |
| `button-name` | `<button>` with no text, `aria-label`, `aria-labelledby` or `title` |
| `tabindex` | `tabindex` above 0 |
| `aria-attr` | an `aria-*` name that ARIA does not have |

`<!-- wisp-ignore a11y-img-alt -->` on the line before an element silences
that lint there (several names may follow). A value set by an expression
(`alt={x}`, `:alt="x"`, `{...attrs}`) counts as set. The examples have none.

The client API (`beforeNavigate`, `afterNavigate`, `onNavigate`,
`preloadData`, `preloadCode`, `invalidate(key)`, `updated`) and the link
attributes `data-wisp-noscroll`, `-keepfocus` and `-replacestate` are in
wisp.js and live.js only: `wisp:navigate` is cancelable, `wisp:leave` collects
what `onNavigate` waits for, `wisp:preload` reuses the hover prefetch, and
`updated` is set when a fetched page names another `wisp.js?v=`. `depends`
is in the browser's `+page.js` `load` (the server renders pages whole, so
there is nothing for it to skip); nothing is added to a request.

The rest of accessibility is CSS, the client script and the starters, with
nothing added to a request: a navigation moves focus to the `<h1>` and says
the title in an `aria-live` region; view transitions and `--change`
(every component's transition time) go to nothing under
`prefers-reduced-motion`; `tokens.css` turns its lines and quiet text up
under `prefers-contrast: more`; the starters carry a skip link
(`.skip`, `<main id="main">`), `:focus-visible` rings, 44px buttons where the
pointer is coarse, `forced-colors` borders, `viewport-fit=cover` with
`env(safe-area-inset-*)`, `100dvh`, and fluid `clamp()` tokens
(`--wisp-step-0..3`, `--wisp-space-s..xl`). `Dialog` and `Menu` are the
native `<dialog>` and popover (focus trap, Escape, focus returned); `Input`,
`Textarea` and `Select` set `aria-invalid` and `aria-describedby` from
`problem`/`hint`. `Card` answers its own box width with `@container`. Phone
behavior is in [client.md](/docs/client#phones-and-flaky-networks).

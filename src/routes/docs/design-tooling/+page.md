---
title: Tooling, Images and Translations
description: Speed up Wisp work with recipes from wisp add, the component kit from wisp ui add, built-in image handling and translations for apps in more than one language.
group: Design
order: 12
---

## Recipes: `wisp add <name>`

A recipe is the app's own, in `add/<name>/`; Wisp ships none and has no runtime part in it. `wisp add` lists recipes, `wisp add sqlite` applies one; a name with no recipe is an npm package. A recipe wires in an existing crate, so the app has no database or auth code of its own to maintain.

`add/<name>/recipe` lines (`#` comments): `dep` (a `[dependencies]` line), `env` (a `.env.example` line), `file <path>` (copies `add/<name>/<path>` to `<path>`), `note` (printed after). Nothing runs, nothing downloads. Idempotent: an existing crate or key is skipped, an existing file stays unless `--force`, a path outside the app is refused, every file is checked before any is written.

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
pub fn pool() -> &'static Pool {
    wisp::state::<Pool>()
}

// add/sqlite/src/routes/api/time/+server.rs
async fn get() -> Result<Response> {
    let (now,): (String,) = sqlx::query_as("select datetime('now')")
        .fetch_one(pool())
        .await?;
    Ok(Response::text(now))
}
```

Other recipes (`add/<name>/recipe`, files beside it):

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
# hash per table, HGETALL to load); init calls wisp::store(RedisStore::new(url))
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

Wisp does not ship or maintain integrations. Recipes are folders you write, change and share.

## Component Kit: `wisp ui add`

```sh
wisp ui list                     # what there is
wisp ui add button dialog tabs   # into src/components
```

Copies components into `src/components`; the copy is the app's to change. An existing file stays unless `--force`.

Component | Use | Browser code
---|---|---
`Button` | `<Button variant="secondary" kind="submit">Save</Button>`; `href` makes it a link | none
`Badge` | `<Badge tone="success">Paid</Badge>` | none
`Card` | `<Card title="Tea">…</Card>` | none
`Input`, `Textarea` | `<Input label="Email" name="email" kind="email" hint="…" problem={p} />` | none
`Checkbox`, `Switch` | `<Switch label="Dark" name="dark" checked />` (checkbox, `role="switch"`) | none
`Select` | `<Select label="Drink" name="drink"><option>Tea</option></Select>` (native) | none
`Accordion` | `<Accordion title="Q" group="faq">A</Accordion>` (`<details name>`) | none
`ClientOnly` | `<ClientOnly fallback="Loading…"><Chart /></ClientOnly>`: server sends the fallback, children wait in an inert `<template>` and are drawn on mount | `onMount`
`Dialog` | `<Dialog id="d" title="Sure?" trigger="Delete">…</Dialog>` (`<dialog>`, `commandfor`) | none
`Menu` | `<Menu id="m" label="Actions"><button role="menuitem">Edit</button></Menu>` (popover) | arrow keys
`Tabs` | `<Tabs id="t" labels={["A", "B"]}><div>…</div><div>…</div></Tabs>` | arrow keys
`Tooltip` | `<Tooltip id="tip" text="Saves it"><button>Save</button></Tooltip>` | `aria-describedby`, Escape
`Toast` | `<Toast message={flash.unwrap_or_default()} />` in the layout; scripts send `dispatchEvent(new CustomEvent('toast', { detail: 'Saved' }))` | the list

- Props are typed. Styles are scoped and read the demo's tokens with fallbacks (`var(--accent, #896ce0)`, `--panel`, `--line`, `--ink`, `--radius`, `--danger`, `--success`, `--warning`), so an app's `:root` restyles them all.
- Native elements first (`<dialog>`, `popover`, `<details>`, `<select>`, checkboxes): browser keyboard, focus and screen reader support, no JavaScript for ten of fifteen. The rest follow WAI-ARIA patterns. A test builds all of them with no accessibility warnings.

## Images

`<img src="$lib/photo.jpg" alt="…">` (a file of `src/lib`) or `src="/photo.jpg"` (from `static/`), a JPEG, PNG or WebP with a quoted `src`, is filled in by the compiler before parsing (`wisp-build/src/image.rs`):

- Always: `width` and `height` from the file header (a small reader for the three formats, EXIF orientation included; no image crate), unless the tag sets either. No layout shift.
- `wisp build`: each image is written as WebP at up to three widths (640, 1280, 1920, never wider than it) to `.wisp/img/<hash>-<w>.webp` by a pinned cwebp (libwebp 1.6.0, downloaded once to `~/.wisp/bin`, SHA-256 checked, as Tailwind is; `$WISP_CWEBP` overrides). Names are the content hash, so a second build encodes nothing. Release embeds them (a `src/lib` original too), served under `/_app/img/` as immutable, and adds `srcset`, `sizes="100vw"`, `loading="lazy"`, `decoding="async"`. Attributes the tag has stay.
- Durable: without cwebp (no network, no build for the platform, failed encode) the build warns and the tag gets no `srcset`; the original is served, sized. A JPEG whose EXIF turns it gets no WebP. A missing `$lib/` file is a build error.
- Dev serves the original (`/_app/img/lib/photo.jpg` from `src/lib`) with only `width` and `height`.
- `<img priority …>` (bare, as in next/image) is above the fold: the attribute goes, `fetchpriority="high"` comes, no lazy.
- `<img data-wisp-raw …>` stays as written (a `$lib/` src still gets its URL). A `src` with a hole, or another site's, is left alone.
- Opt-in `avif` feature (`wisp-cli`, `wisp-build`; off, so the default tree is unchanged): `wisp build` also writes AVIF widths in process with `ravif` and `image` (pure Rust, slow, hence opt-in), and the tag becomes `<picture><source type="image/avif" srcset sizes>…<img …></picture>`. Without the files nothing changes.
- Opt-in `img` feature (`wisp`; deps `image` with png, jpeg, webp decoders only, because resizing needs decoders): a `src/routes/_img/+server.rs` with `wisp::img::serve::<crate::App>(cx)` answers `/_img?src=/photo.jpg&w=640&q=75`. Only `static/` files (embedded in release), `w` from a fixed list (next/image's), `q` 1 to 100, no `..`, files over 10 MB or 40 megapixels refused, a decoder panic is a 400, results cached in memory (64 MB). A route like any other: no hot-path code, nothing compiled without the feature.
- Cost: none without local images; a header read per image per build.

## Translations

One JSON file per locale in `src/locales`, flat or nested keys:

```json
{ "cart": { "title": "Your cart",
            "items": "{count, plural, =0 {No items} one {# item} other {# items}}" },
  "hi": "Hello, {name}!" }
```

```html
<h1>{t("cart.title")}</h1>
<p>{t("cart.items", count)} {t("hi", name = user.name)}</p>
<button on:click="n++">{:t('cart.items', n)}</button>
```

- Messages are ICU's subset: `{name}`, and `{n, plural, …}` with `=N` and the locale's CLDR cases (`one`, `few`, ...; `other` required; `#` is the count). `'{'` is a brace, `''` an apostrophe. A plural counts a whole number.
- Values: one, for a message with one placeholder; else by name (`name = expr`, or a variable of that name alone). In a script: one, or an object `t('hi', { name })`.
- Build checks, at file and line: a key missing from any locale, a placeholder one locale has and another lacks, a case the language lacks, an unknown key, mismatched values.
- Compiled to an index: `t("cart.title")` is a `&'static str` from a table per locale (can be a `&str` prop); values are written as displayed. No key lookup at run time.
- Locale order: the route's `[[lang=locale]]` (built-in matcher of the app's locales), the `lang` cookie, `Accept-Language`, the default (first file, or `wisp::default_locale("fr")?` in `init`). `cx.locale()` says it, `<html lang>` is set, a `CACHE`d page is kept per locale.
- A page's scripts get only the messages they use, in its locale, with the page; plurals follow `Intl.PluralRules`. `src/lib` modules cannot call `t`: pass them text.
- Switchers: `{@html wisp::switcher(cx)}` is a `<nav class="wisp-locales">` of links to the page in each locale, named in its own language; or `{#each wisp::locales().iter() as l}<a href={wisp::localize(cx.path(), l)}>{l}</a>{/each}` (`/fr/about` to `/en/about`).

Routing and the rest are opt-in, `i18n = [...]` in `[package.metadata.wisp]` of Cargo.toml, each string `name value`, baked at build (no setting, no code):

```toml
i18n = ["default en", "prefix as-needed", "domain example.fr fr", "missing warn"]
```

Setting | Behavior
---|---
`prefix optional` | The default. `/about` and `/fr/about` both answer
`prefix always` | Every page has its locale; `/about` redirects (307, GET and HEAD, query kept) to the visitor's (cookie, then `Accept-Language`): `/fr/about`
`prefix as-needed` | Default locale has no prefix and is what an unprefixed page gets (no detection: a URL names one language); `/en/about` redirects (308) to `/about`
`domain example.fr fr` | One per locale: a request's locale is its `Host`'s, `localize` gives `//example.fr/about`, redirects are off. A `[[lang=locale]]` segment still wins
`default fr` | Locale for a request naming none, instead of the first file (`wisp::default_locale` in `init` still overrides)
`missing warn` | A locale lacking a key the default has uses the default's message and the build warns (`file:line: "key" is missing`); a key the default lacks, or a differing placeholder, is still an error. `missing error` is the default

- `wisp::localize` follows the prefix mode, so links and the switcher need no change. Redirects are emitted only in pages under `[[lang=locale]]`: other routes pay nothing.
- `{@html wisp::alternates(cx)}` in a head writes `<link rel="canonical">` and an `alternate` with `hreflang` per locale plus `x-default`; addresses start with `SITE_URL`, else the request's host (a domain's host for its locale).
- `/sitemap.xml` lists every page in every locale with `xhtml:link` alternates (the default's unprefixed under `as-needed`; `prefix optional` lists the prefixed pages). `wisp build --static` writes each locale's pages (`index.html`, `fr/index.html`), plus the unprefixed ones unless `prefix always`. `entries()` of a page under `[[lang=locale]]` lists the values of its other params.
- `<html lang>` and, for right-to-left languages (ar, he, fa, ur...), `dir` are set per request; `wisp::dir("ar")` says `rtl` for your own elements. Pages under `[[lang=locale]]` are not baked.
- Formatting (small tables, no dependency): `wisp::format_number(n, l)` (`1,234.5`, `1 234,5`, `1.234,5`), `format_money(n, "EUR", l)`, `format_date(d, l)` (`10/4/2026`, `04/10/2026`, `4.10.2026`), `format_date_long(d, l)` (`October 4, 2026`, `4 octobre 2026`). `d` is Unix seconds, `"2026-10-04"` or `(2026, 10, 4)`; `l` is `cx.locale()`. A language without a table is `en` (numbers) or ISO 8601 (dates).
- Example: `examples/i18n`.

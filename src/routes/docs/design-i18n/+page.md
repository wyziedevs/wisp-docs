---
title: Translations
description: Translations, locale detection, prefixes and formatting.
group: Design
order: 16
---

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

- Messages are ICU's subset: `{name}`, and `{n, plural, …}` with `=N`
  cases and the locale's CLDR ones (`one`, `few`, …; `other` required, `#`
  is the count). `'{'` is a brace, `''` an apostrophe. A plural counts by
  a whole number.
- Values: one, for a message with one placeholder; else by name
  (`name = expr`, or a variable of that name alone). In a script, one, or
  an object: `t('hi', { name })`.
- Checked at build, each at its file and line: a key missing from any
  locale, a placeholder one locale has and another lacks, a case the
  language has not, an unknown key, values that do not match.
- Compiled to an index: `t("cart.title")` is a `&'static str` from a table
  per locale (it can be a `&str` prop), with values it writes as it is
  displayed. No lookup by key at run time.
- The locale: the route's `[[lang=locale]]` (a built-in matcher of the
  app's locales), then the `lang` cookie, then `Accept-Language`, then the
  default (the first file, or `wisp::default_locale("fr")?` in `init`).
  `cx.locale()` says it, `<html lang>` is set to it, and a `CACHE`d page is
  kept per locale.
- A page's scripts get only the messages they use, in its locale, with
  the page; their plurals follow `Intl.PluralRules`. `src/lib` modules
  cannot call `t`: pass them the text.
- Switchers: `{@html wisp::switcher(cx)}` is a `<nav class="wisp-locales">`
  of links to the page in each locale, named in its own language; or
  `{#each wisp::locales().iter() as l}<a
  href={wisp::localize(cx.path(), l)}>{l}</a>{/each}` (`/fr/about` →
  `/en/about`).

Locale routing and the rest are opt-in, in `[package.metadata.wisp]` of the
app's Cargo.toml as `i18n = [...]`, each string `name value`, baked at build
(an app that says nothing has no code for them):

```toml
i18n = ["default en", "prefix as-needed", "domain example.fr fr", "missing warn"]
```

- `prefix optional` (what it is without one): `/about` and `/fr/about` both
  answer. `prefix always`: every page has its locale, and `/about` redirects
  (307, GET and HEAD, keeping the query) to the visitor's by cookie then
  `Accept-Language`, `/fr/about`. `prefix as-needed`: the default locale has
  no prefix and is what a page without one gets (no detection: a URL names
  one language), `/en/about` redirects (308) to `/about`. `wisp::localize`
  follows it, so links and the switcher need no change. The redirect is
  emitted only in pages under `[[lang=locale]]`: other routes pay nothing.
- `domain example.fr fr` (one per locale): the locale of a request is its
  `Host`'s, `localize` gives `//example.fr/about`, and the redirects are off.
  The `[[lang=locale]]` segment still wins when a URL has one.
- `default fr`: the locale for a request that names none, instead of the
  first file (`wisp::default_locale` in `init` still overrides).
- `missing warn`: a locale without a key the default has uses the default's
  message and the build warns (`file:line: "key" is missing`); a key the
  default lacks, or a placeholder that differs, is still an error. `missing
  error` is the default.
- `{@html wisp::alternates(cx)}` in a head writes `<link rel="canonical">`,
  an `alternate` with `hreflang` per locale and `x-default`; addresses start
  with `SITE_URL`, else the request's host (a domain's host for its locale).
- `/sitemap.xml` lists every page in every locale, each with its
  `xhtml:link` alternates (the default's without a prefix under
  `as-needed`; `prefix optional` lists the prefixed pages). `wisp build
  --static` writes each locale's pages (`index.html`, `fr/index.html`) with
  the unprefixed ones too unless `prefix always`. `entries()` of a page under
  `[[lang=locale]]` lists the values of its other parameters.
- `<html lang>` and, for a right-to-left language (ar, he, fa, ur…), `dir` are
  set per request; `wisp::dir("ar")` says `rtl` for your own elements. Pages
  under `[[lang=locale]]` are not baked: they say their language.
- Formatting, small tables and no dependency: `wisp::format_number(n, l)`
  (`1,234.5`, `1 234,5`, `1.234,5`), `format_money(n, "EUR", l)`,
  `format_date(d, l)` (`10/4/2026`, `04/10/2026`, `4.10.2026`) and
  `format_date_long(d, l)` (`October 4, 2026`, `4 octobre 2026`), `d` being Unix
  seconds, `"2026-10-04"` or `(2026, 10, 4)`; `l` is `cx.locale()`. A language
  without a table is written as `en` (numbers) or ISO 8601 (dates).
- The example is `examples/i18n`.

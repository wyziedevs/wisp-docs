# Wisp docs

The documentation and launch site for [Wisp](https://github.com/wyziedevs/wisp), a fast, fun web framework for Rust. It is a Wisp app: the launch page is `src/routes/+page.md`, and every docs page is `src/routes/docs/<slug>/+page.md`. Canonical address: https://wispweb.dev.

## Layout

```
src/routes/+page.md              the launch page (components in src/components)
src/routes/+layout.wisp          header, footer, meta and Open Graph tags
src/routes/docs/+layout.wisp     sidebar, filter, table of contents, previous and next
src/routes/docs/+page.md         Getting started (/docs)
src/routes/docs/<slug>/+page.md  one docs page each
src/css/*.css                    all the styling, joined in name order (light and dark follow the system)
static/                          favicon, og.png, fonts
```

A docs page starts with front matter:

```
---
title: Deploying
description: One line for the search results and the link card.
group: Deploy and run
order: 60
---
```

`order` sorts the sidebar and the previous and next links; `group` is the sidebar heading (pages next to each other with the same group share it). Fenced code is highlighted at build time; `app.css` colors the `hl-*` classes. `/sitemap.xml` and `/robots.txt` are made by Wisp.

## Edit and build

You need Rust and the `wisp` CLI. The app depends on the Wisp crates by path, so keep the two repositories side by side:

```
projects/
  wisp/        git clone https://github.com/wyziedevs/wisp
  wisp-docs/   this repository
```

```bash
cargo install --path ../wisp/crates/wisp-cli   # once, and after Wisp changes
wisp dev                                       # http://127.0.0.1:3000, reloads on save
wisp check                                     # templates, routes, accessibility lints
SITE_URL=https://wispweb.dev wisp build --static   # the site, as plain files, in dist/
```

Serve `dist/` from any static host. `SITE_URL` makes the sitemap and the feed absolute.

## Deploy

`.github/workflows/deploy.yml` builds with the sibling checkout and publishes `dist/` to Cloudflare Pages on every push to `main`. One-time setup, by hand:

1. In Cloudflare, create a Pages project named `wisp-docs` (direct upload, no build settings) or set the repository variable `CLOUDFLARE_PAGES_PROJECT` to its name.
2. Add the repository secrets `CLOUDFLARE_API_TOKEN` (Pages edit permission) and `CLOUDFLARE_ACCOUNT_ID`.
3. Add the custom domain `wispweb.dev` to the Pages project; its DNS is a CNAME to `<project>.pages.dev` (Cloudflare adds it when the zone is on Cloudflare).
4. Redirect the old name: for `wisp.wyzie.io`, either keep a proxied DNS record for it and add a Cloudflare Redirect Rule (hostname equals `wisp.wyzie.io`, dynamic redirect to `concat("https://wispweb.dev", http.request.uri.path)`, status 301, preserve the query string), or set a CNAME to the Pages project, add it as a second custom domain and use the same rule. The canonical `<link>` and the Open Graph tags already say `https://wispweb.dev`.

## License

[MIT](LICENSE)

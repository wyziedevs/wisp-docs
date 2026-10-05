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
build.rs                         joins src/css into .wisp/app.css, writes static/search-index.json and the
                                 docs and blog heading tables, then runs the Wisp build
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

The site is deployed by hand from a checkout, with the Cloudflare login wrangler already has. From this folder:

```bash
git pull
export SITE_URL=https://wispweb.dev
wisp build --static
npx wrangler@4 pages deploy dist --project-name wisp-docs --branch main
```

The Pages project is `wisp-docs`, with the custom domain `wispweb.dev` (a CNAME to `wisp-docs.pages.dev`). The old name `wisp.wyzie.io` is redirected by a Cloudflare Redirect Rule (hostname equals `wisp.wyzie.io`, dynamic redirect to `concat("https://wispweb.dev", http.request.uri.path)`, status 301, preserve the query string). The canonical `<link>` and the Open Graph tags already say `https://wispweb.dev`.

## License

[MIT](LICENSE). Made by [Wyzie LLC](https://wyzie.io) for the community.

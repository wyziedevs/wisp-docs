---
title: Host on GitHub Pages
description: Publish a Wisp app as a static site on GitHub Pages with wisp build --static and the workflow that wisp deploy init pages writes.
group: Hosting
order: 83
---

GitHub Pages serves plain files. Wisp writes every parameterless page as HTML, so the site needs no server.

## Build

```sh
wisp build --static          # dist/ (--out <folder>)
```

`--spa` is `--static` plus an `index.html` fallback. The same build works for GitLab Pages and S3.

## Deploy

```sh
wisp deploy init pages
```

This writes `.github/workflows/deploy.yml`: build with `--static`, then `actions/upload-pages-artifact` and `actions/deploy-pages` on push to `main`. It reads no secrets; in the repository set Settings, Pages, Source to GitHub Actions. `--force` replaces the file.

## Environment

- `SITE_URL` (for example `https://me.github.io/my-app`): the address that sitemaps, feeds and absolute links use. Set it when you build.
- `WISP_BASE`: a base path, set at build (`/my-app`). A project site under a path prefix needs prefix-safe links.
- There is no server, so `WISP_SECRET` and the runtime variables do not apply. See [Environment variables](/docs/env/).

## Limits

- Forms need a server: the export warns for each page with actions, and for each exported page whose HTML holds a form that posts.
- A route with actions or a `+server.rs` needs a server (the export warns).
- A `[params]` route lists its pages with `entries`.

## Static Assets

- `static/` and the `/_app` files are written into `dist/`.
- Saved tables do not exist here: there is no process to keep them.

## More

[Deploying](/docs/deploy/), [Hosting](/docs/hosting/).

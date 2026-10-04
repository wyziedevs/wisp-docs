---
title: PWA and the Dev Loop
description: Make a Wisp app installable and usable offline as a PWA, and learn the dev loop with hot reload and the devtools that help while you build the app.
group: Browser Code
order: 35
---

## Installable and Offline (PWA)
`src/manifest.json` is served at `/manifest.webmanifest` and linked by every page; nothing is emitted without it.

```json
{ "name": "Notes", "theme_color": "#7c3aed", "offline": true }
```

- Filled in: `short_name`/`name`, `start_url` `/`, `display` `standalone`, `icons` from `static/icon*.png` (size read) and `static/icon*.svg`.
- One `static/icon.png` (512 px or more) suffices: `wisp build` also writes 192 and 512 px WebP into `/_app/img/` with cwebp (absent: a warning, the PNG alone).
- At startup instead: `wisp::app_manifest(r#"{"name": "Notes"}"#)?;` in `init`.

`"offline": true` adds Wisp's service worker: at install it keeps `/`, the browser files and `static/`; pages come from the network and are kept; offline: the kept page or a 503; a new build drops the old cache.

Your own `src/service-worker.js` (or `.ts`) replaces it: a classic script at `/service-worker.js`, registered by every page, importing only `'wisp/sw'` (`env.PUBLIC_X` works). The CSP gets `worker-src 'self'` and the registering script's hash.

```js
import { build, files, version } from 'wisp/sw'  // browser files, static/ files, hash of both (empty in dev)
self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(`app-${version}`).then((c) => c.addAll([...build, ...files])))
})
```

## Dev: Hot Reload
`wisp dev` applies a `.wisp` save with no compile when only browser code or static text changed:

- A script or `{:…}` change swaps the file's module (instances rerun it, keeping `$state` by name, focus, selection and field values).
- Text alone morphs that file's part between the `<!--w:src/components/Card.wisp-->` marks.
- `<style>` swaps the stylesheet.
- Else it compiles and morphs.

Instances restart (one console line says why) when:
- the `---` block or `{@props}` changed;
- the script has a top-level statement other than declarations, logging, writes to its own names and instance-ending helpers (`$effect`, `onMount`, `setInterval`…; `init()`, `if`, `new X()`, `window.x = 1` could run twice);
- the swap throws.

Components match by creation order, so a reordering list may trade states. Build errors show in a dialog whose `src/…:line` lines open in the editor; an error the page's code throws (also what `onError` hears) shows there too. The next successful build closes it. None of this is in release builds.

## Devtools
`Alt+Shift+W` opens dev-only devtools:

- Component tree with live props and state (editable), stores.
- The route (params, server values, the page's forms), a table of all the app's routes.
- Timings (dev responses carry `Server-Timing: total;dur=…`).
- A server panic or other 5xx opens the same error dialog with its message and `file:line`; "Open" uses `$WISP_EDITOR` or `$EDITOR`, else `code -g`.



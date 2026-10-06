---
title: The Router and Forms
description: Learn how the Wisp client router morphs pages, keeps snapshots and works offline, and how use:enhance and +page.js make forms feel instant in the browser.
group: Browser Code
order: 33
---

## Morphs and the Router
Same-origin clicks and back/forward fetch and morph, no full reload. A form action or navigation morphs the page; layouts stay mounted.

```js
goto('/login')                       // or goto(url, { replace: true })
invalidate()                         // run this page's load again
page.value.url.pathname              // page: { url, status, form, state }
navigating.value                     // { from, to } while loading, else null
pushState('?tab=2', { tab: 2 })      // history entry, no navigation
replaceState('', { tab: 3 })         // this entry's state ('' keeps the URL)
```

- A component instance on an element the morph keeps keeps its state and gets the new `data`. `data-wisp-reset` on an element around it starts it fresh.
- Global stores (`store`, `persisted`) are module state: they outlive every navigation.
- Prefetch on hover (60 ms) and touch; `data-wisp-preload="viewport"` (on a link or around links) fetches once in view; `data-wisp-preload="off"` opts out.
- Scroll is restored, the page's and each scrolled element's with an `id` (a sidebar, a list); focus moves to `[autofocus]`. A navigation lands at once, as a page load does, even under `scroll-behavior: smooth`, which still smooths same-page `#` links.
- View transitions when available. `data-wisp-notransition` on a link, or on `<body>` for the app, skips them; reduced motion skips them too.
- `data-wisp-reload` on a link or parent forces a full load. Links with `target`, `download`, `rel="external"` and `/_app/` are left alone.
- `pushState(url, state)` (shallow routing, for tabs and modals) adds an entry at `url` (`''`: this one) and loads nothing; `page.value.state` is reactive (`{}` on other entries). Back/forward restores it with no request; a reload keeps it only at its URL.
- `document` events: `wisp:navigate wisp:update wisp:goto wisp:refresh wisp:stay wisp:error wisp:push wisp:pop` (`wisp:stay`: a navigation ended with the page staying, for a download or a `data-wisp-cut` slot, and `navigating.value` is `null` again); forms: `wisp:submit` (cancelable), `wisp:result`, sent to the form and bubbling, so a listener on `document` sees every form's.

### Link and Navigation Options
`data-wisp-noscroll`, `data-wisp-keepfocus`, `data-wisp-replacestate`, `data-wisp-notransition` (on or around a link) keep scroll, keep focus, replace history, skip the view transition. `goto(url, { noscroll, keepfocus, replace, novt })` does the same.

Hooks from `'wisp'` return an unsubscribe:

<div class="table-wrap">

| Hook | Does |
|---|---|
| `beforeNavigate(({ from, to, pop, cancel }) => ..)` | Before leaving; `cancel()` does not stop back/forward. |
| `afterNavigate` | After the swap. |
| `onNavigate` | After fetch, before the swap; a returned promise is awaited, a returned function runs after. |
| `preloadData(url)`, `preloadCode(url)` | Fetch ahead. |
| `invalidateAll()` | Rerun every load. |
| `updated.value` | A newer wisp.js or build exists. |

</div>

`+page.js` `load` gets `depends(key)` (a `fetch`ed URL counts); `invalidate('key')` reruns only those loads, no page request.

### Snapshots
Back, forward and reload restore each changed `<input>`, `<textarea>`, `<select>` (never passwords, files, hidden, `autocomplete="off"`) from `sessionStorage`. A script keeps its own state; `snapshot` is the only export a script may have:

```html
<script>
  let open = false
  export const snapshot = { capture: () => open, restore: (v) => (open = v) }  // capture: any JSON
</script>
```

### Phones and Offline
- Pages leave with `pagehide` (back/forward cache; scroll restored).
- `<body data-wisp-revalidate="30">` refetches data when the tab or network returns (at most every N s, default 30; the morph keeps focus, scroll, typed text).
- Offline, `<form data-wisp-queue>` (safe to send twice) waits in `sessionStorage`, is sent in order when back, then the page refreshes (`wisp:sent`). Only urlencoded forms queue.
- `wisp:result` also fires when a download link is clicked, and for a post a later one superseded (the older request's result, whose page is not shown).
- Other forms show "You are offline" and fire `wisp:result` with `error: "offline"`.
- A navigation focuses the `<h1>` (else `<main>`) and announces the title; view transitions skip under `prefers-reduced-motion`.

## Forms: `use:enhance`
Plain forms already update in place; `use:enhance` adds hooks:

```html
<form method="post" action="?/add" use:enhance="submit">
  <input name="text" bind:value="text">
  <button disabled={:pending}>Send</button>
</form>
<script>
  let text = '', pending = false
  function submit({ formData, cancel }) {
    pending = true
    return (result) => { pending = false }   // after the page updated
  }
</script>
```

- The first function gets `{ form, formData, submitter, action, cancel }`; the returned one `{ ok, status, location?, data?, error? }`.
- An action answering JSON (`Response::json_of(…)`) leaves the form on the page; `data` and `page.value.form` hold it.

## `+page.js`
Runs in the browser on every navigation, not on the server. Its return is the script's `data`.

```js
export async function load({ data, url, params, route, fetch }) {
  return { ...data, results: await (await fetch('/api/search?q=' + url.searchParams.get('q'))).json() }
}
```

With a server `load` the whole `Data` is sent (`#[derive(Json)]`). `params.slug` for `blog/[slug]`; `route.id` is `/blog/[slug]`.

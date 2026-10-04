---
title: Client Components and State
description: Build client components in Wisp, register custom elements, and share state with the built-in state helpers and shared stores across a page or an app.
group: Browser Code
order: 36
---

## Client Components
A component inside a client block, or given `{:…}`, `bind:` or `on:`, is drawn by the browser.

```html
{:#each names as name (name)}
  <Item label={:name} bind:count="counts[name]" on:bump="bumped = event">
    <b>{:name}!</b>
  </Item>
{:/each}
```
```html
<!-- src/components/Item.wisp -->
{@props label: &str, count: i32 = 0}
<button on:click="count++; emit('bump', label)">{:label}: {:count}</button>
```

- Props are browser values (a `{…}` Rust prop is an error). `{:...props}` spreads an object (`<Item {:...item} label="x" />`, `label` wins).
- `bind:count` writes back to the parent. `emit('bump', x)` fires the parent's `on:bump`; the handler sees `x` as `event`.
- Only text, directives, `{:…}`, client blocks and `{@render children()}`; server code in it is a build error.
- It may render itself (tree view) inside an `{:#if}`/`{:#each}` (bare is a build error); depth stops at 64 in the browser, 32 on the server.
- `setContext(key, value)`/`getContext(key)` share with descendants; `const [getUser, setUser] = context()` makes a keyed pair.
- A prop's Rust type matters only where Rust renders the component; a browser-only one takes any `Json` type.
- With `$props()` (no `{@props}`) every prop is optional and Rust shows it as the browser would; declare it in `{@props}` to use it in Rust (`{#if}`, methods).

```html
<!-- src/components/Pill.wisp -->
<span class={:['pill', tone]} {:...rest}>{:text}</span>
<script>
  let { label: text, tone = 'plain', ...rest } = $props()
</script>
```
`<Pill label="new" tone="warm" title="Just in" />` (`title` goes to `rest`).

## Custom Elements
`{@element "x-card"}` first in a component also builds it as a custom element at `/_app/c/el/x-card.js` (AGENTS.md has the form). Any site:

```html
<script type="module" src="https://app.example/_app/c/el/x-card.js"></script>
<x-card title="Hi" count="3" featured>Kids</x-card>
```

- Each prop is an attribute (`snake_case` as `snake-case`) and property, read as its Rust type: number; `bool` (present is true, `"false"` false); text; else JSON (`tags='["a"]'`). Removing it resets the default.
- Open shadow root with scoped `<style>`s; `{@render children()}` is a `<slot>`.
- Markup is browser code and defaults are literals (build errors otherwise); the app still renders `<Card>` server first.
- The module sends `access-control-allow-origin: *` and loads `live.js`, not `wisp.js`.

## State Helpers
In any client script, no imports:

```js
watch(() => data.id, (id) => { load(id) })         // when data.id changes
effect(() => { load(id) }, () => [id])             // at start and when id changes (return cleanup)
onMount(() => { ready = true })                    // may return a cleanup
onDestroy(() => socket.close())
setInterval(() => n++, 1000)                       // also setTimeout, requestAnimationFrame,
                                                   // addEventListener: stopped for you
listen('/events', (data) => { last = data })       // server-sent events
await tick()                                       // after the redraw
flushSync()                                        // redraw now, not at the end of the task
onError((e) => report(e))                          // each uncaught error and rejection, and each error no {:#try} took
const w = tweened(0, { duration: 400 })            // w.value = 5 runs there; numbers, arrays, objects of numbers
const s = spring({ x: 0, y: 0 })                   // s.set({ x: 9, y: 4 }) with momentum; { hard: true } jumps
const [send, receive] = crossfade({ duration: 400 })   // out:send={{ key: id }} in:receive={{ key: id }}
```

### Shared State
A store outlives components and navigation; put it in `src/lib/`:

```js
// src/lib/cart.js
import { store, persisted, derived } from 'wisp'
export const cart = store([])
export const theme = persisted('theme', 'light')       // localStorage
export const count = derived(() => cart.value.length)
```

`import { cart } from '$lib/cart.js'` in a script, then `cart.value = [...]` or `$cart`. A store has `.value`, `set(v)`, `update(fn)`, `subscribe(fn)` and is deep. `src/lib/**/*.js` is served; `'wisp'` and `'$lib/…'` imports work in them, scripts and `+page.js`.

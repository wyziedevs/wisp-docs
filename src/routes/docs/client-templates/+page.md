---
title: Server values, blocks and components
description: Server values in the browser, client blocks, components and state helpers.
group: Browser code
order: 31
---

## Server values in the browser
Any Rust value client code mentions is sent, only the mentioned parts.

```html
<script>
  let guess = data.guess          // the script's `guess`, from the server's
  const total = items.length      // the page's `let items` (or `data.items`)
</script>
{#each keys as key}<button on:click="type(key.letter)">{key.letter}</button>{/each}   <!-- sends key.letter only -->
```

- Sent: a page's or layout's Rust names (block `let`s, route params, `Data`
  fields) by name or `data.x.y`; component props; loop, `if let` and
  `{@const}` values used in a directive. A name the script declares is the
  script's; a browser global (`document`, `location`, `event`, `fetch`)
  stays the browser's (the Rust one is `data.location`); a parameter or
  local of that name (`items.map(data => data.x)`) is just that.
- Sent as JSON via `wisp::Json`: numbers, strings, `bool`, `Option`, `Vec`,
  arrays, tuples, maps; own types `#[derive(Json)]`. An unsendable value is
  a compile error naming `wisp::Json`; a prop that is also a script
  variable is a build error.
- `matches(text, q)` (no import): case-insensitive contains; empty `q`
  matches all. Live search: `<input bind:value="q">` then
  `{:#each items.filter((i) => matches(i.name, q)) as item}<p>{:item.name}</p>{:/each}`.

## `{:expr}` holes

A live JS expression anywhere in markup: `<p>Hi {:name}</p>`,
`<p class="card {:mood}" data-id={:item.id}>`, `<a href={:url}>`. Mixing
`{…}` and `{:…}` in one attribute value is a build error.

## Client blocks

```html
{:#if open}<p>Open</p>{:else if name}<p>{:name}</p>{:else}<p>Closed</p>{:/if}

{:#each items as item, i (item.id)}
  <li animate:flip>{:i}: {:item.text}</li>
{:else}
  <li>Nothing</li>
{:/each}

{:#key user.id}<Profile id={:user.id} />{:/key}      <!-- redrawn when it changes -->

{:#await results}<p>Loading…</p>{:then list}{:list.length}{:catch error}{:error.message}{:/await}
{:#await p then v}…{:/await}                        <!-- no pending branch -->

{:#try}<Chart data={:points} />{:catch error}
  <p>{:error.message}</p><button on:click="reset()">Retry</button>
{:/try}
```

`(item.id)` is the key (else by position). `{:#each list}` alone draws once
per item; `{:#each 3 as i}` counts. Also `<template each="item, i in list">`
and `<template if="cond">`. The server paints key blocks, an await's pending
branch and a try body.

Special elements (each takes directives for its target, closes itself):

```html
<wisp:window on:keydown.escape="open = false" bind:innerWidth="w" />
<wisp:document on:visibilitychange="save()" bind:visibilityState="seen" />
<wisp:body on:click="menu = false" />
<wisp:element this={:level > 1 ? 'h3' : 'h2'} class="title">{:text}</wisp:element>
```

Snippets: `{:@render name(args)}` draws a file's `{#snippet}` in the browser
(args are JS; parameters are plain names read in `{:…}`); `{@render}` still
works on the server.

```html
{#snippet chip(tag)}<b class="chip">{:tag}</b>{/snippet}
{:#each tags as tag (tag)}{:@render chip(tag)}{:/each}
```

A component the browser draws takes snippets as props, by name
(`<List items={:xs} {row} />`, `row={other}`) or among its children, and draws
one with `{:@render row(x)}` where `row` is one of its props
(`{@props row: Snippet<&Item>}` or `$props()`). The body sees the page's
names and its parameters, and is drawn after `{:@render}`; none given draws
nothing. It loads `extra.js`, and the server paints no copy of the component.

```html
<!-- src/components/List.wisp -->
{@props items: Vec<String>, row: Snippet<&String, usize>}
<ul>{:#each items as item, i}<li>{:@render row(item, i)}</li>{:/each}</ul>
```
```html
<List items={:fruits}>{#snippet row(name, i)}<b>{:i}</b> {:name}{/snippet}</List>
```

`{:@const name = expr}` names a value for the rest of its block (it ends at
`{:/…}` or `{:else}`); `{:@html expr}` puts markup in unescaped, as `{@html}`
does on the server (trusted markup only), redrawn when the value changes.
The server paints neither; `{:@html}` loads `extra.js`.

```html
{:#each items as item}{:@const total = item.price * item.qty}<li>{:total}</li>{:/each}
<div>{:@html post.body}</div>
```

### First paint

The server renders what it can know into the page (it works before JS and
without it); the browser takes those nodes over and keeps them live. Known:
server values, props, Rust loop values; literals (`0 'text' true null [1,2]
{id:1}`); script variables first set to those (`let todos = data.todos`); an
`{:#each}` item/index inside it; `!`, `&&`, `||`, `.length` of those; a
boolean directive like `:hidden="!open"` with `let open = false`. A call,
sum, comparison or a `+page.js` page's `data` is left to the browser.
Live attributes (`:class`, `class="a {:b}"`) keep static text until it starts.

## Client components
A component inside a client block, or given `{:…}`, `bind:` or `on:`, is
drawn by the browser.

```html
{:#each names as name (name)}
  <Item label={:name} bind:count="counts[name]" on:bump="bumped = event"><b>{:name}!</b></Item>
{:/each}
```
```html
<!-- src/components/Item.wisp -->
{@props label: &str, count: i32 = 0}
<button on:click="count++; emit('bump', label)">{:label}: {:count}</button>
```

- Props are browser values (a `{…}` Rust prop is an error);
  `{:...props}` spreads an object (`<Item {:...item} label="x" />`, `label`
  wins). `bind:count` writes back to the parent. `emit('bump', x)` fires the
  parent's `on:bump`; the handler sees `x` as `event`.
- Only text, directives, `{:…}`, client blocks and `{@render children()}`;
  server code in it is a build error. It may render itself (tree view)
  inside an `{:#if}`/`{:#each}` (bare is a build error); depth stops at 64
  in the browser, 32 on the server.
- `setContext(key, value)`/`getContext(key)` share with descendants;
  `const [getUser, setUser] = context()` makes a keyed pair.
- A prop's Rust type matters only where Rust renders the component; a
  browser-only one takes any `Json` type. With `$props()` (no `{@props}`)
  every prop is optional and Rust shows it as the browser would; declare it
  in `{@props}` to use it in Rust (`{#if}`, methods).

```html
<!-- src/components/Pill.wisp -->
<span class={:['pill', tone]} {:...rest}>{:text}</span>
<script>
  let { label: text, tone = 'plain', ...rest } = $props()
</script>
```
`<Pill label="new" tone="warm" title="Just in" />` (`title` goes to `rest`).

## Custom elements

`{@element "x-card"}` first in a component also builds it as a custom
element at `/_app/c/el/x-card.js` (AGENTS.md has the form). Any site:
`<script type="module" src="https://app.example/_app/c/el/x-card.js"></script>`
then `<x-card title="Hi" count="3" featured>Kids</x-card>`. Each prop is an
attribute (`snake_case` as `snake-case`) and property, read as its Rust type
(number; `bool`: present is true, `"false"` false; text; else JSON
`tags='["a"]'`); removing it resets the default. Open shadow root with
scoped `<style>`s; `{@render children()}` is a `<slot>`. Markup is browser
code and defaults are literals (build errors otherwise); the app still
renders `<Card>` server first. Its module sends `access-control-allow-origin:
*` and loads `live.js`, not `wisp.js`.

## State helpers

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

### Shared state

A store outlives components and navigation; put it in `src/lib/`:

```js
// src/lib/cart.js
import { store, persisted, derived } from 'wisp'
export const cart = store([])
export const theme = persisted('theme', 'light')       // localStorage
export const count = derived(() => cart.value.length)
```

`import { cart } from '$lib/cart.js'` in a script, then `cart.value = [...]`
or `$cart`. A store has `.value`, `set(v)`, `update(fn)`, `subscribe(fn)` and
is deep. `src/lib/**/*.js` is served; `'wisp'` and `'$lib/…'` imports work in
them, scripts and `+page.js`.

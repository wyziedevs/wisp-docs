---
title: Server Values and Client Blocks
description: Server values in the browser, {:expr} holes, client blocks, snippets and first paint.
group: Browser Code
order: 31
---

## Server Values in the Browser
Any Rust value client code mentions is sent, only the mentioned parts.

```html
<script>
  let guess = data.guess          // the script's `guess`, from the server's
  const total = items.length      // the page's `let items` (or `data.items`)
</script>
{#each keys as key}<button on:click="type(key.letter)">{key.letter}</button>{/each}   <!-- sends key.letter only -->
```

- Sent: a page's or layout's Rust names (block `let`s, route params, `Data` fields) by name or `data.x.y`; component props; loop, `if let` and `{@const}` values used in a directive.
- A name the script declares is the script's. A browser global (`document`, `location`, `event`, `fetch`) stays the browser's (the Rust one is `data.location`). A parameter or local of that name (`items.map(data => data.x)`) is just that.
- Sent as JSON via `wisp::Json`: numbers, strings, `bool`, `Option`, `Vec`, arrays, tuples, maps; own types `#[derive(Json)]`.
- An unsendable value is a compile error naming `wisp::Json`; a prop that is also a script variable is a build error.
- `matches(text, q)` (no import): case-insensitive contains; empty `q` matches all.

```html
<input bind:value="q">
{:#each items.filter((i) => matches(i.name, q)) as item}<p>{:item.name}</p>{:/each}
```

## `{:expr}` Holes
A live JS expression anywhere in markup: `<p>Hi {:name}</p>`, `<p class="card {:mood}" data-id={:item.id}>`, `<a href={:url}>`. Mixing `{…}` and `{:…}` in one attribute value is a build error.

## Client Blocks

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

- `(item.id)` is the key (else by position). `{:#each list}` alone draws once per item; `{:#each 3 as i}` counts.
- Also `<template each="item, i in list">` and `<template if="cond">`.
- The server paints key blocks, an await's pending branch and a try body.

### Special Elements
Each takes directives for its target and closes itself:

```html
<wisp:window on:keydown.escape="open = false" bind:innerWidth="w" />
<wisp:document on:visibilitychange="save()" bind:visibilityState="seen" />
<wisp:body on:click="menu = false" />
<wisp:element this={:level > 1 ? 'h3' : 'h2'} class="title">{:text}</wisp:element>
```

### Snippets
`{:@render name(args)}` draws a file's `{#snippet}` in the browser (args are JS; parameters are plain names read in `{:…}`); `{@render}` still works on the server.

```html
{#snippet chip(tag)}<b class="chip">{:tag}</b>{/snippet}
{:#each tags as tag (tag)}{:@render chip(tag)}{:/each}
```

A component the browser draws takes snippets as props, by name (`<List items={:xs} {row} />`, `row={other}`) or among its children, and draws one with `{:@render row(x)}` where `row` is one of its props (`{@props row: Snippet<&Item>}` or `$props()`).

- The body sees the page's names and its parameters, and is drawn after `{:@render}`; none given draws nothing.
- It loads `extra.js`, and the server paints no copy of the component.

```html
<!-- src/components/List.wisp -->
{@props items: Vec<String>, row: Snippet<&String, usize>}
<ul>{:#each items as item, i}<li>{:@render row(item, i)}</li>{:/each}</ul>
```
```html
<List items={:fruits}>{#snippet row(name, i)}<b>{:i}</b> {:name}{/snippet}</List>
```

### `{:@const}` and `{:@html}`
`{:@const name = expr}` names a value for the rest of its block (it ends at `{:/…}` or `{:else}`). `{:@html expr}` puts markup in unescaped, as `{@html}` does on the server (trusted markup only), redrawn when the value changes. The server paints neither; `{:@html}` loads `extra.js`.

```html
{:#each items as item}{:@const total = item.price * item.qty}<li>{:total}</li>{:/each}
<div>{:@html post.body}</div>
```

## First Paint
The server renders what it can know into the page (it works before JS and without it); the browser takes those nodes over and keeps them live.

- Known: server values, props, Rust loop values; literals (`0 'text' true null [1,2] {id:1}`); script variables first set to those (`let todos = data.todos`); an `{:#each}` item/index inside it; `!`, `&&`, `||`, `.length` of those; a boolean directive like `:hidden="!open"` with `let open = false`.
- Left to the browser: a call, sum, comparison, or a `+page.js` page's `data`.
- Live attributes (`:class`, `class="a {:b}"`) keep static text until it starts.

Next: [components, custom elements and state helpers](/docs/client-components).

---
title: Template Syntax and Styles
description: Template syntax, escaping, components, snippets and scoped styles in .wisp files.
group: Design
order: 13
---

## Templates

```html
<head><title>{data.post.title}</title></head>

<h1 class="text-3xl font-bold">{data.post.title}</h1>

{#if data.posts.is_empty()}
  <p>No posts.</p>
{:else if data.posts.len() == 1}
  <p>One post.</p>
{:else}
  {#each data.posts as post, i}
    <a href="/blog/{post.slug}" class={post.class()}>{i}: {post.title}</a>
  {:else}
    <p>Renders when the list is empty.</p>
  {/each}
{/if}

{#match data.status}
  {:case Status::Draft} <span>draft</span>
  {:case Status::Live(date)} <time>{date}</time>
{/match}

{@const total = data.posts.len()}
{@html data.trusted_svg}
```

Syntax | Compiles to
---|---
`{expr}` | Escaped `Display`; an `Option` writes its value, nothing for `None`
`attr={expr}` | `attr="…"`, quotes added, value escaped
`disabled={cond}` | ` disabled` if `cond`, else nothing (all HTML boolean attributes)
`{@html expr}` | Unescaped `Display` (you promise it is safe)
`{@const x = expr}` | `let x = expr;`
`{#if c}…{:else if c}…{:else}…{/if}` | `if`/`else`; `if let` works
`{#each e as pat[, i]}…{:else}…{/each}` | `for`; a plain place like `data.posts` is borrowed
`{#match e}{:case pat}…{/match}` | `match`; a plain place is borrowed
`{#await f}…{:then v}…{:catch e}…{/await}` | Page streams `v` or `e` later ([Streaming a page](/docs/design-state))
`{@render children()}` or `<slot />` | Layout or component slot
`{#snippet row(item, i)}…{/snippet}` | Markup to render later, here or in a component
`{@render row(x, 0)}` | Renders a snippet
`<head>…</head>` or `<wisp:head>…</wisp:head>` | Appended to the document head
`<title>…</title>` at top level | Same as in `<head>` (not an `<svg>`'s)
`{cx.path()}` | `cx`, the request (`&Cx`), in pages, layouts, error pages

- Expressions are Rust passed to `rustc` verbatim, so type errors are real. Inside `<script>`, `<style>` and HTML comments there are no holes, so CSS and JS braces need no escaping. Comments are stripped.
- A bare `<script>` (no attributes) is the file's client script: compiled with the file's directives into an ES module, top-level names are its state, no collisions across files ([client](/docs/client)). A `<script>` with `type` or `src` is copied through.
- Whitespace runs containing a newline collapse to one newline, except in `<pre>`/`<textarea>`. A block tag (`{#…}`, `{:…}`, `{/…}`, `{@const}`) alone on a line leaves no line behind.
- Boolean attributes (`disabled`, `checked`, `selected`, `hidden`, `open`, `required`...) are on when present whatever the value, so `disabled="false"` disables. `name={cond}` takes a `bool` and prints the bare name or nothing; a hole in a quoted value is an error.
- Braces are Rust on the server; a quoted directive value or `{:expr}` is JavaScript in the browser. No Rust expression goes inside `<script>`: use the Rust name or `data.x` (sent as JSON) there, or `data-*` attributes.
- A block (and each branch) must begin and end in the same place (text, one tag, one attribute value), or `{x}` after it could be escaped for the wrong place.

### Escaping and Refused Places

Escaping covers `& < > " '`, safe in text and quoted attributes; unquoted `attr={…}` is always quoted. The parser tracks where each hole lands and refuses:

- `on*` attributes and `srcdoc`;
- a tag name (`<{x}>`); a bare `<` in text is written `&lt;`;
- a URL attribute (`href`, `src`, `action`, `formaction`...) whose static start is `javascript:` or `vbscript:`, or hides its scheme behind a character reference (also for `{:…}` values);
- `to`, `from`, `values`, `by` of an SVG `<animate>` or `<set>`, a `<meta>`'s `http-equiv`, and the `content` of `<meta http-equiv="refresh">`;
- `//` comments inside a hole, which would comment out the generated code after.

When an expression decides a URL attribute's scheme (`href={link}`, `src="{base}/x.png"`), the value is checked at the end (`wisp::rt::guard_url`); one that would run script becomes `about:invalid#blocked`. A static start fixing the scheme (`/p/{id}`, `https://…`, `?q=…`) costs nothing. These rules live in `crates/wisp-shared/src/contexts.rs`, used by both `wisp` and `wisp-build`; its tests hold the browser runtime to the same cases.

## Components

A `.wisp` file in `src/components` (any depth) is a component named by its file: `Card.wisp` is `<Card>`. It declares its props at the top:

```html
<!-- src/components/Card.wisp -->
{@props title: &str, count: u32 = 0, featured: bool = false}
<section class="card">
  <h2>{title}{#if featured} ★{/if}</h2>
  <p>{count} items</p>
  {@render children()}
</section>
```

```html
<Card title={post.title} count={post.tags.len()} featured>
  <Badge label="new" />
</Card>
<Card title="Drafts" />
```

- Props are Rust types, each a parameter of the render function, so rustc checks every use. A reference type gets a borrow (`title={post.title}` gives a `String` to a `&str`). `name="text"` is a string; bare `name` is `true`. A prop with a default may be left out. `impl Display` works.
- `{@render children()}` shows what the tag wraps. Children compile in the using page, so they see its `data`, loop variables and `{@const}`s.
- Build checks: the component exists (the ones that do are listed if not), every given prop is declared, every prop without a default is given, a flag only goes to a `bool`, children only to a component that shows them.
- The name starts with a capital and has a lowercase letter (`<DIV>` is HTML). Components cannot go in `<wisp:head>`; only components take `{@props}`. Component files hot-swap like templates.
- The browser can draw components too (client blocks, `{:…}` props, `bind:`, `on:`): [client](/docs/client).

## Snippets

Markup a file renders more than once, or gives to a component:

```html
{#snippet row(post, i)}
  <td>{i}</td><td>{post.title}</td>
{/snippet}

<table>{#each data.posts as post, i}<tr>{@render row(post, i)}</tr>{/each}</table>

<Table rows={data.posts} {row} />
<Table rows={data.posts}>
  {#snippet row(post, i)}<td>{post.title}</td>{/snippet}
</Table>
```

```html
<!-- src/components/Table.wisp -->
{@props rows: &[Post], row: Snippet<&Post, usize>}
<table>{#each rows as r, i}<tr>{@render row(r, i)}</tr>{/each}</table>
```

- Parameters are Rust `let` patterns, typed or not. The body sees the names around its definition, like a closure. A snippet is in scope after its `{/snippet}` to the end of its block; it cannot render itself (a component can).
- A component takes one as a prop of type `Snippet<A, B>` (`Snippet` for none), which is `&dyn Fn(&mut Out, A, B)`: `{row}` or `row={row}` in its tag, or a `{#snippet row(…)}` among its children; it renders with `{@render row(…)}`.
- `{:@render row(x)}` has the browser draw it: arguments are JavaScript, the body uses its parameters in `{:…}` ([client](/docs/client)). A component the browser draws takes snippets the same way (`<List items={:xs} {row} />`, or `{#snippet row(x)}` among children) and draws one with `{:@render row(x)}` where `row` is a prop. The body is a block before the tag (`Dir::Snip`, which `snip` in extra.js binds), found among the anchors right before the component's own, so no first paint for a component given one.

## Scoped Styles

```html
<h1>Hi</h1>
<style>
  h1, .lead { color: rebeccapurple }
  :global(body) { margin: 0 }
</style>
```

- A `<style>` without attributes in a page, layout or component is that file's: each element it writes gets `class="w-xxxxxx"` (six characters from a hash of its path), and each selector gets `.w-xxxxxx` on its last compound that is not `:global(…)`, before any pseudo-class or pseudo-element: `.card p:hover` becomes `.card p.w-xxxxxx:hover`. Ancestors may come from anywhere (a layout, `<html class="dark">`). A component's elements are its own.
- `:global(x)` is `x`, unscoped. A `<style>` with any attribute (`<style global>`, `media="print"`) is copied as written. `@media`, `@supports`, `@container`, `@layer` and nesting (`&:hover`, `h2 {}` in a rule) are scoped inside; `@keyframes`, `@font-face` and their names stay global. `@import` is a build error: put it in `src/app.css`.
- Top level only (not in a block, `<template>` or `<head>`); a file may have several. No class on `<html>`, `<head>`, `<body>`, `<title>`, `<meta>`, `<link>`, `<base>`, `<script>`, `<style>`, `<template>`; a browser-set `class={:x}` keeps it.
- The CSS is appended to `/_app/app.css` after the app's own: no extra request. Release embeds it; dev reads `.wisp/scoped.css`, which `wisp dev` rewrites on a template save and the browser swaps in, no compile.
- Cost: the class's bytes per element, nothing at run time.

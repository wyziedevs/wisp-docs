---
title: Templates and components
description: Template syntax, blocks and components in .wisp files.
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
    <p>Unreachable, but {#each}…{:else} renders when the list is empty.</p>
  {/each}
{/if}

{#match data.status}
  {:case Status::Draft} <span>draft</span>
  {:case Status::Live(date)} <time>{date}</time>
{/match}

{@const total = data.posts.len()}
{@html data.trusted_svg}
```

| Syntax                         | Compiles to                                        |
|--------------------------------|----------------------------------------------------|
| `{expr}`                       | escaped `Display` of `expr`; an `Option` writes its value, or nothing for `None` |
| `attr={expr}`                  | `attr="…"`, quotes added, value escaped            |
| `disabled={cond}`              | ` disabled` if `cond`, else nothing (all HTML boolean attributes) |
| `{@html expr}`                 | unescaped `Display` (you promise it is safe)       |
| `{@const x = expr}`            | `let x = expr;`                                    |
| `{#if c}…{:else if c}…{:else}…{/if}` | `if`/`else`; `if let` works as in Rust        |
| `{#each e as pat[, i]}…{:else}…{/each}` | `for`; a plain place like `data.posts` is borrowed |
| `{#match e}{:case pat}…{/match}` | `match`; a plain place is borrowed               |
| `{#await f}…{:then v}…{:catch e}…{/await}` | a page streams `v` or `e` in later ([Streaming a page](/docs/design-state#streaming-a-page-await)) |
| `{@render children()}` or `<slot />` | layout or component slot                   |
| `{#snippet row(item, i)}…{/snippet}` | markup to render later, in this file or a component |
| `{@render row(x, 0)}`          | renders a snippet                                  |
| `<head>…</head>` or `<wisp:head>…</wisp:head>` | appended to the document head |
| `<title>…</title>` at the top level | the same as in `<head>` (not an `<svg>`'s) |
| `{cx.path()}`                  | `cx`, the request (`&Cx`), in pages, layouts, error pages |

Expressions are Rust, passed to `rustc` verbatim, so type errors are real type
errors. Inside `<script>`, `<style>` and HTML comments there are no holes, so
CSS and JS braces need no escaping. A bare `<script>` (no attributes) is the
file's client script: the build compiles it, with the file's directives, into
an ES module, so its top-level names are its state and cannot collide with
another file's (see [client.md](/docs/client)). A `<script>` with a `type` or
`src` is plain HTML and copied through. Comments are stripped. Whitespace runs that
contain a newline collapse to one newline, except in `<pre>`/`<textarea>`. A
block tag (`{#…}`, `{:…}`, `{/…}`, `{@const}`) alone on its line leaves no line
behind, so loops don't print blank lines between items.

Boolean attributes (`disabled`, `checked`, `selected`, `hidden`, `open`,
`required`, ...) are on when present, whatever their value, so
`disabled="false"` would disable. For them `name={cond}` takes a `bool` and
prints the bare name or nothing, and a hole in a quoted value is an error.

Escaping covers `& < > " '`, which is safe in text and in quoted attributes.
Unquoted `attr={…}` is always quoted by the compiler. There is no way to put an
Rust expression inside `<script>`; pass values by using them there by
their Rust name or as `data.x` (sent as JSON), or through `data-*`
attributes.
The one rule for client code: braces are Rust on the server, a quoted
directive value or `{:expr}` is JavaScript in the browser.
The parser tracks where in the HTML each hole lands, and refuses the places
where escaping is not enough:

- `on*` attributes and `srcdoc` (script and a whole document);
- a tag name (`<{x}>`); a bare `<` in text is written `&lt;`, so no value
  after it can make it a tag;
- a URL attribute (`href`, `src`, `action`, `formaction`, ...) whose static
  start is a `javascript:` or `vbscript:` URL, or hides its scheme behind a
  character reference (for `{:…}` browser values too);
- places a URL hides in: `to`, `from`, `values` and `by` of an SVG
  `<animate>` or `<set>` (which can set an `href`), a `<meta>`'s
  `http-equiv`, and the `content` of a `<meta http-equiv="refresh">`;
- `//` comments inside a hole, which would comment out the generated code
  after them.

When an expression decides a URL attribute's scheme (`href={link}`,
`src="{base}/x.png"`), the value is checked where it ends
(`wisp::rt::guard_url`) and one that would run script becomes
`about:invalid#blocked`, as React and Angular do. A static start that fixes
the scheme (`/p/{id}`, `https://…`, `?q=…`) costs nothing. These rules
(escaping, which attributes hold URLs, which schemes run script) live in
one file, `crates/wisp-shared/src/contexts.rs`, in a crate both `wisp` and
`wisp-build` depend on: the runtime renders by it, the compiler folds and
checks by it, and its tests hold the browser runtime to the same cases.

A block must begin and end in the same place (in text, inside one tag, in
one attribute value), and so must each branch: otherwise one branch could
leave the page inside a tag that another never opened, and `{x}` after it
would be escaped for the wrong place.

## Components

A `.wisp` file in `src/components` (at any depth) is a component, named by
its file: `Card.wisp` is `<Card>`. It declares what it takes at the top:

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

- Props are Rust types, and each compiles to a parameter of the component's
  render function, so rustc checks every use. A reference type is passed a
  borrow of the expression, so `title={post.title}` gives a `String` to a
  `&str`. `name="text"` is a string; `name` alone is `true` (for a `bool`
  prop). A prop with a default may be left out. `impl Display` works too.
- `{@render children()}` shows what the tag wraps, like a layout's page.
  Children are compiled in the page that uses the component, so they see
  its `data`, loop variables and `{@const}`s.
- Checked at build time, against the file that uses it: the component
  exists (with the ones that do listed if not), every prop it is given is
  one it declares, every prop without a default is given, a flag is only
  given to a `bool`, and children only go to a component that shows them.
- The name starts with a capital letter and has a lowercase one: a tag in
  all capitals (`<DIV>`) is still HTML. Components cannot go in
  `<wisp:head>`, and only components take `{@props}`.
- Component files hot-swap like any template.

Components can also be drawn by the browser (inside client blocks, or with
`{:…}` props, `bind:` and `on:`); see [client.md](/docs/client).

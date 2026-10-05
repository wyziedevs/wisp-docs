---
title: Quick Start
description: A one page quick start for Wisp: create an app, add a page, a component, state and a form with validation, save data in a table, then test, build and deploy.
group: Start
order: 5
---

This page covers the concepts an everyday Wisp app uses.

<div class="learn">

**You Will Learn**

- How to make an app and run it
- How to write a page and a component
- How to add state in the browser
- How to handle a form with validation
- How to save data in a table
- How to build and deploy

</div>

## Create an App

You need [Rust](https://rustup.rs) 1.88 or later. Install the `wisp` command, make an app and start the dev server. `wisp new` asks a few questions: press Enter for the defaults, or add `-y`.

```bash
cargo install wisp-web
wisp new guestbook --template minimal
cd guestbook
wisp dev
```

Open `http://127.0.0.1:3000`. `wisp dev` rebuilds as you edit, and hot reload keeps your browser state. A folder under `src/routes` is a URL, and the `+page.wisp` inside it is the page.

## Creating a Page

A page is a `.wisp` file. It may start with a block of Rust between two `---` lines, then comes markup. The block can hold the whole route: its load, `#[action]` form handlers and `mod server { … }` endpoints ([Pages](/docs/design-pages/)). `src/routes/hello/+page.wisp` is served at `/hello`:

```html
---
let name: String = cx.query_or("name", "world".to_string());
---

<h1>Hello, {name}!</h1>
```

The block runs on the server for each request, and `{name}` writes a value into the HTML, escaped. Open `/hello?name=Ada`. A folder named `[id=int]` is a parameter that matches digits, and the block gets it as a local, `id: u64`.

<aside class="callout note">

<strong>Note</strong>

The prelude brings `Cx`, `Table`, `Email`, `redirect`, `error` and the other usual names into every page, so a page has no `use` lines.

</aside>

## Using a Component

A component is a `.wisp` file in `src/components`. Its `{@props}` line lists what it takes. `src/components/Note.wisp`:

```html
{@props name, message}
<article class="note">
  <h2>{name}</h2>
  <p>{message}</p>
</article>

<style>
  .note {
    border-left: 3px solid var(--accent, #7c5cff);
    padding-left: 1rem;
  }
</style>
```

Use it by its file name, with props as attributes:

```html
<Note name="Ada" message="Hello" />
```

The `<style>` block applies to this component only. Props are checked when the app builds, so a missing one is a build error and not a blank page.

## Adding State

Browser code lives in the same file as the markup. A top-level `let` in a `<script>` is state, `{:count}` shows it, and a directive such as `on:click` changes it:

```html
<button on:click="count++">Clicked {:count} times</button>

<script>
  let count = $state(0)
</script>
```

A write redraws only the parts of the page that read what changed. Without JavaScript the server's HTML still works, which is why forms and links do not depend on a script. See [Browser code](/docs/client/).

<details class="deep-dive">
<summary>Server Values and Browser Values</summary>

`{name}` is Rust, evaluated once on the server. `{:count}` and the quoted value of `on:click` are JavaScript, evaluated in the browser. A name a page's Rust block makes is also available by name in browser code, as long as its type is a `#[model]` or derives `Json`. See [Server values and client blocks](/docs/client-templates/).

</details>

## Handling a Form

A form posts to an action. The action's parameters are the form's fields, and `fields` writes a labelled input for each one. The model, its table and the action can all live in the page's `---` block:

```html
---
#[model]
struct Entry {
    #[validate(len = 1..=40)]
    name: String,
    #[validate(len = 1..=200)]
    message: String,
}
static ENTRIES: Table<Entry> = Table::saved();

#[action]
fn sign(entry: Entry) {
    ENTRIES.add(entry);
    redirect("/")
}
---

<form action="?/sign" fields>
  <button>Sign</button>
</form>
```

An empty name, or a message over 200 characters, answers with a 422. The page is drawn again with each problem beside its input and what was typed kept. The inputs also get the matching browser checks (`required`, `minlength`), and the server checks every value again.

<aside class="callout pitfall">

<strong>Pitfall</strong>

A page file is named `+page.wisp`, with the `+`. In an action, `error()` already returns the `Result`, so write `return error(404, "Gone");` and not `Err(error(..))`.

</aside>

## Saving Data in a Table

A `Table` holds rows of a model. `Table::saved()` keeps them in a log file in the data folder, so they survive a restart, and `Table::new()` keeps them in memory. The page above reads it in the same block:

```html
---
// ...the model, table and action from above...
let entries = ENTRIES.all();
---

<title>Guestbook ({entries.len()})</title>
{#each entries.iter().rev() as entry}
  <Note name={entry.name.as_str()} message={entry.message.as_str()} />
{:else}
  <p>No notes yet. Be the first.</p>
{/each}
```

One `+page.wisp` is the preferred way to write a page. When a second page needs the same table, move the model and the `pub static` to `src/db.rs`: its `pub` items are visible in every route file with no `use` line. See [One file or several](/docs/design-pages/#one-file-or-several).

`add`, `get`, `all`, `find`, `filter`, `update`, `set`, `remove` and `len` cover most needs. A row has an `id` and reads as the value you stored. See [Data, files and jobs](/docs/data/).

<details class="deep-dive">
<summary>Where the Rows Are Kept</summary>

Saved tables live in the folder named by `WISP_DATA`: `.wisp/data` in dev and `data` next to the binary in a release build. On a host with no disk, point a table at a database with a custom store. See [Where rows are kept](/docs/api-tables/).

</details>

## Check, Test and Build

```bash
wisp check      # templates, routes, accessibility lints
wisp test       # your tests
wisp fmt        # format
wisp build      # one release binary
```

`wisp build` writes a single binary with the styles and static files inside. Copy it to a server and run it. It listens on `$HOST:$PORT`, which is `0.0.0.0:3000` in a release build.

## Deploying

Pick the build for your host:

<div class="table-wrap">

| You have | Run |
|---|---|
| A VPS or server | `wisp build`, then `wisp service install` to keep it running |
| A container host | `wisp build --docker` |
| A static host | `wisp build --static` (pages with forms need a server) |
| Cloudflare, Deno, Vercel, Netlify or Lambda | `wisp build --target <host>` |

</div>

`wisp deploy init <host>` writes a GitHub Actions workflow or the host's config. An app that signs cookies needs `WISP_SECRET` set to 32 or more random characters on every host. See [Deploying](/docs/deploy/).

## Next Steps

That covers most of what an everyday Wisp app uses. To go further:

- [Tutorial](/docs/tutorial/): build a guestbook step by step, with tests and a deploy.
- [Pages and templates](/docs/design-pages/): the Rust block, loads, actions and caching in full.
- [Template syntax and styles](/docs/design-syntax/): every `{#each}`, `{#if}` and snippet.
- [Actions, forms and UI](/docs/design-forms/): validation rules, uploads and the built-in form UI.
- [Browser code](/docs/client/): runes, directives, islands and the router.
- [APIs and platforms](/docs/api/): a JSON API from one struct.
- [Deploying](/docs/deploy/) and [Edge and serverless targets](/docs/deploy-targets/).
- Working with an AI agent: [Design and files](/docs/design-editors/) covers `AGENTS.md` and `wisp mcp`.

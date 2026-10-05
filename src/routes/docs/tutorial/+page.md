---
title: "Tutorial: Guestbook"
description: Build a small guestbook app in Wisp step by step: a route, a form with validation, a saved table, a component, browser state, a test and a deploy.
group: Start
order: 6
---

You will build a guestbook: visitors sign it with a name and a message, and every note is kept across restarts. Each step shows the exact file to write. No Wisp knowledge is assumed, but you should be able to read Rust.

<div class="learn">

**You Will Learn**

- How a folder becomes a page
- How a form action validates input and keeps what was typed
- How to save rows in a table
- How to split markup into a component
- How to add state in the browser
- How to test the app and build one binary

</div>

## Set Up

You need [Rust](https://rustup.rs) 1.88 or later. Install the `wisp` command and make the app:

```bash
cargo install --git https://wisp.ar0.eu wisp-cli
wisp new guestbook --template minimal
cd guestbook
wisp dev
```

`wisp new` asks a few questions (press Enter for the defaults, or add `-y`). Open `http://127.0.0.1:3000`. Leave `wisp dev` running: it rebuilds when you save a file and reloads the page. The app has these files, and you will add a few more:

```
src/main.rs                 wisp::main!();
src/app.html                the page shell
src/app.css                 styles
src/routes/+page.wisp       the home page
src/routes/+layout.wisp     wraps every page
src/routes/+error.wisp      the error page
```

## Write the First Page

Open `src/routes/+page.wisp` and replace it:

```html
<title>Guestbook</title>

<h1>Guestbook</h1>
<p>Leave a note for the next visitor.</p>
```

A folder under `src/routes` is a URL, and its `+page.wisp` is the page. This file is the home page, `/`. A top-level `<title>` goes into the document head.

## Describe the Data

Create `src/db.rs`. It holds the models and tables, and its `pub` items are visible in every route file without a `use` line:

```rust
#[model]
struct Entry {
    #[validate(len = 1..=40)]
    name: String,
    #[validate(len = 1..=200)]
    message: String,
}

pub static ENTRIES: Table<Entry> = Table::saved();
```

`#[model]` makes `Entry` something a form can fill and a table can store, and makes it and its fields public. `#[validate]` states the rule once: a name has 1 to 40 characters and a message 1 to 200. `Table::saved()` keeps the rows in a log file, so they survive a restart.

## Add the Form

A form posts to an action, which is a function in the page's block. Its parameters are the form's fields. Replace `src/routes/+page.wisp`:

```html
---
#[action]
fn sign(entry: Entry) {
    ENTRIES.add(entry);
    redirect("/")
}
---

<title>Guestbook</title>

<h1>Guestbook</h1>
<p>Leave a note for the next visitor.</p>

<form action="?/sign" fields>
  <button>Sign</button>
</form>
```

The block between the `---` lines is Rust. `sign` takes an `Entry`, so the form needs a `name` and a `message`. `fields` writes a labelled input for each one and you add the button. A field named `message` becomes a textarea. `redirect("/")` answers with a 303 so a reload does not post again.

Submit the form with the name left empty. You get a 422: the page is drawn again with the problem beside the input and your message kept. The inputs also carry `required` and `minlength`, so the browser stops most mistakes before they reach the server, and the server checks every value anyway.

<aside class="callout note">

<strong>Note</strong>

This works with JavaScript off. With it on, Wisp morphs the page instead of reloading it.

</aside>

## Show the Notes

Rows come from the table. Add a load before the markup, and a list after the form. Statements in the block run on each request before the page is drawn, and the markup reads their names:

```html
---
#[action]
fn sign(entry: Entry) {
    ENTRIES.add(entry);
    redirect("/")
}

let entries = ENTRIES.all();
---

<title>Guestbook ({entries.len()})</title>

<h1>Guestbook</h1>
<p>Leave a note for the next visitor.</p>

<form action="?/sign" fields>
  <button>Sign</button>
</form>

{#each entries.iter().rev() as entry}
  <article>
    <h2>{entry.name}</h2>
    <p>{entry.message}</p>
  </article>
{:else}
  <p>No notes yet. Be the first.</p>
{/each}
```

`{#each}` loops, and `{:else}` runs when the list is empty. `.rev()` puts the newest note first. Sign the guestbook, then stop and restart `wisp dev`: your note is still there. Wisp escapes every `{value}`, so a visitor cannot inject markup.

<details class="deep-dive">
<summary>Where the Rows Are Stored</summary>

A saved table is a log file named after it, `entries.log`, in the folder named by `WISP_DATA`: `.wisp/data` in dev and `data` in a release build. Each change appends a line. Use `Table::new()` for rows that may vanish on restart. See [Where rows are kept](/docs/api-tables/).

</details>

## Make a Component

The note markup will grow, so move it into a component. Create `src/components/Note.wisp`:

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
    margin: 1rem 0;
  }
</style>
```

`{@props}` lists what the component takes, and with no type a prop is a `&str`. The `<style>` block applies to this file only. Now use it in `src/routes/+page.wisp`, in place of the `<article>`:

```html
{#each entries.iter().rev() as entry}
  <Note name={entry.name.as_str()} message={entry.message.as_str()} />
{:else}
  <p>No notes yet. Be the first.</p>
{/each}
```

Props are checked when the app builds. Misspell `message` and `wisp check` fails, naming the file, the line and the props the component takes.

## Add State in the Browser

Let a visitor mark a note as liked. This is browser code, so it goes in a `<script>` in the same file. Update `src/components/Note.wisp`:

```html
{@props name, message}
<article class="note">
  <h2>{name}</h2>
  <p>{message}</p>
  <button on:click="liked = !liked">{:liked ? "Liked" : "Like"}</button>
</article>

<style>
  .note {
    border-left: 3px solid var(--accent, #7c5cff);
    padding-left: 1rem;
    margin: 1rem 0;
  }
</style>

<script>
  let liked = $state(false)
</script>
```

`{name}` is Rust, drawn once on the server. `{:liked ? "Liked" : "Like"}` and the quoted value of `on:click` are JavaScript, and a click redraws only that button. Each note gets its own `liked`.

<aside class="callout pitfall">

<strong>Pitfall</strong>

This state lives in the browser. Reload the page and every note is unliked again. To keep a like, send it to the server with an action or a `#[remote]` function and store it in a table. See [Browser code](/docs/client/).

</aside>

## Check and Test

Run the checks. They read every template and route:

```bash
wisp check
wisp fmt
```

`wisp check` reports a bad route, a missing prop or an accessibility problem, and `wisp fmt` formats every `.wisp` file. Now add a test. Create `src/tests.rs`:

```rust
use wisp::test::{client, fresh};

#[test]
fn signing_the_guestbook() {
    fresh();
    let mut app = client::<crate::App>();

    let bad = app.post_form("/?/sign", &[("name", "Ada"), ("message", "")]);
    assert_eq!(bad.status, 422);

    let ok = app.post_form("/?/sign", &[("name", "Ada"), ("message", "Hello")]);
    assert_eq!(ok.status, 303);
    assert!(app.get("/").text().contains("Hello"));
}
```

Add the module to `src/main.rs`:

```rust
wisp::main!();

#[cfg(test)]
mod tests;
```

Run `wisp test`. The test runs the real app in the process, with no server and no port. `fresh()` empties every table first, so the test does not depend on the notes you signed by hand.

## Build and Deploy

```bash
wisp build
```

This writes one release binary, `target/release/guestbook`, with the styles and static files inside. Copy it to a server and run it. It listens on `$HOST:$PORT`, which is `0.0.0.0:3000` by default, and writes `entries.log` into a `data` folder. Keep that folder across deploys, or set `WISP_DATA` to a folder you back up.

Pick the build that fits your host:

<div class="table-wrap">

| You have | Run |
|---|---|
| A VPS or server | `wisp build`, then `wisp service install` |
| A container host | `wisp build --docker` |
| Cloudflare, Deno, Vercel, Netlify or Lambda | `wisp build --target <host>` |

</div>

A guestbook has a form, so it needs a server: `wisp build --static` suits pages with no actions. On a host with no disk, tables are memory, so use a database store there. See [Deploying](/docs/deploy/) and [Edge and serverless targets](/docs/deploy-targets/).

## Recap

<div class="recap">

You built a small app with Wisp. You learned that:

- A folder under `src/routes` is a URL, and `+page.wisp` is the page.
- A page has an optional block of Rust, then markup, and `{value}` is escaped.
- A `#[model]` with `#[validate]` rules describes data once, and `Table::saved()` keeps it.
- An `#[action]` handles a form, and `fields` writes the inputs. A bad value is a 422 that keeps what was typed.
- A component in `src/components` takes `{@props}` and may carry its own style and script.
- A `<script>` with `$state` adds browser behavior, and the page works without it.
- `wisp check`, `wisp test` and `wisp build` check, test and ship one binary.

</div>

## Challenges

Try these on your own, then open the solution.

<section class="challenges">

<details class="challenge">
<summary>Delete a Note</summary>

Add a Delete button under each note that removes it.

<details class="solution">
<summary>Show Solution</summary>

Add an action next to `sign`, and a button after each `<Note>`. A button with an `action` attribute outside a form is a one-button form, and the extra `&id=` is passed to the action as a parameter:

```html
---
#[action]
fn remove(id: u64) {
    ENTRIES.remove(id);
}
---
```

```html
{#each entries.iter().rev() as entry}
  <Note name={entry.name.as_str()} message={entry.message.as_str()} />
  <button action="?/remove&id={entry.id}">Delete</button>
{:else}
  <p>No notes yet. Be the first.</p>
{/each}
```

The action has no `redirect`, so the page is drawn again with the row gone. Anyone can delete any note, so a real guestbook would check who is signed in first.

</details>

</details>

<details class="challenge">
<summary>Say Thanks</summary>

After a visitor signs, show "Thanks for signing" once on the next page.

<details class="solution">
<summary>Show Solution</summary>

Flash a message in the action, and read it in the block. Reading it deletes it, so it shows once:

```html
---
#[action]
fn sign(entry: Entry) {
    ENTRIES.add(entry);
    cx.flash("Thanks for signing");
    redirect("/")
}

let entries = ENTRIES.all();
let thanks = cx.flashed();
---
```

```html
{#if let Some(message) = thanks}
  <p role="status">{message}</p>
{/if}
```

Wisp adds `cx` to the action when its body uses it. The message waits in a cookie until the next page reads it.

</details>

</details>

<details class="challenge">
<summary>One Page per Note</summary>

Give each note its own page at `/notes/1`, `/notes/2` and so on, with a 404 for a note that does not exist.

<details class="solution">
<summary>Show Solution</summary>

Make the folder `src/routes/notes/[id=int]` and put a page in it. A folder named `[id=int]` matches digits, and the block gets `id` as a `u64`:

```html
---
let note = ENTRIES.get(id).or_404()?;
---

<title>{note.name}</title>

<h1>{note.name}</h1>
<p>{note.message}</p>
```

`ENTRIES.get(id)` returns an `Option`, and `.or_404()?` answers with the error page when it is `None`. Link to it from the list with `<a href="/notes/{entry.id}">Permalink</a>`.

</details>

</details>

</section>

## Next Steps

- [Quick Start](/docs/quick-start/): the same ideas on one page.
- [Actions, forms and UI](/docs/design-forms/): more validation rules, uploads and the built-in UI.
- [Data, files and jobs](/docs/data/): tables, files and background jobs.
- [Browser code](/docs/client/): runes, directives, islands and the router.
- [Testing and mixing with Rust code](/docs/embed/): more on testing an app in process.

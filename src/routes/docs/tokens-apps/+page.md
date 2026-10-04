---
title: Tokens, App by App
description: Compare four small apps written in Wisp and six other frameworks by AI token cost, see the results, and read the full Wisp versions of each app.
group: Project
order: 71
---

Method and the five-feature table: [Tokens](/docs/tokens/).

## The Four Apps

- **counter**: a button that counts clicks.
- **todo**: a list kept in memory, a form that adds an item (1 to 100 characters; otherwise a 422 that shows the problem and keeps what was typed), and a delete button per item.
- **api**: JSON CRUD for notes (`id`, `title`, `done`): list, get, create (title 1 to 200 characters, else 422), update, delete; 404 for a missing note; writes need `Authorization: Bearer $API_KEY`.
- **blog**: a layout with a header, an index of posts, and `/blog/[slug]` with the post's title in `<title>`, 404 for a missing one.

## Results

Estimated tokens (files):

<div class="table-wrap">

| Framework | counter | todo | api | blog | total |
|---|---:|---:|---:|---:|---:|
| **Wisp** | **44** (1) | **191** (1) | **59** (1) | **292** (4) | **586** |
| SvelteKit | 49 (1) | 373 (2) | 622 (4) | 389 (5) | 1433 |
| Next.js | 77 (1) | 501 (4) | 722 (4) | 461 (4) | 1761 |
| Nuxt | 49 (1) | 473 (5) | 572 (7) | 332 (5) | 1426 |
| Axum | 248 (1) | 641 (1) | 1056 (1) | 462 (1) | 2407 |
| FastAPI | 123 (1) | 408 (2) | 494 (1) | 446 (4) | 1471 |
| Rails | 132 (3) | 340 (5) | 132 (4) | 357 (7) | 961 |
| Rails, api by hand | 132 (3) | 340 (5) | 357 (4) | 357 (7) | 1186 |

</div>

Wisp is the shortest on every app, and in all 39% shorter than the next (Rails with its scaffold). The api is a type: Rails' scaffold is the only other that comes close, with a generator command, a model, a route and a controller to edit. Characters / 4 ranks them the same way (Wisp 346, Rails 726, SvelteKit 959).

The apps are not equal in what they do, and the difference favors Wisp's api. Its 59 tokens keep the notes across restarts and crashes (a log file per table in `WISP_DATA`); of the others only Rails does (SQLite, through Active Record), and the rest keep them in memory, as the task allows. The same 59 tokens also answer filters by field, sorting, cursor pages, field selection, ETags with 304 and 412, bulk creates and idempotent retries, which no other version here has.

What a real API adds in Wisp:

- a `created_at: String` field: 6 tokens
- a hook such as `fn before_create(note: &mut Note) -> Result { Ok(()) }`: 22 with its body
- every table in SQLite instead of log files: a `wisp::Store` of 373 (docs/api.md), written once per app

## The Wisp Versions

```rust
// api: src/routes/api/notes/+server.rs
#[derive(Rest)]
#[rest(write = "API_KEY")]
struct Note {
    #[validate(len = 1..=200)]
    title: String,
    done: bool,
}
```

```html
<!-- todo: src/routes/+page.wisp -->
---
static TODOS: Table<String> = Table::new();

#[action]
fn add(#[validate(len = 1..=100)] text: String) {
    TODOS.add(text);
}

#[action]
fn remove(id: u64) {
    TODOS.remove(id);
}
---
<form action="?/add">
  <input name="text">
  <button>Add</button>
</form>
<ul>
  {#each TODOS.all() as todo}
    <li>{todo} <button action="?/remove&id={todo.id}">x</button></li>
  {/each}
</ul>
```

```html
<!-- blog: src/routes/blog/[slug]/+page.wisp -->
---
let post = posts::POSTS.iter().find(|p| p.slug == slug).or_404()?;
---
<title>{post.title}</title>
<h1>{post.title}</h1>
<p>{post.body}</p>
```

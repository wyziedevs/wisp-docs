---
title: APIs and platforms
description: JSON endpoints, #[derive(Rest)] resources, queries, hooks and stores.
group: APIs
order: 40
---

An API is a folder of `+server.rs` files beside pages, one binary. Start
one: `wisp new my-api --api`, `wisp dev`, then `/_wisp/docs`. Template:
[examples/api](https://github.com/wyziedevs/wisp/tree/main/examples/api).

## An endpoint

```rust
// src/routes/api/notes/+server.rs
#[derive(FromJson)]
struct NewNote {
    #[validate(min_len = 1, max_len = 200)]
    title: String,
    tags: Option<Vec<String>>,
}

fn get(q: Option<String>) -> Vec<Note> {
    db::notes(q.as_deref())
}

fn post(body: NewNote) -> Response {
    Response::created(&db::add(body.title, body.tags.unwrap_or_default()))
}
```

The fn name is the method (`get post put patch delete`); HEAD is `get`,
OPTIONS is Wisp's (204 + `Allow`; a method the route lacks is 405 + `Allow`).
A handler may also take `cx: &mut Cx` and return `Result<Response>`.

## A resource

```rust
#[derive(Rest)]
#[rest(write = "API_KEY")]
struct Note {
    #[validate(len = 1..=200)]
    title: String,
    done: bool,
}
```

| Request | Answer |
|---|---|
| `GET /api/notes` | rows by id: `[{"id":1,"title":"Tea","done":false}]` |
| `POST /api/notes` | 201 + row + `Location`; 422 if invalid; an array makes several, all or none |
| `GET /api/notes/1` | row with `etag`, or 404 |
| `PUT /api/notes/1` | replaced by the body |
| `PATCH /api/notes/1` | body's members replace the row's (`null` empties an `Option`); result must pass (422) |
| `DELETE /api/notes/1` | 204 or 404 |

`Rest` = `Json` + `FromJson` + a table `Note::table()` other routes read too.
A handler the file writes (`fn delete(id: u64)`) replaces that one;
`fn before(cx: &mut Cx)` runs before each.

| `#[rest(...)]` | Does |
|---|---|
| `write = "API_KEY"` | writes 401 unless `Authorization: Bearer <value of API_KEY>` |
| `key = "KEY"` | same for every request |
| `admin = "ADMIN_KEY"` | same for DELETE |
| `table = "notes"` | store name (default: type name lowercased) |
| `ids = "random"` | uncountable random ids below 2^53 |
| `memory` | memory only |

A field left out of a request: `bool` false, `Vec` `[]`, `Option` None;
others required. `created_at`/`updated_at` are set by Wisp (RFC 3339
`String`, or whole seconds in a number).

### Queries

| Query | Gives |
|---|---|
| `?done=true` | rows with that field value (numbers compare as numbers) |
| `?points.gte=3` | `.ne .gt .gte .lt .lte`; text and RFC 3339 times compare as text |
| `?title.has=tea` | text containing it (any case); a list containing the item |
| `?sort=-created_at,title` | `-` descending (`id` too) |
| `?limit=20&after=40` | 20 rows after id 40 (stable cursor) |
| `?limit=20&offset=40` | skip 40 (for a sorted list) |
| `?fields=title,done` | only those and `id` (a single row too) |

An unknown field is a 400 listing the known ones. `x-total-count` has the
match count; `link: <…?limit=20&after=60>; rel="next"` the next page;
`accept: application/x-ndjson` gives a line per row.

Every row and list has an `etag`; `if-none-match` gets a 304. A write with
`if-match` is a 412 (`code` `changed`) if the row changed since. `const
CACHE: u32 = 5;` in a `+server.rs` caches each GET per path and query per
worker (rules: design.md); a write does not clear it.

### Hooks

```rust
fn before_create(note: &mut Note) -> Result {
    note.title = note.title.trim().to_string();
    if note.title == "admin" { return invalid("title", "is reserved"); }
    Ok(())
}
fn after_update(note: &Row<Note>) {
    wisp::channel("notes").send(wisp::to_json(note));
}
```

`before_create`/`before_update` take the value (`&mut Note` or `&Note`;
update also `id: u64`); `before_delete`, `after_create`, `after_update`,
`after_delete` take the row (`&Row<Note>`, or `&Note` and `id: u64`). Any
may take `cx` and return nothing or `Result`; a `before_` error stops the
change (422 from `invalid` names the field); `after_` runs once saved. Hooks
run outside the table lock.

A type with a field named `user` in `users/[user=int]/notes/+server.rs`
holds each user's own: the route's `user` filters every request and is set
on every row made or changed there.

### Where rows are kept

Saved before memory changes, read at first use: a log file per table
(`note.log`, a line per change, a cut line dropped on read, rewritten whole
at twice its rows) in `WISP_DATA`: `.wisp/data` in dev, `data` in release,
`/data` in the `--docker` image. `WISP_FSYNC`: `second` (default), `always`,
`off`. `WISP_DATA=off`: memory (tests, edge). Tables hold every row in
memory; for larger data or database-side queries write the handlers.

Any database via `wisp::store(Db)` in `init`: implement `wisp::Store` with
`load(&self, table) -> Result<Vec<(u64, String)>>` (id and JSON of each row)
and `save(&self, table, id, json: Option<&str>) -> Result` (`None` deletes),
e.g. over `Mutex<rusqlite::Connection>` (`create table if not exists {table}
(id integer primary key, json text)`; `insert or replace`; `delete`). Calls
are blocking, one per change, under the table lock (suits a nearby
database). A POST of an array goes through `save_many(table, &[(id, json)])`
(default: each in turn, undoing earlier ones on failure; override with one
transaction); failure is a 500 and nothing is kept. On the edge each
instance has its own memory: tables are caches; use D1/KV through
`wisp::edge::fetch`, or env `WISP_STORE=d1:DB|deno-kv|libsql://…`.

A page's own table: `static TODOS: Table<Todo> = Table::saved();` (named
from the static; `Table::saved("todos")` names it). A field added to a saved
type must be `Option`, `Vec` or `bool`. An `Image` field is a `data:` URL.

`POSTS.page(cx, 10)` is the rows `?page=N` asks for, newest first; it reads
as its rows and has `number`, `prev`, `next` (hrefs, `None` at the ends):

```html
{#each posts as post}<p>{post.title}</p>{/each}
{#if let Some(href) = posts.next}<a {href}>Older</a>{/if}
```

## Handlers for a folder and its `[id]`

A handler with a param `id` in a folder whose URL has none answers at
`/[id]` below it (`[id=int]` when numeric); `list` is the folder's GET:

```rust
// src/routes/api/notes/+server.rs
fn list() -> Vec<Note> { db::notes() }                        // GET /api/notes
fn post(body: New) -> Response { Response::created(&db::add(body)) }
fn get(id: u64) -> Option<Note> { db::note(id) }              // GET /api/notes/7
fn patch(id: u64, body: Changes) -> Option<Note> { db::change(id, body) }
fn delete(id: u64) -> Option<()> { db::remove(id) }           // 204, or 404
```

A folder with its own `[id]` still works; two files answering the same URLs
is a build error.

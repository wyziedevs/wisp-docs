---
title: Where rows are kept
description: Table storage, WISP_DATA, custom stores, the edge and paging.
group: APIs
order: 44
---

## Storage
Saved before memory changes, read at first use: a log file per table (`note.log`, a line per change, a cut line dropped on read, rewritten whole at twice its rows) in `WISP_DATA`.

| Setting | Meaning |
|---|---|
| `WISP_DATA` | Data folder: `.wisp/data` in dev, `data` in release, `/data` in the `--docker` image. |
| `WISP_DATA=off` | Memory (tests, edge). |
| `WISP_FSYNC` | `second` (default), `always`, `off`. |

Tables hold every row in memory; for larger data or database-side queries write the handlers.

## Any database
`wisp::store(Db)` in `init`: implement `wisp::Store`:

- `load(&self, table) -> Result<Vec<(u64, String)>>`: id and JSON of each row.
- `save(&self, table, id, json: Option<&str>) -> Result`: `None` deletes.

E.g. over `Mutex<rusqlite::Connection>` (`create table if not exists {table} (id integer primary key, json text)`; `insert or replace`; `delete`).

- Calls are blocking, one per change, under the table lock (suits a nearby database).
- A POST of an array goes through `save_many(table, &[(id, json)])` (default: each in turn, undoing earlier ones on failure; override with one transaction); failure is a 500 and nothing is kept.
- On the edge each instance has its own memory: tables are caches; use D1/KV through `wisp::edge::fetch`, or env `WISP_STORE=d1:DB|deno-kv|libsql://…`.

## A page's own table
`static TODOS: Table<Todo> = Table::saved();` (named from the static; `Table::saved("todos")` names it).

- A field added to a saved type must be `Option`, `Vec` or `bool`.
- An `Image` field is a `data:` URL.

## Paging
`POSTS.page(cx, 10)` is the rows `?page=N` asks for, newest first; it reads as its rows and has `number`, `prev`, `next` (hrefs, `None` at the ends):

```html
{#each posts as post}<p>{post.title}</p>{/each}
{#if let Some(href) = posts.next}<a {href}>Older</a>{/if}
```

`{@pager posts}` writes both links. `TABLE.add_unless(|t| t.slug == slug, value)` keeps `value` only if no row is taken (checked locked); `None` if one is.

---
title: Data, Files and Jobs
description: Store and move data in Wisp with tables, file uploads, validation rules, background jobs and a cache, all without extra services.
group: Data and Auth
order: 50
---

Everything here is opt-in: an app that uses none of it pays nothing.

## Tables

```rust
// src/db.rs
pub static USERS: Table<User> = Table::saved("users")
    .unique("email", |u: &User| &u.email) // no two rows share it
    .migrate(|row| {
        // old rows, as they are read
        if let Value::Object(m) = row {
            for (k, _) in m.iter_mut().filter(|(k, _)| k == "mail") {
                *k = "email".into();
            }
        }
    })
    .live(); // each change is sent on channel "users"
```

- `set(id, v) -> Option<()>` replaces a row; `clear()` takes every row out (ids are not given again).
- `unique`: `by(&email)` finds the row without a scan. `try_add`, `try_set` and `try_update` return a 422 on the field (`email: is taken`), for an action to return with `?`. `add`, `set` and `update` panic (a 500) instead. Use `try_update` to change a unique field. `#[derive(Rest)]` routes do the same: a taken value is a 422.
- `#[model]` makes the struct and its fields `pub` and derives `Json`, `FromJson` and `Clone`. A model with a borrowed field (`name: &'static str`, for static data a page lists) derives no `FromJson`, since a body cannot fill it.
- On a `#[model]` field: `#[unique]` is the same as `.unique(..)`; `#[json(default)]` or `#[json(default = expr)]` fills a field old rows lack; `#[json(was = "old")]` reads it under its old name.
- `migrate(|v: &mut Value| ..)` runs on each stored row's JSON when it is read (at load, and by `WISP_STORE_POLL`), before it becomes the type.
- `live()`: after each change, `wisp::channel(name).send("change")`, only when someone listens. A page listens with `listen('/users/events', invalidate)` and a `+server.rs` of `wisp::channel("users").events()`. A page that names a live table's static rows refreshes itself through `/_wisp/live/<name>`.
- Several servers on one store: a `Store` may answer `changes(table, since)`, and with `WISP_STORE_POLL=5` (seconds) every table follows it.
- Tables are whole in memory: the store's size is the RAM bound.

## Rules
`#[validate(url, one_of = "a b c", pattern = "[a-z]{3}-\\d+", with = ok)]` beside `len min max min_len max_len email`.

- `url` is an absolute http(s) address.
- `pattern` matches the whole value: literals, `.`, `[a-z_]`, `[^x]`, `\d \w \s`, groups, `|`, `? * + {n} {n,m}` (values up to 1000 characters; too much backtracking does not match).
- `with = f` calls `f(&v) -> Option<String>`, the problem.

## Jobs

```rust
// init
wisp::work("mail", |m: Mail| async move { send(&m).await });
wisp::cron("0 3 * * *", || async { purge().await }); // UTC
// anywhere
wisp::queue("mail").push(&Mail { to, body }); // .later(secs, &job)
```

- Jobs live in the saved table `queue-mail` (a name past 58 characters, or with other than letters, digits, `_` and `-`, gets a table named by its hash). `later(secs)` past the end of time waits, never wraps. A failure (`Err` or a panic) is tried again after 4, 8, 16... seconds (an hour at most), five tries; then it stays `dead` with its last error (`queue.dead()`, `queue.retry(id)`).
- At least once: a job running when the process died runs again a minute later. One at a time per queue, in order.
- `cron` takes five fields (`*`, `n`, `a-b`, `*/n`, lists; Sunday is 0 or 7), in UTC only. As in Vixie cron, a day field starting with `*` (`*/2`) is not a restriction on the day.
- A minute already run never runs again, so a clock stepped back does not repeat it. A run missed while the machine slept runs once on waking. Near the end of time the next run is `None` and the task stops.
- On Cloudflare, Vercel and Netlify (`wisp build --target ...`) the same code runs from the host's cron: `wisp build` writes each `cron` schedule (a string literal) into its trigger config, and a trigger also runs the queues' due jobs (each minute if the app has `work`). Set `CRON_SECRET` and `WISP_STORE` there. See [Edge and serverless targets](/docs/deploy-targets/#jobs).

## Cache
`wisp::cache("top", 60, || async { top_posts().await }).await` keeps an answer for 60 s per process. `wisp::uncache("/posts")` forgets cache keys starting with it and the pages `const CACHE` keeps, on every worker, for `/posts` and below (`/` is all).


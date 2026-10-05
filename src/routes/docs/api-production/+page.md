---
title: Auth, Limits, Jobs and Config
description: Run a Wisp API in production with auth, rate limits, live updates, background jobs, and configuration for databases and other settings the app needs.
group: APIs
order: 42
---

## Auth
Keys:
- `cx.need_bearer("API_KEY")?`: 401 unless `Authorization: Bearer <API_KEY's value>` (constant time; unset matches nothing).
- `cx.writes()` is true for POST/PUT/PATCH/DELETE; `cx.bearer()` is the token; `wisp::secure_eq(a, b)`; `cx.basic_auth()` is `Option<(user, password)>`.

Sessions:
- `cx.sign_in(id)` after `wisp::password::check(&typed, user_hash).await?` (`None` for no such user, as slow; `hash(&password).await?`; both on hashing threads).
- Then `cx.signed_in()?` or `cx.user()?` (`cx.login`/`signup`: [Auth and integrations](/docs/auth/)) where only members go: signed out, a page 303s to `/login` (`wisp::sign_in_page("/x")`), an endpoint or JSON client gets 401 (`signed_out`).
- `cx.sign_out()` ends it here. The id is in a signed cookie for 30 days; each `sign_in` sets a new session.
- `wisp::sign_out_everywhere(id)?` ends all earlier sessions of `id` on every device (counted in the saved table `wisp_sign_outs`; nothing is looked up until an app calls it; another instance sharing the store sees it on its next start; a store failure is its `Err`).

Guards go in `before` (hooks.rs: every route; `+server.rs`: each handler); hand data on with `cx.set`:

```rust
fn before(cx: &mut Cx) -> Result<()> {
    if cx.path().starts_with("/api/admin/") {
        let user = users::by_token(cx.bearer().unwrap_or("")).or_status(401)?;
        if !user.admin {
            return error(403, "Admins only");
        }
        cx.set(user); // a route reads it with cx.get::<User>()
    }
    Ok(())
}
```

## Rate Limits

```rust
static LOGINS: RateLimit = RateLimit::per_minute(10);

fn post(cx: &mut Cx, name: String, password: String) -> Result<()> {
    LOGINS.check(cx.client_ip())?; // 429 + retry-after once the ten are used
    ...
}
```

- Key: anything hashable (IP, API key, user id). It may spend all at once, then refills steadily.
- Behind a proxy set `WISP_CLIENT_IP_HEADER`.
- `BODY_LIMIT` caps bodies per route.

## Live Updates

```rust
wisp::channel("notes").send(wisp::to_json(&note)); // anywhere

// SSE
fn get() -> Response {
    wisp::channel("notes").events()
}
// both ways
fn get() -> Response {
    wisp::channel("chat").websocket()
}
```

- `subscribe()` (`recv().await`) feeds your own `Response::events` or `websocket`; `connect(&ws)` joins an existing socket.
- Channels are per process: relay between servers (Redis pub/sub, Postgres `LISTEN`) from a task started in `init`.

## Background Jobs

```rust
// src/hooks.rs
fn init() {
    wisp::every(Duration::from_secs(3600), || async {
        db::delete_expired_sessions().await;
    });
}
```

- `every` runs until stop, never two at once; a panicking run is reported and the next starts on time.
- `wisp::spawn` runs one task. Durable queues, cron: [Data, files and jobs](/docs/data/).
- A health check is a route: `fn get() -> &'static str { "ok" }` (`/_wisp/health` exists).

## Configuration and Databases
- `wisp::env("KEY")`: process env, else `.env` in the working directory, read once at start; the process wins; bad lines skipped with a warning; edge: the worker's env, no `.env`.
- `wisp::env_or("WORKERS", 4)` parses with a default.
- Read settings once in `init`: `wisp::provide(v)`, then `wisp::state::<T>()` (or `#[derive(Config)]`, AGENTS.md).

No database layer: open in `init`, `provide`, read with `state`.

```rust
wisp::provide(sqlx::PgPool::connect(&url).await?) // in `async fn init`
wisp::state::<sqlx::PgPool>() // in a handler
```

- rusqlite is sync: provide a `Mutex<Connection>`, hold the lock briefly or `spawn_blocking`.
- redis: `provide(redis::Client::open(url)?)`.
- These need tokio: binary, Docker, Lambda, not the edge (use HTTP databases through `wisp::edge::fetch`).

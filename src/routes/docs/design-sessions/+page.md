---
title: Cookies and Sign-In
description: Learn how Wisp handles cookies, signed cookies, sessions and sign-in, including signing out everywhere and hashing passwords safely.
group: Design
order: 20
---

```rust
cx.set_cookie("theme", "dark"); // 400 days, HttpOnly, SameSite=Lax
let theme = cx.cookie_or("theme", "light".to_string());

cx.set_signed_cookie("user", name); // HMAC-SHA256, needs WISP_SECRET
let who = cx.signed_cookie("user"); // Some only if the signature holds

let me = cx.user()?; // members' page: signed-in row or redirect
```

## Cookies

- `cx.set_cookie(name, value)`: site-wide, 400 days, `HttpOnly`, `SameSite=Lax`. The value is any `Display`; an empty one deletes it.
- `cx.cookie(name)` reads within the same request, so the `load` after an action sees what the action stored.
- `cx.cookie_or(name, default)` parses as any `FromStr`; `cx.signed_cookie_or(name, default)` the same for signed ones.
- `cx.delete_cookie(name)` removes one.
- `cx.set_cookie_with(name, value, CookieOptions { ... })`:

<div class="table-wrap">

| Field | Meaning |
|---|---|
| `max_age` | `None` ends it with the browser |
| `script_readable` | not `HttpOnly` |
| `same_site` | `Lax`, `Strict`, `None` |
| `path`, `domain` | scope |
| `signed` | sign it |

</div>

- `Secure` is added when the request came over HTTPS through a proxy (`x-forwarded-proto: https`) or `ORIGIN` is `https://`, and always with `SameSite=None` (browsers require it).
- `#[derive(Cookie)]` puts a struct in one cookie via `Display` and `FromStr`: fields in order, separated by `|`, each escaped (`42|cranesloth|pi`). A fieldless enum is its variant name. The derive reads only type and field names, no `syn`. The value is visitor input: check rules beyond field types after reading (Wisple's `Game::valid`).

## Signed Cookies

- `cx.set_signed_cookie(name, value)` adds an HMAC-SHA256 signature of name and value (`value.signature`), keyed with `WISP_SECRET`.
- `cx.signed_cookie(name)` returns the value only if the signature holds: a visitor can read it but not forge it, change it, or move it to another cookie name.
- A release build without `WISP_SECRET` fails the request that signs or checks, saying to set it. Dev builds keep a secret in `.wisp/secret` so sessions survive restarts.
- Rotate without signing everyone out: move the old secret to `WISP_SECRET_OLD`. Signatures it made still hold (nothing new is signed with it) until removed; 30 days on for sign-ins.

## Signing In

<div class="table-wrap">

| Call | What it does |
|---|---|
| `cx.signup(row).await?` | for a `#[model]` with a `hash` field and `email` or `name` (an `Account`): hashes the password in `row.hash`, refuses a taken name with a 422, signs in |
| `cx.login(&email, &password).await?` | checks it, as slowly for a name no one has |
| `wisp::signup`, `wisp::login` | same without a `Cx` |
| `cx.sign_in(id)` | sets signed cookie `session` to the id and time, 30 days; always a new session, so a planted one never becomes the visitor's |
| `cx.signed_in()?` | the id; signed out (or 30 days on) it is the error that sends to sign in: 303 to `/login`, or 401 for a JSON client |
| `cx.signed_in().ok()` | asks without redirecting |
| `cx.user()?` | the row itself, same way |
| `cx.sign_out()` | ends it |

</div>

- `user`, `login` and `signup` take the users table for you: the lone `Table` of a model with a `Password` field in `src/db.rs`, else the one `wisp::users(&db::USERS)` names in `init` (the build adds it; `&USERS` first still works, and is how a second table is used).
- The page at `/login` is the convention; `wisp::sign_in_page("/enter")` in `init` names another.

### Sign Out Everywhere

A signed session is valid wherever sent, so `cx.sign_out()` cannot end a stolen copy. `wisp::sign_out_everywhere(id)` can:

- It counts up the id's sign-outs in the saved table `wisp_sign_outs`; sessions made after carry the count (`id.time.count`; none while 0), so older ones no longer match.
- Reading a session looks the count up in memory, and not at all while no one has ever signed out everywhere (an atomic flag).
- The table is read at server start (not at all while there is no log file, so an app that never signs out makes none).
- With the app's own store (`wisp::store`), which instances can share, a thread rereads it every 30 s and the higher count of each id wins. Log files are each instance's own.
- A store that cannot be read leaves sessions as they were, says why, and is retried. `sign_out_everywhere` then returns its `Err`: a security action fails as a value, never a panic.

## Passwords

- `wisp::password::hash(&password).await?` stores; `wisp::password::check(&typed, hash).await?` checks. `hash` is `Option<&str>`: `None` (no such user) hashes a stand-in, as slow, so time does not reveal which names exist.
- PBKDF2-HMAC-SHA256, 600,000 rounds (OWASP), random 16-byte salt, written `$pbkdf2-sha256$i=600000$salt$key`, so the count can be raised and old hashes still check.
- `wisp::password::outdated(&hash)`: made with fewer rounds; hash again once the password checks.
- A stored hash naming over 10,000,000 rounds is refused, not computed.
- Full hashing queue (about 3 s of work counted in rounds, so planted hashes with many rounds cannot lengthen the wait) is a 503 with `retry-after`. That keeps the machine answering in a flood; a `RateLimit` on the sign-in action is what stops one.
- Cost: the key's padded blocks are hashed once, each round is two SHA-256 compressions of one fixed-shape block, no allocation. A hash is a fraction of a second of one core, on purpose.
- It runs on threads kept for hashing (one per two cores, started with the first hash), never the worker's: a worker held 0.2 s would stall every connection on its core, and a sign-in flood takes at most half the machine. The edge build, with no threads, hashes in place.

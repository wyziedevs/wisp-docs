---
title: Input, Output and Errors
description: Learn how a Wisp API takes JSON input with FromJson and checks, returns output, reports errors as JSON, and handles webhooks, idempotent retries and big lists.
group: APIs
order: 41
---

## Input
Each param but `cx` is read by name: route param, then form field or JSON object member, then query. `fn put(id: u64, title: String, done: bool)` takes a form post and `{"title":"Tea","done":true}` alike. Missing or wrong type is an error naming it. (A `body: String` is a form field called `body`.)

`body: T` is the whole JSON body:

<div class="table-wrap">

| Sent | Answer |
|---|---|
| JSON that is a `T` and passes | handler runs |
| not JSON | 400 with where: `Invalid JSON: expected `:` at line 1, column 9` |
| JSON not a `T`, or failing a check | 422, every problem by field |
| non-JSON `Content-Type` | 415 |
| no body, `body: Option<T>` | `None` |

</div>

### `FromJson`
`#[derive(FromJson)]` reads a struct from an object.

- `Option` may be absent or `null`; `bool` absent is false; extra members are ignored.
- A one-field tuple struct reads as that field; a fieldless enum from its variant name (`"Low"`).
- Implemented for strings, numbers (`300` is not a `u8`), `bool`, `Option`, `Vec`, `Box`, string-key maps and `wisp::Value` (any JSON: `body.get("title")`).
- `wisp::from_json::<T>(bytes)` reads JSON anywhere with the same errors; `wisp::json::parse` gives a `Value` (strict RFC 8259).

### Checks

<div class="table-wrap">

| Rule | Checks | On |
|---|---|---|
| `len = 1..=200` | length or item count (`1..`, `..=200`) | strings, lists |
| `min = 0` `max = 100` | bounds | numbers |
| `min_len = 1` `max_len = 200` | length or items | strings, lists |
| `email` | what `<input type="email">` takes (`a@b` too) | strings |

</div>

- `None` passes. Further rules (`url one_of pattern with`): [/docs/data](/docs/data/).
- An unknown rule is a build error listing the valid ones.
- Own checks: `return invalid("email", "is already taken")` (422); `Error::invalid(..).and(..)` names several fields.

## Output

<div class="table-wrap">

| Returns | Client gets |
|---|---|
| a `Json` value (`#[derive(Json)]`, `Vec`, numbers, strings, maps) | 200 + JSON |
| nothing, `Result<()>` | 204 |
| `Response` | it |
| `Option<Response>` | it, or 404 |
| `Option<T>` | JSON, 204 for `Some(())`, 404 for `None` |
| any of these in a `Result` | same, or the error |

</div>

`Response::created(&v)` is 201; `Response::json_of(&v).with_status(202)`; `.with_header(name, value)` adds a header (also on `Error`, and `cx.set_header` in a page). A single-valued one (`content-type`, `cache-control`, `location`, `etag`, any case) replaces what was set before instead of going out twice: `Response::text(xml).with_header("content-type", "application/rss+xml")` sends one `content-type`. `content-length` and `transfer-encoding` are the server's and are left out. `Response::text` and its kin take a `String` or a `&str` (the `IntoText` trait); anything else is a compile error. In a page, `cx.set_status(404)` sets the status.

Query: `cx.query("q")`, `cx.query_or("page", 1)` (parsed, else the default), `cx.query_string()` (raw, no `?`). `cx.request_id()` is the request's id, sent back as `x-request-id`.

## Errors Are JSON
An error is JSON (else the app's `+error.wisp`, else Wisp's default page) when the request:

- targets a `+server.rs` (or an unmatched path under a first segment with endpoints and no pages);
- is under `/api`, sent JSON, or prefers JSON by `Accept`;
- has no `Accept` and is not a browser navigating.

An app with no pages always answers JSON.

```json
{"status": 422, "code": "invalid", "error": "title: must have at least 1 character",
 "errors": {"title": "must have at least 1 character"}}
```

- `errors` only for invalid input.
- `code`: the status's (`bad_request unauthorized forbidden not_found method_not_allowed conflict precondition_failed too_large unsupported_media_type invalid rate_limited internal unavailable`) or your own: `Error::new(409, "That email is taken").with_code("email_taken")`.
- `error` is your message, else the status name.
- `accept: application/problem+json`, or `WISP_PROBLEM_JSON=on`, gives RFC 9457 (`type`, `title`, `status`, `code`, `detail`, `errors`).
- Covers 404, 405, `error(403, "…")` and panics (500; details in dev only).

## Webhooks

```rust
// src/routes/hooks/github/+server.rs
fn post(cx: &mut Cx, body: Value) -> Result {
    cx.need_signature("GITHUB_SECRET", "x-hub-signature-256")?; // 401 unless it matches
    Ok(())
}
```

- HMAC-SHA256 of the body with the secret in that variable, hex (with or without `sha256=`) or base64 (Shopify).
- Stripe's `stripe-signature` (`t=…,v1=…`) signs the time too and is refused after five minutes.
- Other schemes: `wisp::hex(&wisp::hmac_sha256(secret, message))`, `wisp::secure_eq`.

## Idempotent Retries
A POST with `Idempotency-Key` retried gets the first answer back with `idempotent-replayed: true`, kept a day per key, path and `authorization`. The same key with another body is 422, one still in progress 409. No header, nothing kept.

## Big Lists

```rust
fn get() -> Response {
    Response::ndjson(|out| async move {
        for page in 0.. {
            let rows = db::page(page).await;
            if rows.is_empty() {
                break;
            }
            // stops once the client left
            for row in rows {
                out.line(&row).await?;
            }
        }
        Ok(())
    })
}
```

## Versions, CORS
- Versions are folders (`api/v1/notes`), or `cx.header_or("x-api-version", 1)`. `(group)` folders don't change URLs. `[id=int]` 404s `/api/notes/abc` before any code runs.
- `cx.cors("*")?` in `before` (a preflight is the `Err` it returns), or `const CORS: &str = "*";`.
- Allowed sites: `"https://app.example.com https://example.com"` (which may then send cookies); a site not allowed gets no CORS headers.
- Some paths only: `if cx.path().starts_with("/api/") { cx.cors("*")?; }`.

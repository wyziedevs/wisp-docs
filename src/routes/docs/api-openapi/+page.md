---
title: OpenAPI and tests
description: The generated OpenAPI document and docs page, and testing an API.
group: APIs
order: 43
---

## OpenAPI and docs page
The build describes the app as OpenAPI 3.1 at `/_wisp/openapi.json`; `/_wisp/docs` lists it with a try-it form. On in dev, off in release; `WISP_API_DOCS=on|off` overrides. Nothing to annotate:

- Every `+server.rs` endpoint, and a `#[derive(Rest)]` type's routes and its `/[id]`: path, query and header parameters, `body: T` (JSON) or form fields by name and type, what it returns (`Option` adds a 404, `()` a 204), and `default`, 400, 401, 422 error answers (`Error`, and RFC 9457 `Problem`).
- A resource also has its `if-match`/`if-none-match`/`idempotency-key` headers, `etag`, `location` and `x-total-count`, a filter parameter per plain field, and a 201 for POST.
- Every page as a GET of `text/html`, and each `#[action]` of its `+page.rs` as a POST: `/contact` for `fn default`, `/contact?/send` for the others (OpenAPI has no other place for `?/name`), a form body (`multipart/form-data` with an `Image` or `Upload`), checks from `#[validate]`, 200/303/422.
- Types from the route file or `src/*.rs` by field: structs as objects (`Option` is also `null`, `#[validate]` limits become `minLength`, `maximum`, `format: email`...), an enum without fields as its variant names. Others are named and left open.
- Security: `bearer` (HTTP bearer) and `session` (the cookie) are declared when used. Marked on a `#[rest(key|write|admin = "...")]` route as its keys need, and on a handler or action whose body calls `need_bearer`/`bearer()` or `signed_in`/`user`. A `fn before` in `src/hooks.rs` that does the same marks every operation (only changes, if it looks at `cx.writes()`). It is read from the code, not run: a check inside a helper is not seen.
- A route with `[[opt]]` or `[...rest]` is two paths. Paths that differ only by parameter names (`[n=int]`, `[slug]`) are one to OpenAPI: the first is shown.

`wisp openapi` prints the same document, indented (`-o openapi.json` writes it). Commit that file and run `wisp openapi --check` in CI: it fails with the command to run when the file is not what the app describes now.

### TypeScript client
Typed, from the same description, no dependencies: `/_wisp/client.ts`, or `wisp build --client ts [--out web/api.ts]`:

```ts
import { client, WispError } from './client';
const api = client({ base: 'https://api.example.com', token: key });
const note = await api.postApiNotes({ title: 'Tea' });
const page = await api.getApiNotes({ sort: '-created_at', limit: 20 });
try { await api.deleteApiNotesId(note.id); }
catch (e) { if (e instanceof WispError && e.code === 'not_found') {} }
```

Method name = HTTP method + path; PATCH takes a Partial; fields that may be left out are optional.

## Tests
In process, no port, same routing, hooks and errors:

```rust
#[test]
fn notes() {
    let mut app = wisp::test::client::<App>();
    app.bearer("dev-key"); // every request from now on
    let made = app.post_json("/api/notes", r#"{"title": "Buy tea"}"#);
    assert_eq!(made.status, 201);
    let note: Note = made.json(); // any FromJson type; Value for any JSON
    assert_eq!(app.post_json("/api/notes", r#"{"title": ""}"#).status, 422);
}
```

- Also `get put_json patch_json delete post_form send_json(method, url, json)`, `send(Request)`, `next_chunk` (events as sent).
- `header(name, value)` applies to the next request only (`if-match`, `idempotency-key`).
- Tables are in memory.

### In a browser
With feature `browser` (new apps have it; `wisp test --browser`) a test drives real headless Chrome or Edge over the DevTools protocol; no Node.

```rust
#[test]
fn counter() {
    let mut b = wisp::browser!(App); // the app on a free port, and a browser
    b.goto("/");
    b.click("text=Plus One");
    assert_eq!(b.text("output"), "1");
}
```

`goto(path) click(sel) hover(sel) fill(sel, text) press(key) text(sel) attr(sel, name) count(sel) wait(sel) eval(js) -> Value url() screenshot(path) timeout(d)`

- Selectors: CSS, or `text=Plus One` (innermost element whose text, `aria-label` or `title` contains it, any case).
- Actions wait for the element (there, visible, enabled, uncovered) and for the page to settle; a wait over 5 s fails with the address and DOM.
- Browser: `$WISP_BROWSER`, else Chrome, Edge, Chromium or Brave; none: `browser!` returns and the test passes, skipped. `wisp::test::browser::<App>()` is an `Option<Browser>`.
- `--no-sandbox` on Linux.

## Where it runs
All of this works in the binary, Docker, Lambda and `tower`. JSON, validation, errors, CORS, auth, webhooks and docs work everywhere. The edge (`--target cloudflare` etc.) runs each request in an instance that may be its own:

- `wisp::channel`, `wisp::every`, `RateLimit` are not there; WebSockets answer 501 (use the host's rate limiting).
- Jobs (`cron`, `work`) run from the host's cron triggers ([/docs/deploy](/docs/deploy)).
- Tables are per-instance memory.

Dev logs every request, release logs failures. Pass a proxy's request id back: `cx.set_header("x-request-id", id)` in `before` (`WISP_LOG=json`: AGENTS.md).

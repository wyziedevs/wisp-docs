---
title: Server Functions and Errors
description: Call Rust from the browser with Wisp server functions, turn server rendering off for a page, and see how errors and source maps behave in client code.
group: Browser Code
order: 34
---

## Server Functions
`#[remote]` on a Rust fn in a page block or `src/*.rs` makes it callable from browser code: no endpoint, fetch or import. In `src/lib`: `import { user } from 'wisp:remote'`.

```html
---
let name = "";
#[remote]
fn user(id: u64) -> Result<User> {
    USERS.get(id).map(|r| r.value).or_404()
}
---

<button on:click="user(5).then((u) => (name = u.name))">Load</button>
<p>{:name}</p>
```

- POST `/_app/r/<hash>`, arguments a JSON object by name (`{"id":5}`), read with `FromJson`; a wrong type or failed `#[validate]` is a 422 by field.
- Answers like an endpoint (`Json` value; `None` is 404; nothing is 204, `undefined`). Built like an action (`cx`, `async`, `-> Result` implied); same-origin check and `before` run first.
- Errors reject with `status`, `message` (and `errors` for 422); `redirect("/x")` navigates.
- `#[remote(get)]`: GET, arguments as JSON in the query (`?id=5&q=%22tea%22`; non-JSON text is a string), with an `etag` (304).
- Names are global to browser code: a duplicate, or one JS/Wisp has (`fetch`, `goto`), is a build error; a script's own or a page's server value of that name wins. `wisp check --types` types each.

## Server Rendering Off
`const SSR: bool = false;` in the block: the server runs the statements and sends layouts, `<head>`, the markup as an unpainted `<template>` and the values it names; the browser draws it.

- The markup is browser code (`{:x}`, `{:#each}`): `{…}`, `{#if}`, `{#each}` or a component given `{…}` is a build error (Rust is fine in `<title>`/`<head>`).
- For pages that depend on the browser (size, `localStorage`) or that `+page.js` fills.
- `wisp build --spa` serves them from a static host.

## Errors and Source Maps
- An error thrown while a script starts, or in `+page.js`, shows the nearest `+error.wisp`; handler errors go to the console with file and line.
- In dev each browser module has `//# sourceMappingURL=t3.js.map` (also `src/lib`, `+page.js`), so DevTools shows the `.wisp` file.
- Release has none unless `wisp build --sourcemap` (`--static --sourcemap` writes them beside the modules).

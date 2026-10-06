---
title: Actions, Forms and UI
description: Handle forms in Wisp with actions and validation, follow the request flow, accept file and image uploads, serve files, and use the built-in UI.
group: Design
order: 14
---

```html
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
{#each TODOS.all() as todo}
  <p>{todo} <button action="?/remove&id={todo.id}">Delete</button></p>
{/each}
```

## Actions

- `action="?/like"` posts to the `like` action and adds `method="post"` when missing.
- A form that posts to `?/name` needs `#[action] fn name` in the same page: the build says so when it is missing (a layout or component may post to the page that uses it, so only a page's own markup is checked).
- A form with no `action` (and `method="post"`) posts to `default`.
- `<button action="?/remove&id={todo.id}">` outside a form becomes its own `<form method="post"><button formaction="...">`. Works without JS.
- A page writes the actions its markup names: `#[action] fn add(todo: Todo) { TODOS.add(todo); }` and `#[action] fn remove(id: u64) { TODOS.remove(id); }` serve `<form action="?/add" fields />` and `<button action="?/remove&id={todo.id}">`.
- `<form fields>` writes a labelled input per parameter of the action (`fields={post}` starts them from `post`); text with `#[validate(one_of = "draft live")]` is a `<select>` of those. A `fields` form with no button gets one: `Send` for `fn default`, `Save` with `{post}`, else the action's name; `<form fields />` is the whole form and `<form fields="Log in" />` names its button.
- Query parameters in an action URL are read like form fields (`id` above is `id: u64`).
- A body with `.await` makes the action `async` (`#[action]` adds it); never write `async` there.
- Cookies, sessions and sign-in: [Cookies and sign-in](/docs/design-sessions/).

## Validation

- Parameter rules: `#[validate(...)]` with `len`, `min`, `max`, `min_len`, `max_len`, `email`. Same as a `FromJson` field. A `Password` (a parameter, a remote argument or a field) with no `min_len` or `len` of its own is held to 8 characters, on the server and as the input's `minlength`; `#[validate(min_len = 12)]` changes it.
- Every parameter is read and checked first, so one 422 lists each failure by field (`wisp::rt::input::read`), from a form or a JSON body.
- A parameter may be a struct with `#[derive(FromJson)]` or `Rest` (`fn default(post: Post)`). Fields are read by name (text by the field's type, blank field = missing) or from JSON, and checked by their own `#[validate]` (`wisp::rt::input::whole`).
- A failure, or `return invalid("text", "...")`, shows the page again as a 422.

On that 422 page:

- Each named `<input>`, `<textarea>`, `<select>` of the form whose action refused shows what was sent (`wisp::rt::kept`) instead of its own value, then `<small class="problem">...</small>` (`wisp::rt::problem`), one per problem of the field. A checkbox or radio is ticked when its value was sent (`wisp::rt::ticked`; left out is unticked), and a `<select multiple>` selects every value sent (`wisp::rt::sent`). Only that form: another form on the page, even one sharing a field name, shows its own values and no problems.
- A field with a problem says so: `aria-invalid="true"`, and when it has an `id`, `aria-describedby="{id}-problem"` naming its `<small>` (`wisp::rt::invalid`).
- A checkbox or radio shows its problem too (a box that must be ticked: `return invalid("terms", "...")`), after the last input of its name in the form; a group written inside a block (`{#each}`) gets it once, before `</form>`.
- Own value forms: `value={post.title}`, or `value="text"` (same node, position in the tag does not matter). A hole inside, `value="a{b}"`, is a build error. Textarea content works; `<select value={post.kind}>` marks the matching option `selected`; a checkbox's or radio's own state is `checked` or `checked={cond}`.
- Passwords and files show the problem but are never sent back. Hidden inputs, component inputs and fields with `bind:value` or `bind:checked` are left alone.
- `{cx.problem("text")}` places that field's `<small>` yourself (nothing when none); none is added then, and the field is not described by it.
- A GET has neither; use an `if` on `cx`'s locals (none) so the page can still be baked. On a GET, or a post that passed, each of these is one inlined test of the refusal (`None`) per field: no lookup, no allocation.

Browser-side checks come from the same rules (`wisp_build::rules::Native`). A field that an action of the page reads gets, as static text, only attributes the server also checks:

<div class="table-wrap">

| Attribute | Added when |
|---|---|
| `required` | blank is refused (struct field, number, `Email`, `Image`, text whose rules refuse it) |
| `type="email"` | `email` rule (WHATWG check, same as the server) |
| `minlength` | `min_len` (UTF-16 units are never fewer than characters) |
| `pattern="[\s\S]{0,N}"` | max length (`maxlength` would count an emoji twice) |
| `min` / `max` | `type="number"` input |

</div>

A textarea gets `required`, and `minlength` when `#[validate(min = N)]` has N above 1, never `maxlength` (the browser counts UTF-16 units and line breaks as two characters). The server still checks everything.

## Request Flow

1. Same-origin check: `Origin`, if present, must match `Host` (else 403). Without it, `Sec-Fetch-Site` other than `same-origin` or `none` is 403. A client sending neither (curl) passes.
2. The action runs. `redirect("/...")` is a 303; other errors go to the error page. For `wisp.js` (requests carry `x-wisp`) a redirect is a 200 with `x-wisp-location` and the script navigates itself (fetch would follow with the post's headers, and not at all to another site).
3. On success the page's `load` runs and renders as normal. Without JS the browser shows it.
4. `wisp.js` intercepts the submit, sends it with `fetch`, and morphs `<body>` in place (keyed by `id`), so focus, scroll and unrelated inputs survive.

`wisp.js` details:

- A redirect to the same path updates the URL with `history.pushState`; elsewhere it loads that page. A non-HTML response (file, JSON) is shown as the browser would.
- The submit button is disabled while the request is out and re-enabled before the morph. A second submit of the same form meanwhile (Enter twice) is dropped.
- Forms are read through attributes and `HTMLFormElement.prototype` (a field named `action` or `reset` hides the property).
- Sent as the browser would: `multipart/form-data` forms as multipart with files, others urlencoded.
- Forms with another target, and posts that fail on the network, are left to the browser.
- After each morph the document gets a `wisp:update` event (for scripts setting up what the morph brought in).
- `data-wisp-keep` on an element leaves its children and attributes alone (a map, a rich text editor).
- A post that redirects loads the page so its scripts run as on any load. A script a morph brings into the same page (inside an `{#if}`) runs once, the first time it appears.

## Forms and Files

- `cx.form()` reads urlencoded and multipart bodies (`enctype="multipart/form-data"` for files). Text fields read the same either way.
- `cx.form().file("photo")` is the file of `<input type="file" name="photo">` (`None` when none): `name` as sent without folders or trailing dots and spaces (a Windows device name such as `CON` gets a `_` in front), `content_type`, `bytes`. `files("photo")` is every file of a `multiple` input.
- File name and type are visitor input: the name is never a path (a drive such as `C:` and an NTFS stream such as `:stream` are dropped too), the type says nothing the bytes do not.
- Uploads are held in memory; a route taking large ones raises its own `BODY_LIMIT`.

### Images

`avatar: Image` (or `Option<Image>`, may be empty) is an action parameter.

- Max 2 MB (`wisp::MAX_SIZE`) unless `#[validate(max_size = 5 * MB)]`. The build adds each action's `max_size` to the page's body limit; no `BODY_LIMIT` needed.
- The build gives the form `enctype="multipart/form-data"` and the input `accept="image/*"`.
- Kind comes from the first bytes: PNG, JPEG, GIF, WebP or AVIF. Anything else (SVG included, it can carry script) or over `max_size` shows the page again as a 422 with the problem by the field.
- Cloning shares the bytes. In a saved table it is a `data:` URL (its JSON).
- As a response: `fn get(id: u64) -> Option<Image> { USERS.get(id)?.value.avatar }` in `avatars/[id=int]/+server.rs` sends bytes and type with an ETag (304 when matched), `no-cache`, `nosniff`. Any response with an `etag` answers a matching `if-none-match` GET with 304.

### Serving Files

```rust
// [...name]/+server.rs
async fn get(name: String) -> Result<Response> {
    Response::file_in("uploads", &name).await
}
```

- `Response::file_in(dir, name)` reads without blocking, typed by extension. A name reaching outside the directory (`..`, absolute path, drive, a Windows device such as `nul` or `CON.txt`, a name Windows trims such as `a.txt.` or `a.txt `) is a 404, like a missing file. Static files get the same rule. The name may come straight from the URL.
- `Response::download("report.csv", bytes)` sends bytes the browser saves as that file name.

## Built-In UI

Wisp draws a few things from one design system: dark tokens, as the demo site has, with Wisp violet (`#896ce0`) as the only accent, used on what is interactive. It has one-pixel hairlines, two shadow steps, one type scale and one focus ring.

Styles live in `crates/wisp/src/client/tokens.css` (the one source of tokens), `ui.css` (buttons), `error.css` and `dialog.css` (dev only). All are `--wisp-*` tokens and `.wisp-*` classes, so they never touch app CSS.

<div class="table-wrap">

| Piece | What it is |
|---|---|
| Error page | For apps without `+error.wisp`. Status and one line (status name, or the error's message when it says more), centered, dark tokens, styles inlined. No links or buttons; write a `+error.wisp` for those. Errors for endpoints and API clients are JSON (see [APIs and platforms](/docs/api/)). |
| Error page in `wisp dev` | Adds the status name, the request, what caused a 5xx and a link home. |
| Server errors in dev | Every answer has `Server-Timing: total;dur=ms`, split into `before`, `handler` and `render` (`WISP_SERVER_TIMING=on` asks for the total in release too). A 5xx dev page holds its message (a panic says `file:line`) in `<template id="wisp-server-error">`, which `wisp-dev.js` opens in the dialog below. Debug builds only. |
| Build error dialog (dev) | Title, one sentence on where to look (`Error in src/routes/+page.rs on line 7.`), then the error in a code block with Copy. Lives in a shadow root off `<html>`, so app CSS and morphs cannot touch it. Closes when the next build succeeds. |
| Rebuild bar | A two-pixel accent line across the top once a rebuild has taken 200 ms. |
| Terminal | Every status line has a mark and words: `✓` done (green), `!` needs a look (yellow), `✗` failed (red), `›` under way and `~` changed (dim). Violet is only for what can be typed. A failure is a sentence, then the reason or fix indented under it. |

</div>

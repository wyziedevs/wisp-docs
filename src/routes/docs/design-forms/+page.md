---
title: Actions, forms and cookies
description: Actions, form handling, validation, uploads and cookies.
group: Design
order: 17
---

## Actions and `wisp.js`

`<form action="?/like">` posts to the `like` action: an `action` that starts
with `?/` adds `method="post"` when the form does not say. A form with no
`action` (and `method="post"`) posts to the action named `default`. A
`<button action="?/remove&id={todo.id}">` that is not in a form becomes a
form of its own, `<form method="post"><button formaction="…">`: the
one-button forms a list's delete and toggle buttons are, which work without
JavaScript. Query parameters in an action's URL are read like form fields,
so `id` above is the action's `id: u64`.

An action checks its input on its parameters, as a `FromJson` field does:
`#[action] fn add(#[validate(len = 1..=100)] text: String)` (and `min`,
`max`, `min_len`, `max_len`, `email`). Every parameter is read and checked
before the answer, so one 422 lists each that does not pass, by field
(`wisp::rt::input::read`), from a form or a JSON body. A parameter may be a
struct with `#[derive(FromJson)]` or `Rest` (`fn default(post: Post)`): its
fields are read by name, from the form (text read by the field's type, a
blank field missing) or a JSON body, and checked by its own `#[validate]`
rules (`wisp::rt::input::whole`). A value that does not pass, or `return
invalid("text", "…")`, shows the page again as a 422. There each named
`<input>`, `<textarea>` and `<select>` of the form (one posting to `?/name`,
or a `method="post"` one posting to `default`) shows what was sent
(`wisp::rt::kept`) instead of its own value (`value={post.title}`, or
`value="text"`, which becomes the same node as it is read, so it holds
wherever it is in the tag; one with a hole in it, `value="a{b}"`, is a
build error, never a value dropped; the textarea's content, a select's `value={post.kind}`, which marks the
option with that value `selected`), followed by what was wrong with it,
`<small class="problem">…</small>` (`wisp::rt::problem`); a password or
file shows its problem but is never sent back; checkboxes, radios and
hidden inputs are left alone, and so are the inputs of a component, which
has no request. A file that writes `cx.problem("text")` places that
field's message itself (`{cx.problem("text")}` is the same `<small>`, and
nothing while there is none), and gets none added for it. A GET never has
either, and takes an `if` on `cx`'s locals (none) per input, so they do
not stop a page from being baked.

The browser checks first what it can, from the same rules
(`wisp_build::rules::Native`): a page's form field that an action of the
page reads gets, as static text, the attributes whose check is one the
server makes too, so the browser never stops what the server would take:
`required` where blank is refused (a struct's field, a number, an
`Email`, an `Image`, text whose rules refuse it), `type="email"` (the
server's check is WHATWG's), `minlength` (UTF-16 units are never fewer
than characters), the most length as `pattern="[\s\S]{0,N}"` (`maxlength`
would count an emoji twice), and `min`/`max` on a `type="number"` input.
A textarea gets only `required` (its line breaks are sent as two
characters). The server still checks everything.

An action's body that has `.await` makes it `async` (`#[action]` adds the
word and the build awaits the call), so `async` is never written there.

Flow:

1. Same-origin check: if `Origin` is present it must match `Host` (403
   otherwise); without it, a `Sec-Fetch-Site` other than `same-origin` or
   `none` is a 403 too. A client that sends neither (curl) is let through.
2. The action runs. `redirect("/…")` → 303. Other errors → error page. For
   `wisp.js` (its requests carry `x-wisp`) a redirect is a 200 with
   `x-wisp-location`, and the script goes there itself: fetch would follow it
   with the post's own headers, and to another site (a payment page) not at
   all.
3. On success the page's `load` runs and the page is rendered as a normal
   response. Without JS the browser just shows it.
4. `wisp.js` intercepts the submit, sends it with `fetch`, then morphs `<body>`
   in place (keyed by `id`), so focus, scroll and unrelated inputs survive.
   A redirect to the same path updates the URL with `history.pushState`; one
   anywhere else loads that page. A response that is not HTML (a file, JSON)
   is shown as the browser would. The submit button is disabled while the
   request is out and re-enabled before the morph, so the new page decides its
   final state; a second submit of the same form meanwhile (Enter pressed
   twice) is dropped. Forms are read through attributes and
   `HTMLFormElement.prototype`, since a field named `action` or `reset` hides
   the form's property of that name. A form is sent as the browser would
   send it: a `multipart/form-data` one as multipart, files included, and any
   other urlencoded. Forms with another target are left to the browser, and
   so is a post that fails on the network.
5. After each morph the document gets a `wisp:update` event, for scripts that
   set up what the morph brought in. An element with `data-wisp-keep` is
   left as it is, children and attributes, for a widget that owns its own
   DOM (a map, a rich text editor).

## Forms and files

`cx.form()` reads either kind of form body: urlencoded, and multipart, which
is how a form with `enctype="multipart/form-data"` sends files.
`cx.form().file("photo")` is the file chosen in `<input type="file"
name="photo">` (`None` when none was), with its `name` as the browser sent it,
its `content_type` and its `bytes`; `files("photo")` is every file of a
`multiple` input. Both are visitor input: the name is never a path, and the
type says nothing the bytes do not. Text fields read the same either way.
Uploads are held in memory, so a route that takes large ones raises its own
`BODY_LIMIT` rather than the whole app's.

A picture is an action parameter: `avatar: Image` (or `Option<Image>`, which
may be left empty). It takes at most 2 MB (`wisp::MAX_SIZE`) unless
`#[validate(max_size = 5 * MB)]` says another size. The build gives its form
`enctype="multipart/form-data"` and its file input `accept="image/*"`. Its kind is what its
first bytes say, never what the browser claimed: PNG, JPEG, GIF, WebP or
AVIF. Anything else, SVG included (it can carry script), and a file over
`max_size`, show the page again as a 422 with the problem by the field. The
build adds each action's `max_size` to the page's body limit, so no
`BODY_LIMIT` is written for it. An `Image` shares its bytes when cloned, is
kept in a saved table as a `data:` URL (its JSON), and is a response as
itself: `fn get(id: u64) -> Option<Image> { USERS.get(id)?.value.avatar }`
in `avatars/[id=int]/+server.rs` sends its bytes and type with an ETag
(304 when the browser has them), `no-cache` and `nosniff`. Any response
with an `etag` answers a matching `if-none-match` GET with a 304.

To serve saved files back, `async fn get(name: String) -> Result<Response> {
Response::file_in("uploads", &name).await }` in a `[...name]/+server.rs`
reads one from the directory without blocking, typed by its extension.
`Response::download("report.csv", bytes)` sends bytes the browser saves as
a file of that name. The name may come straight from the URL: one that
would reach outside the directory (`..`, an absolute path, a drive) is a
404, like a file that does not exist.

## Cookies

State that belongs to one visitor goes in a cookie: `cx.set_cookie(name, value)`
sets it site-wide for 400 days, `HttpOnly`, `SameSite=Lax` (the value is any
`Display`; an empty one deletes it), and `cx.cookie(name)` reads it back within
the same request (`cx.cookie_or(name, default)` parses it as any `FromStr`), so
the `load` that runs after an action sees what the action stored.

`cx.set_signed_cookie(name, value)` adds an HMAC-SHA256 signature of the name
and value (`value.signature`), keyed with `WISP_SECRET`; `cx.signed_cookie(name)`
is the value only if the signature holds, so a visitor can read it but not
make one up, change it, or move it to another cookie's name. That is enough
to say who is signed in. A release build without `WISP_SECRET` fails the
request that signs or checks one, saying to set it; dev builds keep a secret
in `.wisp/secret` so sessions survive restarts. To change the secret without
signing everyone out, move the old one to `WISP_SECRET_OLD`: signatures it
made still hold (nothing new is signed with it) until it is removed, 30 days
on for sign-ins.

Signing in is built on that. For a `#[model]` with a `hash` field and an
`email` or `name` (an `Account`), `cx.signup(row).await?` hashes the
password in `row.hash`, refuses a taken name with a 422 and signs in, and
`cx.login(&email, &password).await?` checks it as slowly for a name
no one has; `wisp::signup` and `wisp::login` do the same without a `Cx`. `cx.sign_in(id)` (a row id of the app's users)
sets the signed cookie `session` to the id and the time, for 30 days;
`cx.signed_in()?` is the id, and signed out (or 30 days on) it is the error
that sends the visitor to sign in: a 303 to `/login`, or a 401 for a JSON
client. `cx.user()?` is the row itself, the same way. A members' page
starts with `let me = cx.user()?;`. `user`, `login` and `signup` take the
users table for you: the lone `Table` of a model with a `Password` field in
`src/db.rs`, else the one `wisp::users(&db::USERS)` names in `init`; the build
adds it (`&USERS` first still works, and is how a second table is used).
`cx.signed_in().ok()` asks without
sending anyone anywhere; `cx.sign_out()` ends it. The page at `/login` is
the convention; `wisp::sign_in_page("/enter")` in `init` names another.
`sign_in` always sets a new session, so one planted on a visitor before
they sign in never becomes theirs.

A signed session is valid wherever it is sent, so `cx.sign_out()` cannot
end a copy someone stole. `wisp::sign_out_everywhere(id)` can: it counts
up the id's sign-outs in the saved table `wisp_sign_outs`, and a session
made after carries the count (`id.time.count`; none while it is 0), so
every older one no longer matches. Reading a session looks the count up
in memory, and not at all while no one has ever signed out everywhere (an
atomic flag says so). The table is read when the server starts (not at
all while it has no log file, so an app that never signs anyone out makes
none); with the app's own store (`wisp::store`), which instances can
share, a thread reads it again every 30 s and the higher count of each id
wins, so a sign-out on one instance holds on all within that. Log files
are each instance's own. A store that cannot be read leaves sessions as
they were rather than failing them, says why, and is tried again;
`sign_out_everywhere` then returns its `Err`, saying why: a security
action fails as a value, never by a panic.

Passwords are kept as `wisp::password::hash(&password).await?`, checked with
`wisp::password::check(&typed, hash).await?` (`hash` an `Option<&str>`:
`None` for no such user hashes a stand-in, as slow, so the time does not
say which names exist; a full hashing queue, about 3 s of work counted in
rounds, so hashes planted with many cannot make the wait longer, is a 503
with `retry-after`; that keeps the machine answering through a flood, and
a `RateLimit` on the sign-in action is what stops one): PBKDF2-HMAC-SHA256 on the same
HMAC, 600,000 rounds (OWASP), a random 16-byte salt, written as
`$pbkdf2-sha256$i=600000$salt$key` so the count can be raised later and old
hashes still check; `wisp::password::outdated(&hash)` says when one was made
with fewer rounds, to hash again once the password checks. A stored hash
naming more than 10,000,000 rounds is refused rather than computed. The key's padded blocks are hashed once and each round
is two SHA-256 compressions of one fixed-shape block, with no allocation:
a hash is a fraction of a second of one core, on purpose. It runs on a
thread kept for hashing (one per two cores, started with the first hash),
never the worker's: a worker held for 0.2 s would stall every connection
on its core, and a flood of sign-ins takes at most half the machine. The
edge build, which has no threads, hashes in place.

`cx.set_cookie_with(name, value, CookieOptions { … })` takes the rest: a
`max_age` (`None` ends it with the browser), `script_readable`, `same_site`
(`Lax`, `Strict`, `None`), `path`, `domain`, and `signed`. Cookies get
`Secure` when the request came over HTTPS through a proxy
(`x-forwarded-proto: https`) or `ORIGIN` is `https://`, and always with
`SameSite=None`, which browsers require.

A struct of such values goes in one cookie with `#[derive(Cookie)]`, which
writes its `Display` and `FromStr`: the fields in order, separated by `|`,
each escaped for a cookie (`42|cranesloth|pi`); an enum without fields is its
variant's name. The derive reads only the type's name and field names, with
no `syn`. What comes back is visitor input, so a type with rules beyond its
field types checks them after reading (Wisple's `Game::valid`).

A post that redirects to another page loads that page, so its scripts run as
on any load; a script that a morph brings into the same page (one inside an
`{#if}`) runs once, the first time it appears.

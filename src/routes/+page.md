---
title: Wisp, a fast, fun web framework for Rust
description: A fast, fun web framework for Rust. File routes, .wisp templates compiled to Rust, form actions, one binary.
noindex: false
---

<Hero />

<section class="showcase">
<div class="wrap">
<div class="pair">
<figure class="file">
<figcaption>src/db.rs</figcaption>

```rust
#[model]
pub struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
pub static TODOS: Table<Todo> = Table::saved();
```

</figure>
<figure class="file">
<figcaption>src/routes/+page.wisp</figcaption>

```html
---
#[action]
fn add(todo: Todo) {
    TODOS.add(todo);
}

let count = TODOS.len();
---
<title>Todos ({count})</title>
<form action="?/add" fields><button>Add</button></form>
{#each TODOS.all() as todo}
  <p>{todo.text}</p>
{/each}
```

</figure>
</div>
<p class="note">A model, a saved table, a validated form action and a list. No imports, no router file, no handler wiring.</p>
</div>
</section>

<Band id="routes" title="Files are routes" lead="A folder is a URL, and its +page.wisp is the page. Brackets make parameters, groups stay out of the address, and a +server.rs next to a page is an endpoint.">

```text
src/routes/
  +layout.wisp          wraps every page
  +page.wisp            /
  blog/
    +page.wisp          /blog
    [slug]/+page.wisp   /blog/hello
  api/notes/+server.rs  /api/notes
  docs/intro/+page.md   /docs/intro
```

</Band>

<Band id="forms" flip title="Forms that work without JavaScript" lead="A form posts to an action. A bad value is a 422 that shows each problem beside its input and keeps what was typed. Turn JavaScript off and it still works; leave it on and the page morphs instead of reloading.">

```html
---
#[action]
fn signup(email: Email, #[validate(min_len = 8)] password: Password) {
    cx.signup(User { email, password }).await?;
    redirect("/me")
}
---
<form action="?/signup" fields>
  <button>Sign up</button>
</form>
```

</Band>

<Band id="reactive" title="Reactivity in the same file" lead="The block is Rust that runs for each request, name is drawn on the server, and the count is JavaScript state in the browser. Turn JavaScript off and the server's HTML still works.">

```html
---
let name: String = cx.query_or("name", "world");
---
<h1>Hello, {name}!</h1>

<button on:click="count++">Clicked {:count} times</button>

<script>
  let count = $state(0)
</script>
```

</Band>

<Band id="binary" flip title="One binary" lead="Templates compile to plain Rust, and the whole app, styles and static files included, becomes one small binary. Copy it to a server, or let wisp service install keep it running.">

```bash
wisp build
./target/release/my-app

wisp service install
```

</Band>

<Band id="hosts" title="Host anywhere" lead="The same app builds as a server binary, a container, a folder of static HTML, or for an edge or serverless host. wisp deploy init writes the GitHub Actions workflow.">

```bash
wisp build --static
wisp build --docker
wisp build --target cloudflare
wisp deploy init cloudflare
```

</Band>

<section class="strip">
<div class="wrap">
<h2 class="sr">Hosts</h2>

<Hosts />

</div>
</section>

<section class="band fast" id="fast">
<div class="wrap">
<div class="claim wide">

## Fast, and cheap to write

On a server-rendered HTML page (the TechEmpower fortunes test without the database) on a 4-vCPU Linux VPS with 64 connections, Wisp serves 97,502 requests a second at 19.8 CPU microseconds each and 3 MB of memory. A whole app takes about half the tokens of SvelteKit or Next.js to write. A bigger one, with sign in, a posts table, uploads and live refresh, is 995 tokens: 3.4x less than SvelteKit and 3.2x less than Next.js.

</div>

<Speed />

<p class="note">Bench of 2026-09-28 and the token counts come from the Wisp repository: <a href="/docs/overview#performance">performance</a> and <a href="/docs/tokens">how tokens are counted</a>.</p>
</div>
</section>

<section class="final">
<div class="wrap">

## Make something

```bash
wisp new my-app
cd my-app
wisp dev
```

<p class="cta"><a class="btn primary" href="/docs">Read the docs</a> <a class="btn" href="https://github.com/wyziedevs/wisp">Star Wisp on GitHub</a></p>
</div>
</section>

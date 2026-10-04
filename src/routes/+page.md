---
title: Wisp, a fast, fun web framework for Rust
description: A fast, fun web framework for Rust that costs an AI the fewest tokens to write. One page, one binary.
---

<Hero />

<section class="showcase">
<div class="wrap">

<Demo>

<div class="pane" id="pane-page" role="tabpanel" aria-labelledby="tab-page">

```html
---
#[action]
fn add(todo: Todo) {
    TODOS.add(todo);
}
#[action]
fn remove(id: u64) {
    TODOS.remove(id);
}
---
<title>Todos ({TODOS.len()})</title>
<form action="?/add" fields><button>Add</button></form>
{#each TODOS.all() as todo}
  <p>{todo.text} <button action="?/remove&id={todo.id}">Remove</button></p>
{/each}
```

</div>
<div class="pane" id="pane-db" role="tabpanel" aria-labelledby="tab-db">

```rust
#[model]
pub struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
pub static TODOS: Table<Todo> = Table::saved();
```

</div>

</Demo>

<p class="note">The form writes its own inputs and errors, and a bad value is a 422 that keeps what was typed. The model in <code>src/db.rs</code> is in every route file with no <code>use</code> lines.</p>
</div>
</section>

<section class="band" id="fast">
<div class="wrap">
<div class="claim wide">

## Nothing extra on the hot path

A route pays only for the features it uses, and a change that touches the request path is checked by an instructions-per-request A/B before it lands. Wisp's first rule is that speed is never traded away for convenience.

<p class="cta left"><a class="btn" href="/docs/benchmarks">How speed is measured</a></p>

</div>
</div>
</section>

<section class="band cheap" id="cheap">
<div class="wrap">
<div class="claim wide">

## An AI writes the same app in half the tokens

AI writes most code now, and every token it reads and writes costs time and money. Wisp is built so an app costs the fewest: conventions instead of config, types the compiler infers, and forms that write themselves. The whole reference is one file, [llms.txt and AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), and `wisp mcp` serves it to coding agents.

</div>

<div class="pair">
<figure class="file">
<figcaption>Wisp: a contact form that validates, 89 tokens</figcaption>

```html
---
fn default(#[validate(len = 1..=50)] name: String, email: Email) {
    eprintln!("{name} <{email}>");
    redirect("/")
}
---
<title>Contact</title>
<form fields><button>Send</button></form>
```

</figure>
<figure class="file">
<figcaption>SvelteKit: the same form, 396 tokens</figcaption>

```js
// +page.server.js
import { fail, redirect } from '@sveltejs/kit';

export const actions = {
  default: async ({ request }) => {
    const form = await request.formData();
    const name = String(form.get('name') ?? '');
    const email = String(form.get('email') ?? '');
    const errors = {};
    if (name.length < 1 || name.length > 50) errors.name = 'Name must be 1 to 50 characters';
    if (!email.includes('@')) errors.email = 'Enter a valid email';
    if (errors.name || errors.email) return fail(422, { name, email, errors });
    console.log(`${name} <${email}>`);
    redirect(303, '/');
  }
};
```

```html
<!-- +page.svelte -->
<script>
  import { enhance } from '$app/forms';
  let { form } = $props();
</script>

<svelte:head><title>Contact</title></svelte:head>
<form method="POST" use:enhance>
  <input name="name" value={form?.name ?? ''} />
  {#if form?.errors?.name}<p>{form.errors.name}</p>{/if}
  <input name="email" value={form?.email ?? ''} />
  {#if form?.errors?.email}<p>{form.errors.email}</p>{/if}
  <button>Send</button>
</form>
```

</figure>
</div>

<div class="claim wide">

The same five features (a list page, a contact form, a JSON endpoint, a layout and a live search) written as a complete app in each stack:

| Stack | Tokens | Files |
|---|---:|---:|
| **Wisp** | **464** | 6 |
| SvelteKit | 928 | 9 |
| Next.js | 934 | 8 |
| Axum + askama | 1330 | 7 |
| Actix + tera | 1457 | 7 |

A bigger app, with sign up and in, a posts table, uploads, live refresh and a component, is 995 tokens in Wisp, 3368 in SvelteKit and 3220 in Next.js. The numbers come from `cargo run -p wisp-tokens`, which counts every hand-written file and its path with a byte-pair style estimate; the [Tokens page](/docs/tokens) has the method and the apps.

</div>
</div>
</section>

<Band id="forms" title="Forms that work without JavaScript" lead="A form posts to an action. A bad value is a 422 that shows each problem beside its input and keeps what was typed. With JavaScript on, the page morphs instead of reloading.">

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

<Band id="reactive" flip title="Reactivity in the same file" lead="The block is Rust that runs for each request, name is drawn on the server, and the count is JavaScript state in the browser. Turn JavaScript off and the server's HTML still works.">

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

<Band id="binary" title="One binary, on any host" lead="Templates compile to plain Rust, and the whole app, styles and static files included, becomes one small binary. Every fast path is proven at startup and falls back, and nothing after startup panics. The same app builds as a container, static HTML, or for an edge or serverless host.">

```bash
wisp build
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

<section class="final">
<div class="wrap">

## Make something

```bash
wisp new my-app
cd my-app
wisp dev
```

<p class="cta"><a class="btn primary" href="/docs">Read the docs</a> <a class="btn" href="https://github.com/wyziedevs/wisp">Wisp on GitHub</a></p>
</div>
</section>

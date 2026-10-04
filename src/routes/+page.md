---
title: Wisp, a Fast, Fun Web Framework for Rust
description: A fast, fun web framework for Rust that costs an AI the fewest tokens to write. One page, one binary.
---

<Hero />

<section class="sec showcase">
<div class="wrap">
<div class="sec-head">
<h2>A Page Is One File</h2>
<p>The form writes its own inputs and errors, and a bad value is a 422 that keeps what was typed. The model in <code>src/db.rs</code> is in every route file with no <code>use</code> lines.</p>
</div>

<Demo todos={&demo_todos(cx)}>

<div class="pane pane-1">

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
<div class="pane pane-2">

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

</div>
</section>

<Claim id="fast">

## Nothing Extra on the Hot Path

A route pays only for the features it uses, and a change that touches the request path is checked by an instructions-per-request A/B before it lands. Wisp's first rule is that speed is never traded away for convenience.

<p class="more"><a href="/docs/benchmarks">How Speed Is Measured</a></p>

</Claim>

<Claim id="measured">

## Measured, Not Claimed

TechEmpower's plaintext and JSON tests, run with their own load scripts against their reference sources of each framework, on one 4-vCPU VM with the server pinned to 2 cores. Medians of 3 runs of 15 seconds each.

<table class="tally">
<caption>Plaintext, 256 connections, pipelined</caption>
<thead><tr><th scope="col">Framework</th><th scope="col"><span class="sr">Relative speed</span></th><th scope="col" class="num">Req/s</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">1,129,577</td></tr>
<tr><th scope="row">Actix Web</th><td class="meter" aria-hidden="true"><span style="--v: 0.534"></span></td><td class="num">603,163</td></tr>
<tr><th scope="row">Axum</th><td class="meter" aria-hidden="true"><span style="--v: 0.245"></span></td><td class="num">276,948</td></tr>
<tr><th scope="row">Fastify</th><td class="meter" aria-hidden="true"><span style="--v: 0.046"></span></td><td class="num">51,713</td></tr>
<tr><th scope="row">Express</th><td class="meter" aria-hidden="true"><span style="--v: 0.036"></span></td><td class="num">40,421</td></tr>
<tr><th scope="row">Hono (Node)</th><td class="meter" aria-hidden="true"><span style="--v: 0.026"></span></td><td class="num">28,966</td></tr>
<tr><th scope="row">SvelteKit</th><td class="meter" aria-hidden="true"><span style="--v: 0.010"></span></td><td class="num">10,929</td></tr>
<tr><th scope="row">Hono (Bun)</th><td class="meter" aria-hidden="true"><span style="--v: 0.009"></span></td><td class="num">10,599</td></tr>
</tbody>
</table>

<table class="tally">
<caption>JSON, 64 connections</caption>
<thead><tr><th scope="col">Framework</th><th scope="col"><span class="sr">Relative speed</span></th><th scope="col" class="num">Req/s</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">96,089</td></tr>
<tr><th scope="row">Actix Web</th><td class="meter" aria-hidden="true"><span style="--v: 0.933"></span></td><td class="num">89,648</td></tr>
<tr><th scope="row">Axum</th><td class="meter" aria-hidden="true"><span style="--v: 0.816"></span></td><td class="num">78,427</td></tr>
<tr><th scope="row">Hono (Bun)</th><td class="meter" aria-hidden="true"><span style="--v: 0.620"></span></td><td class="num">59,619</td></tr>
<tr><th scope="row">Fastify</th><td class="meter" aria-hidden="true"><span style="--v: 0.229"></span></td><td class="num">21,965</td></tr>
<tr><th scope="row">Express</th><td class="meter" aria-hidden="true"><span style="--v: 0.153"></span></td><td class="num">14,746</td></tr>
<tr><th scope="row">SvelteKit</th><td class="meter" aria-hidden="true"><span style="--v: 0.108"></span></td><td class="num">10,378</td></tr>
<tr><th scope="row">Hono (Node)</th><td class="meter" aria-hidden="true"><span style="--v: 0.094"></span></td><td class="num">8,988</td></tr>
<tr><th scope="row">Next.js</th><td class="meter" aria-hidden="true"><span style="--v: 0.016"></span></td><td class="num">1,524</td></tr>
</tbody>
</table>

Wisp is first on plaintext at 256, 1,024 and 4,096 connections, 1.9 times Actix Web at 256. On JSON it is first at 3 of 6 levels and within the run-to-run noise of Actix Web and Axum at the rest; Actix Web is ahead at 16 and 256 connections. At 16,384 connections Wisp's default limit of 10,000 refuses the overflow, and most servers collapse there too. Next.js did not complete the plaintext run. This is not an official TechEmpower result: the VM is shared, and the gaps between the Rust servers are about the size of its noise.

<p class="more"><a href="https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md">Every Number, Including the Losses</a> &middot; <a href="/docs/benchmarks">How Speed Is Measured</a></p>

</Claim>

<section class="sec cheap" id="cheap">
<div class="wrap">
<div class="claim wide">

## Make the Same App with Half the Tokens

AI writes most code now, and every token it reads and writes costs time and money. Wisp is built so an app costs the fewest: conventions instead of config, types the compiler infers, and forms that write themselves. The whole reference is one file, [llms.txt and AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), and `wisp mcp` serves it to coding agents.

```bash
claude mcp add wisp -- wisp mcp
```

</div>

<div class="pair">
<figure class="cmp">
<figcaption>Wisp: a contact form that validates, 89 tokens</figcaption>
<div class="file">
<div class="tabs"><span class="tab">+page.wisp</span></div>
<div class="scroll" tabindex="0" aria-label="Wisp code">

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

</div>
</div>
</figure>
<figure class="cmp">
<figcaption>SvelteKit: the same form, 470 tokens</figcaption>
<div class="file tabbed">
<div class="tabs" role="radiogroup" aria-label="SvelteKit files">
<input class="sr" type="radio" name="sk-file" id="sk-server" checked>
<label for="sk-server">+page.server.js</label>
<input class="sr" type="radio" name="sk-file" id="sk-page">
<label for="sk-page">+page.svelte</label>
</div>
<div class="scroll pane pane-1" tabindex="0" aria-label="SvelteKit +page.server.js">

```js
import { fail, redirect } from '@sveltejs/kit';

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const actions = {
  default: async ({ request }) => {
    const form = await request.formData();
    const name = String(form.get('name') ?? '');
    const email = String(form.get('email') ?? '');
    const errors = {};
    if (name.length < 1 || name.length > 50) errors.name = 'Name must be 1 to 50 characters';
    if (!EMAIL.test(email)) errors.email = 'Enter a valid email';
    if (errors.name || errors.email) return fail(422, { name, email, errors });
    console.log(`${name} <${email}>`);
    redirect(303, '/');
  }
};
```

</div>
<div class="scroll pane pane-2" tabindex="0" aria-label="SvelteKit +page.svelte">

```html
<script>
  import { enhance } from '$app/forms';
  let { form } = $props();
</script>

<svelte:head><title>Contact</title></svelte:head>
<form method="POST" use:enhance>
  <label>Name <input name="name" required minlength="1" maxlength="50" value={form?.name ?? ''} />
    {#if form?.errors?.name}<small class="problem">{form.errors.name}</small>{/if}</label>
  <label>Email <input name="email" type="email" required value={form?.email ?? ''} />
    {#if form?.errors?.email}<small class="problem">{form.errors.email}</small>{/if}</label>
  <button>Send</button>
</form>
```

</div>
</div>
</figure>
</div>

<div class="claim wide">

The same five features (a list page, a contact form, a JSON endpoint, a layout and a live search) written as a complete app in each stack:

<table class="tally">
<thead><tr><th scope="col">Stack</th><th scope="col"><span class="sr">Relative size</span></th><th scope="col" class="num">Tokens</th><th scope="col" class="num">Files</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="meter" aria-hidden="true"><span style="--v: 0.303"></span></td><td class="num">464</td><td class="num">6</td></tr>
<tr><th scope="row">SvelteKit</th><td class="meter" aria-hidden="true"><span style="--v: 0.654"></span></td><td class="num">1002</td><td class="num">9</td></tr>
<tr><th scope="row">Next.js</th><td class="meter" aria-hidden="true"><span style="--v: 0.660"></span></td><td class="num">1010</td><td class="num">8</td></tr>
<tr><th scope="row">Axum + askama</th><td class="meter" aria-hidden="true"><span style="--v: 0.951"></span></td><td class="num">1456</td><td class="num">7</td></tr>
<tr><th scope="row">Actix + tera</th><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">1531</td><td class="num">7</td></tr>
</tbody>
</table>

A bigger app, with sign up and in, a posts table, uploads, live refresh and a component, is 995 tokens in Wisp, 3473 in SvelteKit and 3331 in Next.js. The numbers come from `cargo run -p wisp-tokens`, which counts every hand-written file and its path with a byte-pair style estimate; the [Tokens page](/docs/tokens) has the method and the apps.

</div>
</div>
</section>

<Band id="forms" title="Forms That Work Without JavaScript" lead="A form posts to an action. A bad value is a 422 that shows each problem beside its input and keeps what was typed. With JavaScript on, the page morphs instead of reloading.">

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

<Band id="reactive" flip title="Reactivity in the Same File" lead="The block is Rust that runs for each request, name is drawn on the server, and the count is JavaScript state in the browser. Turn JavaScript off and the server's HTML still works.">

```html
---
let name = cx.query_or("name", "world".to_string());
---
<h1>Hello, {name}!</h1>

<button on:click="count++">Clicked {:count} times</button>

<script>
  let count = $state(0)
</script>
```

</Band>

<Band id="binary" title="One Binary, on Any Host" lead="Templates compile to plain Rust, and the whole app, styles and static files included, becomes one small binary. Every fast path is proven at startup and falls back, and nothing after startup panics. The same app builds as a container, static HTML, or for an edge or serverless host. This site is one too: server-rendered pages that work with JavaScript off, down to the demo and the search form.">

```bash
wisp build
wisp build --static
wisp build --docker
wisp build --target cloudflare
wisp deploy init cloudflare
```

<h3 class="hosts-title">Builds for Your Host</h3>

<Hosts />

</Band>


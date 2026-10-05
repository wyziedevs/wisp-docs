---
title: "Wisp: A Fast, Fun Web Framework"
description: Wisp is a fast, fun web framework for Rust with file routes, templates compiled to Rust and form actions. It ships as one binary and costs an AI few tokens.
---

<Hero />

<section class="sec showcase">
<div class="wrap">
<div class="sec-head">
<h2>A Page Is One File</h2>
<p>The model, the table, the actions and the markup sit in one file. The form writes its own inputs and errors, and a bad value is a 422 that keeps what was typed. JSON endpoints join the same file as a <code>mod server</code> block, and a model can move to <code>src/db.rs</code> once other pages need it.</p>
</div>

<Demo todos={&demo_todos(cx)}>

<div class="pane pane-1">

```html
---
#[model]
struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
static TODOS: Table<Todo> = Table::saved();

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

</Demo>

</div>
</section>

<Claim id="fast">

## Nothing Extra on the Hot Path

A route pays only for the features it uses, and a change that touches the request path is checked by an instructions-per-request A/B before it lands. Wisp's first rule is that speed is never traded away for convenience.

The same app built for Node, Deno and Bun answers from the app's own HTTP parser over raw sockets. The raw tables against Hono on each host, with the machine and date, are on the benchmarks page (run validity not recorded, no steal data; no ranking is drawn from them). Rank tables against more frameworks are pending a valid run.

<p class="more"><a href="/docs/benchmarks/">Results and How Speed Is Measured</a></p>

</Claim>

<Claim id="measured">

## Benchmarked Against Popular Frameworks

TechEmpower's plaintext and JSON tests, run with their own load scripts against TechEmpower's source for each framework that has one (SvelteKit and Next.js have none, so theirs are two plain route handlers in a production build), on one 4-vCPU VM with the server pinned to 2 cores. Medians of 3 runs of 15 seconds each.

<div class="benches">
<div class="bench"><table class="tally">
<caption>Plaintext, 256 connections, pipelined</caption>
<thead><tr><th scope="col">Framework</th><th scope="col">Built On</th><th scope="col"><span class="sr">Relative speed</span></th><th scope="col" class="num">Req/s</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">1,129,577</td></tr>
<tr><th scope="row">Actix Web</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 0.534"></span></td><td class="num">603,163</td></tr>
<tr><th scope="row">Axum</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 0.245"></span></td><td class="num">276,948</td></tr>
<tr><th scope="row">Fastify</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.046"></span></td><td class="num">51,713</td></tr>
<tr><th scope="row">Express</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.036"></span></td><td class="num">40,421</td></tr>
<tr><th scope="row">Hono (Node)</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.026"></span></td><td class="num">28,966</td></tr>
<tr><th scope="row">SvelteKit</th><td class="stack">Svelte</td><td class="meter" aria-hidden="true"><span style="--v: 0.010"></span></td><td class="num">10,929</td></tr>
<tr><th scope="row">Hono (Bun)</th><td class="stack">Bun</td><td class="meter" aria-hidden="true"><span style="--v: 0.009"></span></td><td class="num">10,599</td></tr>
<tr><th scope="row">Next.js</th><td class="stack">React</td><td class="meter" aria-hidden="true"><span style="--v: 0.000"></span></td><td class="num">0</td></tr>
</tbody>
</table></div>
<div class="bench"><table class="tally">
<caption>JSON, 64 connections</caption>
<thead><tr><th scope="col">Framework</th><th scope="col">Built On</th><th scope="col"><span class="sr">Relative speed</span></th><th scope="col" class="num">Req/s</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">96,089</td></tr>
<tr><th scope="row">Actix Web</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 0.933"></span></td><td class="num">89,648</td></tr>
<tr><th scope="row">Axum</th><td class="stack">Rust</td><td class="meter" aria-hidden="true"><span style="--v: 0.816"></span></td><td class="num">78,427</td></tr>
<tr><th scope="row">Hono (Bun)</th><td class="stack">Bun</td><td class="meter" aria-hidden="true"><span style="--v: 0.620"></span></td><td class="num">59,619</td></tr>
<tr><th scope="row">Fastify</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.229"></span></td><td class="num">21,965</td></tr>
<tr><th scope="row">Express</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.153"></span></td><td class="num">14,746</td></tr>
<tr><th scope="row">SvelteKit</th><td class="stack">Svelte</td><td class="meter" aria-hidden="true"><span style="--v: 0.108"></span></td><td class="num">10,378</td></tr>
<tr><th scope="row">Hono (Node)</th><td class="stack">Node.js</td><td class="meter" aria-hidden="true"><span style="--v: 0.094"></span></td><td class="num">8,988</td></tr>
<tr><th scope="row">Next.js</th><td class="stack">React</td><td class="meter" aria-hidden="true"><span style="--v: 0.016"></span></td><td class="num">1,524</td></tr>
</tbody>
</table></div>
</div>

Source: [`bench/tfb`](https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md), run 2026-10-04 on a shared 4-vCPU AMD EPYC 7B13 VM, wrk, medians of 3 runs of 15 seconds, server on 2 pinned cores; sorted by requests per second. Every contender, both workloads and all connection levels are in the full results; this is not an official TechEmpower result, and the same binary moved between moments on this shared VM, so gaps inside the min-max ranges are ties.

<p class="more"><a href="https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md">Full Results</a></p>

</Claim>

<section class="sec cheap" id="cheap">
<div class="wrap">
<div class="claim wide">

## Make the Same App with Half the Tokens

An AI is paid for by the token, in time and money, for what it reads and writes. Wisp keeps that count low with conventions instead of config, types the compiler infers, and forms that write themselves. The whole reference is one file, [llms.txt and AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), and `wisp mcp` serves it to coding agents.

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
<figcaption>SvelteKit: the same form, 425 tokens</figcaption>
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

export const actions = {
  default: async ({ request }) => {
    const form = Object.fromEntries(await request.formData());
    const errors = {};
    if (!form.name || form.name.length > 50) errors.name = 'must have 1 to 50 characters';
    if (!/^\S+@\S+\.\S+$/.test(form.email)) errors.email = 'must be an email address';
    if (Object.keys(errors).length) return fail(422, { ...form, errors });
    console.log(`${form.name} <${form.email}>`);
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

The same five features (a list page, a contact form, a JSON endpoint, a layout and a live search) written as a complete app in each stack. Every stack's form checks the same two rules with the same messages, and a stack with no built-in rule writes them by hand:

<table class="tally">
<thead><tr><th scope="col">Stack</th><th scope="col"><span class="sr">Relative size</span></th><th scope="col" class="num">Tokens</th><th scope="col" class="num">Files</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="meter" aria-hidden="true"><span style="--v: 0.313"></span></td><td class="num">432</td><td class="num">6</td></tr>
<tr><th scope="row">Nuxt (Vue)</th><td class="meter" aria-hidden="true"><span style="--v: 0.631"></span></td><td class="num">872</td><td class="num">8</td></tr>
<tr><th scope="row">SvelteKit</th><td class="meter" aria-hidden="true"><span style="--v: 0.692"></span></td><td class="num">957</td><td class="num">9</td></tr>
<tr><th scope="row">Next.js (React)</th><td class="meter" aria-hidden="true"><span style="--v: 0.703"></span></td><td class="num">971</td><td class="num">8</td></tr>
<tr><th scope="row">Express (Node.js)</th><td class="meter" aria-hidden="true"><span style="--v: 0.836"></span></td><td class="num">1,156</td><td class="num">7</td></tr>
<tr><th scope="row">React (Vite + Express)</th><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">1,382</td><td class="num">8</td></tr>
</tbody>
</table>

A bigger app, with sign up and in, a posts table, uploads, live refresh and a component, is 958 tokens in Wisp, 3,473 in SvelteKit and 3,331 in Next.js. The numbers come from `cargo run -p wisp-tokens`, which counts every hand-written file and its path with a byte-pair style estimate; the [Tokens page](/docs/tokens/) has the method and the apps.

</div>
</div>
</section>

<Claim id="status">

## Tested and Actively Hardened

Wisp is new and has not been audited. Over a thousand tests run on every change. The HTTP, HTTP/2, template and formatter parsers are fuzzed with seeded inputs, a table of request-smuggling shapes is refused on both HTTP versions, every fast path is proven at startup with a fallback, and there is no `unsafe` outside the Linux I/O drivers and the edge exports. Bugs are likely to remain, and issues are welcome.

<p class="more"><a href="/docs/security/">What Is Hardened, and What Is Not</a></p>

</Claim>

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


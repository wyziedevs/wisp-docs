---
title: "Wisp: A Fast, Fun Web Framework"
description: Wisp is a fast, fun web framework for Rust with file routes, templates compiled to Rust and form actions. It ships as one binary and costs an AI few tokens.
---

<Hero />

<section class="sec" id="abstraction">
<div class="wrap">
<div class="claim wide">

## All the Abstraction, Without Losing Speed

Pages, forms and validation take a few lines, and all of it compiles to plain Rust. The work of each abstraction happens once, when you build, so a request only runs the result: fixed text, a few function calls and nothing to parse or look up. A route pays only for the features it uses.

</div>

<ol class="flow">
<li><b>You Write</b><span>Pages, forms, validation and logic in a few lines</span></li>
<li><b>The Build Compiles</b><span>Templates and routes become plain Rust</span></li>
<li class="us"><b>A Request Runs</b><span>Compiled code answers it directly, with nothing left to parse</span></li>
</ol>
</div>
</section>

<section class="sec showcase">
<div class="wrap">
<div class="sec-head">
<h2>A Page Is One File</h2>
<p>The model, the table, the actions and the markup live in one file. The form writes its own inputs and errors, and JSON endpoints go in the same file. When other pages need a model, move it to <code>src/db.rs</code>.</p>
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

<form action="?/add" fields />

{#each TODOS.all() as todo}
  <p> {todo.text}
    <button action="?/remove&id={todo.id}">
      Remove
    </button>
  </p>
{/each}
```

</div>

</Demo>

</div>
</section>

<Claim id="fast">

## Nothing Extra on the Hot Path

A route pays only for the features it uses, and every change to the request path is measured before it ships. Speed is never traded for convenience.

<p class="more"><a href="/docs/benchmarks/">Results and How Speed Is Measured</a></p>

</Claim>

<Claim id="measured">

## Benchmarked Against Popular Frameworks

Requests per second on the TechEmpower plaintext and JSON tests. Every framework runs on the same machine with the same 2 CPU cores, and each number is the median of 3 runs. Rows marked tie have a min-max range that overlaps another row's, so no rank is drawn between them. "Not published" means a run was disturbed by hypervisor steal, and a lead over a rival whose cell is not published is not counted as a win. Run 2026-10-04 on one shared 4-vCPU VM (hypervisor steal was not zero), not a TechEmpower result; most cells predate the warmup-drain and steal controls, and a harness re-run is pending.

<Speed />

<p class="more"><a href="https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md">Full Results</a></p>

</Claim>

<section class="sec cheap" id="cheap">
<div class="wrap">
<div class="claim wide">

## Make the Same App with Less Than Half the Tokens

AI is billed by the token. Wisp keeps the count low with conventions over config, inferred types and forms that write themselves. The whole reference is one file, [AGENTS.md](https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md), and `wisp mcp` serves it to coding agents.

```bash
claude mcp add wisp -- wisp mcp
```

</div>

<div class="pair">
<figure class="cmp">
<figcaption>Wisp: a contact form that validates, <Stat k="form.wisp" /> tokens</figcaption>
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
<form fields />
```

</div>
</div>
</figure>
<figure class="cmp">
<figcaption>SvelteKit: the same form, <Stat k="form.sveltekit" /> tokens</figcaption>
<div class="file tabbed">
<div class="tabs" role="radiogroup" aria-label="SvelteKit files">
<input class="sr" type="radio" name="sk-file" id="sk-server" checked>
<label for="sk-server">+page.server.js</label>
<input class="sr" type="radio" name="sk-file" id="sk-page">
<label for="sk-page">+page.svelte</label>
</div>
<div class="scroll pane pane-1" tabindex="0" aria-label="SvelteKit +page.server.js">

```js
import { error, fail, redirect } from '@sveltejs/kit';

export const actions = {
  default: async ({ request }) => {
    const form = Object.fromEntries(await request.formData());
    if (typeof form.name != 'string' || typeof form.email != 'string') error(400, 'missing form field');
    const errors = {};
    const n = [...form.name].length;
    if (n < 1) errors.name = 'must have at least 1 character';
    if (n > 50) errors.name = 'must have at most 50 characters';
    if (!/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/.test(form.email)) errors.email = 'must be an email address';
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
  <label>Name <input name="name" required minlength="1" pattern="[\s\S]{0,50}" value={form?.name ?? ''} />
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

One app built in each stack: a list, a contact form, a JSON endpoint, a layout and a live search. Every form checks the same rules and shows the same messages.

<Tokens />

<p class="more"><a href="/docs/tokens/">How Tokens Are Counted</a></p>

</div>
</div>
</section>

<Claim id="status">

## Tested and Actively Hardened

Wisp is new and not yet audited. Over a thousand tests run on every change, the parsers are fuzzed, request smuggling is refused on HTTP/1 and HTTP/2, and there is no unsafe code outside the Linux I/O drivers and edge exports. Bugs likely remain; issues are welcome.

<p class="more"><a href="/docs/security/">What Is Hardened, and What Is Not</a></p>

</Claim>

<Band id="forms" title="Forms That Work Without JavaScript" lead="A form posts to an action. A bad value sends the form back with the problem beside its input and what you typed kept. With JavaScript on, the page updates in place.">

```html
---
#[action]
fn signup(email: Email, password: Password) {
    cx.signup(User { email, password }).await?;
    redirect("/me")
}
---

<form action="?/signup" fields>
  <button>Sign up</button>
</form>
```

</Band>

<Band id="reactive" flip title="Reactivity in the Same File" lead="The top block is Rust that runs on the server for each request. The count is JavaScript state in the browser. Turn JavaScript off and the server's HTML still works.">

```html
---
let name = cx.query_or("name", "world".to_string());
---

<h1>Hello, {name}!</h1>

<button on:click="count++">Clicked {:count} times</button>
```

A name nothing declares starts at 0, so `count++` just works. Use a `<script>` only for real browser code.

</Band>

<Band id="binary" title="One Binary, on Any Host" lead="Templates compile to Rust, and the app, styles and static files become one small binary. Build it as a container, static HTML, or for an edge or serverless host. This site is built that way, and works with JavaScript off.">

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


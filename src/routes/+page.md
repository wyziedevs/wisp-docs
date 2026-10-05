---
title: "Wisp: A Fast, Fun Web Framework"
description: Wisp is a fast, fun web framework for Rust with file routes, templates compiled to Rust and form actions. It ships as one binary and costs an AI few tokens.
---

<Hero />

<section class="sec showcase">
<div class="wrap">
<div class="sec-head">
<h2>A Page Is One File</h2>
<p>The model, the actions and the markup of a whole page, with a form that validates itself.</p>
</div>

<Demo todos={&demo_todos(cx)}>

<div class="pane pane-1">

```html
---
#[model(saved, crud)]
struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}
---

<title>Todos ({TODOS.len()})</title>
<form action="?/add" fields />
{#each TODOS as todo}
  <p>{todo.text} <button action="?/remove&id={todo.id}">Remove</button></p>
{/each}
```

</div>

</Demo>

</div>
</section>

<section class="sec" id="why">
<div class="wrap">
<div class="claim wide">
<h2>Why Wisp</h2>
<ul class="points">
<li><strong>Fast.</strong> Nothing extra on the request path. <a href="/docs/benchmarks/">Benchmarks</a></li>
<li><strong>Cheap in tokens.</strong> The same app in less than half the tokens. <a href="/docs/tokens/">Tokens</a></li>
<li><strong>Works without JavaScript.</strong> Forms post, validate and keep what was typed. <a href="/docs/design-forms/">Forms</a></li>
<li><strong>One binary.</strong> Templates compile to Rust; styles and static files ship inside. <a href="/docs/design/">Design</a></li>
<li><strong>Host anywhere.</strong> A VPS, a container, static HTML, edge or serverless. <a href="/docs/hosting/">Hosting</a></li>
</ul>
</div>
</div>
</section>

<Claim id="cheap">

## Less Than Half the Tokens

The same five features in each stack: a list, a contact form, a JSON endpoint, a layout and a live search.

<table class="tally">
<thead><tr><th scope="col">Stack</th><th scope="col"><span class="sr">Relative size</span></th><th scope="col" class="num">Tokens</th><th scope="col" class="num">Files</th></tr></thead>
<tbody>
<tr class="us"><th scope="row">Wisp</th><td class="meter" aria-hidden="true"><span style="--v: 0.298"></span></td><td class="num">476</td><td class="num">7</td></tr>
<tr><th scope="row">Nuxt (Vue)</th><td class="meter" aria-hidden="true"><span style="--v: 0.652"></span></td><td class="num">1,043</td><td class="num">8</td></tr>
<tr><th scope="row">SvelteKit</th><td class="meter" aria-hidden="true"><span style="--v: 0.709"></span></td><td class="num">1,134</td><td class="num">9</td></tr>
<tr><th scope="row">Next.js (React)</th><td class="meter" aria-hidden="true"><span style="--v: 0.717"></span></td><td class="num">1,146</td><td class="num">8</td></tr>
<tr><th scope="row">Express (Node.js)</th><td class="meter" aria-hidden="true"><span style="--v: 0.868"></span></td><td class="num">1,388</td><td class="num">8</td></tr>
<tr><th scope="row">React (Vite + Express)</th><td class="meter" aria-hidden="true"><span style="--v: 1.000"></span></td><td class="num">1,599</td><td class="num">9</td></tr>
</tbody>
</table>

<p class="more"><a href="/docs/tokens/">How It Is Counted</a></p>

</Claim>

<Claim id="fast">

## Benchmarked Against Popular Frameworks

TechEmpower's plaintext and JSON tests, every server on the same 2 cores.

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
<tr><th scope="row">Next.js</th><td class="stack">React</td><td class="meter" aria-hidden="true"></td><td class="num">No result</td></tr>
</tbody>
</table>
</div>
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
</table>
</div>
</div>

<p class="source">Source: <a href="https://github.com/wyziedevs/wisp/blob/main/bench/tfb/RESULTS.md">bench/tfb</a>, shared 4-vCPU VM, 2026-10-04, medians of 3 runs; not an official TechEmpower result.</p>

<p class="more"><a href="/docs/benchmarks/">Results and How Speed Is Measured</a></p>

</Claim>

<Claim id="hosts">

## Builds for Your Host

<Hosts />

</Claim>

<Claim id="status">

## Status

Wisp is new and not audited: over a thousand tests run on every change, and bugs are likely to remain. <a href="/docs/security/">What is hardened</a>

</Claim>

<section class="sec start" id="start">
<div class="wrap">
<div class="sec-head">
<h2>Start Building</h2>
<p class="cta">
<a class="btn primary" href="/docs/quick-start/">Learn Wisp</a>
<a class="btn" href="https://github.com/wyziedevs/wisp">GitHub</a>
</p>
</div>
</div>
</section>

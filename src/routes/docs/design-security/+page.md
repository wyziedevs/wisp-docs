---
title: Security and milestones
description: Security headers, CSP, non-goals and milestones.
group: Design
order: 24
---

## Security

- Escaping by default; `{@html}` is the only raw output. Component props are
  typed Rust values, so they are escaped where they are shown like any other.
- Actions are opt-in (`#[action]`), same-origin checked, and take only form
  fields, no client-supplied type names or serialized state (Livewire
  CVE-2025-54068 class).
- Signed cookies bind the signature to the cookie's name and value, and are
  compared in constant time. `WISP_SECRET` shorter than 32 characters stops
  the server at start.
- Dev endpoints exist only in debug builds and only answer loopback peers
  (behind a proxy on the same machine every peer is loopback: never serve a
  debug build). Dev mode on a non-loopback address says so at start.
- Live URL attributes (`href={:x}`, `:src="x"`) block `javascript:` and
  `vbscript:` on the server's first paint and in the browser, as `href={x}`
  does; wisp.js never follows a `javascript:` redirect or `goto`, and saves a
  posted form's attachment instead of opening it as a page of this site.
- Request size and time limits as above; no request smuggling surface
  (strict chunked parsing, CL+TE rejected).
- At most `WISP_MAX_CONNS` (10000) open connections, WebSockets included;
  past it a new one gets a 503 and is closed before it costs a task.
- URL attributes whose scheme an expression decides are checked where they
  end; `javascript:` never reaches a page (see Templates).
- Pages and error pages carry a `content-security-policy` (see below).
- `examples/demo/tests/http.rs` runs the demo's binary and sends it
  malformed, oversized, smuggling and cross-site requests, path traversal
  attempts and junk cookies, and checks every answer and that the server
  keeps answering. `tests/app` is an app that uses what the demo does not
  (hooks, state, components, uploads, signed cookies, chunked bodies, body
  limits, streamed responses), and its `tests/http.rs` checks each on the
  wire.

## Content Security Policy

Every page and error page (rendered, baked or kept by `CACHE`) gets:

```
content-security-policy: default-src 'self'; script-src 'self' 'sha256-…';
  style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;
  connect-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'self'
```

- Wisp's own scripts are files (`wisp.js`, `live.js`, modules under
  `/_app/c/`); its JSON data block runs nothing. The only inline scripts
  are the app's (`<script defer>…</script>` in a template, or in
  `src/app.html`), and no hole can go in one, so the build hashes each
  and `script-src` lists the hashes. No nonce: the header is one string
  made after `init`, so a page costs one more header line, a baked or
  `CACHE` page stays bytes made before, and the scripts wisp.js runs after
  a navigation pass (a nonce would be the first page's). An inline script
  edited in dev takes a build, for its hash.
- Dev mode adds `https://esm.sh` (npm modules) to `script-src` and
  `connect-src`, and `wisp dev`'s reload events to `connect-src`.
- `wisp::csp("img-src 'self' https://cdn.example; font-src https://f.example")`
  in `init`: each directive replaces the default one of its name, or is
  added; `script-src` keeps the hashes (unless it has `'unsafe-inline'`,
  which a hash would turn off). `wisp::csp_off()` sends none, for an app
  that sets its own.
- Not covered: endpoints and `Response::html` (not pages), `/_wisp/docs`,
  and `wisp build --static`, whose files have no headers (the host sets
  them). A script put in by `{@html}` or an `onclick="…"` attribute does
  not run; use a file, or `on:click`.

## v0 non-goals

No homegrown auth, ORM or job system, now or later: Wisp gives the tools
(cookies, sessions, the `Store` trait, hooks, `wisp::spawn` from `init`)
and the app builds on them. Integrations wire in existing, maintained
crates (a recipe in `add/`, `wisp add sqlite`, scaffolds the glue). Also out:
HTTP/2 in process, Windows services.

## Milestones

1. **Core** – routes, layouts, templates, load, actions, errors, static files,
   `wisp.js` morph, `wisp dev` with hot swap.  ← current
2. **Measure** – dev-loop timings; req/s and latency vs ASP.NET Core Minimal
   APIs on the same machine.
3. **Flexible** – hooks, state, components, uploads, signed cookies,
   streaming, body limits, proxies.  ← done
   **Reactive and everywhere** – client scripts, router, tower, static
   export, Docker, edge targets.  ← done
4. **v0.2** – behaviors, link boosting, docs site built with Wisp.

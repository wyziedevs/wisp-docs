---
title: Built-in UI
description: The few things Wisp draws itself, from one design system.
group: Design
order: 19
---

Wisp draws a few things of its own, all from one design system: Kinetrix's
roles and values (dark, as the demo site), with Wisp violet (`#896ce0`) as
the one accent, only on what is interactive. One-pixel hairlines, two shadow steps, one type scale, and one
focus ring. The styles live in `crates/wisp/src/client/tokens.css` (the one
source of the tokens), `ui.css` (buttons), `error.css` and `dialog.css` (dev
only), all `--wisp-*` tokens
and `.wisp-*` classes, so they never touch an app's own CSS.

- **The error page**, for apps without a `+error.wisp`: laid out as the demo's
  own, the status and one line, centered, on the dark tokens. The line is the
  status's name, or the error's own message when it says more. No links or
  buttons; an app that wants them writes a `+error.wisp`. Under `wisp dev` it
  also has the status's name, the request, what caused a 5xx and a link home.
  Its styles come inlined, since the app's own CSS may not exist yet. Errors
  for endpoints and API clients are JSON instead (see docs/api.md).
- **Server errors in dev**: every answer carries `Server-Timing: total;dur=ms`,
  and a 5xx's dev error page holds its message (a handler's panic says
  `file:line`) in a `<template id="wisp-server-error">` that `wisp-dev.js`
  opens in the dialog below. Debug builds only.
- **The build error dialog** in dev: a title and one sentence saying where to
  look (`src/routes/+page.rs, line 7. Save a fix and the page updates.`), then
  the error text in a code block with a Copy control. It lives in a shadow
  root hung off `<html>`, so neither the app's CSS nor a page morph can touch
  it, and it closes by itself when the next build succeeds. While a rebuild
  runs, a two-pixel accent line crosses the top of the window, once the
  rebuild has taken 200 ms.
- **The terminal.** Every status line has a mark and words: `✓` done in
  green, `!` needs a look in yellow, `✗` failed in red, `›` under way and `~`
  changed in dim. Violet is only for what can be typed. A failure is a
  sentence, then the reason or what to do indented under it.

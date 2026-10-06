---
let me = wisp::pages("")
    .iter()
    .find(|p| p.path == site::bare(cx.path()));
---

<div class="page community doc">
  <nav class="crumbs" aria-label="Breadcrumb"><a href="/">Wisp</a><span>FAQ</span></nav>
  <h1 class="doc-title">{me.map_or("FAQ", |p| p.title)}</h1>
  <slot />
</div>

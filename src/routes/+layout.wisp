---
const SITE: &str = "https://wispweb.dev";

let home = cx.path() == "/";
let docs = cx.path().starts_with("/docs");
let me = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .find(|p| p.path == cx.path());
let title = me.map_or("Wisp", |p| p.title);
let about = me
    .and_then(|p| p.get("description"))
    .unwrap_or("A fast, fun web framework for Rust");
---
<head>
  <meta name="description" content={about}>
  {@html wisp::og(title, about, &format!("{SITE}/og.png"))}
  <link rel="canonical" href={format!("{SITE}{}", cx.path())}>
  <meta name="twitter:card" content="summary_large_image">
</head>
<a class="skip" href="#main">Skip to content</a>
<header class="top">
  <div class="bar">
    <a class="brand" href="/" aria-label="Wisp home"><img src="/favicon.svg" alt="" width="28" height="28"><span>Wisp</span></a>
    <nav aria-label="Site">
      <a href="/docs" aria-current={docs.then_some("page")}>Docs</a>
      <a href="/docs/overview">Overview</a>
      <a href="https://github.com/wyziedevs/wisp">GitHub</a>
    </nav>
  </div>
</header>
<main id="main" class:home={home}>
  <slot />
</main>
<footer class="foot">
  <div class="bar">
    <p class="mark"><img src="/favicon.svg" alt="" width="22" height="22"> Wisp. A fast, fun web framework for Rust.</p>
    <ul>
      <li><a href="/docs">Docs</a></li>
      <li><a href="https://github.com/wyziedevs/wisp">Wisp on GitHub</a></li>
      <li><a href="https://github.com/wyziedevs/wisp-docs">Docs on GitHub</a></li>
    </ul>
  </div>
</footer>

<script>
  import { afterNavigate } from 'wisp'

  function focusable() {
    for (const p of document.querySelectorAll('pre')) p.tabIndex = 0
  }

  onMount(focusable)
  afterNavigate(focusable)
</script>

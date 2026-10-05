---
const SITE: &str = "https://wispweb.dev";
const ORG: &str = r#"{"@type":"Organization","name":"Wyzie LLC","url":"https://wyzie.io"}"#;
const SITE_LD: &str = r#"{"@context":"https://schema.org","@type":"WebSite","name":"Wisp","url":"~/","potentialAction":{"@type":"SearchAction","target":"~/search?q={search_term_string}","query-input":"required name=search_term_string"}}"#;

let path = site::bare(cx.path());
let home = path == "/";
let me = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .chain(wisp::pages("docs/hosting").iter())
    .chain(wisp::pages("blog").iter())
    .find(|p| p.path == path);
let title = me.map_or("Wisp", |p| p.title);
let about = me
    .and_then(|p| p.get("description"))
    .unwrap_or("Wisp is a fast, fun web framework for Rust: file routes, .wisp templates compiled to Rust, form actions and one binary to deploy.");
let docs = path == "/docs" || path.starts_with("/docs/");
let tab = if docs { me.map_or("learn", |p| site::section(p)) } else { "" };
let reference = tab == "reference";
let hosting = tab == "hosting";
let learn = tab == "learn";
let community = path == "/community";
let blog = path == "/blog" || path.starts_with("/blog/");
let links = [
    ("/docs/", "Learn", learn),
    ("/docs/design/", "Reference", reference),
    ("/docs/deploy/", "Hosting", hosting),
    ("/community/", "Community", community),
    ("/blog/", "Blog", blog),
];

// The page's head: Open Graph, a canonical address and JSON-LD. An error page is not indexed.
// Addresses end in `/`: the static host serves `dir/index.html` there and 308s the bare form.
let url = if home { format!("{SITE}/") } else { format!("{SITE}{path}/") };
// Layouts cannot see the status, so a path no page or route answers (a 404) is the error case.
let indexed = me.is_some();
let dated = me.and_then(|p| p.get("date"));
let json = |s: &str| format!("\"{}\"", s.replace('\\', "\\\\").replace('"', "\\\"").replace('\n', " ").replace('<', "\\u003c"));
let ld = match me {
    _ if !indexed => String::new(),
    _ if home => format!(
        "{{\"@context\":\"https://schema.org\",\"@graph\":[{},{{\"@type\":\"SoftwareSourceCode\",\"name\":\"Wisp\",\"description\":{},\"url\":\"{SITE}/\",\"codeRepository\":\"https://github.com/wyziedevs/wisp\",\"programmingLanguage\":\"Rust\",\"license\":\"https://github.com/wyziedevs/wisp/blob/main/LICENSE\",\"author\":{ORG}}}]}}",
        SITE_LD.replace('~', SITE).replace("\"@context\":\"https://schema.org\",", ""),
        json(about),
    ),
    Some(p) if blog && dated.is_some() => format!(
        "{{\"@context\":\"https://schema.org\",\"@type\":\"BlogPosting\",\"headline\":{},\"description\":{},\"url\":{},\"image\":\"{SITE}/og.png?v=2\",\"inLanguage\":\"en\",\"datePublished\":{},\"author\":{},\"publisher\":{ORG}}}",
        json(p.title),
        json(about),
        json(&url),
        json(dated.unwrap_or("")),
        p.get("author").map_or(ORG.to_string(), |a| format!("{{\"@type\":\"Person\",\"name\":{}}}", json(a))),
    ),
    Some(p) if docs => format!(
        "{{\"@context\":\"https://schema.org\",\"@graph\":[{{\"@type\":\"TechArticle\",\"headline\":{},\"description\":{},\"url\":{},\"image\":\"{SITE}/og.png?v=2\",\"inLanguage\":\"en\",\"author\":{ORG},\"publisher\":{ORG}}},{{\"@type\":\"BreadcrumbList\",\"itemListElement\":[{{\"@type\":\"ListItem\",\"position\":1,\"name\":\"Home\",\"item\":\"{SITE}/\"}},{{\"@type\":\"ListItem\",\"position\":2,\"name\":\"Docs\",\"item\":\"{SITE}/docs/\"}}{}]}}]}}",
        json(p.title),
        json(about),
        json(&url),
        if path == "/docs" { String::new() } else { format!(",{{\"@type\":\"ListItem\",\"position\":3,\"name\":{},\"item\":{}}}", json(p.title), json(&url)) },
    ),
    _ => String::new(),
};
---
<head>
  <title>{if home { title.to_string() } else { format!("{title} | Wisp Rust Web Framework") }}</title>
  <meta name="description" content={about}>
  <meta name="author" content="Wyzie LLC">
  {@html wisp::og(title, about, &format!("{SITE}/og.png?v=2"))}
  <meta property="og:type" content={if blog && dated.is_some() { "article" } else { "website" }}>
  <meta property="og:site_name" content="Wisp">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="Wisp, a fast, fun web framework for Rust">
  {#if indexed}
    <link rel="canonical" href={url.clone()}>
    <meta property="og:url" content={url.clone()}>
  {:else}
    <meta name="robots" content="noindex">
  {/if}
  <link rel="alternate" type="application/rss+xml" title="Wisp Blog" href="/feed.xml">
  {#if !ld.is_empty()}
    {@html format!("<script type=\"application/ld+json\">{ld}</script>")}
  {/if}
</head>
<a class="skip" href="#main">Skip to Content</a>
<header class="top">
  <div class="bar">
    <a class="brand" href="/" aria-label="Wisp home">
      <span class="ghost" aria-hidden="true">
        <svg viewBox="0 0 32 32">
          <path
            class="shape"
            d="M16 2.5C21 2.5 24.5 6.5 24.5 11.5C24.5 13.6 25.3 14.7 26.9 14.7C28.2 14.7 29.3 14 30.2 13.3C31.2 12.6 31.9 13.8 31.3 14.9C30.1 17.4 28.4 19.4 27.1 20.5C26.3 21.2 26.2 22.4 26.5 23.8C26.8 25.2 27.6 26.2 27.6 27.4C27.6 28.6 26.5 29.4 25.4 29.4C24.2 29.4 23.6 27.5 22.3 27.5C21.25 27.5 20.9 28.8 19.8 28.8C18.7 28.8 18.29 27.8 17.2 27.8C15.69 27.8 14.9 29.7 13.6 29.7C12.3 29.7 11.57 27.4 10.1 27.4C8.71 27.4 8.05 29.1 6.8 29.1C5.6 29.1 4.4 28.6 4.4 27.4C4.4 26.2 5.2 25.2 5.5 23.8C5.8 22.4 5.7 21.2 4.9 20.5C3.6 19.4 1.9 17.4 0.7 14.9C0.1 13.8 0.8 12.6 1.8 13.3C2.7 14 3.8 14.7 5.1 14.7C6.7 14.7 7.5 13.6 7.5 11.5C7.5 6.5 11 2.5 16 2.5Z" />
          <ellipse class="eye" cx="12.8" cy="10.8" rx="1.8" ry="2.6" />
          <ellipse class="eye" cx="19.2" cy="10.8" rx="1.8" ry="2.6" />
          <ellipse class="mouth" cx="15.6" cy="16.6" rx="1.3" ry="1.7" />
        </svg>
      </span>
      <span>Wisp</span>
    </a>

    <form class="search" action="/search/" role="search" bind:this="bar">
      <label class="sr" for="q">Search</label>
      <SearchIcon />
      <input id="q" name="q" type="search" placeholder="Search" autocomplete="off" spellcheck="false" bind:this="q">
      <kbd class="key" aria-hidden="true"><span bind:this="mod">Ctrl</span> K</kbd>
    </form>

    <div class="end">
    <nav class="links" aria-label="Site">
      <NavLinks links={links} />
    </nav>

    <button class="icon theme" type="button" on:click="flip()" aria-label="Switch light or dark theme">
      <svg class="moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>
      <svg class="sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
    </button>
    <a class="icon gh" href="https://github.com/wyziedevs/wisp" aria-label="Wisp on GitHub">
      <svg viewBox="0 0 24 24" aria-hidden="true"><path class="fill" d="M12 1.5a10.5 10.5 0 0 0-3.3 20.47c.52.1.72-.23.72-.5v-1.8c-2.92.63-3.54-1.4-3.54-1.4-.48-1.22-1.17-1.54-1.17-1.54-.95-.65.08-.64.08-.64 1.05.08 1.6 1.08 1.6 1.08.94 1.6 2.46 1.14 3.06.87.1-.68.37-1.14.66-1.4-2.33-.27-4.78-1.17-4.78-5.18 0-1.15.4-2.08 1.08-2.82-.1-.27-.47-1.34.1-2.78 0 0 .88-.29 2.89 1.07a10 10 0 0 1 5.26 0c2-1.36 2.88-1.07 2.88-1.07.58 1.44.21 2.51.1 2.78.68.74 1.08 1.67 1.08 2.82 0 4.02-2.45 4.9-4.79 5.16.38.33.71.97.71 1.95v2.9c0 .28.19.6.72.5A10.5 10.5 0 0 0 12 1.5z"/></svg>
    </a>

    <details class="mnav">
      <summary aria-label="Menu"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"/></svg></summary>
      <nav aria-label="Site menu">
        <NavLinks links={links} />
        <a href="https://github.com/wyziedevs/wisp">GitHub</a>
      </nav>
    </details>
    </div>
  </div>
</header>
<noscript>
  <p class="nojs">JavaScript is off, so copy buttons, the theme switch and page ratings are hidden. Enable JavaScript for this site to use them.</p>
</noscript>

<dialog class="finder" aria-label="Search the Docs" bind:this="dlg">
  <div class="find-bar">
    <SearchIcon />
    <input
      type="search"
      placeholder="Search the Docs"
      aria-label="Search the Docs"
      autocomplete="off"
      spellcheck="false"
      role="combobox"
      aria-expanded="false"
      aria-controls="find-hits"
      aria-autocomplete="list"
      bind:this="fq">
    <button class="esc" type="button" on:click="find?.close()">Esc</button>
  </div>
  <p class="sr" role="status" aria-live="polite" bind:this="status"></p>
  <ul id="find-hits" class="hits" role="listbox" aria-label="Search results" bind:this="hits"></ul>
  <p class="find-tip" bind:this="tip">Type to search every docs page and heading.</p>
</dialog>

<main id="main" class:home={home}>
  <slot />
</main>

<footer class="foot">
  <div class="wrap cols">
    <div class="mark">
      <a class="brand" href="/"><img src="/favicon.svg" alt="" width="28" height="28"> Wisp</a>
      <p>A fast, fun web framework for Rust.</p>
      <p class="maker">Made by <a href="https://wyzie.io">Wyzie LLC</a></p>
    </div>
    <nav aria-label="Learn">
      <h2>Learn</h2>
      <a href="/docs/">Getting Started</a>
      <a href="/docs/why/">Why Wisp</a>
      <a href="/docs/overview/">Overview</a>
      <a href="/docs/tokens/">Tokens</a>
      <a href="/docs/benchmarks/">Benchmarks</a>
    </nav>
    <nav aria-label="Reference">
      <h2>Reference</h2>
      <a href="/docs/design/">Design and Files</a>
      <a href="/docs/cli/">CLI Reference</a>
      <a href="/docs/env/">Environment Variables</a>
      <a href="/docs/config/">Knobs and Settings</a>
    </nav>
    <nav aria-label="Community">
      <h2>Community</h2>
      <a href="/community/">Community</a>
      <a href="/blog/">Blog</a>
      <a href="https://discord.gg/2mxraHBVtB">Discord</a>
      <a href="https://github.com/wyziedevs/wisp/discussions">Discussions</a>
      <a href="https://github.com/wyziedevs/wisp/issues">Issues</a>
    </nav>
    <nav aria-label="More">
      <h2>More</h2>
      <a href="https://github.com/wyziedevs/wisp">Wisp on GitHub</a>
      <a href="https://github.com/wyziedevs/wisp/blob/main/llms/AGENTS.md">AGENTS.md</a>
      <a href="https://github.com/wyziedevs/wisp-docs">Site Source</a>
    </nav>
  </div>
</footer>

<script>
  import { afterNavigate } from 'wisp'
  import { path } from '$lib/toc.js'
  import { blocks, flip as swap } from '$lib/page.js'
  import { finder } from '$lib/search.js'
  import { haptics } from '$lib/haptic.js'
  import { demo } from '$lib/demo.js'

  let bar, q, mod, dlg, fq, status, hits, tip
  let find = null

  const flip = () => swap()

  // The phone menu closes on a press outside it and on Escape.
  const mnav = () => document.querySelector('.mnav')
  const shut = (e) => {
    const m = mnav()
    if (m?.open && (e.type === 'keydown' ? e.key === 'Escape' : !m.contains(e.target))) m.removeAttribute('open')
  }

  onMount(() => {
    addEventListener('pointerdown', shut)
    addEventListener('keydown', shut)
    blocks()
    haptics()
    demo()
    if (/Mac|iPhone|iPad/.test(navigator.platform)) mod.textContent = '⌘'
    find = finder({ bar, q, dlg, fq, status, hits, tip })
    console.log('%cwispweb.dev is a Wisp app, one Rust binary. Source: https://github.com/wyziedevs/wisp-docs', 'color:#a17ff5;font-weight:600')
  })
  afterNavigate(({ from, to }) => {
    blocks()
    demo()
    find?.close()
    document.querySelector('.mnav')?.removeAttribute('open')
  })
</script>

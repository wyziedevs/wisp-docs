---
let mut all: Vec<_> = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .chain(wisp::pages("docs/hosting").iter())
    .filter(|p| p.path == "/docs" || p.path.starts_with("/docs/"))
    .collect();
// Quick Start and the Tutorial lead Learn, then front matter `order`.
all.sort_by_key(|p| {
    let lead = match p.path {
        "/docs/quick-start" => 0,
        "/docs/tutorial" => 1,
        _ => 2,
    };
    let order = p.get("order").and_then(|o| o.parse::<u32>().ok()).unwrap_or(999);
    (lead, order)
});
let secs: Vec<&str> = all.iter().map(|p| site::section(p)).collect();
let at = all.iter().position(|p| p.path == site::bare(cx.path()));
let tab = at.map_or("learn", |i| secs[i]);
let kind = match tab {
    "reference" => "Reference",
    "hosting" => "Hosting",
    _ => "Learn",
};
let list: Vec<_> = all.iter().zip(&secs).filter(|(_, s)| **s == tab).map(|(p, _)| *p).collect();
let home = |s: &str| all.iter().zip(&secs).find(|(_, t)| **t == s).map_or("/docs", |(p, _)| p.path);
let (learn_home, ref_home, host_home) = (home("learn"), home("reference"), home("hosting"));

let mut groups: Vec<(&str, bool, Vec<_>)> = Vec::new();
for p in &list {
    let g = p.get("group").unwrap_or("Docs");
    let here = p.path == site::bare(cx.path());
    match groups.last_mut() {
        Some((name, open, items)) if *name == g => {
            *open |= here;
            items.push(*p);
        }
        _ => groups.push((g, here, vec![*p])),
    }
}
// The first group stays open, as does the one holding this page.
if let Some(first) = groups.first_mut() {
    first.1 = true;
}
let group = at.and_then(|i| all[i].get("group")).unwrap_or("Docs");

let me = list.iter().position(|p| p.path == site::bare(cx.path()));
let prev = me.and_then(|i| i.checked_sub(1)).map(|i| list[i]);
let next = me.and_then(|i| list.get(i + 1)).copied();
let toc: &[(&str, &[(&str, &str, u8)])] = include!(concat!(env!("OUT_DIR"), "/toc.rs"));
let heads = toc
    .iter()
    .find(|(p, _)| *p == site::bare(cx.path()))
    .map_or(&[][..], |(_, h)| *h);
let edit = match site::bare(cx.path()) {
    "/docs" => "src/routes/docs/+page.md".to_string(),
    p => format!("src/routes{p}/+page.md"),
};
---
<div class="docs">
  <aside class="side" aria-label="Documentation">
    <details class="menu">
      <summary>{kind} Menu</summary>
      <div class="switch" role="list">
        <a role="listitem" href={site::dir(learn_home)} aria-current={(tab == "learn").then_some("true")}>Learn</a>
        <a role="listitem" href={site::dir(ref_home)} aria-current={(tab == "reference").then_some("true")}>Reference</a>
        <a role="listitem" href={site::dir(host_home)} aria-current={(tab == "hosting").then_some("true")}>Hosting</a>
      </div>
      <nav aria-label={format!("{kind} pages")}>
        {#each groups as (name, open, items)}
          <details class="grp" open={*open}>
            <summary>{name}</summary>
            <ul>
              {#each items as p}
                <li><a href={site::dir(p.path)} aria-current={(p.path == site::bare(cx.path())).then_some("page")}>{p.title}</a></li>
              {/each}
            </ul>
          </details>
        {/each}
      </nav>
    </details>
  </aside>

  <article class="doc" bind:this="doc">
    <p class="sr" role="status" aria-live="polite" bind:this="copied"></p>
    <nav class="crumbs" aria-label="Breadcrumb">
      <a href={site::dir(home(tab))}>{kind}</a>
      <span>{group}</span>
    </nav>
    <h1 class="doc-title">{at.map(|i| all[i].title).unwrap_or("")}</h1>
    <slot />

    <div class="useful">
      <p>Is This Page Useful?</p>
      <button type="button" class="btn" data-v="yes">Yes</button>
      <button type="button" class="btn" data-v="no">No</button>
    </div>

    <Pager
      label="Previous and next"
      before="Previous"
      after="Next"
      prev={prev.map(|p| (p.path, p.title))}
      next={next.map(|p| (p.path, p.title))} />
    <p class="edit"><a href={format!("https://github.com/wyziedevs/wisp-docs/edit/main/{edit}")}>Edit This Page</a></p>
  </article>

  <Toc heads={heads} cls="toc" />
</div>

<script>
  import { afterNavigate } from 'wisp'
  import { reading, path } from '$lib/toc.js'

  let doc, copied
  let off = null

  // Heading link icons and the On This Page marker, again for each page.
  function build() {
    off?.()
    off = reading(doc, '.toc ul', (m) => (copied.textContent = m))
    // A page change can swap the node for a fresh one, so each page's box is wired once.
    const box = document.querySelector('.useful')
    if (box && !box.dataset.live) {
      box.dataset.live = '1'
      box.addEventListener('click', feedback)
    }
  }

  // Is This Page Useful: a thank you, nothing sent anywhere.
  function feedback(e) {
    const b = e.target.closest('button')
    if (!b) return
    const p = document.createElement('p')
    p.className = 'thanks'
    p.setAttribute('role', 'status')
    p.textContent = b.dataset.v === 'yes' ? 'Thanks for letting us know.' : 'Thanks. An issue on GitHub helps us fix it.'
    e.currentTarget.replaceChildren(p)
  }

  onMount(() => {
    build()
    if (location.hash) document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView()
  })
  // A new page eases in; a hash jump or a form post on the same page does not.
  afterNavigate(({ from, to }) => {
    build()
    // On a phone the page menu folds away once a page is chosen.
    if (path(from) !== path(to) && !matchMedia('(min-width: 48rem)').matches) document.querySelector('.menu')?.removeAttribute('open')
    if (path(from) === path(to) || matchMedia('(prefers-reduced-motion: reduce)').matches) return
    doc.animate(
      [{ opacity: 0, translate: '0 6px' }, { opacity: 1, translate: '0 0' }],
      { duration: 320, easing: 'cubic-bezier(0.16, 1, 0.3, 1)' },
    )
  })
</script>

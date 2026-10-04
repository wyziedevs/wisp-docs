---
// The docs groups that make up Reference; every other group is Learn.
// A page can also say `section: reference` or `section: learn` in its front matter.
const REFERENCE: &[&str] = &["Reference", "Design"];

let mut all: Vec<_> = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
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
let is_ref: Vec<bool> = all
    .iter()
    .map(|p| match p.get("section") {
        Some(s) => s == "reference",
        None => REFERENCE.contains(&p.get("group").unwrap_or("")),
    })
    .collect();
let at = all.iter().position(|p| p.path == cx.path());
let reference = at.is_some_and(|i| is_ref[i]);
let list: Vec<_> = all
    .iter()
    .zip(&is_ref)
    .filter(|(_, r)| **r == reference)
    .map(|(p, _)| *p)
    .collect();
let learn_home = all.iter().zip(&is_ref).find(|(_, r)| !**r).map_or("/docs", |(p, _)| p.path);
let ref_home = all.iter().zip(&is_ref).find(|(_, r)| **r).map_or("/docs", |(p, _)| p.path);

let mut groups: Vec<(&str, bool, Vec<_>)> = Vec::new();
for p in &list {
    let g = p.get("group").unwrap_or("Docs");
    let here = p.path == cx.path();
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

let me = list.iter().position(|p| p.path == cx.path());
let prev = me.and_then(|i| i.checked_sub(1)).map(|i| list[i]);
let next = me.and_then(|i| list.get(i + 1)).copied();
let toc: &[(&str, &[(&str, &str, u8)])] = include!(concat!(env!("OUT_DIR"), "/toc.rs"));
let heads = toc
    .iter()
    .find(|(p, _)| *p == cx.path())
    .map_or(&[][..], |(_, h)| *h);
let edit = match cx.path() {
    "/docs" => "src/routes/docs/+page.md".to_string(),
    p => format!("src/routes{p}/+page.md"),
};
---
<div class="docs">
  <aside class="side" aria-label="Documentation">
    <details class="menu">
      <summary>{if reference { "Reference" } else { "Learn" }} Menu</summary>
      <div class="switch" role="list">
        <a role="listitem" href={learn_home} aria-current={(!reference).then_some("true")}>Learn</a>
        <a role="listitem" href={ref_home} aria-current={reference.then_some("true")}>Reference</a>
      </div>
      <nav aria-label={if reference { "Reference pages" } else { "Learn pages" }}>
        {#each groups as (name, open, items)}
          <details class="grp" open={*open}>
            <summary>{name}</summary>
            <ul>
              {#each items as p}
                <li><a href={p.path} aria-current={(p.path == cx.path()).then_some("page")}>{p.title}</a></li>
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
      <a href={if reference { ref_home } else { learn_home }}>{if reference { "Reference" } else { "Learn" }}</a>
      <span>{group}</span>
    </nav>
    <h1 class="doc-title">{at.map(|i| all[i].title).unwrap_or("")}</h1>
    <slot />

    <div class="useful" bind:this="useful">
      <p>Is This Page Useful?</p>
      <button type="button" class="btn" data-v="yes">Yes</button>
      <button type="button" class="btn" data-v="no">No</button>
    </div>

    <nav class="pager" aria-label="Previous and next">
      {#if let Some(p) = prev}
        <a class="prev" rel="prev" href={p.path}><small>Previous</small><span>{p.title}</span></a>
      {/if}
      {#if let Some(p) = next}
        <a class="next" rel="next" href={p.path}><small>Next</small><span>{p.title}</span></a>
      {/if}
    </nav>
    <p class="edit"><a href={format!("https://github.com/wyziedevs/wisp-docs/edit/main/{edit}")}>Edit This Page</a></p>
  </article>

  {#if heads.len() > 1}
    <aside class="toc" aria-label="On this page">
      <h2>On This Page</h2>
      <ul>
        {#each heads as (id, text, level)}
          <li class={format!("h{level}")}><a href={format!("#{id}")}>{text}</a></li>
        {/each}
      </ul>
    </aside>
  {/if}
</div>

<script>
  import { afterNavigate } from 'wisp'
  import { spy } from '$lib/toc.js'
  import { wrapTables } from '$lib/tables.js'

  let doc, copied, useful

  // Headings have ids from the build; this adds the link icon that copies one.
  function build() {
    wrapTables(doc)
    for (const h of doc.querySelectorAll('h2[id], h3[id]')) {
      if (h.querySelector('.anchor')) continue
      const a = document.createElement('a')
      a.className = 'anchor'
      a.href = '#' + h.id
      a.setAttribute('aria-label', 'Link to this section')
      a.addEventListener('click', () => {
        navigator.clipboard?.writeText(location.origin + location.pathname + '#' + h.id).then(() => {
          a.classList.add('done')
          copied.textContent = 'Link copied'
          setTimeout(() => {
            a.classList.remove('done')
            copied.textContent = ''
          }, 1200)
        }, () => {})
      })
      h.append(a)
    }
    off?.()
    off = null
    const toc = document.querySelector('.toc ul')
    if (toc) off = spy(toc)
  }

  let off = null

  // Is This Page Useful: a thank you, nothing sent anywhere.
  function feedback(e) {
    const b = e.target.closest('button')
    if (!b) return
    const p = document.createElement('p')
    p.className = 'thanks'
    p.setAttribute('role', 'status')
    p.textContent = b.dataset.v === 'yes' ? 'Thanks for Letting Us Know' : 'Thanks. An issue on GitHub helps us fix it.'
    useful.replaceChildren(p)
  }

  onMount(() => {
    build()
    useful.addEventListener('click', feedback)
    if (location.hash) document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView()
  })
  // A new page eases in; a hash jump or a form post on the same page does not.
  const path = (u) => u && new URL(u, location.href).pathname
  afterNavigate(({ from, to }) => {
    build()
    if (path(from) === path(to) || matchMedia('(prefers-reduced-motion: reduce)').matches) return
    doc.animate(
      [{ opacity: 0, translate: '0 6px' }, { opacity: 1, translate: '0 0' }],
      { duration: 320, easing: 'cubic-bezier(0.16, 1, 0.3, 1)' },
    )
  })
</script>

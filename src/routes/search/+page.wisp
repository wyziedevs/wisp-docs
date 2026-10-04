---
// The search that works without JavaScript: page titles, descriptions and
// headings that hold every word of the query. The header dialog is the fast one.
let q: String = cx.query_or("q", String::new());
let words: Vec<String> = q.to_lowercase().split_whitespace().map(str::to_string).collect();
let has = |text: &str| {
    let t = text.to_lowercase();
    !words.is_empty() && words.iter().all(|w| t.contains(w.as_str()))
};
let toc: &[(&str, &[(&str, &str, u8)])] = include!(concat!(env!("OUT_DIR"), "/toc.rs"));
let mut found: Vec<(String, &str, &str)> = Vec::new();
for p in wisp::pages("").iter().chain(wisp::pages("docs").iter()).chain(wisp::pages("blog").iter()) {
    let about = p.get("description").unwrap_or("");
    if has(&format!("{} {about}", p.title)) {
        found.push((p.path.to_string(), p.title, about));
    }
    let heads = toc.iter().find(|(t, _)| *t == p.path).map_or(&[][..], |(_, h)| *h);
    for (id, text, _) in heads {
        if has(text) {
            found.push((format!("{}#{id}", p.path), text, p.title));
        }
    }
}
---
<head>
  <title>Search the Docs | Wisp Rust Web Framework</title>
  <meta name="robots" content="noindex, follow">
</head>

<div class="page narrow">
  <h1>Search</h1>
  <form class="plain-find" action="/search/" role="search">
    <label class="sr" for="sq">Search the Docs</label>
    <input id="sq" name="q" type="search" value={q} placeholder="Search the Docs">
    <button class="btn primary">Search</button>
  </form>
  <p class="muted" role="status" aria-live="polite" bind:this="count" data-q={q.trim()} hidden={words.is_empty()}>{if !words.is_empty() { format!("{} {} for {q}", found.len(), if found.len() == 1 { "result" } else { "results" }) } else { String::new() }}</p>
  <ul class="found" bind:this="list">
    {#each found as (href, title, about)}
      <li><a href={href}>{title}</a><span>{about}</span></li>
    {/each}
  </ul>
</div>

<script>
  import { afterNavigate } from 'wisp'
  import { results } from '$lib/search.js'

  let count, list

  // A static host cannot run the search for the page, so the page does: the
  // query in the address is answered from the same index as the header box.
  async function fill() {
    const q = new URLSearchParams(location.search).get('q')?.trim() ?? ''
    const field = document.getElementById('sq')
    if (!q || count.dataset.q) return // a server already answered
    field.value = q
    const hits = await results(q)
    list.replaceChildren(
      ...hits.map(({ e }) => {
        const li = document.createElement('li')
        const a = document.createElement('a')
        const span = document.createElement('span')
        a.href = e.path + (e.id ? '#' + e.id : '')
        a.textContent = e.heading || e.title
        span.textContent = e.id ? e.title : e.text
        li.append(a, span)
        return li
      }),
    )
    count.textContent = hits.length + (hits.length === 1 ? ' result' : ' results') + ' for ' + q
    count.hidden = false
  }

  onMount(fill)
  afterNavigate(fill)
</script>

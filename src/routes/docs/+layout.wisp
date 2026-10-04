---
let mut all: Vec<_> = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .filter(|p| p.path.starts_with("/docs"))
    .collect();
all.sort_by_key(|p| {
    p.get("order")
        .and_then(|o| o.parse::<u32>().ok())
        .unwrap_or(999)
});

let mut groups: Vec<(&str, Vec<_>)> = Vec::new();
for p in &all {
    let g = p.get("group").unwrap_or("Docs");
    match groups.last_mut() {
        Some((name, list)) if *name == g => list.push(*p),
        _ => groups.push((g, vec![*p])),
    }
}

let at = all.iter().position(|p| p.path == cx.path());
let prev = at.and_then(|i| i.checked_sub(1)).map(|i| all[i]);
let next = at.and_then(|i| all.get(i + 1)).copied();
let edit = match cx.path() {
    "/docs" => "src/routes/docs/+page.md".to_string(),
    p => format!("src/routes{p}/+page.md"),
};
---
<div class="docs">
  <aside class="side" aria-label="Documentation">
    <details class="menu">
      <summary>Menu</summary>
      <label class="find">
        <span class="sr">Filter pages</span>
        <input type="search" placeholder="Filter pages" autocomplete="off" bind:this="filter">
      </label>
      <nav aria-label="Docs pages" bind:this="menu">
        {#each groups as (name, list)}
          <h2 class="group">{name}</h2>
          <ul>
            {#each list as p}
              <li><a href={p.path} data-find={format!("{} {}", p.title, p.get("description").unwrap_or(""))} aria-current={(p.path == cx.path()).then_some("page")}>{p.title}</a></li>
            {/each}
          </ul>
        {/each}
      </nav>
    </details>
  </aside>

  <article class="doc" bind:this="doc">
    <h1 class="doc-title">{at.map(|i| all[i].title).unwrap_or("")}</h1>
    <slot />
    <nav class="pager" aria-label="Previous and next">
      {#if let Some(p) = prev}
        <a class="prev" rel="prev" href={p.path}><small>Previous</small><span>{p.title}</span></a>
      {/if}
      {#if let Some(p) = next}
        <a class="next" rel="next" href={p.path}><small>Next</small><span>{p.title}</span></a>
      {/if}
    </nav>
    <p class="edit"><a href={format!("https://github.com/wyziedevs/wisp-docs/edit/main/{edit}")}>Edit this page on GitHub</a></p>
  </article>

  <aside class="toc" aria-label="On this page">
    <h2>On this page</h2>
    <ul bind:this="toc"></ul>
  </aside>
</div>

<script>
  import { afterNavigate } from 'wisp'

  let filter, menu, doc, toc

  function slug(text) {
    return text.toLowerCase().replace(/[^\w\- ]/g, '').trim().replace(/ /g, '-')
  }

  function build() {
    toc.replaceChildren()
    for (const h of doc.querySelectorAll('h2:not([id]), h3:not([id]), h4:not([id])')) {
      let id = slug(h.textContent)
      while (document.getElementById(id)) id += '-2'
      h.id = id
    }
    for (const h of doc.querySelectorAll('h2[id], h3[id]')) {
      const li = document.createElement('li')
      li.className = h.tagName.toLowerCase()
      const a = document.createElement('a')
      a.href = '#' + h.id
      a.textContent = h.textContent
      li.append(a)
      toc.append(li)
    }
    toc.parentElement.hidden = toc.children.length < 2
  }

  function narrow() {
    const q = filter.value.trim().toLowerCase()
    for (const a of menu.querySelectorAll('a')) {
      a.parentElement.hidden = q !== '' && !a.dataset.find.toLowerCase().includes(q)
    }
    for (const g of menu.querySelectorAll('.group')) {
      g.hidden = q !== '' && [...g.nextElementSibling.children].every((li) => li.hidden)
    }
  }

  onMount(() => {
    build()
    if (location.hash) document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView()
    filter.addEventListener('input', narrow)
  })
  afterNavigate(build)
</script>

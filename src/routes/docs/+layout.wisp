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
      <div class="find">
        <label class="sr" for="search">Search the docs</label>
        <input
          id="search"
          type="search"
          placeholder="Search the docs"
          autocomplete="off"
          spellcheck="false"
          role="combobox"
          aria-expanded="false"
          aria-controls="search-results"
          aria-autocomplete="list"
          bind:this="filter">
        <p class="sr" role="status" aria-live="polite" bind:this="status"></p>
        <ul
          id="search-results"
          class="results"
          role="listbox"
          aria-label="Search results"
          hidden
          bind:this="results"></ul>
      </div>
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
    <p class="sr" role="status" aria-live="polite" bind:this="copied"></p>
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
    <h2>Contents</h2>
    <ul bind:this="toc"></ul>
  </aside>
</div>

<script>
  import { afterNavigate } from 'wisp'

  let filter, menu, doc, toc, copied

  function slug(text) {
    return text.toLowerCase().replace(/[^\w\- ]/g, '').trim().replace(/ /g, '-')
  }

  function build() {
    toc.replaceChildren()
    for (const h of doc.querySelectorAll('h2:not([id]), h3:not([id]), h4:not([id])')) {
      const base = slug(h.textContent)
      let id = base
      for (let n = 2; document.getElementById(id); n++) id = base + '-' + n
      h.id = id
    }
    for (const h of doc.querySelectorAll('h2[id], h3[id]')) {
      const li = document.createElement('li')
      li.className = h.tagName.toLowerCase()
      const a = document.createElement('a')
      a.href = '#' + h.id
      a.textContent = h.textContent.replace(/^(#|✓)/, '')
      li.append(a)
      toc.append(li)
    }
    toc.parentElement.hidden = toc.children.length < 2
    for (const h of doc.querySelectorAll('h2[id], h3[id]')) {
      if (h.querySelector('.anchor')) continue
      const a = document.createElement('a')
      a.className = 'anchor'
      a.href = '#' + h.id
      a.textContent = '#'
      a.setAttribute('aria-label', 'Link to this section')
      a.addEventListener('click', () => {
        navigator.clipboard?.writeText(location.origin + location.pathname + '#' + h.id).then(() => {
          a.textContent = '✓'
          a.classList.add('done')
          copied.textContent = 'Link copied'
          setTimeout(() => {
            a.textContent = '#'
            a.classList.remove('done')
            copied.textContent = ''
          }, 1200)
        }, () => {})
      })
      h.prepend(a)
    }
    spy()
  }

  let seen = null
  let off = null

  function spy() {
    seen?.disconnect()
    off?.()
    const links = new Map([...toc.querySelectorAll('a')].map((a) => [a.hash.slice(1), a]))
    const heads = [...links.keys()].map((id) => document.getElementById(id)).filter(Boolean)
    let current = null
    let locked = false
    let lockTimer = 0
    let frame = 0

    function mark(id) {
      if (!id || id === current || !links.has(id)) return
      current = id
      for (const [k, a] of links) {
        if (k === id) {
          if (a.getAttribute('aria-current') !== 'true') a.setAttribute('aria-current', 'true')
          const box = toc.parentElement
          if (box.scrollHeight > box.clientHeight) a.scrollIntoView({ block: 'nearest' })
        } else if (a.hasAttribute('aria-current')) a.removeAttribute('aria-current')
      }
    }

    function pick() {
      frame = 0
      if (locked || !heads.length) return
      const atEnd = innerHeight + scrollY >= document.documentElement.scrollHeight - 4
      if (atEnd) return mark(heads[heads.length - 1].id)
      const line = 96
      let last = heads[0]
      for (const h of heads) if (h.getBoundingClientRect().top <= line) last = h
      mark(last.id)
    }

    function queue() {
      if (!frame) frame = requestAnimationFrame(pick)
    }

    function unlock() {
      if (!locked) return
      locked = false
      clearTimeout(lockTimer)
      queue()
    }

    function lock() {
      locked = true
      clearTimeout(lockTimer)
      lockTimer = setTimeout(unlock, 700)
    }

    function click(e) {
      const a = e.target.closest('a')
      if (!a) return
      lock()
      mark(a.hash.slice(1))
    }

    function hash() {
      const id = decodeURIComponent(location.hash.slice(1))
      if (links.has(id)) {
        lock()
        mark(id)
      }
    }

    toc.addEventListener('click', click)
    addEventListener('scroll', queue, { passive: true })
    addEventListener('scrollend', unlock)
    addEventListener('wheel', unlock, { passive: true })
    addEventListener('touchstart', unlock, { passive: true })
    addEventListener('keydown', unlock)
    addEventListener('hashchange', hash)
    addEventListener('popstate', hash)
    off = () => {
      cancelAnimationFrame(frame)
      clearTimeout(lockTimer)
      toc.removeEventListener('click', click)
      removeEventListener('scroll', queue)
      removeEventListener('scrollend', unlock)
      removeEventListener('wheel', unlock)
      removeEventListener('touchstart', unlock)
      removeEventListener('keydown', unlock)
      removeEventListener('hashchange', hash)
      removeEventListener('popstate', hash)
    }
    seen = { disconnect: off }

    if (links.has(decodeURIComponent(location.hash.slice(1)))) hash()
    else pick()
  }

  let status, results
  let index = null
  let loading = null
  let hits = []
  let sel = -1

  function load() {
    loading ??= fetch('/search-index.json')
      .then((r) => r.json())
      .then((pages) => {
        index = []
        for (const [path, title, group, desc, secs] of pages) {
          for (const [id, heading, text] of secs) {
            index.push({ path, title, id, heading, text })
          }
          index.push({ path, title, id: '', heading: '', text: desc })
        }
      })
      .catch(() => (loading = null))
    return loading
  }

  function words(s) {
    return s.toLowerCase().match(/[\p{L}\p{N}_]+/gu) ?? []
  }

  // Edit distance of a to b, or more than max.
  function near(a, b, max) {
    if (Math.abs(a.length - b.length) > max) return max + 1
    let prev = Array.from({ length: b.length + 1 }, (_, i) => i)
    for (let i = 1; i <= a.length; i++) {
      const cur = [i]
      let low = i
      for (let j = 1; j <= b.length; j++) {
        cur[j] = Math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] === b[j - 1] ? 0 : 1))
        if (cur[j] < low) low = cur[j]
      }
      if (low > max) return max + 1
      prev = cur
    }
    return prev[b.length]
  }

  // How well a query word matches a word: exact, prefix, inside, a typo, a subsequence.
  function word(q, w) {
    if (w === q) return 100
    if (w.startsWith(q)) return 80
    if (q.length > 2 && w.includes(q)) return 55
    if (q.length > 3) {
      const k = q.length > 6 ? 2 : 1
      const d = near(q, w, k)
      if (d <= k) return 45 - 5 * d
      if (w.length > q.length && near(q, w.slice(0, q.length), k) <= k) return 35
    }
    if (q.length > 2) {
      let i = 0
      for (const c of w) if (c === q[i]) i++
      if (i === q.length) return 15
    }
    return 0
  }

  function field(text, q, weight) {
    let best = 0
    for (const w of words(text)) {
      const s = word(q, w)
      if (s > best) best = s
    }
    return best * weight
  }

  function score(e, qs) {
    let total = 0
    for (const q of qs) {
      const best = Math.max(field(e.title, q, 5), field(e.heading, q, 3), e.heading === '' ? 0 : field(e.text, q, 1))
      if (!best) return 0
      total += best
    }
    return total + (e.id === '' ? 8 : 0)
  }

  function search(query) {
    const qs = words(query)
    if (!qs.length) return []
    const scored = []
    for (const e of index) {
      const s = score(e, qs)
      if (s) scored.push([s, e])
    }
    scored.sort((a, b) => b[0] - a[0])
    const seen = new Set()
    const out = []
    for (const [, e] of scored) {
      const key = e.path + '#' + e.id
      if (seen.has(key)) continue
      seen.add(key)
      out.push({ e, qs })
      if (out.length === 8) break
    }
    // grouped by page, in the order of each page's best hit
    const order = [...new Set(out.map((h) => h.e.path))]
    return order.flatMap((p) => out.filter((h) => h.e.path === p))
  }

  function snippet(text, qs) {
    const low = text.toLowerCase()
    let at = -1
    for (const q of qs) {
      const i = low.indexOf(q)
      if (i >= 0 && (at < 0 || i < at)) at = i
    }
    const start = Math.max(0, at - 30)
    return (start > 0 ? '...' : '') + text.slice(start, start + 110) + (start + 110 < text.length ? '...' : '')
  }

  function mark(el, text, qs) {
    const esc = qs.map((q) => q.replace(/[.*+?^$()|[\]\\]/g, '\\$&'))
    const re = new RegExp('(' + esc.join('|') + ')', 'gi')
    text.split(re).forEach((piece, i) => {
      if (i % 2) {
        const b = document.createElement('b')
        b.textContent = piece
        el.append(b)
      } else el.append(piece)
    })
  }

  function render(query) {
    results.replaceChildren()
    sel = -1
    filter.removeAttribute('aria-activedescendant')
    const active = query.trim() !== ''
    results.hidden = !active
    menu.hidden = active
    filter.setAttribute('aria-expanded', String(active && hits.length > 0))
    if (!active) {
      status.textContent = ''
      return
    }
    if (!hits.length) {
      const li = document.createElement('li')
      li.className = 'none'
      li.setAttribute('role', 'presentation')
      li.textContent = 'No results'
      results.append(li)
      status.textContent = 'No results'
      return
    }
    let page = null
    hits.forEach(({ e, qs }, i) => {
      if (e.path !== page) {
        page = e.path
        const g = document.createElement('li')
        g.className = 'page'
        g.setAttribute('role', 'presentation')
        g.textContent = e.title
        results.append(g)
      }
      const li = document.createElement('li')
      li.id = 'hit-' + i
      li.setAttribute('role', 'option')
      li.setAttribute('aria-selected', 'false')
      const a = document.createElement('a')
      a.href = e.path + (e.id ? '#' + e.id : '')
      a.tabIndex = -1
      const h = document.createElement('span')
      h.className = 'h'
      mark(h, e.heading || e.title, qs)
      const t = document.createElement('span')
      t.className = 't'
      mark(t, snippet(e.text, qs), qs)
      a.append(h, t)
      li.append(a)
      results.append(li)
    })
    status.textContent = hits.length + (hits.length === 1 ? ' result' : ' results')
  }

  function pick(i) {
    const items = results.querySelectorAll('[role=option]')
    if (!items.length) return
    sel = (i + items.length) % items.length
    items.forEach((li, j) => li.setAttribute('aria-selected', String(j === sel)))
    filter.setAttribute('aria-activedescendant', items[sel].id)
    items[sel].scrollIntoView({ block: 'nearest' })
  }

  async function typed() {
    const q = filter.value
    if (q.trim() && !index) await load()
    if (q !== filter.value || (q.trim() && !index)) return
    hits = q.trim() ? search(q) : []
    render(q)
  }

  function clear() {
    filter.value = ''
    hits = []
    render('')
  }

  function keys(e) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      pick(sel + 1)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      pick(sel < 0 ? -1 : sel - 1)
    } else if (e.key === 'Enter') {
      const items = results.querySelectorAll('[role=option]')
      const li = items[sel < 0 ? 0 : sel]
      if (li) {
        e.preventDefault()
        li.querySelector('a').click()
        clear()
        filter.blur()
      }
    } else if (e.key === 'Escape') {
      clear()
    }
  }

  function shortcut(e) {
    const typing = /^(input|textarea|select)$/i.test(e.target.tagName) || e.target.isContentEditable
    const slash = e.key === '/' && !typing && !e.ctrlKey && !e.metaKey
    const k = (e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k'
    if (!slash && !k) return
    e.preventDefault()
    const box = filter.closest('details')
    if (box) box.open = true
    filter.focus()
    filter.select()
  }

  onMount(() => {
    build()
    if (location.hash) document.getElementById(decodeURIComponent(location.hash.slice(1)))?.scrollIntoView()
    filter.addEventListener('focus', load, { once: true })
    filter.addEventListener('input', typed)
    filter.addEventListener('keydown', keys)
    addEventListener('keydown', shortcut)
    results.addEventListener('click', () => setTimeout(clear, 0))
  })
  afterNavigate(build)
</script>

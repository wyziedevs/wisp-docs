---
const SITE: &str = "https://wispweb.dev";
// The wisp crate's version, from ../wisp/Cargo.toml ([workspace.package]).
const VERSION: &str = "v0.1.0";
// The docs groups that make up Reference; every other group is Learn.
const REFERENCE: &[&str] = &["Reference", "Design"];

let path = cx.path();
let home = path == "/";
let me = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .chain(wisp::pages("blog").iter())
    .find(|p| p.path == path);
let title = me.map_or("Wisp", |p| p.title);
let about = me
    .and_then(|p| p.get("description"))
    .unwrap_or("A fast, fun web framework for Rust");
let reference = me.is_some_and(|p| {
    p.path.starts_with("/docs") && REFERENCE.contains(&p.get("group").unwrap_or(""))
});
let learn = !reference && (path == "/docs" || path.starts_with("/docs/"));
let community = path == "/community";
let blog = path == "/blog" || path.starts_with("/blog/");
let links = [
    ("/docs", "Learn", learn),
    ("/docs/design", "Reference", reference),
    ("/community", "Community", community),
    ("/blog", "Blog", blog),
];
---
<head>
  <meta name="description" content={about}>
  <meta name="author" content="Wyzie LLC">
  {@html wisp::og(title, about, &format!("{SITE}/og.png"))}
  <link rel="canonical" href={format!("{SITE}{}", path)}>
  <meta name="twitter:card" content="summary_large_image">
</head>
<a class="skip" href="#main">Skip to Content</a>
<header class="top">
  <div class="bar">
    <a class="brand" href="/" aria-label="Wisp home">
      <span
        class="ghost"
        aria-hidden="true"
        bind:this="ghost"
        on:pointermove.window="look"
        style:--look-x="x"
        style:--look-y="y">
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
    <a class="ver" href="https://github.com/wyziedevs/wisp" aria-label={format!("Version {VERSION}")}>{VERSION}</a>

    <form class="search" action="/search" role="search" bind:this="bar">
      <label class="sr" for="q">Search</label>
      <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
      <input id="q" name="q" type="search" placeholder="Search" autocomplete="off" spellcheck="false" bind:this="q">
      <kbd class="key" aria-hidden="true"><span bind:this="mod">Ctrl</span> K</kbd>
    </form>

    <nav class="links" aria-label="Site">
      {#each links as (href, name, on)}
        <a href={href} aria-current={on.then_some("page")}>{name}</a>
      {/each}
    </nav>

    <button class="icon theme" type="button" on:click="flip()" aria-label="Switch Light or Dark Theme">
      <svg class="moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>
      <svg class="sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>
    </button>
    <a class="icon gh" href="https://github.com/wyziedevs/wisp" aria-label="Wisp on GitHub">
      <svg viewBox="0 0 24 24" aria-hidden="true"><path class="fill" d="M12 1.5a10.5 10.5 0 0 0-3.3 20.47c.52.1.72-.23.72-.5v-1.8c-2.92.63-3.54-1.4-3.54-1.4-.48-1.22-1.17-1.54-1.17-1.54-.95-.65.08-.64.08-.64 1.05.08 1.6 1.08 1.6 1.08.94 1.6 2.46 1.14 3.06.87.1-.68.37-1.14.66-1.4-2.33-.27-4.78-1.17-4.78-5.18 0-1.15.4-2.08 1.08-2.82-.1-.27-.47-1.34.1-2.78 0 0 .88-.29 2.89 1.07a10 10 0 0 1 5.26 0c2-1.36 2.88-1.07 2.88-1.07.58 1.44.21 2.51.1 2.78.68.74 1.08 1.67 1.08 2.82 0 4.02-2.45 4.9-4.79 5.16.38.33.71.97.71 1.95v2.9c0 .28.19.6.72.5A10.5 10.5 0 0 0 12 1.5z"/></svg>
    </a>

    <details class="mnav">
      <summary aria-label="Menu"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h16M4 12h16M4 17h16"/></svg></summary>
      <nav aria-label="Site menu">
        {#each links as (href, name, on)}
          <a href={href} aria-current={on.then_some("page")}>{name}</a>
        {/each}
        <a href="https://github.com/wyziedevs/wisp">GitHub</a>
      </nav>
    </details>
  </div>
</header>

<dialog class="finder" aria-label="Search the Docs" bind:this="dlg">
  <div class="find-bar">
    <svg class="i" viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
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
    <button class="esc" type="button" on:click="close()">Esc</button>
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
      <a href="/docs">Getting Started</a>
      <a href="/docs/why">Why Wisp</a>
      <a href="/docs/overview">Overview</a>
      <a href="/docs/tokens">Tokens</a>
      <a href="/docs/benchmarks">Benchmarks</a>
    </nav>
    <nav aria-label="Reference">
      <h2>Reference</h2>
      <a href="/docs/design">Design and Files</a>
      <a href="/docs/cli">CLI Reference</a>
      <a href="/docs/env">Environment Variables</a>
      <a href="/docs/config">Knobs and Settings</a>
    </nav>
    <nav aria-label="Community">
      <h2>Community</h2>
      <a href="/community">Community</a>
      <a href="/blog">Blog</a>
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

  // Every code block can be focused and copied.
  function focusable() {
    for (const p of document.querySelectorAll('pre')) {
      p.tabIndex = 0
      if (p.querySelector('.copy-code')) continue
      const b = document.createElement('button')
      b.type = 'button'
      b.className = 'copy-code'
      b.textContent = 'Copy'
      b.setAttribute('aria-label', 'Copy code')
      b.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(p.querySelector('code').innerText)
          b.textContent = 'Copied'
          b.classList.add('done')
        } catch (e) {
          b.textContent = 'Press Ctrl+C'
        }
        setTimeout(() => {
          b.textContent = 'Copy'
          b.classList.remove('done')
        }, 1500)
      })
      p.append(b)
    }
  }

  // Theme: the head script already applied a saved choice; this flips it.
  function flip() {
    const root = document.documentElement
    const now = root.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    const next = now === 'dark' ? 'light' : 'dark'
    root.dataset.theme = next
    try {
      localStorage.setItem('theme', next)
    } catch (e) {}
  }

  let ghost
  let x = 0, y = 0, frame = 0, last = null
  const calm = matchMedia('(prefers-reduced-motion: reduce)')

  // The ghost's eyes and body lean toward the pointer, one update a frame.
  function look(e) {
    if (calm.matches) return
    last = e
    if (!frame) frame = requestAnimationFrame(aim)
  }

  function aim() {
    frame = 0
    const box = ghost.getBoundingClientRect()
    const dx = last.clientX - (box.left + box.width / 2)
    const dy = last.clientY - (box.top + box.height * 0.4)
    const d = Math.hypot(dx, dy) || 1
    const k = Math.min(1, d / 240) / d
    x = (dx * k).toFixed(3)
    y = (dy * k).toFixed(3)
  }

  // The ghost hops when a new page arrives, and says boo when you type it.
  function play(name) {
    if (calm.matches || !ghost) return
    ghost.classList.remove('hop', 'boo')
    void ghost.offsetWidth
    ghost.classList.add(name)
  }

  const typing = (t) => /^(input|textarea|select)$/i.test(t.tagName) || t.isContentEditable

  let typedKeys = ''
  function boo(e) {
    if (typing(e.target)) return
    typedKeys = (typedKeys + e.key.toLowerCase()).slice(-3)
    if (typedKeys === 'boo') play('boo')
  }

  // Search: the header field opens a dialog over the docs index. Without
  // JavaScript the field is a plain form that posts to /search.
  let bar, q, mod, dlg, fq, status, hits, tip
  let index = null
  let loading = null
  let found = []
  let sel = -1

  function load() {
    loading ??= fetch('/search-index.json')
      .then((r) => r.json())
      .then((pages) => {
        index = []
        for (const [path, title, , desc, secs] of pages) {
          for (const [id, heading, text] of secs) index.push({ path, title, id, heading, text })
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
  function word(qw, w) {
    if (w === qw) return 100
    if (w.startsWith(qw)) return 80
    if (qw.length > 2 && w.includes(qw)) return 55
    if (qw.length > 3) {
      const k = qw.length > 6 ? 2 : 1
      const d = near(qw, w, k)
      if (d <= k) return 45 - 5 * d
      if (w.length > qw.length && near(qw, w.slice(0, qw.length), k) <= k) return 35
    }
    if (qw.length > 2) {
      let i = 0
      for (const c of w) if (c === qw[i]) i++
      if (i === qw.length) return 15
    }
    return 0
  }

  function field(text, qw, weight) {
    let best = 0
    for (const w of words(text)) {
      const s = word(qw, w)
      if (s > best) best = s
    }
    return best * weight
  }

  function score(e, qs) {
    let total = 0
    for (const qw of qs) {
      const best = Math.max(field(e.title, qw, 5), field(e.heading, qw, 3), e.heading === '' ? 0 : field(e.text, qw, 1))
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
      if (out.length === 10) break
    }
    // grouped by page, in the order of each page's best hit
    const order = [...new Set(out.map((h) => h.e.path))]
    return order.flatMap((p) => out.filter((h) => h.e.path === p))
  }

  function snippet(text, qs) {
    const low = text.toLowerCase()
    let at = -1
    for (const qw of qs) {
      const i = low.indexOf(qw)
      if (i >= 0 && (at < 0 || i < at)) at = i
    }
    const start = Math.max(0, at - 30)
    return (start > 0 ? '...' : '') + text.slice(start, start + 110) + (start + 110 < text.length ? '...' : '')
  }

  function mark(el, text, qs) {
    const esc = qs.map((s) => s.replace(/[.*+?^$()|[\]\\]/g, '\\$&'))
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
    hits.replaceChildren()
    sel = -1
    fq.removeAttribute('aria-activedescendant')
    const active = query.trim() !== ''
    tip.hidden = active
    fq.setAttribute('aria-expanded', String(active && found.length > 0))
    if (!active) {
      status.textContent = ''
      return
    }
    if (!found.length) {
      const li = document.createElement('li')
      li.className = 'none'
      li.setAttribute('role', 'presentation')
      li.textContent = 'No Results'
      hits.append(li)
      status.textContent = 'No Results'
      return
    }
    let page = null
    found.forEach(({ e, qs }, i) => {
      if (e.path !== page) {
        page = e.path
        const g = document.createElement('li')
        g.className = 'page'
        g.setAttribute('role', 'presentation')
        g.textContent = e.title
        hits.append(g)
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
      hits.append(li)
    })
    status.textContent = found.length + (found.length === 1 ? ' result' : ' results')
    choose(0)
  }

  function choose(i) {
    const items = hits.querySelectorAll('[role=option]')
    if (!items.length) return
    sel = (i + items.length) % items.length
    items.forEach((li, j) => li.setAttribute('aria-selected', String(j === sel)))
    fq.setAttribute('aria-activedescendant', items[sel].id)
    items[sel].scrollIntoView({ block: 'nearest' })
  }

  async function typed() {
    const v = fq.value
    if (v.trim() && !index) await load()
    if (v !== fq.value || (v.trim() && !index)) return
    found = v.trim() ? search(v) : []
    render(v)
  }

  function open(v = '') {
    if (!dlg.open) dlg.showModal()
    fq.value = v
    fq.focus()
    load()
    typed()
  }

  function close() {
    if (dlg.open) dlg.close()
  }

  function keys(e) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      choose(sel + 1)
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      choose(sel - 1)
    } else if (e.key === 'Enter') {
      e.preventDefault()
      const li = hits.querySelectorAll('[role=option]')[sel < 0 ? 0 : sel]
      if (li) li.querySelector('a').click()
      else if (fq.value.trim()) location.href = '/search?q=' + encodeURIComponent(fq.value)
      close()
    }
  }

  function shortcut(e) {
    const k = (e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k'
    const slash = e.key === '/' && !typing(e.target) && !e.ctrlKey && !e.metaKey
    if (!k && !slash) return
    e.preventDefault()
    open()
  }

  const path = (u) => u && new URL(u, location.href).pathname

  onMount(() => {
    focusable()
    if (/Mac|iPhone|iPad/.test(navigator.platform)) mod.textContent = '⌘'
    bar.addEventListener('submit', (e) => {
      e.preventDefault()
      open(q.value)
    })
    q.addEventListener('pointerdown', (e) => {
      e.preventDefault()
      open(q.value)
    })
    q.addEventListener('input', () => {
      open(q.value)
      q.value = ''
    })
    fq.addEventListener('input', typed)
    fq.addEventListener('keydown', keys)
    dlg.addEventListener('click', (e) => {
      if (e.target === dlg) close()
      else if (e.target.closest('a')) setTimeout(close, 0)
    })
    ghost.addEventListener('animationend', (e) => {
      if (e.animationName === 'hop' || e.animationName === 'boo') ghost.classList.remove('hop', 'boo')
    })
    addEventListener('keydown', shortcut)
    addEventListener('keydown', boo)
    console.log('%cwispweb.dev is a Wisp app, one Rust binary. Source: https://github.com/wyziedevs/wisp-docs\n%cTry typing boo.', 'color:#a17ff5;font-weight:600', 'color:inherit')
  })
  afterNavigate(({ from, to }) => {
    focusable()
    close()
    document.querySelector('.mnav')?.removeAttribute('open')
    if (path(from) !== path(to)) play('hop')
  })
</script>

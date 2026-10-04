// Search: the header field opens a dialog over the docs index. Without
// JavaScript the field is a plain form that posts to /search.
export const typing = (t) => /^(input|textarea|select)$/i.test(t.tagName) || t.isContentEditable

const words = (s) => s.toLowerCase().match(/[\p{L}\p{N}_]+/gu) ?? []
const unique = (s) => [...new Set(words(s))]

let index = null
let loading = null

// The index is fetched once; every entry's words are split once, here.
function load() {
  loading ??= fetch('/search-index.json')
    .then((r) => r.json())
    .then((pages) => {
      index = []
      for (const [path, title, , desc, secs] of pages) {
        const tw = unique(title)
        for (const [id, heading, text] of secs) {
          index.push({ path, title, id, heading, text, tw, hw: unique(heading), xw: unique(text) })
        }
        index.push({ path, title, id: '', heading: '', text: desc, tw, hw: [], xw: [] })
      }
    })
    .catch(() => (loading = null))
  return loading
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

// One edit leaves one of the first two letters in place (or shifts them), so
// words that share none of them are skipped before the edit distance runs.
const alike = (a, b) => a[0] === b[0] || a[1] === b[1] || a[0] === b[1] || a[1] === b[0]

// How well a query word matches a word: exact, prefix, inside, a typo, a subsequence.
function word(qw, w) {
  if (w === qw) return 100
  if (w.startsWith(qw)) return 80
  if (qw.length > 2 && w.includes(qw)) return 55
  if (qw.length > 3) {
    const k = qw.length > 6 ? 2 : 1
    if (k === 2 || alike(qw, w)) {
      const d = near(qw, w, k)
      if (d <= k) return 45 - 5 * d
      if (w.length > qw.length && near(qw, w.slice(0, qw.length), k) <= k) return 35
    }
  }
  if (qw.length > 2) {
    let i = 0
    for (const c of w) if (c === qw[i]) i++
    if (i === qw.length) return 15
  }
  return 0
}

function field(list, qw, weight) {
  let best = 0
  for (const w of list) {
    const s = word(qw, w)
    if (s > best) best = s
  }
  return best * weight
}

function score(e, qs) {
  let total = 0
  for (const qw of qs) {
    const best = Math.max(field(e.tw, qw, 5), field(e.hw, qw, 3), e.heading === '' ? 0 : field(e.xw, qw, 1))
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

// Wires the header form and the dialog. els: bar, q, dlg, fq, status, hits, tip.
// Returns { open, close }.
export function finder({ bar, q, dlg, fq, status, hits, tip }) {
  let found = []
  let sel = -1
  let frame = 0

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
    frame = 0
    const v = fq.value
    if (v.trim() && !index) await load()
    if (v !== fq.value || (v.trim() && !index)) return
    found = v.trim() ? search(v) : []
    render(v)
  }

  // One search a frame, however fast the keys come.
  const soon = () => frame || (frame = requestAnimationFrame(typed))

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
  fq.addEventListener('input', soon)
  fq.addEventListener('keydown', keys)
  dlg.addEventListener('click', (e) => {
    if (e.target === dlg) close()
    else if (e.target.closest('a')) setTimeout(close, 0)
  })
  addEventListener('keydown', shortcut)
  return { open, close }
}

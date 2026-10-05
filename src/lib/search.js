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

// The hits for a query, for the search page: the same ranking as the box, ten at most.
export async function results(query) {
  await load()
  return index ? search(query) : []
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

// Wires the header form and the results box. els: bar, q, dlg, fq, status,
// hits, tip. From 48rem the header field is the search box and the results
// drop below it (at least 32rem wide, centered); on a narrower screen they open as a modal with its own field
// (fq). Returns { open, close }.
export function finder({ bar, q, dlg, fq: modalField, status, hits, tip }) {
  const wide = matchMedia('(min-width: 48rem)')
  let fq = modalField
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
      li.textContent = 'No results'
      hits.append(li)
      status.textContent = 'No results'
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

  function choose(i, scroll = true) {
    const items = hits.querySelectorAll('[role=option]')
    if (!items.length) return
    sel = (i + items.length) % items.length
    items.forEach((li, j) => li.setAttribute('aria-selected', String(j === sel)))
    fq.setAttribute('aria-activedescendant', items[sel].id)
    if (scroll) items[sel].scrollIntoView({ block: 'nearest' })
  }

  // The pointer moves the one highlight (no second hover highlight beside the keyboard's).
  hits.addEventListener('pointermove', (e) => {
    const li = e.target.closest('[role=option]')
    const i = li ? [...hits.querySelectorAll('[role=option]')].indexOf(li) : -1
    if (i >= 0 && i !== sel) choose(i, false)
  })

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

  // The results sit under the header field, as wide as it is.
  function place() {
    const r = bar.getBoundingClientRect()
    const w = Math.min(Math.max(r.width, 32 * 16), innerWidth - 32)
    const left = Math.min(Math.max(r.left + r.width / 2 - w / 2, 16), innerWidth - 16 - w)
    dlg.style.setProperty('--drop-top', r.bottom + 8 + 'px')
    dlg.style.setProperty('--drop-left', left + 'px')
    dlg.style.setProperty('--drop-w', w + 'px')
  }

  function open(v = '') {
    if (wide.matches) {
      fq = q
      dlg.classList.add('drop')
      place()
      if (!dlg.open) dlg.show()
      q.value = v
      q.focus()
    } else {
      fq = modalField
      dlg.classList.remove('drop')
      if (!dlg.open) dlg.showModal()
      fq.value = v
      fq.focus()
    }
    load()
    typed()
  }

  function close() {
    if (dlg.open) dlg.close()
    dlg.classList.remove('drop')
    fq.setAttribute('aria-expanded', 'false')
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
      else if (fq.value.trim()) location.href = '/search/?q=' + encodeURIComponent(fq.value)
      close()
      if (fq === q) q.blur()
    }
  }

  function shortcut(e) {
    const k = (e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k'
    const slash = e.key === '/' && !typing(e.target) && !e.ctrlKey && !e.metaKey
    if (!k && !slash) return
    e.preventDefault()
    open(wide.matches ? q.value : '')
    if (wide.matches) q.select()
  }

  q.setAttribute('role', 'combobox')
  q.setAttribute('aria-controls', 'find-hits')
  q.setAttribute('aria-expanded', 'false')
  q.setAttribute('aria-autocomplete', 'list')
  bar.addEventListener('submit', (e) => {
    e.preventDefault()
    if (!wide.matches) open(q.value)
  })
  q.addEventListener('pointerdown', (e) => {
    if (wide.matches) return
    e.preventDefault()
    open(q.value)
  })
  q.addEventListener('focus', () => wide.matches && open(q.value))
  q.addEventListener('input', () => {
    if (wide.matches) return dlg.open ? soon() : open(q.value)
    open(q.value)
    q.value = ''
  })
  q.addEventListener('keydown', (e) => {
    if (!wide.matches) return
    if (e.key === 'Escape') {
      close()
      q.blur()
    } else keys(e)
  })
  // The dialog takes focus as it opens and the field takes it back; only a blur that stays is a close.
  q.addEventListener('blur', () => wide.matches && setTimeout(() => document.activeElement !== q && close(), 0))
  fq.addEventListener('input', soon)
  fq.addEventListener('keydown', keys)
  addEventListener('resize', () => dlg.classList.contains('drop') && place())
  // Keep the field's focus while a result is pressed; the click still lands.
  dlg.addEventListener('pointerdown', (e) => dlg.classList.contains('drop') && e.preventDefault())
  dlg.addEventListener('click', (e) => {
    if (e.target === dlg) close()
    else if (e.target.closest('a')) setTimeout(close, 0)
  })
  addEventListener('keydown', shortcut)
  return { open, close }
}

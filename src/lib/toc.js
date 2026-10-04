// Shared by the docs and blog layouts: the pathname of a URL, heading anchors,
// and the On This Page list that marks the section being read.
export const path = (u) => u && new URL(u, location.href).pathname

// Adds the link icon to every h2 and h3 with an id under root. With `say`, a
// click copies the heading's link and says so through it.
export function anchors(root, say) {
  for (const h of root.querySelectorAll('h2[id], h3[id]')) {
    if (h.querySelector('.anchor')) continue
    const a = document.createElement('a')
    a.className = 'anchor'
    a.href = '#' + h.id
    a.setAttribute('aria-label', 'Link to this section')
    if (say) {
      a.addEventListener('click', () => {
        navigator.clipboard?.writeText(location.origin + location.pathname + '#' + h.id).then(() => {
          a.classList.add('done')
          say('Link copied')
          setTimeout(() => {
            a.classList.remove('done')
            say('')
          }, 1200)
        }, () => {})
      })
    }
    h.append(a)
  }
}

// Anchors under root and the On This Page list at `list`. Returns the stop function.
export function reading(root, list, say) {
  anchors(root, say)
  const toc = document.querySelector(list)
  return toc ? spy(toc) : () => {}
}

// The On This Page list (docs and blog posts) marks the section being read.
// One IntersectionObserver watches a band near the top of the viewport.
// Returns the function that stops it.
export function spy(toc) {
  const links = new Map([...toc.querySelectorAll('a')].map((a) => [a.hash.slice(1), a]))
  const heads = [...links.keys()].map((id) => document.getElementById(id)).filter(Boolean)
  const seen = new Set()
  let current = null
  let locked = false
  let lockTimer = 0
  let bottom = false

  function mark(id) {
    if (!id || id === current || !links.has(id)) return
    current = id
    for (const [k, a] of links) {
      if (k === id) {
        a.setAttribute('aria-current', 'true')
        const box = toc.parentElement
        if (box.scrollHeight > box.clientHeight) a.scrollIntoView({ block: 'nearest' })
      } else a.removeAttribute('aria-current')
    }
  }

  // The heading in the band, else the last one above it, else the first. At the end the last.
  function pick() {
    if (locked || !heads.length) return
    if (bottom) return mark(heads[heads.length - 1].id)
    let at = heads.find((h) => seen.has(h))
    if (!at) {
      at = heads[0]
      for (const h of heads) if (h.getBoundingClientRect().top <= 96) at = h
    }
    mark(at.id)
  }

  function unlock() {
    if (!locked) return
    locked = false
    clearTimeout(lockTimer)
    pick()
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

  const band = new IntersectionObserver(
    (list) => {
      for (const e of list) e.isIntersecting ? seen.add(e.target) : seen.delete(e.target)
      pick()
    },
    { rootMargin: '-96px 0px -70% 0px' },
  )
  for (const h of heads) band.observe(h)

  // The end of the page is a zero-height marker: in view means the last section.
  const end = document.createElement('div')
  end.setAttribute('aria-hidden', 'true')
  document.getElementById('main')?.append(end)
  const foot = new IntersectionObserver((list) => {
    bottom = list[list.length - 1].isIntersecting
    pick()
  })
  foot.observe(end)

  const on = [
    ['scrollend', unlock],
    ['wheel', unlock, { passive: true }],
    ['touchstart', unlock, { passive: true }],
    ['keydown', unlock],
    ['hashchange', hash],
    ['popstate', hash],
  ]
  toc.addEventListener('click', click)
  for (const [n, f, o] of on) addEventListener(n, f, o)
  const off = () => {
    band.disconnect()
    foot.disconnect()
    end.remove()
    clearTimeout(lockTimer)
    toc.removeEventListener('click', click)
    for (const [n, f] of on) removeEventListener(n, f)
  }

  if (links.has(decodeURIComponent(location.hash.slice(1)))) hash()
  else pick()
  return off
}

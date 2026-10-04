// The On This Page list (docs and blog posts) marks the section being read.
// Returns the function that stops it.
export function spy(toc) {
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
        a.setAttribute('aria-current', 'true')
        const box = toc.parentElement
        if (box.scrollHeight > box.clientHeight) a.scrollIntoView({ block: 'nearest' })
      } else a.removeAttribute('aria-current')
    }
  }

  function pick() {
    frame = 0
    if (locked || !heads.length) return
    if (innerHeight + scrollY >= document.documentElement.scrollHeight - 4) return mark(heads[heads.length - 1].id)
    let last = heads[0]
    for (const h of heads) if (h.getBoundingClientRect().top <= 96) last = h
    mark(last.id)
  }

  const queue = () => frame || (frame = requestAnimationFrame(pick))

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

  const on = [
    ['scroll', queue, { passive: true }],
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
    cancelAnimationFrame(frame)
    clearTimeout(lockTimer)
    toc.removeEventListener('click', click)
    for (const [n, f] of on) removeEventListener(n, f)
  }

  if (links.has(decodeURIComponent(location.hash.slice(1)))) hash()
  else pick()
  return off
}

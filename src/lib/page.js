// Page chrome every route shares: code blocks and the theme switch.
const COLORS = { light: '#fcfbfe', dark: '#1c1b24' }

// Theme: the head script already applied a saved choice; this flips it.
export function flip() {
  const root = document.documentElement
  const now = root.dataset.theme || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  const next = now === 'dark' ? 'light' : 'dark'
  root.dataset.theme = next
  for (const m of document.querySelectorAll('meta[name=theme-color]')) {
    m.content = COLORS[next]
    m.media = 'all'
  }
  try {
    localStorage.setItem('theme', next)
  } catch (e) {}
}

// A block or table that scrolls can be focused (and read as a region); one that fits is left alone.
const fit = (p) => {
  const over = p.scrollWidth > p.clientWidth || p.scrollHeight > p.clientHeight
  if (over) {
    p.tabIndex = 0
    p.setAttribute('role', 'region')
    p.setAttribute('aria-label', p.tagName === 'PRE' ? 'Code' : 'Table')
  } else {
    p.removeAttribute('tabindex')
    p.removeAttribute('role')
    p.removeAttribute('aria-label')
  }
}
const watch = new ResizeObserver((list) => list.forEach((e) => fit(e.target)))

// Every code block gets a copy button and, if it overflows, a focus stop.
export function blocks() {
  watch.disconnect()
  // An article table scrolls inside its own wrapper rather than widening the page.
  for (const t of document.querySelectorAll('.doc table:not(.tally)')) {
    if (t.parentElement.classList.contains('table-wrap')) continue
    const w = document.createElement('div')
    w.className = 'table-wrap'
    t.replaceWith(w)
    w.append(t)
  }
  for (const t of document.querySelectorAll('.table-wrap, .bench')) watch.observe(t)
  for (const p of document.querySelectorAll('pre')) {
    watch.observe(p)
    if (p.querySelector('.copy-code')) continue
    const b = document.createElement('button')
    b.type = 'button'
    b.className = 'copy-code'
    b.textContent = 'Copy'
    b.setAttribute('aria-label', 'Copy code')
    b.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(p.querySelector('code').textContent)
        b.textContent = 'Copied'
        b.classList.add('done')
      } catch (e) {
        getSelection()?.selectAllChildren(p.querySelector('code'))
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

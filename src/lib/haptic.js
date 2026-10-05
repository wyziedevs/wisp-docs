// Haptic taps on every press. Android Chrome: navigator.vibrate. iOS 17.4+
// Safari: toggling a hidden <input type=checkbox switch> through its label
// inside the gesture gives a system tick. Desktop and everything else: silent.
// Off under prefers-reduced-motion or prefers-reduced-data. Never throws, never logs.
const quiet = (q) => {
  try {
    return matchMedia(q)
  } catch (e) {
    return { matches: false }
  }
}
const still = quiet('(prefers-reduced-motion: reduce)')
const lean = quiet('(prefers-reduced-data: reduce)')

// Android motors skip pulses under about 15ms, so the lightest is 15.
const PULSES = {
  tap: 15,
  key: [8, 30, 8],
  strong: 25,
  copy: [15, 50, 25],
  add: 20,
  remove: 20,
}

let tick = null
// Builds the iOS switch once: off-screen, not display:none, hidden from readers.
function ios() {
  if (tick !== null) return tick
  tick = false
  try {
    const i = document.createElement('input')
    i.type = 'checkbox'
    i.setAttribute('switch', '')
    if (!('switch' in i) && !/iP(hone|ad|od)|Macintosh/.test(navigator.userAgent)) return tick
    if (!('ontouchend' in document)) return tick
    const l = document.createElement('label')
    l.setAttribute('aria-hidden', 'true')
    i.tabIndex = -1
    l.style.cssText = 'position:fixed;left:-9999px;top:0;width:1px;height:1px;opacity:0;pointer-events:none'
    l.append(i)
    document.body.append(l)
    tick = l
  } catch (e) {}
  return tick
}

// Buzzes the named pulse: 'tap', 'key', 'strong', 'copy', 'add' or 'remove'.
// Call it synchronously from a user gesture so iOS honors it.
export function haptic(name) {
  if (still.matches || lean.matches) return
  try {
    if (typeof navigator.vibrate === 'function') {
      navigator.vibrate(PULSES[name] ?? PULSES.tap)
      return
    }
    const l = ios()
    if (!l) return
    l.click()
    // A second tick reads as a firmer pulse for primary actions and successes.
    if (name === 'strong' || name === 'copy') setTimeout(() => l.click(), 60)
  } catch (e) {}
}

const PRESS = 'a[href], button, summary, label, [role=button], [role=tab], [role=option], input[type=submit], input[type=checkbox], input[type=radio], input[type=search]'
const PROSE = '.content, .doc article, .prose, .post-body'
const TOGGLE = 'summary, .tabs, [role=tab], .theme, .mnav, input[type=checkbox], input[type=radio]'
const PRIMARY = '.btn.primary, .primary, [type=submit], .install, .cta'

function kind(t) {
  if (t.matches(TOGGLE) || t.closest('.tabs, .mnav > summary')) return 'key'
  if (t.closest(PRIMARY)) return 'strong'
  return 'tap'
}

// Wires haptics to every press on the page, through one delegated listener, so
// content added later (page changes, search hits) needs no wiring. Returns the stop function.
export function haptics() {
  const press = (e) => {
    if (!e.isTrusted || e.target === tick || e.target?.parentNode === tick) return
    const t = e.target.closest?.(PRESS)
    if (!t || t === tick) return
    // Links inside docs prose stay calm; buttons in prose (copy) still tick.
    if (t.matches('a') && t.closest(PROSE) && !t.closest('.copy-code, .copy-icon')) return
    if (t.closest('form') && t.matches('[type=submit], button:not([type=button])')) return // the submit handler buzzes
    haptic(kind(t))
  }
  // A copy finishing: the button, the install box or a heading link gains `done`.
  // Android buzzes here; iOS already ticked on the press itself.
  const seen = new MutationObserver((list) => {
    for (const m of list) {
      if (m.target.classList.contains('done') && !(m.oldValue || '').split(' ').includes('done')) {
        if (typeof navigator.vibrate === 'function') haptic('copy')
      }
    }
  })
  const form = (e) => haptic(e.submitter?.classList.contains('remove') ? 'remove' : 'strong')
  document.addEventListener('click', press, true)
  document.addEventListener('submit', form, true)
  seen.observe(document.body, { subtree: true, attributes: true, attributeFilter: ['class'], attributeOldValue: true })
  return () => {
    document.removeEventListener('click', press, true)
    document.removeEventListener('submit', form, true)
    seen.disconnect()
  }
}

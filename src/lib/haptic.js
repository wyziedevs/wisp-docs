// Tiny haptic taps on phones that support them (navigator.vibrate). A no-op
// elsewhere and when the visitor prefers reduced motion. Only called from
// press handlers (never on hover or scroll), so a user gesture is always behind it.
const calm = matchMedia('(prefers-reduced-motion: reduce)')

const PULSES = {
  tap: 10,
  key: 6,
  copy: [10, 40, 10],
  add: 8,
  remove: 8,
}

// Buzzes the named pulse: 'tap', 'key', 'copy', 'add' or 'remove'.
export function haptic(name) {
  if (calm.matches || !navigator.vibrate) return
  try {
    navigator.vibrate(PULSES[name] ?? PULSES.tap)
  } catch (e) {}
}

// Wires haptics to every press on the page. Returns the stop function.
export function haptics() {
  const press = (e) => {
    if (!e.isTrusted) return
    const t = e.target.closest?.('a[href], button, summary, label, [role=button]')
    if (!t || t.closest('.copy-code, .anchor, .copy-icon')) return
    if (t.closest('.demo')) return
    haptic(t.matches('summary') || t.closest('.tabs') ? 'key' : 'tap')
  }
  // A copy finishing: the button, the install box or a heading link gains `done`.
  const seen = new MutationObserver((list) => {
    for (const m of list) {
      if (m.target.classList.contains('done') && !(m.oldValue || '').split(' ').includes('done')) haptic('copy')
    }
  })
  const form = (e) => haptic(e.submitter?.classList.contains('remove') ? 'remove' : 'add')
  document.addEventListener('click', press)
  document.addEventListener('submit', form)
  seen.observe(document.body, { subtree: true, attributes: true, attributeFilter: ['class'], attributeOldValue: true })
  return () => {
    document.removeEventListener('click', press)
    document.removeEventListener('submit', form)
    seen.disconnect()
  }
}

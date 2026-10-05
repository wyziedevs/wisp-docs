// The header ghost: it leans toward the pointer (where there is one), hops
// when a new page arrives and says boo when you type it.
import { typing } from '$lib/search.js'

// Returns { play }. `el` is the ghost span; its --look-x and --look-y follow the pointer.
export function ghost(el) {
  const calm = matchMedia('(prefers-reduced-motion: reduce)')
  let box = null
  let frame = 0
  let last = null

  // The ghost's eyes and body lean toward the pointer, one update a frame.
  function aim() {
    frame = 0
    box ??= el.getBoundingClientRect()
    const dx = last.clientX - (box.left + box.width / 2)
    const dy = last.clientY - (box.top + box.height * 0.4)
    const d = Math.hypot(dx, dy) || 1
    const k = Math.min(1, d / 240) / d
    el.style.setProperty('--look-x', (dx * k).toFixed(3))
    el.style.setProperty('--look-y', (dy * k).toFixed(3))
  }

  function look(e) {
    if (calm.matches) return
    last = e
    if (!frame) frame = requestAnimationFrame(aim)
  }

  function play(name) {
    if (calm.matches) return
    el.classList.remove('hop', 'boo', 'happy', 'spin')
    void el.offsetWidth
    el.classList.add(name)
  }

  let typed = ''
  function boo(e) {
    if (typing(e.target)) return
    typed = (typed + e.key.toLowerCase()).slice(-3)
    if (typed === 'boo') play('boo')
  }

  // Touch screens have no pointer to follow; the header stays put, so the box is kept.
  if (matchMedia('(hover: hover)').matches) {
    addEventListener('pointermove', look, { passive: true })
    addEventListener('resize', () => (box = null))
  }
  el.addEventListener('animationend', (e) => {
    if (['hop', 'boo', 'happy', 'spin'].includes(e.animationName)) el.classList.remove('hop', 'boo', 'happy', 'spin')
  })
  // A click makes the ghost (or the big logo on the home page) hop happily.
  document.addEventListener('click', (e) => {
    const logo = e.target.closest?.('.hero .logo')
    if (logo && !calm.matches) {
      logo.classList.remove('happy')
      void logo.offsetWidth
      logo.classList.add('happy')
    }
  })
  document.addEventListener('animationend', (e) => e.target.classList?.remove('happy'))
  el.addEventListener('click', () => play('happy'))

  // Up up down down left right left right b a: the ghost spins once.
  const code = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a']
  let at = 0
  function konami(e) {
    if (typing(e.target)) return
    at = e.key === code[at] ? at + 1 : e.key === code[0] ? 1 : 0
    if (at === code.length) {
      at = 0
      play('spin')
    }
  }
  addEventListener('keydown', boo)
  addEventListener('keydown', konami)
  return { play }
}

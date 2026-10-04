// GSAP motion for the launch pages: sections rise as they scroll in, table rows
// follow one by one, the call to action leans toward the pointer and Rust is
// underlined again on hover. GSAP is vendored in /vendor, loaded after the page
// is idle and only where motion is welcome. Without it (no JavaScript, reduced
// motion, a failed load) the page is complete and CSS does the lighter version.
const REVEAL = '.sec-head, .band .claim, .band .sample, .demo, .pair .cmp, .hosts, .bench, .foot .cols > *'

const calm = matchMedia('(prefers-reduced-motion: reduce)')
const fine = matchMedia('(hover: hover) and (pointer: fine)')

const load = (src) =>
  new Promise((ok, no) => {
    const s = document.createElement('script')
    s.src = src
    s.onload = ok
    s.onerror = no
    document.head.append(s)
  })

let ready = null
const boot = () =>
  (ready ??= load('/vendor/gsap.min.js')
    .then(() => load('/vendor/ScrollTrigger.min.js'))
    .then(() => {
      gsap.registerPlugin(ScrollTrigger)
      return true
    }, () => false))

// Returns { scan, stop }. `scan` (re)builds the motion for the page now showing.
export function motion() {
  let undo = []

  function stop() {
    for (const f of undo) f()
    undo = []
    if (!window.ScrollTrigger) return
    ScrollTrigger.getAll().forEach((t) => t.kill())
    gsap.set(REVEAL, { clearProps: 'opacity,transform' })
    document.documentElement.classList.remove('gsap')
  }

  // Sections below the fold start hidden and rise, in a small stagger, as they arrive.
  function reveal() {
    const below = [...document.querySelectorAll(REVEAL)].filter((e) => e.getBoundingClientRect().top > innerHeight * 0.9)
    if (!below.length) return
    gsap.set(below, { opacity: 0, y: 28 })
    ScrollTrigger.batch(below, {
      start: 'top 90%',
      once: true,
      onEnter: (els) =>
        gsap.to(els, { opacity: 1, y: 0, duration: 0.7, stagger: 0.08, ease: 'power3.out', overwrite: true, clearProps: 'opacity,transform' }),
    })
  }

  // Table rows settle in as their table arrives.
  function rows() {
    for (const t of document.querySelectorAll('.tally tbody')) {
      ScrollTrigger.create({
        trigger: t,
        start: 'top 90%',
        once: true,
        onEnter: () => gsap.from(t.rows, { opacity: 0, x: -10, duration: 0.5, stagger: 0.045, ease: 'power3.out', clearProps: 'opacity,transform' }),
      })
    }
  }

  // The hero buttons lean a few pixels toward the pointer.
  function lean() {
    if (!fine.matches) return
    for (const b of document.querySelectorAll('.cta .btn')) {
      const x = gsap.quickTo(b, 'x', { duration: 0.4, ease: 'power3.out' })
      const y = gsap.quickTo(b, 'y', { duration: 0.4, ease: 'power3.out' })
      const move = (e) => {
        const r = b.getBoundingClientRect()
        x((e.clientX - (r.left + r.width / 2)) * 0.12)
        y((e.clientY - (r.top + r.height / 2)) * 0.2)
      }
      const rest = () => {
        x(0)
        y(0)
      }
      b.addEventListener('pointermove', move)
      b.addEventListener('pointerleave', rest)
      undo.push(() => {
        b.removeEventListener('pointermove', move)
        b.removeEventListener('pointerleave', rest)
        gsap.set(b, { clearProps: 'x,y' })
      })
    }
  }

  // Hovering Rust draws its underline again.
  function scribble() {
    const em = document.querySelector('.hero em')
    if (!em || !fine.matches) return
    const paths = em.querySelectorAll('path')
    const again = () =>
      gsap.fromTo(paths, { strokeDashoffset: 1 }, { strokeDashoffset: 0, duration: 0.55, stagger: 0.12, ease: 'power2.out', overwrite: true })
    em.addEventListener('pointerenter', again)
    undo.push(() => em.removeEventListener('pointerenter', again))
  }

  async function scan() {
    stop()
    if (calm.matches || !(await boot())) return
    document.documentElement.classList.add('gsap')
    reveal()
    rows()
    lean()
    scribble()
  }

  addEventListener('beforeprint', stop)
  return { scan, stop }
}

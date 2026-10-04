// GSAP motion: sections, docs blocks and lists rise as they scroll in, table rows
// follow one by one, the hero drifts away as you scroll and Rust is
// underlined again on hover. GSAP is vendored in /vendor, loaded after the page
// is idle and only where motion is welcome. Without it (no JavaScript, reduced
// motion, a failed load) the page is complete and CSS does the lighter version.
const REVEAL = [
  '.sec-head, .band .claim, .band .sample, .demo, .pair .cmp, .hosts, .bench, .foot .cols > *',
  '.posts li, .found li, .pager, .useful',
  '.doc > :is(h2, pre, table, blockquote, figure, .callout, .tally, .file)',
].join(',')

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

  // Hovering Rust draws its underline again.
  function scribble() {
    const em = document.querySelector('.hero em')
    if (!em || !fine.matches) return
    const stroke = em.querySelector('svg')
    const again = () =>
      gsap.fromTo(stroke, { clipPath: 'inset(0 100% 0 0)' }, { clipPath: 'inset(0 0% 0 0)', duration: 0.6, ease: 'power2.out', overwrite: true, clearProps: 'clipPath' })
    em.addEventListener('pointerenter', again)
    undo.push(() => em.removeEventListener('pointerenter', again))
  }

  // The hero settles back and fades a little as it scrolls out.
  function drift() {
    const wrap = document.querySelector('.hero .wrap')
    if (!wrap) return
    gsap.to(wrap, {
      y: 48,
      opacity: 0.35,
      ease: 'none',
      scrollTrigger: { trigger: '.hero', start: 'top top', end: 'bottom top', scrub: true },
    })
    undo.push(() => gsap.set(wrap, { clearProps: 'opacity,transform' }))
  }

  async function scan() {
    stop()
    if (calm.matches || !(await boot())) return
    document.documentElement.classList.add('gsap')
    reveal()
    rows()
    scribble()
    drift()
  }

  // The theme switch turns its icon as the theme flips.
  addEventListener('click', (e) => {
    const b = e.target.closest?.('.theme')
    if (!b || !window.gsap || calm.matches) return
    gsap.fromTo(b.querySelectorAll('svg'), { rotate: -80, scale: 0.6 }, { rotate: 0, scale: 1, duration: 0.5, ease: 'power3.out', clearProps: 'transform' })
  })

  addEventListener('beforeprint', stop)
  return { scan, stop }
}

// GSAP motion: sections, docs blocks and lists rise as they scroll in, table rows
// follow one by one with their bars growing and numbers counting, code unrolls,
// the hero drifts away as you scroll
// and Rust is underlined again on hover. GSAP is vendored in /vendor, loaded after the page
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

  // Table rows settle in as their table arrives, the bars grow from zero and
  // the numbers count up to their value.
  function rows() {
    for (const t of document.querySelectorAll('.tally tbody')) {
      const bars = t.querySelectorAll('.meter span')
      const nums = [...t.querySelectorAll('.num')].filter((n) => /^[\d,]+$/.test(n.textContent.trim()))
      gsap.set(bars, { scaleX: 0, transformOrigin: '0 50%' })
      ScrollTrigger.create({
        trigger: t,
        start: 'top 90%',
        once: true,
        onEnter: () => {
          gsap.from(t.rows, { opacity: 0, x: -10, duration: 0.5, stagger: 0.045, ease: 'power3.out', clearProps: 'opacity,transform' })
          gsap.to(bars, { scaleX: 1, duration: 1.1, stagger: 0.06, delay: 0.15, ease: 'expo.out', clearProps: 'transform' })
          for (const n of nums) count(n)
        },
      })
      undo.push(() => gsap.set(bars, { clearProps: 'transform' }))
    }
  }

  function count(n) {
    const text = n.textContent.trim()
    const end = +text.replace(/,/g, '')
    const comma = text.includes(',')
    const v = { x: 0 }
    gsap.to(v, {
      x: end,
      duration: 1.2,
      delay: 0.15,
      ease: 'expo.out',
      onUpdate: () => (n.textContent = comma ? Math.round(v.x).toLocaleString('en-US') : String(Math.round(v.x))),
      onComplete: () => (n.textContent = text),
    })
    undo.push(() => (n.textContent = text))
  }

  // Code samples on the home page unroll top to bottom as they arrive.
  function unroll() {
    for (const c of document.querySelectorAll('.showcase pre, .band .sample pre, .cmp .scroll')) {
      ScrollTrigger.create({
        trigger: c,
        start: 'top 88%',
        once: true,
        onEnter: () => gsap.fromTo(c, { clipPath: 'inset(0 0 100% 0)' }, { clipPath: 'inset(0 0 0% 0)', duration: 0.9, ease: 'power3.inOut', clearProps: 'clipPath' }),
      })
    }
  }

  // The host names pop in one by one.
  function hosts() {
    const chips = document.querySelectorAll('.hosts > span')
    if (!chips.length) return
    // Their hover transition is off while GSAP runs, or the two would fight.
    gsap.set(chips, { opacity: 0, scale: 0.85, transition: 'none' })
    ScrollTrigger.create({
      trigger: '.hosts',
      start: 'top 92%',
      once: true,
      onEnter: () => gsap.to(chips, { opacity: 1, scale: 1, duration: 0.45, stagger: 0.03, ease: 'power3.out', clearProps: 'opacity,transform,transition' }),
    })
    undo.push(() => gsap.set(chips, { clearProps: 'opacity,transform,transition' }))
  }

  // Hovering Rust draws its underline again.
  function scribble() {
    const em = document.querySelector('.hero em')
    if (!em || !fine.matches) return
    const pen = em.querySelector('path')
    // The Web Animations API, not a tween: it leaves no inline offset behind to hide the line.
    const again = () =>
      pen.animate({ strokeDashoffset: [1, 0] }, { duration: 750, easing: 'cubic-bezier(0.45, 0, 0.55, 1)' })
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
    unroll()
    hosts()
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

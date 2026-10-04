---
const SITE: &str = "https://wispweb.dev";

let home = cx.path() == "/";
let docs = cx.path() == "/docs" || cx.path().starts_with("/docs/");
let me = wisp::pages("")
    .iter()
    .chain(wisp::pages("docs").iter())
    .find(|p| p.path == cx.path());
let title = me.map_or("Wisp", |p| p.title);
let about = me
    .and_then(|p| p.get("description"))
    .unwrap_or("A fast, fun web framework for Rust");
---
<head>
  <meta name="description" content={about}>
  {@html wisp::og(title, about, &format!("{SITE}/og.png"))}
  <link rel="canonical" href={format!("{SITE}{}", cx.path())}>
  <meta name="twitter:card" content="summary_large_image">
</head>
<a class="skip" href="#main">Skip to Content</a>
<header class="top">
  <div class="bar">
    <a class="brand" href="/" aria-label="Wisp home">
      <span
        class="ghost"
        aria-hidden="true"
        bind:this="ghost"
        on:pointermove.window="look"
        style:--look-x="x"
        style:--look-y="y">
        <svg viewBox="0 0 32 32">
          <path
            class="shape"
            d="M16 2.5C21 2.5 24.5 6.5 24.5 11.5C24.5 13.6 25.3 14.7 26.9 14.7C28.2 14.7 29.3 14 30.2 13.3C31.2 12.6 31.9 13.8 31.3 14.9C30.1 17.4 28.4 19.4 27.1 20.5C26.3 21.2 26.2 22.4 26.5 23.8C26.8 25.2 27.6 26.2 27.6 27.4C27.6 28.6 26.5 29.4 25.4 29.4C24.2 29.4 23.6 27.5 22.3 27.5C21.25 27.5 20.9 28.8 19.8 28.8C18.7 28.8 18.29 27.8 17.2 27.8C15.69 27.8 14.9 29.7 13.6 29.7C12.3 29.7 11.57 27.4 10.1 27.4C8.71 27.4 8.05 29.1 6.8 29.1C5.6 29.1 4.4 28.6 4.4 27.4C4.4 26.2 5.2 25.2 5.5 23.8C5.8 22.4 5.7 21.2 4.9 20.5C3.6 19.4 1.9 17.4 0.7 14.9C0.1 13.8 0.8 12.6 1.8 13.3C2.7 14 3.8 14.7 5.1 14.7C6.7 14.7 7.5 13.6 7.5 11.5C7.5 6.5 11 2.5 16 2.5Z" />
          <ellipse class="eye" cx="12.8" cy="10.8" rx="1.8" ry="2.6" />
          <ellipse class="eye" cx="19.2" cy="10.8" rx="1.8" ry="2.6" />
          <ellipse class="mouth" cx="15.6" cy="16.6" rx="1.3" ry="1.7" />
        </svg>
      </span>
      <span>Wisp</span>
    </a>
    <nav aria-label="Site">
      <a href="/docs" aria-current={docs.then_some("page")}>Docs</a>
      <a href="https://github.com/wyziedevs/wisp" target="_blank" rel="noopener">GitHub</a>
    </nav>
  </div>
</header>
<main id="main" class:home={home}>
  <slot />
</main>
<footer class="foot">
  <div class="bar">
    <p class="mark"><img src="/favicon.svg" alt="" width="22" height="22"> Wisp. A fast, fun web framework for Rust.</p>
    <ul>
      <li><a href="/docs">Docs</a></li>
      <li><a href="https://github.com/wyziedevs/wisp">Wisp on GitHub</a></li>
    </ul>
  </div>
</footer>

<script>
  import { afterNavigate } from 'wisp'

  function focusable() {
    for (const p of document.querySelectorAll('pre')) {
      p.tabIndex = 0
      if (p.querySelector('.copy-code')) continue
      const b = document.createElement('button')
      b.type = 'button'
      b.className = 'copy-code'
      b.textContent = 'Copy'
      b.setAttribute('aria-label', 'Copy code')
      b.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(p.querySelector('code').innerText)
          b.textContent = 'Copied'
        } catch (e) {
          b.textContent = 'Press Ctrl+C'
        }
        setTimeout(() => (b.textContent = 'Copy'), 1500)
      })
      p.append(b)
    }
  }

  let ghost
  let x = 0, y = 0, frame = 0, last = null
  const calm = matchMedia('(prefers-reduced-motion: reduce)')

  // The ghost's eyes and body lean toward the pointer, one update a frame.
  function look(e) {
    if (calm.matches) return
    last = e
    if (!frame) frame = requestAnimationFrame(aim)
  }

  function aim() {
    frame = 0
    const box = ghost.getBoundingClientRect()
    const dx = last.clientX - (box.left + box.width / 2)
    const dy = last.clientY - (box.top + box.height * 0.4)
    const d = Math.hypot(dx, dy) || 1
    const k = Math.min(1, d / 240) / d
    x = (dx * k).toFixed(3)
    y = (dy * k).toFixed(3)
  }

  onMount(focusable)
  afterNavigate(focusable)
</script>

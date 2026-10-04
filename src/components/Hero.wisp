<section class="hero">
  <div class="wrap">
    <img class="logo" src="/favicon.svg" alt="" width="132" height="132">
    <h1>Wisp</h1>
    <p class="sub">A Fast, Fun Web Framework for <em>Rust<svg class="scribble" viewBox="0 0 120 14" preserveAspectRatio="none" aria-hidden="true" focusable="false"><path pathLength="1" d="M2.4 9.2C9 6.8 15.5 10.3 25 8.4C37 6.1 44 5.9 58 7.6C71 9.2 82 9.6 94 6.8C102 5 110 5.6 117.6 2.9"/><path class="again" pathLength="1" d="M9 12C27 10.1 46 12.3 66 10.9C80 10 92 10.7 104 9.4"/></svg></em></p>
    <p class="cta">
      <a class="btn primary" href="/docs/quick-start">Learn Wisp</a>
      <a class="btn" href="/docs/design">API Reference</a>
    </p>
    <div class="install">
      <code id="install-cmd"><span class="prompt" aria-hidden="true">$</span> cargo install --git https://wisp.ar0.eu wisp-cli</code>
      <button
        class="copy-icon"
        type="button"
        class:done="done"
        on:click="copy()"
        aria-label="Copy the install command">
        <svg class="i-copy" viewBox="0 0 24 24" aria-hidden="true"><rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h8"/></svg>
        <svg class="i-done" viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>
      </button>
      <span class="sr" aria-live="polite">{:label}</span>
    </div>
  </div>
</section>

<style>
  .hero {
    padding-block: clamp(3.5rem, 9vw, 6.5rem) 4rem;
    text-align: center;
  }

  .hero .logo {
    display: block;
    width: clamp(5.5rem, 14vw, 8.25rem);
    height: auto;
    margin: 0 auto 1.5rem;
    user-select: none;
    -webkit-user-drag: none;
  }

  .hero h1 {
    margin: 0;
    font-size: clamp(3.25rem, 9vw, 4.75rem);
    font-weight: 700;
    letter-spacing: -0.045em;
    line-height: 1;
  }

  .hero .sub {
    margin: 1.25rem 0 0;
    font-size: clamp(1.375rem, 3.4vw, 2rem);
    font-weight: 600;
    line-height: 1.3;
    letter-spacing: -0.02em;
  }

  .hero .lede {
    margin: 0.75rem auto 2.25rem;
    max-width: 36rem;
    color: var(--slate);
    font-size: var(--fs-lede);
  }

  .install {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    max-width: 100%;
    margin-top: 2rem;
    padding: 0.5rem 1.5rem;
    border: 1px solid var(--line);
    border-radius: var(--pill);
    background: var(--panel);
    text-align: left;
  }

  .install code {
    padding: 0;
    background: none;
    overflow-x: auto;
    font: 0.875rem/1.6 var(--mono);
    white-space: nowrap;
    scrollbar-width: none;
  }

  .install .prompt {
    color: var(--ash);
  }

  /* On a phone the whole command shows, wrapped, instead of scrolling out of sight. */
  @media (max-width: 30rem) {
    .install {
      border-radius: var(--radius-lg);
      padding-inline: 1rem;
    }

    .install code {
      overflow-wrap: anywhere;
      white-space: normal;
    }
  }

  /* The copy button (round, see 1-base.css) sits nearer the edge than the text does. */
  .copy-icon {
    --size: 2.25rem;
    position: relative;
    --fg: var(--ash);
    margin-right: -1rem;
  }

  .copy-icon:active {
    scale: 0.85;
  }

  .copy-icon svg {
    grid-area: 1 / 1;
    width: 1.125rem;
    height: 1.125rem;
    fill: none;
    stroke: currentColor;
    stroke-width: 2;
    stroke-linecap: round;
    stroke-linejoin: round;
    transition:
      opacity var(--t),
      scale 300ms var(--ease);
  }

  .copy-icon .i-done,
  .copy-icon.done .i-copy {
    opacity: 0;
    scale: 0.5;
  }

  .copy-icon.done {
    color: var(--good);
  }

  .copy-icon.done .i-done {
    opacity: 1;
    scale: 1;
  }

  .copy-icon.done .i-done path {
    stroke-dasharray: 20;
    animation: check 350ms var(--ease) 80ms backwards;
  }

  /* Rust gets a pen stroke: two loose passes, drawn by hand. */
  .hero em {
    position: relative;
    font-style: normal;
    color: var(--accent-ink);
    white-space: nowrap;
  }

  .hero .scribble {
    position: absolute;
    left: -0.06em;
    bottom: -0.2em;
    width: calc(100% + 0.12em);
    height: 0.3em;
    overflow: visible;
    fill: none;
    stroke: currentColor;
    stroke-linecap: round;
    stroke-linejoin: round;
    stroke-width: 3.4px;
    opacity: 0.8;
    pointer-events: none;
  }

  .hero .scribble path {
    vector-effect: non-scaling-stroke;
    stroke-dasharray: 1;
  }

  .hero .scribble .again {
    stroke-width: 2px;
    opacity: 0.55;
  }

  @media (prefers-reduced-motion: no-preference) {
    .hero .wrap > * {
      animation: fade 500ms var(--ease) backwards;
    }

    .hero .wrap > :nth-child(2) { animation-delay: 60ms; }
    .hero .wrap > :nth-child(3) { animation-delay: 120ms; }
    .hero .wrap > :nth-child(4) { animation-delay: 180ms; }
    .hero .wrap > :nth-child(5) { animation-delay: 240ms; }
    .hero .wrap > :nth-child(6) { animation-delay: 300ms; }

    /* The logo floats. */
    .hero .logo {
      animation:
        fade 500ms var(--ease) backwards,
        bob 5s cubic-bezier(0.37, 0, 0.63, 1) 600ms infinite alternate;
    }

    .hero .scribble path {
      animation: scribble 650ms var(--ease) 500ms backwards;
    }

    .hero .scribble .again {
      animation-delay: 850ms;
      animation-duration: 450ms;
    }
  }
</style>

<script>
  let label = $state('')
  let done = $state(false)

  async function copy() {
    const text = document.getElementById('install-cmd').textContent.replace(/^\$\s*/, '').trim()
    try {
      await navigator.clipboard.writeText(text)
      label = 'Copied'
      done = true
    } catch (e) {
      label = 'Press Ctrl+C'
    }
    setTimeout(() => {
      label = ''
      done = false
    }, 1800)
  }
</script>

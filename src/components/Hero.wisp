<section class="hero">
  <div class="wrap">
    <img class="logo" src="/favicon.svg" alt="" width="132" height="132">
    <h1>Wisp</h1>
    <p class="sub">A Fast, Fun Web Framework for <em>Rust</em></p>
    <p class="lede">The fastest full stack web framework for anything.</p>
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

  /* Rust gets a pen stroke. */
  .hero em {
    position: relative;
    font-style: normal;
    color: var(--accent-ink);
    white-space: nowrap;
  }

  .hero em::after {
    content: "";
    position: absolute;
    left: -0.04em;
    right: -0.06em;
    bottom: -0.16em;
    height: 0.26em;
    background: var(--mask-ink, currentColor);
    forced-color-adjust: none;
    opacity: 0.7;
    mask: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 120 14' preserveAspectRatio='none'%3E%3Cpath d='M2.5 9.6C14 8.1 27 7.1 41 6.9C60 6.5 80 7.3 96 6.6C104 6.2 110 5.3 117.5 3.4' fill='none' stroke='black' stroke-width='3.2' stroke-linecap='round'/%3E%3C/svg%3E") center / 100% 100% no-repeat;
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

    .hero em::after {
      animation: draw 800ms var(--ease) 500ms backwards;
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

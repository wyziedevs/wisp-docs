<section class="hero">
  <div class="wrap">
    <h1>A Fast, Fun Web Framework for <em>Rust</em></h1>
    <p class="lede">Built to run fast, and to cost an AI the fewest tokens to write.</p>
    <div class="install">
      <code id="install-cmd"><span class="prompt" aria-hidden="true">$</span> cargo install --git https://github.com/wyziedevs/wisp wisp-cli</code>
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
    <p class="cta">
      <a class="btn primary" href="/docs">Get Started</a>
      <a class="btn" href="https://github.com/wyziedevs/wisp">View on GitHub</a>
    </p>
  </div>
</section>

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

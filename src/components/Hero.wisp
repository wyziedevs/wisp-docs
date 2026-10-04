<section class="hero">
  <div class="wrap">
    <h1>A Fast, Fun Web Framework for <em>Rust</em></h1>
    <p class="lede">Built to run fast, and to cost an AI the fewest tokens to write.</p>
    <div class="install">
      <code id="install-cmd"><span class="prompt" aria-hidden="true">$</span> cargo install --git https://github.com/wyziedevs/wisp wisp-cli</code>
      <button class="copy" type="button" on:click="copy()"><span aria-live="polite">{:label}</span></button>
    </div>
    <p class="cta">
      <a class="btn primary" href="/docs">Get Started</a>
      <a class="btn" href="https://github.com/wyziedevs/wisp">View on GitHub</a>
    </p>
  </div>
</section>

<script>
  let label = $state('Copy')

  async function copy() {
    const text = document.getElementById('install-cmd').textContent.replace(/^\$\s*/, '').trim()
    try {
      await navigator.clipboard.writeText(text)
      label = 'Copied'
    } catch (e) {
      label = 'Press Ctrl+C'
    }
    setTimeout(() => (label = 'Copy'), 1800)
  }
</script>

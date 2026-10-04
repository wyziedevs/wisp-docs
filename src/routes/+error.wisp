<title>{status}</title>

<div class="error">
  <img class="float" src="/favicon.svg" alt="" width="64" height="64">
  <span class="shade" aria-hidden="true"></span>
  <h1>{status}</h1>
  {#if status == 404}
    <p>This page vanished. It may have moved; the docs menu lists every page.</p>
  {:else}
    <p>{message}</p>
  {/if}
  <p><a class="button" href="/docs">Go to the Docs</a></p>
</div>

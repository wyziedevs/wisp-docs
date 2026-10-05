<title>{status} Error - Wisp</title>

<div class="error">
  <img class="float" src="/favicon.svg" alt="" width="72" height="72">
  <span class="shade" aria-hidden="true"></span>
  <h1>{status}</h1>
  {#if status == 404}
    <p>This page was not found. It may have moved, so try the search or the docs menu.</p>
  {:else}
    <p>{message}</p>
  {/if}
  <p class="cta"><a class="btn primary" href="/docs/">Go to the Docs</a> <a class="btn" href="/">Home</a></p>
</div>

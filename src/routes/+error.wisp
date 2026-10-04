<title>{status}</title>

<div class="error">
  <img src="/favicon.svg" alt="" width="64" height="64">
  <h1>{status}</h1>
  {#if status == 404}
    <p>This page is not here. It may have moved; the docs menu has the current list.</p>
  {:else}
    <p>{message}</p>
  {/if}
  <p><a class="button" href="/docs">Go to the Docs</a></p>
</div>

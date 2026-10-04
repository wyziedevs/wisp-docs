<div class="hosts" role="list" aria-label="Hosts Wisp builds for">
  {#each ["A VPS (one binary)", "Docker", "Fly.io", "Render", "Railway", "Cloudflare", "Deno Deploy", "Vercel", "Netlify", "AWS Lambda", "Bun", "Node", "GitHub Pages (static)", "Cloud Run", "Azure"] as h}
    <span role="listitem">{h}</span>
  {/each}
</div>

<style>
  .hosts {
    display: flex;
    flex-wrap: wrap;
    gap: 0.625rem;
    max-width: 44rem;
    margin-inline: auto;
  }

  .hosts span {
    padding: 0.375rem 1rem;
    border: 1px solid var(--line);
    border-radius: var(--pill);
    background: var(--panel);
    color: var(--slate);
    font-size: var(--fs-sm);
  }
</style>

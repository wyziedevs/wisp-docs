<nav class="hosts" aria-label="Hosts Wisp builds for">
  {#each [("A VPS (one binary)", "vps"), ("Docker", "docker"), ("Fly.io", "fly"), ("Render", "render"), ("Railway", "railway"), ("Cloudflare", "cloudflare"), ("Deno Deploy", "deno-deploy"), ("Vercel", "vercel"), ("Netlify", "netlify"), ("AWS Lambda", "aws-lambda"), ("Bun", "bun"), ("Node", "node"), ("GitHub Pages (static)", "github-pages"), ("Cloud Run", "cloud-run"), ("Azure", "azure")] as (name, slug)}
    <a href="/docs/hosting/{slug}/">{name}</a>
  {/each}
</nav>

<style>
  .hosts {
    display: flex;
    flex-wrap: wrap;
    gap: 0.625rem;
  }

  .hosts a {
    padding: 0.375rem 1rem;
    border: 1px solid var(--line);
    border-radius: var(--pill);
    background: var(--panel);
    color: var(--slate);
    font-size: var(--fs-sm);
    text-decoration: none;
    transition: color var(--t), border-color var(--t);
  }

  .hosts a:hover, .hosts a:focus-visible {
    border-color: var(--accent);
    color: var(--ink);
  }
</style>

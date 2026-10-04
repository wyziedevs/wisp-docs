<div class="speed">
  <figure>
    <figcaption>Requests per second, server-rendered page, 4 vCPU</figcaption>
    <ul class="bars">
      {#each [("Wisp", 97502u32), ("Actix Web", 86169), ("Axum", 76818), ("Fastify", 24576), ("SvelteKit", 2676)] as (name, n)}
        <li class:ours={name == "Wisp"} style={format!("--w: {:.3}", n as f64 / 97502.0)}><span class="name">{name}</span><span class="meter"></span><span class="num">{n}</span></li>
      {/each}
    </ul>
  </figure>
  <figure>
    <figcaption>Tokens to write the same five features, fewer is better</figcaption>
    <ul class="bars">
      {#each [("Wisp", 464u32), ("SvelteKit 2", 928), ("Next.js 15", 934), ("Axum + askama", 1330), ("Actix Web + tera", 1457)] as (name, n)}
        <li class:ours={name == "Wisp"} style={format!("--w: {:.3}", n as f64 / 1457.0)}><span class="name">{name}</span><span class="meter"></span><span class="num">{n}</span></li>
      {/each}
    </ul>
  </figure>
</div>

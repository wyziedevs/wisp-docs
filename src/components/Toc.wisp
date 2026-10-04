{@props heads: &[(&str, &str, u8)], cls: &str}
{#if heads.len() > 1}
  <aside class={cls} aria-label="On this page">
    <h2>On This Page</h2>
    <ul>
      {#each heads as (id, text, level)}
        <li class={format!("h{level}")}><a href={format!("#{id}")}>{text}</a></li>
      {/each}
    </ul>
  </aside>
{/if}

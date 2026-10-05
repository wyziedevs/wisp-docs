{@props heads: &[(&str, &str, u8)], cls: &str}
{#if heads.len() > 1}
  <aside class={cls} aria-label="On this page">
    <p class="toc-head">On This Page</p>
    <ul>
      {#each heads as (id, text, level)}
        <li class={format!("h{level}")}><a href={format!("#{id}")}>{text}</a></li>
      {/each}
    </ul>
  </aside>
{/if}

{@props label: &str, before: &str, after: &str, prev: Option<(&str, &str)>, next: Option<(&str, &str)>}
<nav class="pager" aria-label={label}>
  {#if let Some((href, title)) = prev}
    <a class="prev" rel="prev" href={site::dir(href)}><small>{before}</small><span>{title}</span></a>
  {/if}
  {#if let Some((href, title)) = next}
    <a class="next" rel="next" href={site::dir(href)}><small>{after}</small><span>{title}</span></a>
  {/if}
</nav>

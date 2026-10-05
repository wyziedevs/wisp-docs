{@props links: &[(&str, &str, bool)]}
{#each links as (href, name, on)}
  <a href={href} aria-current={on.then_some("page")}>{name}</a>
{/each}

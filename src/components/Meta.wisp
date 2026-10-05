{@props iso: &str = "", when: &str = "", author: &str = "", read: &str}
<p class="meta">
  {#if !iso.is_empty()}<time datetime={iso}>{when}</time> · {/if}
  {#if !author.is_empty()}{author} · {/if}
  {read}
</p>

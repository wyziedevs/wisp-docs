---
let posts: Vec<_> = wisp::pages("blog").iter().filter(|p| p.path != "/blog").collect();
let index = cx.path() == "/blog";
let me = posts.iter().find(|p| p.path == cx.path());
---
<div class="page blog">
  {#if index}
    <header class="page-head">
      <h1>Wisp Blog</h1>
      <p class="lede">News and notes from the Wisp project.</p>
    </header>
    <slot />
    <ul class="posts">
      {#each posts as p}
        <li>
          <a href={p.path}>
            <span class="t">{p.title}</span>
            {#if let Some(d) = p.get("date")}<time datetime={d}>{d}</time>{/if}
            {#if let Some(d) = p.get("description")}<span class="d">{d}</span>{/if}
          </a>
        </li>
      {/each}
    </ul>
  {:else}
    <article class="post doc">
      <nav class="crumbs" aria-label="Breadcrumb"><a href="/blog">Blog</a></nav>
      {#if let Some(p) = me}
        <h1 class="doc-title">{p.title}</h1>
        <p class="byline">
          {#if let Some(d) = p.get("date")}<time datetime={d}>{d}</time>{/if}
          {#if let Some(a) = p.get("author")}<span>By {a}</span>{/if}
        </p>
      {/if}
      <slot />
      <p class="edit"><a href="/blog">All Posts</a></p>
    </article>
  {/if}
</div>

---
const MONTHS: [&str; 12] = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
];
// Each post's prose word count and headings, from build.rs: [(path, words, [(id, text, level)])].
let facts: &[(&str, usize, &[(&str, &str, u8)])] = include!(concat!(env!("OUT_DIR"), "/blog.rs"));
// "2026-10-04" to "Oct 4, 2026" (short) or "October 4, 2026".
let day = |d: &str, short: bool| {
    let mut it = d.splitn(3, '-');
    let (y, m, n) = (it.next().unwrap_or(""), it.next().unwrap_or(""), it.next().unwrap_or(""));
    match (m.parse::<usize>(), n.parse::<u32>()) {
        (Ok(m @ 1..=12), Ok(n)) => {
            let name = MONTHS[m - 1];
            format!("{} {n}, {y}", if short { &name[..3] } else { name })
        }
        _ => d.to_string(),
    }
};
let read = |path: &str| {
    let words = facts.iter().find(|f| f.0 == path).map_or(0, |f| f.1);
    format!("{} min read", words.div_ceil(230).max(1))
};
let tags_of = |p: &wisp::MdPage| -> Vec<&'static str> {
    p.get("tags").unwrap_or("").split(',').map(str::trim).filter(|t| !t.is_empty()).collect()
};

let path = cx.path();
let index = path == "/blog";
let tags_page = path == "/blog/tags";
let posts: Vec<&wisp::MdPage> = wisp::pages("blog").iter().filter(|p| p.get("date").is_some()).collect();

let q = cx.query_or("q", String::new());
let tag = cx.query_or("tag", String::new());
let needle = q.trim().to_lowercase();
let shown: Vec<(&wisp::MdPage, String)> = posts
    .iter()
    .map(|p| {
        let text = format!("{} {} {}", p.title, p.get("description").unwrap_or(""), p.get("tags").unwrap_or(""));
        (*p, text.to_lowercase())
    })
    .filter(|(p, text)| {
        (needle.is_empty() || text.contains(&needle))
            && (tag.is_empty() || tags_of(p).iter().any(|t| t.eq_ignore_ascii_case(&tag)))
    })
    .collect();
let count = |n: usize| format!("{n} {}", if n == 1 { "post" } else { "posts" });

let mut all_tags: Vec<(&str, usize)> = Vec::new();
for p in &posts {
    for t in tags_of(p) {
        match all_tags.iter_mut().find(|(k, _)| *k == t) {
            Some(e) => e.1 += 1,
            None => all_tags.push((t, 1)),
        }
    }
}
all_tags.sort_by(|a, b| a.0.cmp(b.0));

let me = posts.iter().position(|p| p.path == path);
let newer = me.and_then(|i| i.checked_sub(1)).map(|i| posts[i]);
let older = me.and_then(|i| posts.get(i + 1)).copied();
let post = me.map(|i| posts[i]);
let heads = facts.iter().find(|f| f.0 == path).map_or(&[][..], |f| f.2);
---
<div class="page blog">
  {#if index}
    <header class="blog-head">
      <h1>Wisp Blog</h1>
      <form class="blog-bar" method="get" action="/blog" role="search">
        <label class="sr" for="blog-q">Filter Posts</label>
        <input id="blog-q" type="search" name="q" value={q} placeholder="Filter by word or tag" autocomplete="off" on:input="filter(event)">
        {#if !tag.is_empty()}<input type="hidden" name="tag" value={tag}>{/if}
        <p class="blog-count" role="status" aria-live="polite">{count(shown.len())}</p>
        <a href="/blog/tags">All Tags</a>
        <a href="/rss.xml">RSS</a>
      </form>
      {#if !tag.is_empty()}
        <p class="blog-tag">Tagged <strong>{tag}</strong> · <a href="/blog">Show All</a></p>
      {/if}
    </header>
    <ul class="posts">
      {#each shown as (p, text)}
        <li data-text={text}>
          <h2><a href={p.path}>{p.title}</a></h2>
          {#if let Some(d) = p.get("description")}<p>{d}</p>{/if}
          <p class="meta">
            {#if let Some(d) = p.get("date")}<time datetime={d}>{day(d, true)}</time> · {/if}
            {#if let Some(a) = p.get("author")}{a} · {/if}
            {read(p.path)}
          </p>
        </li>
      {/each}
    </ul>
    <p class="blog-none" hidden={!shown.is_empty()}>No posts match. <a href="/blog">Show All</a></p>
  {:else}
    {#if tags_page}
      <header class="blog-head">
        <p class="eyebrow"><a href="/blog">The Blog</a></p>
        <h1>Everything We Write About</h1>
        <p class="lede">Every topic on the Wisp blog, with how many posts cover it.</p>
      </header>
      <ul class="tag-list">
        {#each all_tags as (t, n)}
          <li><a href={format!("/blog?tag={t}")}>{t}</a> <span>{count(*n)}</span></li>
        {/each}
      </ul>
    {:else}
      <div class="post-wrap">
        {#if heads.len() > 1}
          <aside class="post-toc" aria-label="On this page">
            <h2>On This Page</h2>
            <ul>
              {#each heads as (id, text, level)}
                <li class={format!("h{level}")}><a href={format!("#{id}")}>{text}</a></li>
              {/each}
            </ul>
          </aside>
        {/if}
        <article class="post doc">
          <p class="eyebrow"><a href="/blog">The Blog</a></p>
          {#if let Some(p) = post}
            <h1 class="doc-title">{p.title}</h1>
            {#if let Some(d) = p.get("description")}<p class="lede">{d}</p>{/if}
            <p class="meta">
              {#if let Some(d) = p.get("date")}<time datetime={d}>{day(d, false)}</time> · {/if}
              {#if let Some(a) = p.get("author")}{a} · {/if}
              {read(path)}
            </p>
            {#if !tags_of(p).is_empty()}
              <nav class="chips" aria-label="Tags">
                {#each tags_of(p) as t}<a href={format!("/blog?tag={t}")}>{t}</a>{/each}
              </nav>
            {/if}
          {/if}
          <slot />
          <nav class="pager" aria-label="Newer and older posts">
            {#if let Some(p) = newer}
              <a class="prev" rel="prev" href={p.path}><small>Newer</small><span>{p.title}</span></a>
            {/if}
            {#if let Some(p) = older}
              <a class="next" rel="next" href={p.path}><small>Older</small><span>{p.title}</span></a>
            {/if}
          </nav>
        </article>
      </div>
    {/if}
  {/if}
</div>

<script>
  import { afterNavigate } from 'wisp'
  import { spy } from '$lib/toc.js'

  // Filters the list as you type; without JS the form filters on the server.
  function filter(e) {
    const words = e.target.value.trim().toLowerCase()
    let n = 0
    for (const li of document.querySelectorAll('.posts li')) {
      const hit = !words || li.dataset.text.includes(words)
      li.hidden = !hit
      if (hit) n++
    }
    document.querySelector('.blog-count').textContent = n + (n === 1 ? ' post' : ' posts')
    document.querySelector('.blog-none').hidden = n > 0
  }

  // Heading anchors on a post.
  function anchors() {
    for (const h of document.querySelectorAll('.post h2[id], .post h3[id]')) {
      if (h.querySelector('.anchor')) continue
      const a = document.createElement('a')
      a.className = 'anchor'
      a.href = '#' + h.id
      a.setAttribute('aria-label', 'Link to this section')
      h.append(a)
    }
  }

  // The On This Page list marks the section being read, as in the docs.
  let off = null
  function post() {
    anchors()
    off?.()
    off = null
    const toc = document.querySelector('.post-toc ul')
    if (toc) off = spy(toc)
  }

  onMount(post)
  afterNavigate(post)
</script>

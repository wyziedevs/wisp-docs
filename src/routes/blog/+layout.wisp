---
const MONTHS: [&str; 12] = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
];
// Each post's prose word count and headings, from build.rs: [(path, words, [(id, text, level)])].
let facts: &[(&str, usize, &[(&str, &str, u8)])] =
    include!(concat!(env!("OUT_DIR"), "/blog.rs"));
// "2026-10-04" to "Oct 4, 2026" (short) or "October 4, 2026".
let day = |d: &str, short: bool| {
    let mut it = d.splitn(3, '-');
    let (y, m, n) = (
        it.next().unwrap_or(""),
        it.next().unwrap_or(""),
        it.next().unwrap_or(""),
    );
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
    p.get("tags")
        .unwrap_or("")
        .split(',')
        .map(str::trim)
        .filter(|t| !t.is_empty())
        .collect()
};

let path = site::bare(cx.path());
let index = path == "/blog";
let tags_page = path == "/blog/tags";
let posts: Vec<&wisp::MdPage> = wisp::pages("blog")
    .iter()
    .filter(|p| p.get("date").is_some())
    .collect();

let q = cx.query_or("q", String::new());
let tag = cx.query_or("tag", String::new());
let words: Vec<String> = q
    .to_lowercase()
    .split_whitespace()
    .map(str::to_string)
    .collect();
let shown: Vec<(&wisp::MdPage, String)> = posts
    .iter()
    .map(|p| {
        let text = format!(
            "{} {} {}",
            p.title,
            p.get("description").unwrap_or(""),
            p.get("tags").unwrap_or("")
        );
        (*p, text.to_lowercase())
    })
    .filter(|(p, text)| {
        words.iter().all(|w| text.contains(w.as_str()))
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
      {#if posts.is_empty()}
        <div class="blog-empty">
          <h2>No Posts Yet</h2>
          <p>The first one is on its way. Until then, follow along on <a href="https://github.com/wyziedevs/wisp">GitHub</a> or join the <a href="/community/">community</a>.</p>
        </div>
      {:else}
      <form class="blog-bar" method="get" action="/blog/" role="search">
        <label class="sr" for="blog-q">Filter Posts</label>
        <input
          id="blog-q"
          type="search"
          name="q"
          value={q}
          placeholder="Filter by word or tag"
          autocomplete="off"
          on:input="filter(event)">
        {#if !tag.is_empty()}<input type="hidden" name="tag" value={tag}>{/if}
        <p class="blog-count" role="status" aria-live="polite">{count(shown.len())}</p>
        <a href="/blog/tags/">All Tags</a>
        <a href="/feed.xml">RSS</a>
      </form>
      <p class="blog-tag" hidden={tag.is_empty()}>Tagged <strong>{tag}</strong> · <a href="/blog/">Show All</a></p>
      {/if}
    </header>
    <ul class="posts">
      {#each shown as (p, text)}
        <li data-text={text} data-tags={tags_of(p).join(",").to_lowercase()}>
          <h2><a href={site::dir(p.path)}>{p.title}</a></h2>
          {#if let Some(d) = p.get("description")}<p>{d}</p>{/if}
          <Meta
            iso={p.get("date").unwrap_or("")}
            when={day(p.get("date").unwrap_or(""), true)}
            author={p.get("author").unwrap_or("")}
            read={read(p.path)} />
        </li>
      {/each}
    </ul>
    <p class="blog-none" hidden={!shown.is_empty() || posts.is_empty()}>No posts match. <a href="/blog/">Show All</a></p>
  {:else}
    {#if tags_page}
      <header class="blog-head">
        <p class="eyebrow"><a href="/blog/">The Blog</a></p>
        <h1>Everything We Write About</h1>
        <p class="lede">Every topic on the Wisp blog, with how many posts cover it.</p>
      </header>
      <ul class="tag-list">
        {#each all_tags as (t, n)}
          <li><a href={format!("/blog/?tag={t}")}>{t}</a> <span>{count(*n)}</span></li>
        {/each}
      </ul>
    {:else}
      <div class="post-wrap">
        <Toc heads={heads} cls="post-toc" />
        <article class="post doc">
          <p class="eyebrow"><a href="/blog/">The Blog</a></p>
          {#if let Some(p) = post}
            <h1 class="doc-title">{p.title}</h1>
            {#if let Some(d) = p.get("description")}<p class="lede">{d}</p>{/if}
            <Meta
              iso={p.get("date").unwrap_or("")}
              when={day(p.get("date").unwrap_or(""), false)}
              author={p.get("author").unwrap_or("")}
              read={read(path)} />
            {#if !tags_of(p).is_empty()}
              <nav class="chips" aria-label="Tags">
                {#each tags_of(p) as t}<a href={format!("/blog/?tag={t}")}>{t}</a>{/each}
              </nav>
            {/if}
          {/if}
          <slot />
          <Pager
            label="Newer and older posts"
            before="Newer"
            after="Older"
            prev={newer.map(|p| (p.path, p.title))}
            next={older.map(|p| (p.path, p.title))} />
        </article>
      </div>
    {/if}
  {/if}
</div>

<script>
  import { afterNavigate } from 'wisp'
  import { reading } from '$lib/toc.js'

  // Shows the posts that hold every word of q and carry the tag. The server
  // filters the same way for a request; a static host cannot, so the page does.
  function show(q, tag) {
    const words = q.toLowerCase().split(/\s+/).filter(Boolean)
    let n = 0
    for (const li of document.querySelectorAll('.posts li')) {
      const hit = words.every((w) => li.dataset.text.includes(w)) && (!tag || li.dataset.tags.split(',').includes(tag))
      li.hidden = !hit
      if (hit) n++
    }
    document.querySelector('.blog-count').textContent = n + (n === 1 ? ' post' : ' posts')
    document.querySelector('.blog-none').hidden = n > 0
  }

  const tagOf = () => (new URLSearchParams(location.search).get('tag') ?? '').toLowerCase()

  function filter(e) {
    show(e.target.value, tagOf())
  }

  // The address's ?q= and ?tag= on the list page.
  function query() {
    const field = document.getElementById('blog-q')
    if (!field) return
    const p = new URLSearchParams(location.search)
    const tag = p.get('tag') ?? ''
    const chip = document.querySelector('.blog-tag')
    chip.hidden = !tag
    chip.querySelector('strong').textContent = tag
    field.value = p.get('q') ?? ''
    show(field.value, tag.toLowerCase())
  }

  // Heading anchors on a post, and the On This Page marker, as in the docs.
  let off = null
  function post() {
    off?.()
    off = null
    const art = document.querySelector('.post')
    if (!art) return
    // The copy notice for screen readers, as the docs have beside their article.
    let live = art.querySelector('.copied')
    if (!live) {
      live = document.createElement('p')
      live.className = 'sr copied'
      live.setAttribute('role', 'status')
      live.setAttribute('aria-live', 'polite')
      art.prepend(live)
    }
    off = reading(art, '.post-toc ul', (m) => (live.textContent = m))
  }

  // Leaving a post stops the marker's window listeners.
  onDestroy(() => off?.())
  onMount(() => {
    post()
    query()
    // Typing filters in place, so Enter has nothing to submit.
    document.querySelector('.blog-bar')?.addEventListener('submit', (e) => e.preventDefault())
  })
  afterNavigate(() => {
    post()
    query()
  })
</script>

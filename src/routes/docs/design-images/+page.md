---
title: Images and snippets
description: Images, WebP srcset, and snippets: markup a file renders more than once.
group: Design
order: 15
---

## Images

`<img src="$lib/photo.jpg" alt="…">` (a file of `src/lib`) or
`src="/photo.jpg"` (one of `static/`), a JPEG, PNG or WebP with a quoted
`src`, is filled in by the compiler before it parses the template (in
`wisp-build/src/image.rs`, on the same lines):

- Always: `width` and `height` from the file's header (a small reader for
  the three formats, EXIF orientation included; no image crate), unless
  the tag sets either. The page does not shift as images load.
- `wisp build`: each image is written as WebP at up to three widths (640,
  1280, 1920, never wider than it) into `.wisp/img/<hash>-<w>.webp`, by a
  pinned cwebp (libwebp 1.6.0, downloaded once to `~/.wisp/bin` and checked
  by SHA-256, as Tailwind is; `$WISP_CWEBP` overrides it). The names are
  the content's hash, so a second build encodes nothing. The release build
  embeds them, a `src/lib` original too, served under `/_app/img/` as
  immutable, and adds `srcset`, `sizes="100vw"`, `loading="lazy"` and
  `decoding="async"`. An attribute the tag has stays as written.
- Durable: without cwebp (no network, no build for the platform, a failed
  encode) the build warns, and the tag gets no `srcset`: the original is
  served, sized. A JPEG whose EXIF turns it gets no WebP (cwebp would not
  turn it). A `$lib/` file that is not there is a build error.
- Dev serves the original (`/_app/img/lib/photo.jpg` from `src/lib`),
  adding only `width` and `height`: nothing to encode on a save.
- `<img priority …>` (bare, as in next/image) is above the fold: the
  attribute goes, `fetchpriority="high"` comes, and the tag is not lazy.
- Opt-in `avif` feature (`wisp-cli` and `wisp-build`, off by default, so the
  default dependency tree is unchanged): `wisp build` also writes AVIF
  widths, in process with `ravif` and `image` (pure Rust, slow, which is
  why it is opt-in), and the tag becomes
  `<picture><source type="image/avif" srcset sizes>…<img …></picture>`.
  Without the files nothing changes.
- Opt-in `img` feature (`wisp`, off by default; deps `image` with the png,
  jpeg and webp decoders only, reason: resizing needs decoders): a route
  file `src/routes/_img/+server.rs` with `wisp::img::serve::<crate::App>(cx)`
  answers `/_img?src=/photo.jpg&w=640&q=75`. Only `static/` files (embedded
  in a release binary), `w` from a fixed list (next/image's), `q` 1 to 100,
  no `..`, files over 10 MB or 40 megapixels refused, a decoder panic is a
  400, results cached in memory (64 MB). It is a route like any other: the
  hot path has no code for it, and nothing is compiled without the feature.
- `<img data-wisp-raw …>` stays as written (a `$lib/` src still gets its
  URL). A `src` with a hole, or another site's, is left alone.
- Cost: none for an app without local images; a header read per image per
  build.

## Snippets

A snippet is markup a file renders more than once, or gives to a component:

```html
{#snippet row(post, i)}
  <td>{i}</td><td>{post.title}</td>
{/snippet}

<table>{#each data.posts as post, i}<tr>{@render row(post, i)}</tr>{/each}</table>

<Table rows={data.posts} {row} />
<Table rows={data.posts}>
  {#snippet row(post, i)}<td>{post.title}</td>{/snippet}
</Table>
```

```html
<!-- src/components/Table.wisp -->
{@props rows: &[Post], row: Snippet<&Post, usize>}
<table>{#each rows as r, i}<tr>{@render row(r, i)}</tr>{/each}</table>
```

- Parameters are Rust `let` patterns, typed or not: each render gives them
  their types. The body sees the names around its definition, like a
  closure. A snippet is in scope after its `{/snippet}`, to the end of the
  block it is in; it cannot render itself (a component can).
- A component takes one as a prop of type `Snippet<A, B>` (`Snippet` for
  none), which is `&dyn Fn(&mut Out, A, B)`: `{row}` or `row={row}` in its
  tag, or a `{#snippet row(…)}` among its children, and it renders it with
  `{@render row(…)}`.
- `{:@render row(x)}` has the browser draw it: the arguments are
  JavaScript, and the body uses its parameters in `{:…}` (see
  [client.md](/docs/client)). A component the browser draws takes snippets
  the same way (`<List items={:xs} {row} />`, or `{#snippet row(x)}` among
  its children) and draws one with `{:@render row(x)}` where `row` is a
  prop: the snippet's body is a block before the tag (`Dir::Snip`, which
  `snip` in extra.js binds), and the component finds it among the anchors
  right before its own, so no first paint for a component given one.

---
title: Islands and Loading
description: Use islands in Wisp to add React, Vue, Svelte or Preact, web components, npm UI libraries and third-party scripts, with loading views and lazy loading.
group: Browser Code
order: 32
---

## Islands
A page ships JS only for files with client code; a component can wait:

```html
<Chart client:visible />                        <!-- near the viewport (200px) -->
<Comments client:idle />                        <!-- browser idle -->
<Filters client:media="(min-width: 800px)" />   <!-- query matches -->
<Menu client:interaction />                     <!-- first pointer, focus or key -->
<Badge client:none />                           <!-- never: no module, no values -->
<section client:visible>{:#each rows as row}…{:/each}</section>   <!-- an element with browser code -->
```

- `client:load` (default) starts with the page.
- The server paints every island, so it works as HTML until it wakes; the click that wakes one is replayed.
- `client:*` on a component needs it to have browser code.
- Islands get no `modulepreload`; a page of only islands loads no runtime until one wakes.
- A component with no browser code is a server component (no JS). They nest with islands in any order (`<Panel client:idle><Plain label="Sales" /></Panel>`, where `Plain.wisp` may hold `<Chart client:visible />`).
- An inner island wakes at its own moment and wakes the waiting island around it (its parent, for `getContext`).

### React, Vue, Svelte, Preact
`wisp add react react-dom react-switch` (framework first), then:

```html
<Island
  of="react:react-switch"
  client:visible
  props={:{ checked: on, onChange: (v) => (on = v) }} />
<p>{:on ? 'On' : 'Off'}</p>
<script>
  let on = false
</script>
```

- `of="framework:module"` (`react preact vue svelte`); the default export is the component, `#Name` a named one (`react:recharts#LineChart`); `$lib` works (`react:$lib/Chart.js#Chart`).
- `props={:…}` is browser (state, callbacks, redraws on change); `props={rows}` is Rust, sent once as JSON.
- `client:*` as for any island; children show until it starts. Other attributes (`class`, `id`) go on its `<div>`, which morphs leave alone.
- The framework must be in `package.json` (else a build error); it loads only on pages with an island of it, one shared copy. A Svelte package must ship compiled JS.

### Web Components
Import the module, write the tag (Shoelace, Web Awesome `wa-`, Lit). `on:` takes their events (dashes too); `bind:value` listens for `input`.

```html
<sl-input label="Name" bind:value="name"></sl-input>
<sl-switch on:sl-change="on = event.target.checked">Power</sl-switch>
<script>
  import '@shoelace-style/shoelace/dist/components/input/input.js'
  import '@shoelace-style/shoelace/dist/components/switch/switch.js'
  let on = false
</script>
```

- `wisp add @shoelace-style/shoelace`; import each component's own module.
- Theme CSS: copy `cdn/themes/light.css` into `static/` and `<link>` it in `src/app.html`, or `@import` a CDN after `wisp::csp("style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net")` in `init`.
- Your own with Lit: `wisp add lit`, `customElements.define('hello-tag', class extends LitElement {…})` in a `src/lib` module a script imports.
- The `click-events` a11y lint skips custom elements.

## Your Own Bundle (npm UI Libraries)
For a widget `wisp add` cannot serve (React, Svelte, a charting kit): bundle it with your own tool, no Wisp dependency, into `static/`, and mount it from a `use:` action. `data-wisp-keep` stops a morph from touching what the widget draws.

```sh
esbuild src/widget.js --bundle --minify --format=esm --outfile=static/widget.js   # or vite build
```

```html
<div data-wisp-keep use:widget="{ label }"></div>
<script>
  function widget(el, props) {            // mount(el, props), update(props), destroy()
    let w
    import('/widget.js').then((m) => (w = m.mount(el, props)))
    return { update: (p) => w?.update(p), destroy: () => w?.destroy() }
  }
</script>
```

- `destroy` runs when the element leaves the page (a navigation or `{:#if}`).
- To share a library between bundles, a `<script type="importmap">` in `src/app.html` maps `"react"` to a file in `static/`.
- Packages `wisp add` serves need none of this: `<Island of="react:name">`.

## Third-Party Scripts
Pick when one loads (`src`, so no code of yours). In the head:

<div class="table-wrap">

| Tag | Loads |
|---|---|
| `<script src>` | before interactive |
| `<script defer src>` | after interactive |
| `<script src="https://t.example/a.js" type="wisp/idle">` | when the browser is idle (also on a client navigation) |
| `type="wisp/interaction"` | at the first pointer, key or scroll |

</div>

Other attributes (`async`, `data-*`) are copied.

## Loading Views
`src/routes/blog/+loading.wisp` is static HTML (a `<style>` is fine; no `---` block, holes or components). A client navigation to `/blog` or any page below it shows it in `<main>` the moment the link is followed, until the page arrives and morphs over it (`aria-busy` is set meanwhile).

- The deepest folder that fits wins; `routes/+loading.wisp` is for every page.
- None for a page already fetched ahead (hover), back or forward, or a full page load.
- The build writes the views as JSON into the shell's head: an app with no `+loading.wisp` has none of it, and no request is made for one.

## Web Vitals
`<meta name="wisp-vitals" content="/vitals">` (in `src/app.html`) is opt-in: when the page is hidden, wisp.js sends that path one beacon (`sendBeacon`, a POST) of JSON: `{"path":"/x","ttfb":12,"lcp":480.5,"cls":0.02,"inp":64}`.

- Times in ms, `cls` a score; a metric the browser never measured is left out.
- One per page load; client navigations are not counted.
- Receive it with `vitals/+server.rs`: `fn post(cx: &mut Cx) -> Result<()>` reading `cx.body()`.
- No page that does not name the tag runs any of it.

## Loading Code on Demand
`import()` loads when reached:

```html
<button on:click="import('$lib/chart.js').then((m) => m.draw(el))">Chart</button>
```

- Resolves like a static import: `$lib/x.js` (or `$lib/x`; `x.js` for `x.ts`), a relative path into `src/lib`, an npm package. A missing path, or one outside `src/lib` (the only files the browser loads), is a build error.
- No bundle: each lib file, component and package is one immutable hashed URL shared by all pages.
- A page `modulepreload`s its static imports all the way down; `import()` targets and island code wait.

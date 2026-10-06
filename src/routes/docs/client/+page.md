---
title: Browser Code
description: Write browser code in the same .wisp file as your page: scripts, runes, TypeScript, environment variables, translations, directives and event modifiers in Wisp.
group: Browser Code
order: 30
---

Pages work without JavaScript; a script and directives in the same `.wisp` file add behavior. No bundler. `{…}` is Rust (server); a quoted directive value and `{:…}` are JavaScript (browser).

```html
<button on:click="count++">Clicked {:count} times</button>
```

A handler that counts (`n++`) or toggles (`open = !open`) a name nothing declares starts it at 0 or `false`; another start is `let count = 5;` in the `---` block. A `<script>` is only for real browser logic.

## State in the `---` Block
The cheapest browser state is a literal `let` in the page's `---` block: a number, `true`/`false`, `None` (null), a string, or `[..]`/`vec![..]` of those, alone on its line (a trailing comment is fine). The build moves it into the page's client code exactly as a `<script>` `let` would be: no per-request server cost, and `{:count}` and directives read it. A computed value, or one the server also renders, stays a Rust `let` and is sent with the page.

- A form action that rewrites the name keeps the browser's value across the morph.
- A moved number is no longer a Rust value, so its type and range are not checked: `let x: u8 = 300;` builds.
- A `let` that shares its line with other code stays Rust.
- Use a `<script>` for real browser logic: the DOM, `$effect`, lifecycle, imports, `$props`.

## The Script
A bare `<script>` (no attributes; one per file) is for real browser logic and works in pages, layouts and components and runs once per place the file is shown. `<script type|src>` stays plain HTML. Errors point at the `.wisp` line.

- Top-level `let`s are state: assigning one, or changing an object, array, `Map` or `Set` in it (`todos.push(t)`, `todo.done = true`), redraws. A `let` set to a string, number or boolean and never assigned is a constant.
- `import` lines move to the module head (`import c from 'https://esm.sh/canvas-confetti'`).
- npm: `wisp add canvas-confetti[@1.2.3|tag]` pins it in `package.json` (`wisp remove x`; no Node); `import c from 'canvas-confetti'` (also `'pkg/sub'`, `'@scope/pkg'`) in scripts and `src/lib`. Dev loads esm.sh; `wisp build` downloads into `.wisp/npm` and the binary serves `/_app/c/npm/`. A package not in `package.json`, or a range (`^1.0`), is a build error.

### Runes
A write redraws only the bindings that read what changed (no virtual DOM); the script runs once; writes batch in a microtask.

```html
<p>{:done} of {:todos.length} done</p>
{:#each todos as todo (todo.id)}
  <li class:done="todo.done" on:click="todo.done = !todo.done">{:todo.text}</li>
{:/each}
<script>
  let todos = $state([{ id: 1, text: 'Tea', done: false }])
  let done = $derived(todos.filter((t) => t.done).length)
  $effect(() => { document.title = `${done} done` })
</script>
```

<div class="table-wrap">

| Rune | Meaning |
|---|---|
| `let x = $state(v)` | Deep state (a plain `let x = v` is the same). |
| `$state.raw(v)` | Changes only when assigned. |
| `$state.snapshot(x)` | Plain copy. |
| `$derived(expr)`, `$derived.by(fn)` | Recomputed when read after an input changed; assigning is a build error. |
| `$effect(fn)` | After the DOM is drawn and when what it read changes; may return a cleanup. |
| `$effect.pre(fn)` | Same, before the DOM is drawn. |
| `$effect.root(fn)` | Effects made in `fn` end with the function it returns, not with the component. |
| `$effect.tracking()` | Whether the running code tracks what it reads (inside an effect or a binding). |
| `let { a, b = 1, c: d, ...rest } = $props()` | Component props with browser defaults (absent or `null`); needs no `{@props}`. |
| `$bindable(default)` | A prop a parent may `bind:`; with `$props()` only these bind. |
| `$inspect(a, b)` | Logs on change (`.with(f)`: `f('update', a, b)` instead); gone in release. |
| `$props.id()` | An id of the instance's own, for `for` and `aria-*`. |
| `$cart` | Store `cart`'s `.value`, tracked; `$cart = x` sets it. |

</div>

- A class's `$state`/`$derived` fields make its instances state. `untrack(fn)` reads untracked. A misplaced rune is a build error.
- Deep state tracks plain objects, arrays, maps, sets and such classes; for a `Date` or other instance assign again (`d = d`).
- `x === e` redraws only where the answer changes (`class:on="selected === row.id"` redraws two rows).

## TypeScript
`<script lang="ts">`, `src/lib/*.ts` (`'$lib/x'`) and `+page.ts`. Types are stripped in place (lines and columns stay); no compiler. Code-producing TS is a build error saying what to write:

<div class="table-wrap">

| Not allowed | Write |
|---|---|
| `enum Color { Red }` | `const Color = { Red: 'red' } as const` |
| `namespace` | a module |
| `constructor(private x: number)` | `x: number; constructor(x: number) { this.x = x }` |
| `import fs = require('fs')` | `import fs from 'fs'` |

</div>

`wisp check --types` also type-checks with the app's TypeScript (`npm install -D typescript`, or `WISP_TSC` naming a `tsc`; else skipped). Server values are typed by Rust (`Vec<Item>` is `Item[]`, a `#[derive(Json)]` type an interface; hand-written `Json` is `unknown`).

## Environment Variables
`env.PUBLIC_NAME` in browser code (script, directive, `src/lib`, `+page.js`) is written in at build (no `env` object exists).

- Values: the build's environment, then `.env` for names it lacks; `wisp dev` rebuilds when `.env` changes.
- Only `PUBLIC_` names reach the browser (`env.DATABASE_URL` is a build error). An unset one is a build error too: set it even empty (`PUBLIC_FLAG=`).
- `env` read whole or `env[name]` is an error; a variable of your own named `env` is just that.
- Server: `wisp::env("K")`.

## Translations
`t('cart.items', n)` or `t('hi', { name, count: n })` in a script or directive, no import; keys checked at build; the page sends only the messages its scripts use. `src/lib` code can't call `t`. Message files: [Tooling, images and translations](/docs/design-tooling/#translations).

## Directives

<div class="table-wrap">

| Syntax | Meaning |
|---|---|
| `on:click="count++"` | Handler; a bare name (`on:click="press"`) is called with the event. |
| `bind:value="q"` / `bind:checked="done"` | Two-way. `bind:value` alone binds `value`. An undeclared name is declared as state (`let q`): live search needs no `<script>`. |
| `bind:group="size"` | Radios (value) and checkboxes (array) sharing a `name`. |
| `bind:files` `bind:open` `bind:innerHTML` `bind:currentTime` `bind:paused`… | Any property; the element's own event keeps it current. |
| `bind:clientWidth="w"` | Sizes (`clientWidth/Height`, `offsetWidth/Height`, `contentRect`). |
| `bind:this="el"` | Element into `el`. |
| `:hidden="!open"` | Live attribute; `false`, `null`, `undefined` remove it. |
| `:text="name"` | Live text. |
| `class:open="isOpen"` | Toggle a class; `class:open` alone reads `open`. |
| `style:--x="x"` | Style property; `style:color` alone reads `color`. |
| `class={:['card', { on }]}` | Names from strings, arrays, truthy object keys. |
| `style={:{ color, fontSize: '2em' }}` | Properties from an object. |
| `{:...attrs}` | Each key an attribute (an `on…` function a listener). |
| `transition:fade` | `fade slide scale fly blur`; options `transition:fly="{ y: 20 }"`. |
| `in:fly` / `out:fade` | Only in / only out. |
| `transition:spin` | Your `spin(el, options, { direction })` returning `{ duration, delay, easing, css: (t, u) => '…' }` or `{ tick(t, u) }`. |
| `use:tip="'Hello'"` | Calls `tip(el, 'Hello')` and its `update` on change; may return a cleanup or `{ update, destroy }`. |
| `use:portal="'#modal'"` | Move the element there (bare: `<body>`). |
| `use:outside="() => open = false"` | Calls it at a press outside the element (menus, popovers). |
| `use:inview="(v) => seen = v"` | `true` as the element comes into view, `false` as it leaves. |
| `use:shortcut="'mod+k'"` | The keys click the element (a field: focus it); `ctrl shift alt meta`, `mod` is ⌘ on a Mac, else Ctrl. A bare key typed in a field stays typed. |
| `use:modal="open"` | A `<dialog>` shown as a modal while `open` is true; `on:close="open = false"` for Escape. |
| `use:preload` | On a link or around links: each is fetched ahead once in view; not with data saver on or under `data-wisp-preload="off"`. |
| `use:keepscroll` | Back and forward put this element's scroll back (give it an `id` when there are several). |
| `animate:flip` | Animate moves in a keyed `{:#each}`. |

</div>

```html
<input bind:value="query" on:keydown.enter="search" on:keydown.escape="query = ''">
<div on:click.outside="open = false">…</div>
<input on:input.debounce.300ms="search()">
<div on:keydown.ctrl.s.prevent.window="save">…</div>
```

### Event Modifiers
- `.prevent .stop .once .self .capture .passive`
- `.window`, `.document`: listen there. `.outside`.
- `.debounce[.300ms]` (default 250 ms).
- Keys: `.enter .escape .space .tab .backspace .delete .up .down .left .right .home .end .pageup .pagedown`, a letter or digit.
- `.ctrl .shift .alt .meta`.

Unknown ones are a build error. A bound input starts from what the server rendered or the visitor already typed.

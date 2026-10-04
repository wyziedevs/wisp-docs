{@props todos: &[String], problem: &str = "", text: &str = ""}
<div class="demo tabbed" id="demo">
  <div class="code">
    <div class="tabs" role="radiogroup" aria-label="Files">
      <input class="sr" type="radio" name="demo-file" id="demo-page" checked>
      <label for="demo-page">+page.wisp</label>
      <input class="sr" type="radio" name="demo-file" id="demo-db">
      <label for="demo-db">db.rs</label>
    </div>
    <div class="panes">{@render children()}</div>
  </div>

  <div class="result">
    <div class="chrome"><span class="url">localhost:3000</span></div>
    <div class="view">
      <h3>Todos ({todos.len()})</h3>
      <form method="post" action="/demo?/add" novalidate>
        <label for="todo-text">Text</label>
        <div class="row">
          <input
            id="todo-text"
            name="text"
            value={text}
            aria-invalid={if problem.is_empty() { "false" } else { "true" }}
            aria-describedby="todo-problem"
            autocomplete="off">
          <button>Add</button>
        </div>
        <small id="todo-problem" class="problem" role="alert">{problem}</small>
      </form>
      <ul>
        {#each todos.iter().enumerate() as (i, t)}
          <li><span>{t}</span><button class="remove" form="todo-remove" formaction={format!("/demo?/remove&i={i}")} aria-label={format!("Remove {t}")}>Remove</button></li>
        {/each}
      </ul>
      <form id="todo-remove" method="post" action="/demo?/remove" hidden></form>
    </div>
  </div>
</div>

<style>
  /* Code next to its rendered result. */
  .demo {
    display: grid;
    gap: 1.5rem;
  }

  @media (min-width: 60rem) {
    .demo {
      grid-template-columns: 1.15fr 1fr;
    }
  }

  .demo .code,
  .result {
    min-width: 0;
    background: var(--code);
    overflow: hidden;
  }

  .demo :global(pre) {
    margin: 0;
    border: 0;
    border-radius: 0;
  }

  .chrome {
    padding: 0.625rem 1rem;
    border-bottom: 1px solid var(--line);
    color: var(--ash);
    font: 0.8125rem/1.4 var(--mono);
  }

  .chrome .url::before {
    content: "";
    display: inline-block;
    width: 0.4375rem;
    height: 0.4375rem;
    margin-right: 0.5rem;
    border-radius: 50%;
    background: var(--good);
    vertical-align: 0.0625em;
  }

  .result {
    background: var(--panel);
  }

  .view {
    padding: 1.25rem 1.5rem 1.5rem;
  }

  .view h3 {
    margin: 0 0 1rem;
    font-size: 1.375rem;
  }

  .view label {
    display: block;
    margin-bottom: 0.25rem;
    font-size: 0.875rem;
    font-weight: 600;
  }

  .view .row {
    display: flex;
    gap: 0.5rem;
  }

  .view input[aria-invalid="true"] {
    border-color: var(--warn);
    animation: shake 340ms var(--ease);
  }

  .view form button,
  .view .remove {
    padding: 0 1rem;
    border: 1px solid var(--line-strong);
    border-radius: var(--pill);
    background: var(--panel-2);
    color: var(--ink);
    font: 500 var(--fs-sm) var(--sans);
    cursor: pointer;
  }

  .view .remove {
    height: 2rem;
    padding: 0 0.625rem;
    font-size: 0.8125rem;
  }

  .view .problem {
    display: block;
    min-height: 1.5em;
    color: var(--warn);
    font-size: 0.875rem;
  }

  .view ul {
    display: grid;
    gap: 0.5rem;
    margin: 0.5rem 0 0;
    padding: 0;
    list-style: none;
  }

  .view li {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 1rem;
    padding: 0.5rem 0.5rem 0.5rem 0.875rem;
    border: 1px solid var(--line);
    border-radius: var(--radius);
    transition:
      opacity 300ms var(--ease),
      translate 300ms var(--ease);
  }

  @starting-style {
    .view li {
      opacity: 0;
      translate: 0 -0.375rem;
    }
  }
</style>


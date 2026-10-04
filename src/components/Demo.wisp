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


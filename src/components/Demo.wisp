<div class="demo tabbed">
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
      <h3>Todos ({:todos.length})</h3>
      <form on:submit.prevent="add()" novalidate>
        <label for="todo-text">Text</label>
        <div class="row">
          <input
            id="todo-text"
            name="text"
            bind:value="text"
            :aria-invalid="error !== ''"
            aria-describedby="todo-problem"
            autocomplete="off">
          <button>Add</button>
        </div>
        <small id="todo-problem" class="problem" role="alert">{:error}</small>
      </form>
      <ul>
        {:#each todos as t, i}
          <li><span>{:t}</span><button type="button" class="remove" on:click="remove(i)" :aria-label="'Remove ' + t">Remove</button></li>
        {:/each}
      </ul>
    </div>
  </div>
</div>

<script>
  let text = ''
  let error = ''
  let todos = ['Buy milk', 'Write the docs']

  function add() {
    const t = text.trim()
    if (t.length < 1 || t.length > 100) {
      error = 'text must be 1 to 100 characters'
      return
    }
    error = ''
    todos = [...todos, t]
    text = ''
  }

  function remove(i) {
    todos = todos.filter((_, j) => j !== i)
  }
</script>

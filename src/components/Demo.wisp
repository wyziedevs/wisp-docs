<div class="demo" :data-tab="tab">
  <div class="code">
    <div class="tabs" role="tablist" aria-label="Files" on:keydown="move">
      <button
        type="button"
        role="tab"
        id="tab-page"
        aria-controls="pane-page"
        class:on="tab === 0"
        :aria-selected="tab === 0"
        :tabindex="tab === 0 ? 0 : -1"
        on:click="tab = 0">+page.wisp</button>
      <button
        type="button"
        role="tab"
        id="tab-db"
        aria-controls="pane-db"
        class:on="tab === 1"
        :aria-selected="tab === 1"
        :tabindex="tab === 1 ? 0 : -1"
        on:click="tab = 1">db.rs</button>
    </div>
    <div class="panes">{@render children()}</div>
  </div>

  <div class="result">
    <div class="chrome"><span class="dots" aria-hidden="true"><i></i><i></i><i></i></span><span class="url">localhost:3000</span></div>
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
        {:#each todos as t}
          <li>{:t}</li>
        {:/each}
      </ul>
    </div>
  </div>
</div>

<script>
  let tab = 0
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

  function move(e) {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return
    tab = tab === 0 ? 1 : 0
    e.currentTarget.querySelectorAll('[role=tab]')[tab].focus()
  }
</script>

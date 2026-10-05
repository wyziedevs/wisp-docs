// The home page's todo demo posts to the server, and works with JavaScript off.
// With JavaScript the posts go in the background and the list on the page is
// updated in place, so nothing reloads, rises or counts a second time. A server
// keeps the list in the visitor's cookie; a static host (404, 405, 501) has
// nothing to keep it, so the list lives in the page.
let hosted // does a server answer the demo's posts? learned from the first one

const post = async (url, body) => {
  if (hosted === false) return
  try {
    const r = await fetch(url, { method: 'POST', body, redirect: 'manual' })
    hosted = ![404, 405, 501].includes(r.status)
  } catch {
    hosted = false
  }
}

export function demo() {
  const root = document.querySelector('.demo .view')
  if (!root || root.dataset.live) return
  root.dataset.live = '1'
  const list = root.querySelector('ul')
  const count = root.querySelector('h3')
  const input = root.querySelector('input[name=text]')
  const problem = root.querySelector('.problem')
  const add = root.querySelector('form[action*="?/add"]')

  const rows = () => [...list.children]
  const recount = () => (count.textContent = `Todos (${list.children.length})`)
  const fail = (msg) => {
    problem.textContent = msg
    input.setAttribute('aria-invalid', msg ? 'true' : 'false')
  }

  add.addEventListener('submit', async (e) => {
    e.preventDefault()
    const text = input.value.trim()
    if (!text || text.length > 100) return fail('text must be 1 to 100 characters')
    fail('')
    input.value = ''
    // From the page's own row, so it carries the same scoped styles and enters the same way.
    const li = root.querySelector('#todo-row').content.firstElementChild.cloneNode(true)
    li.querySelector('span').textContent = text
    li.querySelector('button').setAttribute('aria-label', `Remove ${text}`)
    list.append(li)
    recount()
    await post(add.action, new URLSearchParams({ text }))
  })

  // Every Remove, the server-drawn rows' and the added ones, goes by its place in the list.
  list.addEventListener('click', async (e) => {
    const b = e.target.closest('button.remove')
    if (!b) return
    e.preventDefault()
    const li = b.closest('li')
    const i = rows().indexOf(li)
    if (i < 0) return
    li.remove()
    recount()
    await post(`${add.action.replace('?/add', '?/remove')}&i=${i}`, new URLSearchParams())
  })
}

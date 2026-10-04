// Wraps each table in a scroll box, so a wide one scrolls inside it
// instead of widening the page.
export function wrapTables(root) {
  for (const t of root.querySelectorAll('table')) {
    if (t.parentElement.classList.contains('table-wrap')) continue
    const box = document.createElement('div')
    box.className = 'table-wrap'
    t.before(box)
    box.append(t)
  }
}

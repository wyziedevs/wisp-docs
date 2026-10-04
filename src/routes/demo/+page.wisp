---
// The home page demo's forms post here. Done: back to the demo on the home
// page. A bad value: a 422 drawing the demo with the problem and the text.
#[model]
struct Todo {
    #[validate(len = 1..=100)]
    text: String,
}

#[action]
fn add(todo: Todo) {
    let text = todo.text.trim();
    if text.is_empty() {
        return invalid("text", "blank");
    }
    let mut todos = demo_todos(cx);
    todos.push(text.to_string());
    demo_save(cx, &todos);
    redirect("/#demo")
}

#[action]
fn remove(i: usize) {
    let mut todos = demo_todos(cx);
    if i < todos.len() {
        todos.remove(i);
    }
    demo_save(cx, &todos);
    redirect("/#demo")
}

let todos = demo_todos(cx);
let problem = match cx.problem("text") {
    Some(_) => "text must be 1 to 100 characters",
    None => "",
};
let text = cx.form().get("text").map(|t| t.into_owned()).unwrap_or_default();
---
<title>Todos Demo</title>
<section class="sec showcase">
<div class="wrap">
<Demo todos={&todos} problem={&problem} text={&text}></Demo>
<p><a href="/#demo">Back to the Home Page</a></p>
</div>
</section>

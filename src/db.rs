// The home page demo's todo list lives in the visitor's `todos` cookie (no
// server storage), so its forms work with JavaScript off.

const COOKIE: &str = "todos";
const MAX: usize = 20;
const BYTES: usize = 3800;

/// The list: items joined by `|`, each with `%XX` for `|`, `%` and what a
/// cookie cannot hold. Missing or bad: the default list.
pub fn demo_todos(cx: &Cx) -> Vec<String> {
    let Some(raw) = cx.cookie(COOKIE) else {
        return vec!["Buy milk".into(), "Write the docs".into(), "Learn to code".into()];
    };
    let todos: Vec<String> = raw.split('|').filter(|s| !s.is_empty()).filter_map(decode).collect();
    todos.into_iter().filter(|t| (1..=100).contains(&t.chars().count())).take(MAX).collect()
}

pub fn demo_save(cx: &mut Cx, todos: &[String]) {
    let skip = todos.len().saturating_sub(MAX);
    let mut parts: Vec<String> = todos[skip..].iter().map(|t| encode(t)).collect();
    // A cookie over 4096 bytes is dropped by the browser, so the oldest items go first.
    while parts.len() > 1 && parts.iter().map(|p| p.len() + 1).sum::<usize>() > BYTES {
        parts.remove(0);
    }
    let out = parts.join("|");
    // An empty list is one empty item, so it stays empty, not the default.
    cx.set_cookie(COOKIE, if out.is_empty() { "|" } else { &out });
}

fn encode(t: &str) -> String {
    let mut out = String::new();
    for b in t.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => out.push(b as char),
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

fn decode(s: &str) -> Option<String> {
    let b = s.as_bytes();
    let mut out = Vec::with_capacity(b.len());
    let mut i = 0;
    while i < b.len() {
        if b[i] == b'%' {
            let hex = s.get(i + 1..i + 3)?;
            out.push(u8::from_str_radix(hex, 16).ok()?);
            i += 3;
        } else {
            out.push(b[i]);
            i += 1;
        }
    }
    String::from_utf8(out).ok()
}

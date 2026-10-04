//! Writes static/search-index.json from the docs pages, then runs the Wisp build.
//! Entries are `[path, page title, group, description, [[anchor, heading, text]..]]`.

use std::collections::HashSet;
use std::fmt::Write as _;
use std::fs;
use std::path::Path;

const TEXT_CAP: usize = 420;

fn main() {
    println!("cargo:rerun-if-changed=src/routes/docs");
    println!("cargo:rerun-if-changed=src/routes/blog");
    println!("cargo:rerun-if-changed=build.rs");
    index();
    blog();
    wisp_build::run();
}

fn index() {
    let mut pages = Vec::new();
    collect(Path::new("src/routes/docs"), &mut pages);
    pages.sort();
    let mut out = String::from("[");
    let mut toc = String::from("&[");
    let mut first = true;
    for md in pages {
        let Ok(src) = fs::read_to_string(&md) else { continue };
        let path = md
            .strip_prefix("src/routes").ok()
            .and_then(|p| p.parent())
            .map(|p| format!("/{}", p.to_string_lossy().replace('\\', "/")))
            .unwrap_or_default();
        let (entry, heads) = page(&path, &src);
        let _ = write!(toc, "({path:?}, &[");
        for (id, h, level) in heads {
            let _ = write!(toc, "({id:?}, {h:?}, {level}),");
        }
        toc.push_str("]),");
        if !first {
            out.push(',');
        }
        first = false;
        out.push_str(&entry);
    }
    out.push(']');
    toc.push(']');
    // The headings of each page for the docs layout's Contents: [(path, [(id, text, level)])].
    let toc_rs = Path::new(&std::env::var("OUT_DIR").unwrap_or_default()).join("toc.rs");
    if fs::read_to_string(&toc_rs).ok().as_deref() != Some(&toc) {
        let _ = fs::write(&toc_rs, toc);
    }
    let _ = fs::create_dir_all("static");
    // Only rewrite on change, so an unchanged index does not retrigger the build.
    if fs::read_to_string("static/search-index.json").ok().as_deref() != Some(&out) {
        let _ = fs::write("static/search-index.json", out);
    }
}

/// Each blog post's reading words and h2s for the blog layout:
/// [(path, words, [(id, text)])]. Words are the prose a reader reads (text
/// outside code fences, Markdown marks stripped), counted at build time.
fn blog() {
    let mut posts = Vec::new();
    collect(Path::new("src/routes/blog"), &mut posts);
    posts.sort();
    let mut out = String::from("&[");
    for md in posts {
        let Ok(src) = fs::read_to_string(&md) else { continue };
        let Some(dir) = md.parent().and_then(|p| p.strip_prefix("src/routes").ok()) else { continue };
        let path = format!("/{}", dir.to_string_lossy().replace('\\', "/"));
        let body = src
            .strip_prefix("---")
            .and_then(|r| r.split_once("\n---"))
            .map_or(src.as_str(), |(_, b)| b);
        let (_, heads) = page(&path, &src);
        let mut words = 0;
        let mut fenced = false;
        for line in body.lines() {
            if line.trim_start().starts_with("```") {
                fenced = !fenced;
            } else if !fenced {
                words += plain(line.trim_start_matches('#')).split_whitespace().count();
            }
        }
        let _ = write!(out, "({path:?}, {words}, &[");
        for (id, h, level) in heads {
            if level == 2 {
                let _ = write!(out, "({id:?}, {h:?}),");
            }
        }
        out.push_str("]),");
    }
    out.push(']');
    let rs = Path::new(&std::env::var("OUT_DIR").unwrap_or_default()).join("blog.rs");
    if fs::read_to_string(&rs).ok().as_deref() != Some(&out) {
        let _ = fs::write(&rs, out);
    }
}

fn collect(dir: &Path, out: &mut Vec<std::path::PathBuf>) {
    let Ok(rd) = fs::read_dir(dir) else { return };
    for e in rd.flatten() {
        let p = e.path();
        if p.is_dir() {
            collect(&p, out);
        } else if p.file_name().is_some_and(|n| n == "+page.md") {
            out.push(p);
        }
    }
}

fn page(path: &str, src: &str) -> (String, Vec<(String, String, usize)>) {
    let (front, body) = match src.strip_prefix("---\n").or_else(|| src.strip_prefix("---\r\n")) {
        Some(rest) => match rest.split_once("\n---") {
            Some((f, b)) => (f, b.trim_start_matches(['\r', '\n'])),
            None => ("", src),
        },
        None => ("", src),
    };
    let field = |name: &str| {
        front
            .lines()
            .find_map(|l| l.strip_prefix(name)?.strip_prefix(':'))
            .map(|v| v.trim().to_string())
            .unwrap_or_default()
    };
    let (title, group, desc) = (field("title"), field("group"), field("description"));

    let mut sections: Vec<(String, String, String)> = Vec::new();
    let mut ids: HashSet<String> = HashSet::new();
    let mut heads = Vec::new();
    let mut fenced = false;
    let mut cur = (String::new(), String::new(), String::new());
    for line in body.lines() {
        if line.trim_start().starts_with("```") {
            fenced = !fenced;
            continue;
        }
        if fenced {
            continue;
        }
        let hashes = line.bytes().take_while(|b| *b == b'#').count();
        if (2..=4).contains(&hashes) && line[hashes..].starts_with(' ') {
            sections.push(std::mem::take(&mut cur));
            let heading = plain(line[hashes..].trim());
            let base = slug(&heading);
            let mut id = base.clone();
            let mut n = 2;
            while ids.contains(&id) {
                id = format!("{base}-{n}");
                n += 1;
            }
            ids.insert(id.clone());
            if hashes <= 3 {
                heads.push((id.clone(), heading.clone(), hashes));
            }
            cur = (id, heading, String::new());
            continue;
        }
        let t = plain(line);
        if t.is_empty() || t.chars().all(|c| "|-: ".contains(c)) {
            continue;
        }
        if cur.2.len() < TEXT_CAP {
            if !cur.2.is_empty() {
                cur.2.push(' ');
            }
            cur.2.push_str(&t);
        }
    }
    sections.push(cur);
    let mut out = String::new();
    let _ = write!(
        out,
        "[{},{},{},{},[",
        js(path),
        js(&title),
        js(&group),
        js(&desc)
    );
    let mut first = true;
    for (id, h, mut t) in sections {
        if h.is_empty() && t.is_empty() {
            continue;
        }
        if t.len() > TEXT_CAP {
            let mut n = TEXT_CAP;
            while !t.is_char_boundary(n) {
                n -= 1;
            }
            t.truncate(n);
        }
        if !first {
            out.push(',');
        }
        first = false;
        let _ = write!(out, "[{},{},{}]", js(&id), js(&h), js(&t));
    }
    out.push_str("]]");
    (out, heads)
}

/// Markdown to the text a reader sees: links to their text, no emphasis marks.
fn plain(s: &str) -> String {
    let mut out = String::new();
    let mut chars = s.trim().trim_start_matches(['-', '*', '>']).trim().chars().peekable();
    while let Some(c) = chars.next() {
        match c {
            '`' | '*' => {}
            '[' => {}
            ']' if chars.peek() == Some(&'(') => {
                for d in chars.by_ref() {
                    if d == ')' {
                        break;
                    }
                }
            }
            ']' => {}
            '<' => {
                for d in chars.by_ref() {
                    if d == '>' {
                        break;
                    }
                }
            }
            _ => out.push(c),
        }
    }
    out.trim().to_string()
}

/// The id the docs layout gives a heading: lowercase, `\w`, `-` and spaces kept,
/// spaces to dashes.
fn slug(h: &str) -> String {
    h.to_lowercase()
        .chars()
        .filter(|c| c.is_alphanumeric() || *c == '_' || *c == '-' || *c == ' ')
        .collect::<String>()
        .trim()
        .replace(' ', "-")
}

fn js(s: &str) -> String {
    let mut o = String::from("\"");
    for c in s.chars() {
        match c {
            '"' => o.push_str("\\\""),
            '\\' => o.push_str("\\\\"),
            '<' => o.push_str("\\u003c"),
            c if (c as u32) < 0x20 => {
                let _ = write!(o, "\\u{:04x}", c as u32);
            }
            c => o.push(c),
        }
    }
    o.push('"');
    o
}

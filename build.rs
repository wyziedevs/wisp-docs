//! Writes static/search-index.json from the docs pages, then runs the Wisp build.
//! Entries are `[path, page title, group, description, [[anchor, heading, text]..]]`.

use std::collections::HashSet;
use std::fmt::Write as _;
use std::fs;
use std::path::{Path, PathBuf};

const TEXT_CAP: usize = 420;

fn main() {
    println!("cargo:rerun-if-changed=src/routes/docs");
    println!("cargo:rerun-if-changed=src/routes/blog");
    println!("cargo:rerun-if-changed=src/css");
    println!("cargo:rerun-if-changed=build.rs");
    css();
    index();
    blog();
    wisp_build::run();
}

/// Writes `text` to `path` only when it differs, so an unchanged file does not
/// retrigger the build.
fn put(path: &Path, text: &str) {
    if fs::read_to_string(path).ok().as_deref() != Some(text) {
        let _ = fs::write(path, text);
    }
}

fn out_dir() -> PathBuf {
    PathBuf::from(std::env::var("OUT_DIR").unwrap_or_default())
}

/// The URL path of a `+page.md`: its directory below `src/routes`, with a leading slash.
fn route(md: &Path) -> Option<String> {
    let dir = md.parent()?.strip_prefix("src/routes").ok()?;
    Some(format!("/{}", dir.to_string_lossy().replace('\\', "/")))
}

/// A page's headings as Rust tuple source: `(id, text, level),` each.
fn heads_rs(heads: &[(String, String, usize)]) -> String {
    let mut out = String::new();
    for (id, h, level) in heads {
        let _ = write!(out, "({id:?}, {h:?}, {level}),");
    }
    out
}

/// The stylesheet is `src/css/*.css`, in name order, joined into `.wisp/app.css`,
/// which the Wisp build serves in place of `src/app.css`.
fn css() {
    let mut files: Vec<_> = fs::read_dir("src/css")
        .into_iter()
        .flatten()
        .flatten()
        .map(|e| e.path())
        .filter(|p| p.extension().is_some_and(|x| x == "css"))
        .collect();
    files.sort();
    let all = files
        .iter()
        .filter_map(|f| fs::read_to_string(f).ok())
        .collect::<Vec<_>>()
        .join("\n");
    let _ = fs::create_dir_all(".wisp");
    put(Path::new(".wisp/app.css"), &all);
}

fn index() {
    let mut pages = Vec::new();
    collect(Path::new("src/routes/docs"), &mut pages);
    pages.sort();
    let mut entries = Vec::new();
    let mut toc = String::from("&[");
    for md in pages {
        let Ok(src) = fs::read_to_string(&md) else { continue };
        let path = route(&md).unwrap_or_default();
        let p = page(&src);
        let _ = write!(toc, "({path:?}, &[{}]),", heads_rs(&p.heads));
        entries.push(p.entry(&path));
    }
    toc.push(']');
    // The headings of each page for the docs layout's Contents: [(path, [(id, text, level)])].
    put(&out_dir().join("toc.rs"), &toc);
    let _ = fs::create_dir_all("static");
    put(Path::new("static/search-index.json"), &format!("[{}]", entries.join(",")));
}

/// Each blog post's reading words and h2s for the blog layout:
/// [(path, words, [(id, text, level)])]. Words are the prose a reader reads (text
/// outside code fences, Markdown marks stripped), counted at build time.
fn blog() {
    let mut posts = Vec::new();
    collect(Path::new("src/routes/blog"), &mut posts);
    posts.sort();
    let mut out = String::from("&[");
    for md in posts {
        let Ok(src) = fs::read_to_string(&md) else { continue };
        let Some(path) = route(&md) else { continue };
        let body = src
            .strip_prefix("---")
            .and_then(|r| r.split_once("\n---"))
            .map_or(src.as_str(), |(_, b)| b);
        let mut words = 0;
        let mut fenced = false;
        for line in body.lines() {
            if line.trim_start().starts_with("```") {
                fenced = !fenced;
            } else if !fenced {
                words += plain(line.trim_start_matches('#')).split_whitespace().count();
            }
        }
        let _ = write!(out, "({path:?}, {words}, &[{}]),", heads_rs(&page(&src).heads));
    }
    out.push(']');
    put(&out_dir().join("blog.rs"), &out);
}

fn collect(dir: &Path, out: &mut Vec<PathBuf>) {
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

/// A parsed docs page: front matter, sections `(id, heading, text)` and the h2/h3 `heads`.
struct Page {
    title: String,
    group: String,
    desc: String,
    sections: Vec<(String, String, String)>,
    heads: Vec<(String, String, usize)>,
}

impl Page {
    /// The search index entry: `[path, title, group, desc, [[id, heading, text]..]]`.
    fn entry(&self, path: &str) -> String {
        let mut parts = Vec::new();
        for (id, h, t) in &self.sections {
            if h.is_empty() && t.is_empty() {
                continue;
            }
            let mut t = t.as_str();
            if t.len() > TEXT_CAP {
                let mut n = TEXT_CAP;
                while !t.is_char_boundary(n) {
                    n -= 1;
                }
                t = &t[..n];
            }
            parts.push(format!("[{},{},{}]", js(id), js(h), js(t)));
        }
        format!(
            "[{},{},{},{},[{}]]",
            js(path),
            js(&self.title),
            js(&self.group),
            js(&self.desc),
            parts.join(",")
        )
    }
}

fn page(src: &str) -> Page {
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
    Page { title: field("title"), group: field("group"), desc: field("description"), sections, heads }
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

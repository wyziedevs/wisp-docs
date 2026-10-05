// Decisions the root and docs layouts share.

/// The docs groups that make up Reference; Hosting has its own, and every other group is Learn.
const REFERENCE: &[&str] = &["Reference", "Design"];

/// The docs groups that make up Hosting.
const HOSTING: &[&str] = &["Deploy and Run", "Hosting"];

/// Which docs tab a page is in: `learn`, `reference` or `hosting`. A page can
/// say `section: ...` in its front matter; else its group decides.
pub fn section(p: &wisp::MdPage) -> &'static str {
    let group = p.get("group").unwrap_or("");
    match p.get("section") {
        Some("reference") => "reference",
        Some("hosting") => "hosting",
        Some(_) => "learn",
        None if REFERENCE.contains(&group) => "reference",
        None if HOSTING.contains(&group) => "hosting",
        None => "learn",
    }
}

/// A page's address as the site links it, with the trailing slash it is served at.
pub fn dir(path: &str) -> String {
    if path.ends_with('/') { path.to_string() } else { format!("{path}/") }
}

/// The request path without its trailing slash (`/docs/cli/` is `/docs/cli`), the form pages are keyed by.
pub fn bare(path: &str) -> &str {
    if path.len() > 1 { path.trim_end_matches('/') } else { path }
}

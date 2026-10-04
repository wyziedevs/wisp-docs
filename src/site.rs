// Decisions the root and docs layouts share.

/// The docs groups that make up Reference; every other group is Learn.
const REFERENCE: &[&str] = &["Reference", "Design"];

/// Is this docs page in Reference? A page can say `section: reference` or
/// `section: learn` in its front matter; else its group decides.
pub fn is_reference(p: &wisp::MdPage) -> bool {
    match p.get("section") {
        Some(s) => s == "reference",
        None => REFERENCE.contains(&p.get("group").unwrap_or("")),
    }
}

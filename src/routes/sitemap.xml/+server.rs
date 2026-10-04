//! The sitemap, with each address in the trailing-slash form the static host
//! serves without a redirect, and a blog post's date as its lastmod.

const SITE: &str = "https://wispweb.dev";

fn get() -> Response {
    let mut xml = String::from("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n");
    for p in wisp::pages("").iter().chain(wisp::pages("docs")).chain(wisp::pages("blog")) {
        let end = if p.path == "/" { "" } else { "/" };
        xml.push_str(&format!("<url><loc>{SITE}{}{end}</loc>", p.path));
        if let Some(d) = p.get("date") {
            xml.push_str(&format!("<lastmod>{d}</lastmod>"));
        }
        xml.push_str("</url>\n");
    }
    xml.push_str("</urlset>\n");
    Response::text(xml).with_header("content-type", "application/xml; charset=utf-8")
}

//! The blog as an RSS 2.0 feed.

const SITE: &str = "https://wispweb.dev";
const DAYS: [&str; 7] = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"];
const MONTHS: [&str; 12] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

fn get() -> Response {
    let mut items = String::new();
    for p in wisp::pages("blog") {
        let Some(date) = p.get("date") else { continue };
        let link = format!("{SITE}{}/", p.path);
        items.push_str(&format!(
            "<item><title>{}</title><link>{link}</link><guid>{link}</guid><description>{}</description><pubDate>{}</pubDate></item>",
            esc(p.title),
            esc(p.get("description").unwrap_or("")),
            rfc822(date),
        ));
    }
    let xml = format!(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\"><channel><title>Wisp Blog</title><link>{SITE}/blog/</link><atom:link href=\"{SITE}/feed.xml\" rel=\"self\" type=\"application/rss+xml\"/><description>News and notes from the Wisp project.</description><language>en</language>{items}</channel></rss>\n"
    );
    Response::text(xml).with_header("content-type", "application/rss+xml; charset=utf-8")
}

fn esc(s: &str) -> String {
    s.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

/// "2026-10-04" to "Sun, 04 Oct 2026 00:00:00 GMT".
fn rfc822(d: &str) -> String {
    let mut it = d.splitn(3, '-').map(|x| x.parse::<i64>().unwrap_or(0));
    let (y, m, n) = (it.next().unwrap_or(1970), it.next().unwrap_or(1), it.next().unwrap_or(1));
    if !(1..=12).contains(&m) {
        return d.to_string();
    }
    // Days since 1970-01-01 (Howard Hinnant's days_from_civil).
    let yy = if m <= 2 { y - 1 } else { y };
    let era = yy.div_euclid(400);
    let yoe = yy - era * 400;
    let mp = (m + 9) % 12;
    let doy = (153 * mp + 2) / 5 + n - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    let days = era * 146097 + doe - 719468;
    format!("{}, {n:02} {} {y} 00:00:00 GMT", DAYS[days.rem_euclid(7) as usize], MONTHS[m as usize - 1])
}

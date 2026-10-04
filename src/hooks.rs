//! Pages end in `/`, which is how a static host serves them without a redirect
//! and how the sitemap and canonical addresses are written.

fn init() {
    wisp::trailing_slash(wisp::TrailingSlash::Always);
}

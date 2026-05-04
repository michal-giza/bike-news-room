//! Detect "site shut down / portal closed" banners in fetched HTML.
//!
//! Why this exists: Rowery.org closed in December 2024 but kept serving
//! a 200 OK Hugo page reading "Czas pożegnania — wortal rowery.org
//! zakończył działalność" ("Time to say goodbye — the portal has ended
//! operations"). Our crawler considered the source "healthy" (200 +
//! parseable HTML, just zero article cards), so it stayed in the feed
//! catalogue for ~5 months emitting nothing. This detector catches the
//! pattern instantly: scan body text for known closure phrases in every
//! locale we ship, and flag the feed as `dead_reason = "shutdown banner
//! detected: …"` on first hit.
//!
//! False-positive guard: phrases are scanned only inside a normalised,
//! tag-stripped, length-capped (8 KB) prefix of the body. Long-tail body
//! content can't trip the detector via accidental quotation in an
//! article (we'd need both the phrase + zero article cards, and dead
//! sources tend to be small static pages well under 8 KB).
//!
//! Phrase list maintenance: keep entries lowercase + normalised. Add
//! new entries as ops encounters them. Each phrase should be:
//!   - ≥10 chars (avoids matching common substrings)
//!   - unambiguous in context (not "site closed for maintenance")
//!   - locale-tagged in the comment so future ops knows which language

const SHUTDOWN_PHRASES: &[&str] = &[
    // Polish — Rowery.org canonical example
    "zakończył działalność",
    "wortal został zamknięty",
    "serwis został zamknięty",
    "portal został zamknięty",
    "zakończyliśmy działalność",
    "czas pożegnania",
    // English
    "site has been shut down",
    "site has closed",
    "site is no longer active",
    "this site is no longer maintained",
    "we have ceased operations",
    "we have shut down",
    "no longer publishing",
    "this domain is for sale",
    "this site has moved permanently to",
    // Spanish
    "este sitio ha cerrado",
    "hemos cesado nuestras operaciones",
    "el sitio ha sido cerrado",
    "el portal ha cerrado",
    // French
    "ce site a fermé",
    "ce site a cessé",
    "le site a fermé",
    "fin de l'aventure",
    "nous avons cessé nos activités",
    // Italian
    "il sito ha chiuso",
    "il portale ha cessato",
    "abbiamo cessato le attività",
    // German
    "die seite wurde geschlossen",
    "wir haben unsere tätigkeit eingestellt",
    "diese seite wird nicht mehr betrieben",
    "der betrieb wurde eingestellt",
    // Dutch
    "deze site is gesloten",
    "we hebben onze activiteiten beëindigd",
    "we zijn gestopt",
    // Portuguese
    "o site foi encerrado",
    "este site foi encerrado",
    "encerramos as nossas atividades",
    // Japanese (rare for our market but cheap to include)
    "サービスを終了",
    "閉鎖しました",
];

/// True if the body text contains at least one shutdown phrase. Returns
/// the matched phrase on success so the caller can record it in
/// `feeds.dead_reason` for ops review.
pub fn detect_shutdown(body: &str) -> Option<&'static str> {
    // Cheap normalise: lowercase + strip HTML tags + cap to 8 KB. We
    // copy here rather than borrow because lowercase changes char count
    // and HTML stripping touches every byte; the alternative is dual
    // iteration on every fetch which costs more than the alloc.
    let needle = normalise_for_scan(body);
    if needle.is_empty() {
        return None;
    }
    SHUTDOWN_PHRASES
        .iter()
        .find(|phrase| needle.contains(*phrase))
        .copied()
}

fn normalise_for_scan(body: &str) -> String {
    const SCAN_LIMIT: usize = 8 * 1024;
    let mut out = String::with_capacity(SCAN_LIMIT.min(body.len()));
    let mut in_tag = false;
    let mut last_was_space = true;
    for c in body.chars() {
        if out.len() >= SCAN_LIMIT {
            break;
        }
        match c {
            '<' => {
                in_tag = true;
                if !last_was_space {
                    out.push(' ');
                    last_was_space = true;
                }
            }
            '>' => in_tag = false,
            _ if in_tag => {}
            _ => {
                let lower = c.to_lowercase().next().unwrap_or(c);
                if lower.is_whitespace() {
                    if !last_was_space {
                        out.push(' ');
                        last_was_space = true;
                    }
                } else {
                    out.push(lower);
                    last_was_space = false;
                }
            }
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_polish_rowery_org_banner() {
        // Real Rowery.org closure markup — captured 2026-05-04.
        let html = r#"
            <html><head><title>rowery.org</title></head>
            <body>
              <h1>Czas pożegnania</h1>
              <p>Wortal rowery.org <strong>zakończył działalność</strong>. Dziękujemy.</p>
            </body></html>
        "#;
        assert_eq!(detect_shutdown(html), Some("zakończył działalność"),);
    }

    #[test]
    fn detects_across_html_tag_boundaries() {
        // The closure phrase must match even when interleaved with HTML
        // tags — the normaliser strips them.
        let html = r#"<p>This <em>site</em> has <strong>closed</strong></p>"#;
        // Only "site has closed" is in the phrase list — and the strip
        // collapses the tags so the substring check finds it.
        assert_eq!(detect_shutdown(html), Some("site has closed"));
    }

    #[test]
    fn does_not_false_positive_on_normal_news_article() {
        // A real news article shouldn't trip the detector even if it
        // discusses similar topics ("a rider has retired", "a team
        // closed for the season").
        let html = r#"
            <html><body>
            <article><h1>Pogacar wins stage 4</h1>
            <p>The Slovenian rider closed the gap on the leader and took the win
               at Giro d'Italia. The team announced their roster for tomorrow.</p>
            </article>
            </body></html>
        "#;
        assert!(detect_shutdown(html).is_none());
    }

    #[test]
    fn empty_body_returns_none() {
        assert!(detect_shutdown("").is_none());
    }

    #[test]
    fn caps_scan_at_8kb_for_huge_pages() {
        // A 50 KB body with the phrase past the cap shouldn't match.
        // Ensures the 8 KB guard works.
        let mut html = String::with_capacity(50 * 1024);
        html.push_str(&"x".repeat(10 * 1024));
        html.push_str("zakończył działalność");
        // Phrase is past the 8 KB scan window, so the detector skips it.
        assert!(detect_shutdown(&html).is_none());
    }

    #[test]
    fn detects_across_locales() {
        let cases = [
            (
                "<p>This site has closed permanently.</p>",
                "site has closed",
            ),
            ("<p>Este sitio ha cerrado.</p>", "este sitio ha cerrado"),
            ("<p>Ce site a fermé.</p>", "ce site a fermé"),
            (
                "<p>Die Seite wurde geschlossen.</p>",
                "die seite wurde geschlossen",
            ),
            ("<p>サービスを終了しました。</p>", "サービスを終了"),
        ];
        for (html, expected) in cases {
            assert_eq!(detect_shutdown(html), Some(expected), "case: {html}");
        }
    }
}

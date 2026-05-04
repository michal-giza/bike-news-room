//! Race-name matcher — Unicode-aware word-boundary phrase matching.
//!
//! Ported verbatim from the Flutter `WatchedEntity.matches()` regex so
//! client and server agree byte-for-byte on what counts as a match. The
//! cross-platform contract:
//!
//!   1. Lowercase both the article text and the term.
//!   2. Replace every non-letter / non-digit character with a single
//!      space (Unicode-aware, so `č` and `é` survive).
//!   3. Collapse runs of whitespace into single spaces.
//!   4. Wrap both with leading + trailing space sentinels.
//!   5. Term matches iff `' $term '` is a substring of `' $text '` after
//!      that same normalisation. This is "phrase-with-word-boundaries".
//!
//! Why this shape rather than `\b` regex: Unicode word boundaries vary
//! by regex engine, and we explicitly want letters with diacritics to
//! count as word chars. Rolling our own normalise + substring is both
//! cheaper and identical across Dart's RegExp(`\p{L}\p{N}`) and our
//! Rust implementation here.
//!
//! The matcher is pure data — load once, match many. No I/O, no allocs
//! per call beyond the input normalisation buffer.
//!
//! Quality knobs (applied at catalogue load time, not here):
//!   • Aliases shorter than 3 chars are dropped — too noisy.
//!   • Aliases marked "weak" in the catalogue (e.g. "Giro" alone) are
//!     dropped from the auto-tagging matcher but kept available for
//!     user-typed search elsewhere.
//!   • Article discipline must match race discipline OR race discipline
//!     must be `all` — caller enforces, keeps this module pure.

use std::collections::HashSet;

/// Normalise a chunk of text for matching: lowercase, collapse non-word
/// chars to spaces, collapse runs of whitespace, wrap in space sentinels
/// so `contains(" $term ")` is a true word-boundary check.
pub fn normalise(text: &str) -> String {
    let lower = text.to_lowercase();
    // Single-pass char walk: cheaper than regex for this volume.
    let mut buf = String::with_capacity(lower.len() + 2);
    buf.push(' ');
    let mut last_was_space = true;
    for c in lower.chars() {
        // Letters (any script) and digits stay; everything else becomes
        // a single space. `is_alphanumeric` covers Unicode `\p{L}\p{N}`.
        if c.is_alphanumeric() {
            buf.push(c);
            last_was_space = false;
        } else if !last_was_space {
            buf.push(' ');
            last_was_space = true;
        }
    }
    if !last_was_space {
        buf.push(' ');
    }
    buf
}

/// True iff the article-side normalised text contains the term as a
/// whole word/phrase. Both inputs must already be normalised — caller
/// caches the article's normalisation across many term checks.
pub fn term_matches(normalised_article: &str, normalised_term: &str) -> bool {
    if normalised_term.trim().is_empty() {
        return false;
    }
    normalised_article.contains(normalised_term)
}

/// One race in the in-memory matcher. Aliases are pre-normalised so
/// `match_against` is a straight `contains` per term, no per-call work.
#[derive(Debug, Clone)]
pub struct RaceMatchEntry {
    pub race_id: String,
    pub display_name: String,
    pub discipline: String,
    /// Pre-normalised aliases — already passed quality filters at load
    /// time. The "weak" aliases from the JSON are intentionally absent
    /// from this list.
    pub normalised_aliases: Vec<String>,
}

/// In-memory race catalogue used at ingest time. Cheap to clone (it's
/// already ARC-shared in practice) and cheap to iterate — typical use
/// is "for every new article, scan ~36 races, return matching ids".
#[derive(Debug, Clone, Default)]
pub struct RaceCatalogue {
    pub entries: Vec<RaceMatchEntry>,
}

impl RaceCatalogue {
    /// Find every race that matches an article. The discipline filter
    /// is intentionally lenient — `all` race discipline wildcards in,
    /// and articles with no discipline tag (we have plenty) match
    /// regardless. This errs on recall over precision because the
    /// alias-quality rules already strip the noisy short forms.
    pub fn match_article(
        &self,
        title: &str,
        description: Option<&str>,
        article_discipline: Option<&str>,
    ) -> Vec<RaceMatch> {
        let combined = match description {
            Some(d) => format!("{title}  {d}"),
            None => title.to_string(),
        };
        let normalised = normalise(&combined);

        let mut hits = Vec::new();
        let mut seen = HashSet::new();
        for entry in &self.entries {
            if !discipline_compatible(article_discipline, &entry.discipline) {
                continue;
            }
            for alias in &entry.normalised_aliases {
                if term_matches(&normalised, alias) {
                    if seen.insert(entry.race_id.clone()) {
                        hits.push(RaceMatch {
                            race_id: entry.race_id.clone(),
                            matched_alias: alias.trim().to_string(),
                        });
                    }
                    // First alias hit per race is enough; skip remaining
                    // aliases for this race.
                    break;
                }
            }
        }
        hits
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RaceMatch {
    pub race_id: String,
    /// Which alias actually fired — kept in `race_articles.matched_alias`
    /// for debugging "why did this article get linked to that race?"
    pub matched_alias: String,
}

/// Discipline filter: race `all` matches anything; article without a
/// discipline tag matches anything; otherwise must be equal.
fn discipline_compatible(article_disc: Option<&str>, race_disc: &str) -> bool {
    if race_disc == "all" {
        return true;
    }
    match article_disc {
        None | Some("") => true,
        Some(d) => d.eq_ignore_ascii_case(race_disc),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn entry(id: &str, disc: &str, aliases: &[&str]) -> RaceMatchEntry {
        RaceMatchEntry {
            race_id: id.to_string(),
            display_name: id.to_string(),
            discipline: disc.to_string(),
            normalised_aliases: aliases.iter().map(|a| normalise(a)).collect(),
        }
    }

    #[test]
    fn normalise_handles_unicode_diacritics() {
        // č, é, ñ, ü must remain as part of the word — the regex in the
        // Flutter side does the same with \p{L}.
        let n = normalise("Tadej Pogačar wins the Critérium du Dauphiné!");
        assert!(n.contains(" tadej pogačar "));
        assert!(n.contains(" critérium du dauphiné "));
    }

    #[test]
    fn normalise_word_boundaries_via_punctuation() {
        // Punctuation collapses to spaces so "Pogacar's" becomes
        // " pogacar s ".
        let n = normalise("Pogacar's bike");
        assert_eq!(n, " pogacar s bike ");
    }

    #[test]
    fn term_matches_requires_whole_phrase() {
        let article = normalise("Tour de France 2026 stage 5 results");
        assert!(term_matches(&article, &normalise("Tour de France")));
        assert!(term_matches(&article, &normalise("Tour de France 2026")));
        // Substring inside another word doesn't match — "Tour" is not
        // present as a standalone word here? It IS present, and the
        // word-boundary check should hit it. Check:
        assert!(term_matches(&article, &normalise("Tour")));
        // But "France 2026" is also a phrase that matches.
        assert!(term_matches(&article, &normalise("France 2026")));
    }

    #[test]
    fn term_does_not_match_substring_of_a_longer_word() {
        // "Tour" must not match the inside of "Tournee".
        let article = normalise("Tournee de Wallonie kicks off");
        assert!(!term_matches(&article, &normalise("Tour")));
    }

    #[test]
    fn match_article_returns_only_strong_aliases() {
        // Catalogue uses only strong aliases; "Giro" alone is intentionally
        // absent so it doesn't false-match Giro Rosa or Giro di Sicilia.
        let cat = RaceCatalogue {
            entries: vec![
                entry("giro-italia", "road", &["Giro d'Italia", "Il Giro"]),
                entry("lombardia", "road", &["Il Lombardia", "Giro di Lombardia"]),
            ],
        };

        let hits = cat.match_article("Pogacar wins Giro d'Italia stage 4", None, Some("road"));
        assert_eq!(hits.len(), 1);
        assert_eq!(hits[0].race_id, "giro-italia");

        // Article that only says "Giro" — neither catalogue entry
        // includes the bare word "Giro" as an alias, so no match.
        let hits = cat.match_article("Giro 2026 favourites announced", None, Some("road"));
        assert!(hits.is_empty());

        // Article naming Lombardia explicitly — matches Lombardia, not
        // Giro d'Italia, even though Lombardia's alias contains "Giro".
        let hits = cat.match_article(
            "Pogacar takes Il Lombardia for the fourth time",
            None,
            Some("road"),
        );
        assert_eq!(hits.len(), 1);
        assert_eq!(hits[0].race_id, "lombardia");
    }

    #[test]
    fn match_respects_discipline_filter() {
        let cat = RaceCatalogue {
            entries: vec![
                entry("uci-xco-wc", "mtb", &["XCO World Cup"]),
                entry("uci-track-wc", "track", &["Track Champions League"]),
            ],
        };
        // Article tagged road shouldn't match an MTB-only race.
        let hits = cat.match_article("XCO World Cup recap", None, Some("road"));
        assert!(hits.is_empty());
        // Article without a discipline tag matches any race (we'd rather
        // tag than miss it; retention exemption is the cost of a stray
        // tag and that cost is small).
        let hits = cat.match_article("XCO World Cup recap", None, None);
        assert_eq!(hits.len(), 1);
    }

    #[test]
    fn description_contributes_to_match() {
        // Title-only matches and description-only matches both fire.
        let cat = RaceCatalogue {
            entries: vec![entry("paris-roubaix", "road", &["Paris-Roubaix"])],
        };
        let hits = cat.match_article(
            "Hell of the North preview",
            Some("This year's Paris-Roubaix promises chaos"),
            Some("road"),
        );
        assert_eq!(hits.len(), 1);
        assert_eq!(hits[0].race_id, "paris-roubaix");
    }

    #[test]
    fn each_race_matches_at_most_once_per_article() {
        // Even when multiple aliases would match, we record one hit.
        let cat = RaceCatalogue {
            entries: vec![entry(
                "tour-de-france",
                "road",
                &["Tour de France", "Le Tour de France"],
            )],
        };
        let hits = cat.match_article(
            "Tour de France and Le Tour de France same event",
            None,
            Some("road"),
        );
        assert_eq!(hits.len(), 1);
    }
}

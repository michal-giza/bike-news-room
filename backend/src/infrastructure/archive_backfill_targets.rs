//! Per-race per-publisher URL patterns used to drive the Internet
//! Archive backfill. Each entry says: "for this race, look at these
//! publisher tag/category URLs in CDX search results when scoping
//! a backfill run."
//!
//! Patterns include the literal token `{year}` which the backfill use
//! case substitutes with each requested year. CDX wildcards (`*`) are
//! left in place — the IA CDX endpoint accepts them in the `url` query
//! string and matches all snapshots whose URL begins with the
//! pattern's prefix.
//!
//! Adding a new race here is the cheapest way to grow archive
//! coverage; the matcher already knows about the race via
//! `data/cycling_races.json`, this just teaches the backfill where to
//! find old coverage. Keep race_slugs in lockstep with that catalogue.

/// One race + every publisher we know how to archive-search for it.
pub struct ArchiveTarget {
    pub race_slug: &'static str,
    pub patterns: &'static [PublisherPattern],
}

pub struct PublisherPattern {
    /// Used for User-Agent-friendly logging and for honouring
    /// per-publisher robots.txt at backfill time.
    pub publisher_root: &'static str,
    /// CDX query URL pattern. `{year}` is substituted at run time.
    pub url_pattern: &'static str,
}

/// Static catalogue. ~5 publishers × 15 races. Easy to grow.
pub const ARCHIVE_TARGETS: &[ArchiveTarget] = &[
    // ── Grand Tours ─────────────────────────────────────────────────
    ArchiveTarget {
        race_slug: "tour-de-france",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/tour-de-france-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/tour-de-france/{year}/*",
            },
            PublisherPattern {
                publisher_root: "velo.outsideonline.com",
                url_pattern: "velo.outsideonline.com/news/tour-de-france-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/tour-de-france-{year}/*",
            },
            PublisherPattern {
                publisher_root: "escapecollective.com",
                url_pattern: "escapecollective.com/category/racing/tour-de-france-{year}/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "giro-italia",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/giro-d-italia-{year}/*",
            },
            PublisherPattern {
                publisher_root: "velo.outsideonline.com",
                url_pattern: "velo.outsideonline.com/news/giro-d-italia-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/giro-d-italia-{year}/*",
            },
            PublisherPattern {
                publisher_root: "escapecollective.com",
                url_pattern: "escapecollective.com/category/racing/giro-{year}/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "vuelta-espana",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/vuelta-a-espana-{year}/*",
            },
            PublisherPattern {
                publisher_root: "velo.outsideonline.com",
                url_pattern: "velo.outsideonline.com/news/vuelta-a-espana-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/vuelta-a-espana-{year}/*",
            },
        ],
    },
    // ── Monuments — year-agnostic patterns since editions are 1-day ─
    // (we still pass {year} so CDX bounds the snapshot range)
    ArchiveTarget {
        race_slug: "milan-sanremo",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/milan-san-remo/{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/milan-san-remo/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "paris-roubaix",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/paris-roubaix/{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/paris-roubaix/*",
            },
            PublisherPattern {
                publisher_root: "escapecollective.com",
                url_pattern: "escapecollective.com/category/racing/paris-roubaix/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "ronde",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/tour-of-flanders/{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/tour-of-flanders/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "lbl",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/liege-bastogne-liege/{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/liege-bastogne-liege/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "lombardia",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/il-lombardia/{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/il-lombardia/*",
            },
        ],
    },
    // ── Worlds + Olympics ──────────────────────────────────────────
    ArchiveTarget {
        race_slug: "uci-worlds-road",
        patterns: &[
            PublisherPattern {
                publisher_root: "cyclingnews.com",
                url_pattern: "cyclingnews.com/road-world-championships-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/road-world-championships-{year}/*",
            },
        ],
    },
    // ── MTB headliners ─────────────────────────────────────────────
    ArchiveTarget {
        race_slug: "redbull-rampage",
        patterns: &[
            PublisherPattern {
                publisher_root: "pinkbike.com",
                url_pattern: "pinkbike.com/news/red-bull-rampage-{year}/*",
            },
            PublisherPattern {
                publisher_root: "vitalmtb.com",
                url_pattern: "vitalmtb.com/news/red-bull-rampage-{year}/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "redbull-hardline",
        patterns: &[PublisherPattern {
            publisher_root: "pinkbike.com",
            url_pattern: "pinkbike.com/news/red-bull-hardline-{year}/*",
        }],
    },
    ArchiveTarget {
        race_slug: "uci-dh-wc",
        patterns: &[
            PublisherPattern {
                publisher_root: "pinkbike.com",
                url_pattern: "pinkbike.com/news/dh-world-cup-{year}/*",
            },
            PublisherPattern {
                publisher_root: "vitalmtb.com",
                url_pattern: "vitalmtb.com/news/uci-dh-world-cup-{year}/*",
            },
        ],
    },
    ArchiveTarget {
        race_slug: "uci-xco-wc",
        patterns: &[PublisherPattern {
            publisher_root: "pinkbike.com",
            url_pattern: "pinkbike.com/news/xco-world-cup-{year}/*",
        }],
    },
    // ── Gravel ─────────────────────────────────────────────────────
    ArchiveTarget {
        race_slug: "unbound",
        patterns: &[
            PublisherPattern {
                publisher_root: "velo.outsideonline.com",
                url_pattern: "velo.outsideonline.com/news/unbound-gravel-{year}/*",
            },
            PublisherPattern {
                publisher_root: "cyclingweekly.com",
                url_pattern: "cyclingweekly.com/tag/unbound-gravel/*",
            },
        ],
    },
];

/// Find archive patterns for a race slug. Returns an empty slice when
/// the race isn't covered yet — caller treats that as "skip, log, move
/// on". Adding new races here is the entire growth path for backfill.
pub fn patterns_for(race_slug: &str) -> &'static [PublisherPattern] {
    for t in ARCHIVE_TARGETS {
        if t.race_slug == race_slug {
            return t.patterns;
        }
    }
    &[]
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_target_uses_year_placeholder_or_static_tag() {
        // Either the URL contains `{year}` (year-substituted) or no
        // year reference at all (year-agnostic tag URL). Anything else
        // is a typo.
        for target in ARCHIVE_TARGETS {
            for pattern in target.patterns {
                let has_placeholder = pattern.url_pattern.contains("{year}");
                let has_digit_year = pattern
                    .url_pattern
                    .split(|c: char| !c.is_ascii_digit())
                    .any(|s| s.len() == 4 && s.starts_with('2'));
                assert!(
                    has_placeholder || !has_digit_year,
                    "race {} pattern '{}' has a hardcoded year — use {{year}} instead",
                    target.race_slug,
                    pattern.url_pattern,
                );
            }
        }
    }

    #[test]
    fn every_pattern_belongs_to_its_publisher_root() {
        for target in ARCHIVE_TARGETS {
            for pattern in target.patterns {
                assert!(
                    pattern.url_pattern.starts_with(pattern.publisher_root),
                    "race {} pattern '{}' does not begin with root '{}'",
                    target.race_slug,
                    pattern.url_pattern,
                    pattern.publisher_root,
                );
            }
        }
    }

    #[test]
    fn patterns_for_unknown_race_is_empty() {
        assert!(patterns_for("nonexistent-race").is_empty());
    }

    #[test]
    fn patterns_for_known_race_returns_at_least_one() {
        assert!(!patterns_for("tour-de-france").is_empty());
        assert!(!patterns_for("giro-italia").is_empty());
    }
}

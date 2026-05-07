//! Trending-topics extractor.
//!
//! Pure-SQL+Rust pipeline — no LLM, no external API:
//! 1. Pull every non-duplicate title from the last `recent_window` (default
//!    24h) and from the prior `baseline_window` (default 7d ending at the
//!    start of recent).
//! 2. Tokenise + n-gram (1-3 grams) each side, skipping stopwords and very
//!    short fragments.
//! 3. Score each term by TF-IDF-ish *lift*: `recent_freq /
//!    (baseline_freq + smoothing)`. Smoothing avoids divide-by-zero +
//!    keeps brand-new terms from dominating just because their baseline
//!    count is zero.
//! 4. Return the top N terms with at least `min_recent_count` mentions.
//!
//! This is deliberately a heuristic — at our article volume (~300/day)
//! we don't have enough text for an honest topic model, but n-gram lift
//! catches the obvious "Pogačar abandons" or "Tour de France 2026"
//! spikes a user expects to see. If the catalogue grows past 5k/day we
//! revisit with a real bag-of-words model.

use std::collections::HashMap;
use std::sync::Arc;

use chrono::{Duration, Utc};

use crate::domain::errors::DomainResult;
use crate::domain::ports::ArticleRepository;

#[derive(Debug, Clone)]
pub struct TrendingTerm {
    pub term: String,
    pub recent_count: u32,
    pub baseline_count: u32,
    /// `recent / (baseline + smoothing)` — strictly increasing in lift.
    /// Exposed so the frontend can show how "hot" the term is if needed.
    pub score: f64,
}

#[derive(Clone)]
pub struct TrendingUseCase {
    articles: Arc<dyn ArticleRepository>,
    /// Window for "what's hot right now". 24h by default.
    pub recent_window: Duration,
    /// Window for the baseline freq. 7d by default — long enough to
    /// dampen day-of-week effects (cycling news is bursty around
    /// weekends).
    pub baseline_window: Duration,
    /// Hide terms that haven't crossed this many recent mentions —
    /// avoids one-shot anomalies from publisher typos / weird headlines.
    pub min_recent_count: u32,
    /// Smoothing constant added to the baseline denominator. Bigger →
    /// brand-new terms harder to surface (more conservative).
    pub smoothing: f64,
}

impl TrendingUseCase {
    pub fn new(articles: Arc<dyn ArticleRepository>) -> Self {
        Self {
            articles,
            recent_window: Duration::hours(24),
            baseline_window: Duration::days(7),
            min_recent_count: 2,
            smoothing: 1.0,
        }
    }

    /// Compute trending terms. Returns up to `top_n` highest-lift terms.
    pub async fn execute(&self, top_n: usize) -> DomainResult<Vec<TrendingTerm>> {
        let now = Utc::now();
        let recent_start = now - self.recent_window;
        let baseline_start = recent_start - self.baseline_window;

        let recent = self
            .articles
            .titles_in_window(&recent_start.to_rfc3339(), &now.to_rfc3339())
            .await?;
        let baseline = self
            .articles
            .titles_in_window(&baseline_start.to_rfc3339(), &recent_start.to_rfc3339())
            .await?;

        Ok(score_terms(
            &recent,
            &baseline,
            top_n,
            self.min_recent_count,
            self.smoothing,
        ))
    }
}

/// Pure scoring function — exposed for unit tests so we don't need a
/// running database to assert on the n-gram pipeline.
pub fn score_terms(
    recent: &[String],
    baseline: &[String],
    top_n: usize,
    min_recent_count: u32,
    smoothing: f64,
) -> Vec<TrendingTerm> {
    let recent_counts = ngram_counts(recent);
    let baseline_counts = ngram_counts(baseline);

    let mut scored: Vec<TrendingTerm> = recent_counts
        .into_iter()
        .filter(|(_, c)| *c >= min_recent_count)
        .map(|(term, recent_count)| {
            let baseline_count = baseline_counts.get(&term).copied().unwrap_or(0);
            let score = recent_count as f64 / (baseline_count as f64 + smoothing);
            TrendingTerm {
                term,
                recent_count,
                baseline_count,
                score,
            }
        })
        .collect();

    scored.sort_by(|a, b| {
        b.score
            .partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });
    scored.truncate(top_n);
    scored
}

/// Tokenise + count n-grams (1, 2, 3) across all titles. Lowercased,
/// stopword-filtered, min-length 3. Word boundaries are Unicode-aware
/// so accented rider names ("Pogačar") survive intact.
fn ngram_counts(titles: &[String]) -> HashMap<String, u32> {
    let mut counts: HashMap<String, u32> = HashMap::new();
    for title in titles {
        let tokens = tokenise(title);
        for n in 1..=3 {
            for window in tokens.windows(n) {
                let term = window.join(" ");
                if !is_useful_term(&term) {
                    continue;
                }
                *counts.entry(term).or_insert(0) += 1;
            }
        }
    }
    counts
}

fn tokenise(input: &str) -> Vec<String> {
    input
        .split(|c: char| !c.is_alphanumeric())
        .filter(|t| !t.is_empty())
        .map(|t| t.to_lowercase())
        .filter(|t| t.len() >= 3 && !STOPWORDS.contains(&t.as_str()))
        .collect()
}

fn is_useful_term(term: &str) -> bool {
    // Drop pure-number terms ("2026", "21") and over-long terms (>40
    // chars suggests a tokeniser mishap rather than a real topic).
    if term.len() > 40 {
        return false;
    }
    if term.chars().all(|c| c.is_ascii_digit()) {
        return false;
    }
    true
}

/// Cycling-news-aware stopword list. We include both English filler
/// ("the", "and") and high-frequency cycling boilerplate ("stage",
/// "race", "rider", "team") so the trending output surfaces what makes
/// a story unique rather than the generic vocabulary every article
/// shares. Names like "Pogačar" stay because they're not in here.
const STOPWORDS: &[&str] = &[
    // English filler
    "the",
    "and",
    "for",
    "from",
    "with",
    "this",
    "that",
    "into",
    "have",
    "has",
    "had",
    "but",
    "not",
    "are",
    "was",
    "were",
    "will",
    "his",
    "her",
    "they",
    "their",
    "them",
    "you",
    "your",
    "our",
    "out",
    "about",
    "after",
    "before",
    "more",
    "most",
    "very",
    "than",
    "then",
    "there",
    "here",
    "what",
    "when",
    "where",
    "why",
    "how",
    "who",
    "all",
    "any",
    "some",
    // Cycling boilerplate that's in basically every headline
    "race",
    "stage",
    "rider",
    "team",
    "tour",
    "win",
    "wins",
    "won",
    "ride",
    "ridden",
    "riding",
    "racing",
    "raced",
    // Generic news boilerplate
    "says",
    "said",
    "video",
    "watch",
    "live",
    "news",
    "today",
    "yesterday",
    "weekend",
    "results",
    "report",
    "preview",
    "recap",
];

#[cfg(test)]
mod tests {
    use super::*;

    fn make_titles(items: &[&str]) -> Vec<String> {
        items.iter().map(|s| s.to_string()).collect()
    }

    #[test]
    fn surfaces_a_term_that_spikes_in_recent_window() {
        let recent = make_titles(&[
            "Pogačar attacks on Mont Ventoux",
            "Pogačar grabs another Tour de France win",
            "Pogačar leaves Tour de France to focus on Worlds",
            "Pogačar on top form heading into Vuelta",
        ]);
        let baseline = make_titles(&[
            "Vingegaard returns from injury",
            "Roglič crashes out of Critérium",
        ]);
        let trends = score_terms(&recent, &baseline, 5, 2, 1.0);
        let terms: Vec<&str> = trends.iter().map(|t| t.term.as_str()).collect();
        assert!(
            terms.contains(&"pogačar"),
            "expected 'pogačar' in trending; got {terms:?}"
        );
    }

    #[test]
    fn skips_terms_below_min_recent_count() {
        let recent = make_titles(&["Pogačar wins again", "Vingegaard returns", "Roglič crashes"]);
        let trends = score_terms(&recent, &[], 10, 2, 1.0);
        // Each unique noun appears once → all under min_recent_count of 2.
        assert!(
            trends.is_empty(),
            "all single-mentions should be filtered out; got {trends:?}",
        );
    }

    #[test]
    fn drops_pure_number_terms() {
        let recent = make_titles(&[
            "Stage 5 of Tour 2026",
            "Stage 6 of Tour 2026",
            "Stage 7 of Tour 2026",
        ]);
        let trends = score_terms(&recent, &[], 10, 2, 1.0);
        let terms: Vec<&str> = trends.iter().map(|t| t.term.as_str()).collect();
        assert!(
            !terms.iter().any(|t| t.chars().all(|c| c.is_ascii_digit())),
            "pure-number terms must be filtered; got {terms:?}",
        );
    }

    #[test]
    fn stopwords_filtered() {
        let recent = make_titles(&[
            "The race had a great stage today",
            "The race had a great stage today",
            "The race had a great stage today",
        ]);
        let trends = score_terms(&recent, &[], 10, 2, 1.0);
        let terms: Vec<&str> = trends.iter().map(|t| t.term.as_str()).collect();
        assert!(
            !terms.contains(&"the"),
            "stopword 'the' must be filtered; got {terms:?}",
        );
        assert!(
            !terms.contains(&"race"),
            "cycling-boilerplate 'race' must be filtered; got {terms:?}",
        );
    }

    #[test]
    fn computes_bigrams_and_trigrams() {
        let recent = make_titles(&[
            "Tadej Pogačar abandons Vuelta",
            "Tadej Pogačar abandons race after illness",
            "Tadej Pogačar abandons stage in tears",
        ]);
        let trends = score_terms(&recent, &[], 10, 2, 1.0);
        let terms: Vec<&str> = trends.iter().map(|t| t.term.as_str()).collect();
        // Order isn't guaranteed but bigrams + trigrams should appear.
        assert!(
            terms.iter().any(|t| t.contains(' ')),
            "expected at least one multi-word term; got {terms:?}",
        );
    }

    #[test]
    fn higher_lift_terms_score_higher() {
        // 3 recent / 0 baseline (lift = 3/1 = 3)
        // vs. 5 recent / 4 baseline (lift = 5/5 = 1)
        let recent = make_titles(&[
            "Pogačar attacks",
            "Pogačar attacks",
            "Pogačar attacks",
            "evenepoel wins",
            "evenepoel wins",
            "evenepoel wins",
            "evenepoel wins",
            "evenepoel wins",
        ]);
        let baseline = make_titles(&[
            "evenepoel wins",
            "evenepoel wins",
            "evenepoel wins",
            "evenepoel wins",
        ]);
        let trends = score_terms(&recent, &baseline, 10, 2, 1.0);
        let pogačar_pos = trends.iter().position(|t| t.term == "pogačar");
        let evenepoel_pos = trends.iter().position(|t| t.term == "evenepoel");
        match (pogačar_pos, evenepoel_pos) {
            (Some(p), Some(e)) => assert!(
                p < e,
                "pogačar (lift 3) should rank above evenepoel (lift 1); \
                 got pos={p} vs {e}, full={trends:?}"
            ),
            other => panic!("missing terms: {other:?}; full={trends:?}"),
        }
    }
}

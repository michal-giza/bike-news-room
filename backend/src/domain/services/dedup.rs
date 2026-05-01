use sha2::{Digest, Sha256};
use strsim::normalized_levenshtein;

pub fn compute_title_hash(title: &str, domain: &str, date: &str) -> String {
    let normalized = title.to_lowercase().trim().to_string();
    let date_prefix = date.get(..10).unwrap_or(date);
    let input = format!("{normalized}|{domain}|{date_prefix}");
    let mut hasher = Sha256::new();
    hasher.update(input.as_bytes());
    hex::encode(hasher.finalize())
}

pub fn is_fuzzy_duplicate(new_title: &str, existing_titles: &[(i64, String)]) -> Option<i64> {
    let normalized_new = new_title.to_lowercase();

    for (id, existing) in existing_titles {
        let normalized_existing = existing.to_lowercase();
        let similarity = normalized_levenshtein(&normalized_new, &normalized_existing);
        if similarity > 0.85 {
            return Some(*id);
        }
    }

    None
}

pub fn extract_domain(url: &str) -> String {
    url::Url::parse(url)
        .ok()
        .and_then(|u| u.host_str().map(|h| h.to_string()))
        .unwrap_or_else(|| "unknown".to_string())
}

pub fn normalize_url(raw_url: &str) -> String {
    let Ok(mut parsed) = url::Url::parse(raw_url) else {
        return raw_url.to_string();
    };

    let clean_pairs: Vec<(String, String)> = parsed
        .query_pairs()
        .filter(|(key, _)| {
            !key.starts_with("utm_")
                && key.as_ref() != "ref"
                && key.as_ref() != "source"
                && key.as_ref() != "fbclid"
                && key.as_ref() != "gclid"
        })
        .map(|(k, v)| (k.to_string(), v.to_string()))
        .collect();

    if clean_pairs.is_empty() {
        parsed.set_query(None);
    } else {
        let qs: String = clean_pairs
            .iter()
            .map(|(k, v)| format!("{k}={v}"))
            .collect::<Vec<_>>()
            .join("&");
        parsed.set_query(Some(&qs));
    }

    let result = parsed.to_string();
    result.trim_end_matches('/').to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_is_stable_for_same_inputs() {
        let h1 = compute_title_hash("Tour de France stage 5", "cyclingnews.com", "2026-05-01");
        let h2 = compute_title_hash("Tour de France stage 5", "cyclingnews.com", "2026-05-01");
        assert_eq!(h1, h2);
    }

    #[test]
    fn hash_differs_for_different_titles() {
        let h1 = compute_title_hash("Title A", "example.com", "2026-05-01");
        let h2 = compute_title_hash("Title B", "example.com", "2026-05-01");
        assert_ne!(h1, h2);
    }

    #[test]
    fn hash_differs_for_different_domains() {
        let h1 = compute_title_hash("Same title", "a.com", "2026-05-01");
        let h2 = compute_title_hash("Same title", "b.com", "2026-05-01");
        assert_ne!(h1, h2);
    }

    #[test]
    fn hash_is_case_insensitive_for_titles() {
        let h1 = compute_title_hash("RACE Results", "ex.com", "2026-05-01");
        let h2 = compute_title_hash("race results", "ex.com", "2026-05-01");
        assert_eq!(h1, h2);
    }

    #[test]
    fn hash_uses_only_date_part() {
        let h1 = compute_title_hash("Title", "ex.com", "2026-05-01T10:30:00Z");
        let h2 = compute_title_hash("Title", "ex.com", "2026-05-01T22:15:00Z");
        assert_eq!(h1, h2);
    }

    #[test]
    fn fuzzy_dup_finds_similar_titles() {
        let existing = vec![
            (1, "Pogacar wins stage 5 of Tour de France".to_string()),
            (2, "Cycling tech: new aero helmet revealed".to_string()),
        ];
        let result = is_fuzzy_duplicate("Pogacar wins stage 5 of the Tour de France", &existing);
        assert_eq!(result, Some(1));
    }

    #[test]
    fn fuzzy_dup_returns_none_for_distinct_titles() {
        let existing = vec![(1, "Pogacar wins stage 5".to_string())];
        let result = is_fuzzy_duplicate("New gravel bike review", &existing);
        assert_eq!(result, None);
    }

    #[test]
    fn extract_domain_strips_subdomain_correctly() {
        assert_eq!(
            extract_domain("https://www.cyclingnews.com/foo"),
            "www.cyclingnews.com"
        );
        assert_eq!(
            extract_domain("https://pinkbike.com/news/123"),
            "pinkbike.com"
        );
    }

    #[test]
    fn extract_domain_handles_invalid_url() {
        assert_eq!(extract_domain("not a url"), "unknown");
    }

    #[test]
    fn normalize_url_strips_utm_params() {
        let raw = "https://example.com/article?utm_source=twitter&utm_medium=social&id=42";
        let result = normalize_url(raw);
        assert!(!result.contains("utm_"));
        assert!(result.contains("id=42"));
    }

    #[test]
    fn normalize_url_strips_tracking_params() {
        let raw = "https://example.com/article?fbclid=abc&gclid=xyz&ref=feed";
        let result = normalize_url(raw);
        assert!(!result.contains("fbclid"));
        assert!(!result.contains("gclid"));
        assert!(!result.contains("ref="));
    }

    #[test]
    fn normalize_url_removes_trailing_slash() {
        assert_eq!(
            normalize_url("https://example.com/article/"),
            "https://example.com/article"
        );
    }

    #[test]
    fn normalize_url_handles_no_query_params() {
        assert_eq!(
            normalize_url("https://example.com/article"),
            "https://example.com/article"
        );
    }

    #[test]
    fn normalize_url_returns_invalid_unchanged() {
        assert_eq!(normalize_url("not a url"), "not a url");
    }
}

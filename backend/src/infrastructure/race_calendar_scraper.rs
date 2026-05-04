//! Scrapes race calendar from ProCyclingStats.
//!
//! PCS publishes UCI calendar data per discipline at predictable URLs:
//!   - Road  : https://www.procyclingstats.com/races.php
//!   - MTB   : https://www.procyclingstats.com/mtb/races.php
//!
//! The HTML structure is a `<table class="basic">` with rows of (date, name, country, category, …).
//!
//! This crate-internal helper produces [`RaceDraft`]s that the application
//! layer hands to the [`RaceRepository`].

use std::time::Duration;

use scraper::{Html, Selector};
use tracing::{info, warn};

use crate::domain::entities::RaceDraft;
use crate::domain::errors::{DomainError, DomainResult};

/// Source of a race calendar listing — paired with the discipline the rows belong to.
pub struct CalendarSource {
    pub url: &'static str,
    pub discipline: &'static str,
}

/// Default sources we crawl on a 24h cron. Easy to extend.
pub fn default_sources() -> Vec<CalendarSource> {
    vec![
        CalendarSource {
            url: "https://www.procyclingstats.com/races.php",
            discipline: "road",
        },
        CalendarSource {
            url: "https://www.procyclingstats.com/mtb/races.php",
            discipline: "mtb",
        },
    ]
}

pub async fn fetch_calendar(source: &CalendarSource) -> DomainResult<Vec<RaceDraft>> {
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(20))
        .user_agent("Mozilla/5.0 (compatible; BikeNewsRoom/0.1)")
        .build()
        .map_err(|e| DomainError::Crawler(e.to_string()))?;

    let html = client
        .get(source.url)
        .send()
        .await
        .map_err(|e| DomainError::Crawler(format!("fetch {}: {e}", source.url)))?
        .text()
        .await
        .map_err(|e| DomainError::Crawler(format!("body {}: {e}", source.url)))?;

    Ok(extract_races(&html, source.discipline))
}

/// Parse a PCS calendar HTML page into draft races.
/// Public so unit tests can exercise it with fixtures.
pub fn extract_races(html: &str, discipline: &str) -> Vec<RaceDraft> {
    let document = Html::parse_document(html);

    // PCS wraps the calendar in a <table class="basic">. Each <tr> row has
    // ordered cells: date · race name · country flag · category · sometimes more.
    let row_sel = match Selector::parse("table.basic tbody tr") {
        Ok(s) => s,
        Err(_) => return vec![],
    };
    let cell_sel = Selector::parse("td").unwrap();
    let link_sel = Selector::parse("a").unwrap();
    let flag_sel = Selector::parse("span.flag, img.flag").unwrap();

    let current_year = chrono::Utc::now().format("%Y").to_string();
    let mut drafts = Vec::new();

    for row in document.select(&row_sel) {
        let cells: Vec<_> = row.select(&cell_sel).collect();
        if cells.len() < 2 {
            continue;
        }

        let date_text = cells[0].text().collect::<String>().trim().to_string();
        let start_date = parse_pcs_date(&date_text, &current_year);
        if start_date.is_none() {
            continue;
        }

        let Some(name_cell) = cells.get(1) else {
            continue;
        };
        let name = name_cell
            .select(&link_sel)
            .next()
            .map(|el| el.text().collect::<String>().trim().to_string())
            .unwrap_or_else(|| name_cell.text().collect::<String>().trim().to_string());
        if name.is_empty() {
            continue;
        }

        let url = name_cell
            .select(&link_sel)
            .next()
            .and_then(|el| el.value().attr("href"))
            .map(|h| {
                if h.starts_with("http") {
                    h.to_string()
                } else {
                    format!(
                        "https://www.procyclingstats.com/{}",
                        h.trim_start_matches('/')
                    )
                }
            });

        // Country may be a flag class like "flag pl" — pull the 2-letter code.
        let country = row.select(&flag_sel).next().and_then(|el| {
            el.value().attr("class").and_then(|cls| {
                cls.split_whitespace()
                    .find(|w| w.len() == 2 && w.chars().all(|c| c.is_ascii_alphabetic()))
                    .map(|w| w.to_uppercase())
            })
        });

        let category = cells
            .get(2)
            .map(|c| c.text().collect::<String>().trim().to_string())
            .filter(|s| !s.is_empty());

        drafts.push(RaceDraft {
            name,
            start_date: start_date.unwrap(),
            end_date: None,
            country,
            category,
            discipline: discipline.to_string(),
            url,
        });
    }

    info!("calendar {discipline}: parsed {} races", drafts.len());
    drafts
}

/// PCS dates are formatted as `dd.mm` for the current year — convert to ISO.
/// Falls back to `None` for anything we can't parse.
fn parse_pcs_date(raw: &str, year: &str) -> Option<String> {
    let cleaned = raw.replace(' ', "");
    let parts: Vec<&str> = cleaned.split('.').collect();
    if parts.len() != 2 {
        // Some rows are blank or "—" — silently skip.
        if !cleaned.is_empty() {
            warn!("unparseable PCS date: '{raw}'");
        }
        return None;
    }
    let day = parts[0].parse::<u32>().ok()?;
    let month = parts[1].parse::<u32>().ok()?;
    if !(1..=12).contains(&month) || !(1..=31).contains(&day) {
        return None;
    }
    Some(format!("{year}-{month:02}-{day:02}"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_pcs_date_handles_dot_format() {
        assert_eq!(parse_pcs_date("21.07", "2026"), Some("2026-07-21".into()));
        assert_eq!(parse_pcs_date("01.01", "2026"), Some("2026-01-01".into()));
    }

    #[test]
    fn parse_pcs_date_rejects_garbage() {
        assert_eq!(parse_pcs_date("xx", "2026"), None);
        assert_eq!(parse_pcs_date("99.99", "2026"), None);
        assert_eq!(parse_pcs_date("", "2026"), None);
    }

    #[test]
    fn extract_races_skips_rows_without_date() {
        let html = r#"
            <html><body>
              <table class="basic"><tbody>
                <tr><td>—</td><td><a href="/race/abc">Bad row</a></td><td>2.UWT</td></tr>
                <tr><td>21.07</td><td><a href="/race/tdf">Tour de France</a></td><td>2.UWT</td></tr>
              </tbody></table>
            </body></html>
        "#;
        let races = extract_races(html, "road");
        assert_eq!(races.len(), 1);
        assert_eq!(races[0].name, "Tour de France");
        assert_eq!(races[0].discipline, "road");
        assert!(races[0].start_date.ends_with("-07-21"));
    }

    #[test]
    fn extract_races_returns_empty_for_no_table() {
        assert!(extract_races("<html><body><p>nothing</p></body></html>", "road").is_empty());
    }
}

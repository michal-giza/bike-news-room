//! HTML crawler — scrapes websites that don't expose RSS using configured CSS selectors.

use std::time::Duration;

use async_trait::async_trait;
use chrono::Utc;
use scraper::{Html, Selector};

use crate::domain::errors::{DomainError, DomainResult};
use crate::domain::ports::{CrawlTarget, ScrapedItem, WebCrawler};

#[derive(Clone)]
pub struct ScraperHtmlCrawler {
    client: reqwest::Client,
}

impl ScraperHtmlCrawler {
    pub fn new() -> Self {
        let client = reqwest::Client::builder()
            .timeout(Duration::from_secs(20))
            .user_agent("Mozilla/5.0 (compatible; BikeNewsRoom/0.1)")
            .build()
            .expect("build reqwest client");
        Self { client }
    }
}

impl Default for ScraperHtmlCrawler {
    fn default() -> Self {
        Self::new()
    }
}

/// Extract items from arbitrary HTML using widely-used default selectors.
/// Used by the user-source probe — for unknown sites we don't know the
/// correct selectors yet, so we try the patterns most CMSes (WordPress,
/// Ghost, custom news themes) use.
pub fn probe_default(html: &str, base_url: &str) -> Vec<ScrapedItem> {
    let target = CrawlTarget {
        name: "probe".into(),
        url: base_url.to_string(),
        region: "world".into(),
        discipline: "all".into(),
        language: "en".into(),
        selectors: crate::domain::ports::CrawlSelectors {
            article_list: "article, .post, .post-card, .news-item, .news-tile, .card, .entry"
                .into(),
            title: "h2 a, h3 a, .post-title a, .entry-title a, .card-title a, a.title".into(),
            link: "h2 a, h3 a, .post-title a, .entry-title a, .card-title a, a.title".into(),
            description: Some(".excerpt, .post-excerpt, .summary, .entry-summary, p".into()),
            image: Some("img".into()),
            date: Some("time, .date, .post-date, .entry-date, [datetime]".into()),
            relative_links: true,
        },
    };
    extract_items(html, &target)
}

/// Extract items from HTML synchronously. Separated from the async fetch so
/// `scraper`'s non-`Send` types never cross an await point.
fn extract_items(html: &str, target: &CrawlTarget) -> Vec<ScrapedItem> {
    let document = Html::parse_document(html);
    let Ok(base_url) = url::Url::parse(&target.url) else {
        return vec![];
    };
    let Ok(article_sel) = Selector::parse(&target.selectors.article_list) else {
        return vec![];
    };

    let title_sel = Selector::parse(&target.selectors.title).ok();
    let link_sel = Selector::parse(&target.selectors.link).ok();
    let desc_sel = target
        .selectors
        .description
        .as_ref()
        .and_then(|s| Selector::parse(s).ok());
    let img_sel = target
        .selectors
        .image
        .as_ref()
        .and_then(|s| Selector::parse(s).ok());
    let date_sel = target
        .selectors
        .date
        .as_ref()
        .and_then(|s| Selector::parse(s).ok());

    let mut items = Vec::new();

    for article_el in document.select(&article_sel) {
        let title = title_sel
            .as_ref()
            .and_then(|sel| article_el.select(sel).next())
            .map(|el| el.text().collect::<String>().trim().to_string())
            .unwrap_or_default();
        if title.len() < 5 {
            continue;
        }

        let raw_link = link_sel
            .as_ref()
            .and_then(|sel| article_el.select(sel).next())
            .and_then(|el| el.value().attr("href"))
            .unwrap_or_default();
        if raw_link.is_empty() {
            continue;
        }

        let link = if target.selectors.relative_links || raw_link.starts_with('/') {
            base_url
                .join(raw_link)
                .map(|u| u.to_string())
                .unwrap_or_else(|_| raw_link.to_string())
        } else {
            raw_link.to_string()
        };

        let description = desc_sel
            .as_ref()
            .and_then(|sel| article_el.select(sel).next())
            .map(|el| el.text().collect::<String>().trim().to_string());

        let image_url = img_sel
            .as_ref()
            .and_then(|sel| article_el.select(sel).next())
            .and_then(|el| {
                el.value()
                    .attr("src")
                    .or_else(|| el.value().attr("data-src"))
            })
            .map(|src| {
                if src.starts_with("http") {
                    src.to_string()
                } else {
                    base_url
                        .join(src)
                        .map(|u| u.to_string())
                        .unwrap_or_default()
                }
            });

        let published_at = date_sel
            .as_ref()
            .and_then(|sel| article_el.select(sel).next())
            .and_then(|el| {
                el.value()
                    .attr("datetime")
                    .map(|s| s.to_string())
                    .or_else(|| Some(el.text().collect::<String>().trim().to_string()))
            })
            .and_then(|d| {
                chrono::DateTime::parse_from_rfc3339(&d)
                    .ok()
                    .map(|dt| dt.to_rfc3339())
                    .or_else(|| {
                        chrono::NaiveDate::parse_from_str(&d, "%Y-%m-%d")
                            .ok()
                            .and_then(|nd| nd.and_hms_opt(0, 0, 0))
                            .map(|ndt| ndt.and_utc().to_rfc3339())
                    })
            })
            .unwrap_or_else(|| Utc::now().to_rfc3339());

        items.push(ScrapedItem {
            title,
            link,
            description,
            image_url,
            published_at,
        });
    }

    items
}

#[async_trait]
impl WebCrawler for ScraperHtmlCrawler {
    async fn crawl(&self, target: &CrawlTarget) -> DomainResult<Vec<ScrapedItem>> {
        let html = self
            .client
            .get(&target.url)
            .send()
            .await
            .map_err(|e| DomainError::Crawler(format!("fetch {}: {e}", target.url)))?
            .text()
            .await
            .map_err(|e| DomainError::Crawler(format!("body {}: {e}", target.url)))?;

        Ok(extract_items(&html, target))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::ports::CrawlSelectors;

    fn target(html_url: &str) -> CrawlTarget {
        CrawlTarget {
            name: "Test".into(),
            url: html_url.into(),
            region: "world".into(),
            discipline: "all".into(),
            language: "en".into(),
            selectors: CrawlSelectors {
                article_list: "article".into(),
                title: "h2 a".into(),
                link: "h2 a".into(),
                description: Some("p".into()),
                image: Some("img".into()),
                date: Some("time".into()),
                relative_links: true,
            },
        }
    }

    #[test]
    fn extracts_well_formed_articles() {
        let html = r#"
            <html><body>
              <article>
                <h2><a href="/news/1">Pogacar takes stage</a></h2>
                <p>Slovenian wins solo</p>
                <img src="/img1.jpg" />
                <time datetime="2026-05-01T12:00:00+00:00"></time>
              </article>
              <article>
                <h2><a href="/news/2">New aero bike unveiled</a></h2>
                <p>Faster than ever</p>
              </article>
            </body></html>
        "#;
        let items = extract_items(html, &target("https://example.com/news"));
        assert_eq!(items.len(), 2);
        assert_eq!(items[0].title, "Pogacar takes stage");
        assert_eq!(items[0].link, "https://example.com/news/1");
        assert_eq!(
            items[0].image_url.as_deref(),
            Some("https://example.com/img1.jpg")
        );
        assert_eq!(items[1].title, "New aero bike unveiled");
    }

    #[test]
    fn skips_articles_with_no_link() {
        let html = r#"<article><h2><a>Just text</a></h2></article>"#;
        let items = extract_items(html, &target("https://example.com/"));
        assert!(items.is_empty());
    }

    #[test]
    fn skips_articles_with_short_titles() {
        let html = r#"<article><h2><a href="/x">hi</a></h2></article>"#;
        let items = extract_items(html, &target("https://example.com/"));
        assert!(items.is_empty());
    }

    #[test]
    fn handles_empty_html() {
        let items = extract_items("", &target("https://example.com/"));
        assert!(items.is_empty());
    }
}

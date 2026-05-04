//! Hard-coded crawl targets (sites without RSS). In a future iteration these
//! could be loaded from `feeds.toml` alongside the RSS sources.

use crate::domain::ports::{CrawlSelectors, CrawlTarget};

pub fn default_targets() -> Vec<CrawlTarget> {
    vec![
        CrawlTarget {
            name: "PZKol".into(),
            url: "https://www.pzkol.pl/aktualnosci/".into(),
            region: "poland".into(),
            discipline: "all".into(),
            language: "pl".into(),
            selectors: CrawlSelectors {
                article_list: "article, .news-item, .post".into(),
                title: "h2 a, h3 a, .title a".into(),
                link: "h2 a, h3 a, .title a".into(),
                description: Some("p, .excerpt, .summary".into()),
                image: Some("img".into()),
                date: Some("time, .date, .post-date".into()),
                relative_links: true,
            },
        },
        CrawlTarget {
            name: "RFEC".into(),
            url: "https://rfec.com/noticias".into(),
            region: "spain".into(),
            discipline: "all".into(),
            language: "es".into(),
            selectors: CrawlSelectors {
                article_list: "article, .news-item, .noticia".into(),
                title: "h2 a, h3 a, .titulo a".into(),
                link: "h2 a, h3 a, .titulo a".into(),
                description: Some("p, .extracto, .resumen".into()),
                image: Some("img".into()),
                date: Some("time, .fecha, .date".into()),
                relative_links: true,
            },
        },
        CrawlTarget {
            name: "UCI News".into(),
            url: "https://www.uci.org/news".into(),
            region: "world".into(),
            discipline: "all".into(),
            language: "en".into(),
            selectors: CrawlSelectors {
                article_list: "article, .news-card, .card".into(),
                title: "h2 a, h3 a, .card-title a".into(),
                link: "a".into(),
                description: Some(".card-text, .summary, p".into()),
                image: Some("img".into()),
                date: Some("time, .date".into()),
                relative_links: true,
            },
        },
        CrawlTarget {
            name: "Vital MTB".into(),
            url: "https://www.vitalmtb.com/news".into(),
            region: "world".into(),
            discipline: "mtb".into(),
            language: "en".into(),
            selectors: CrawlSelectors {
                article_list: "article, .post, .news-item, .content-block".into(),
                title: "h2 a, h3 a, a.title".into(),
                link: "h2 a, h3 a, a.title".into(),
                description: Some(".excerpt, .summary, p".into()),
                image: Some("img".into()),
                date: Some("time, .date, .posted".into()),
                relative_links: true,
            },
        },
        CrawlTarget {
            name: "Rowery.org".into(),
            url: "https://rowery.org/".into(),
            region: "poland".into(),
            discipline: "all".into(),
            language: "pl".into(),
            selectors: CrawlSelectors {
                article_list: "article, .post, .news-item".into(),
                title: "h2 a, h3 a, .entry-title a".into(),
                link: "h2 a, h3 a, .entry-title a".into(),
                description: Some(".entry-summary, .excerpt, p".into()),
                image: Some("img".into()),
                date: Some("time, .entry-date, .date".into()),
                relative_links: true,
            },
        },
        // NaSzosie — Polish road-cycling magazine. Their /feed/ endpoint
        // returns an anti-bot HTML page to HF Spaces' IPs, but the homepage
        // serves clean WordPress markup. Crawl that instead.
        CrawlTarget {
            name: "NaSzosie".into(),
            url: "https://naszosie.pl/".into(),
            region: "poland".into(),
            discipline: "road".into(),
            language: "pl".into(),
            selectors: CrawlSelectors {
                article_list: "article, .post, .post-card, .news-tile".into(),
                title: "h2 a, h3 a, .post-title a, .entry-title a".into(),
                link: "h2 a, h3 a, .post-title a, .entry-title a".into(),
                description: Some(".excerpt, .post-excerpt, p".into()),
                image: Some("img".into()),
                date: Some("time, .date, .post-date, .entry-date".into()),
                relative_links: true,
            },
        },
        // ── Red Bull bike events: Hardline, Rampage, Joyride, Pump Track Worlds ─
        // Red Bull funds events that span MTB/BMX/road and unite riders globally.
        // No RSS — scrape their event-series listing.
        CrawlTarget {
            name: "Red Bull Bike".into(),
            url: "https://www.redbull.com/int-en/event-series/bike".into(),
            region: "world".into(),
            discipline: "mtb".into(), // dominant — most Red Bull bike events are MTB/BMX
            language: "en".into(),
            selectors: CrawlSelectors {
                article_list: "article, .card, [data-test-id='card'], .event-card".into(),
                title: "h2, h3, .card-title, [data-test-id='card-title']".into(),
                link: "a".into(),
                description: Some(".description, .summary, p, .card-text".into()),
                image: Some("img".into()),
                date: Some("time, .date, [datetime]".into()),
                relative_links: true,
            },
        },
        CrawlTarget {
            name: "Red Bull Hardline".into(),
            url: "https://www.redbull.com/int-en/event-series/red-bull-hardline".into(),
            region: "world".into(),
            discipline: "mtb".into(),
            language: "en".into(),
            selectors: CrawlSelectors {
                article_list: "article, .card, [data-test-id='card']".into(),
                title: "h2, h3, .card-title".into(),
                link: "a".into(),
                description: Some(".description, .summary, p".into()),
                image: Some("img".into()),
                date: Some("time, .date, [datetime]".into()),
                relative_links: true,
            },
        },
    ]
}

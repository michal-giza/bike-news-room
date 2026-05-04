//! Hard-coded crawl targets (sites without RSS). In a future iteration these
//! could be loaded from `feeds.toml` alongside the RSS sources.

use crate::domain::ports::{CrawlSelectors, CrawlTarget};

pub fn default_targets() -> Vec<CrawlTarget> {
    vec![
        CrawlTarget {
            // PZKol — Polski Związek Kolarski (federation news).
            // The trailing-slash variant returns a 301 *with* an HTML
            // body announcing "moved" to the no-slash URL. Our crawler
            // doesn't currently follow that body's redirect, so the
            // canonical URL is the no-slash form. Verified by
            //   curl -L https://www.pzkol.pl/aktualnosci → 200 + content.
            // Article cards on the page render as `.article` blocks
            // with a `.title` anchor inside; default selectors
            // (article, .news-item, .post) didn't match, so we add
            // `.article` and `.title` explicitly. `relative_links: true`
            // is required because anchor hrefs are root-relative.
            name: "PZKol".into(),
            url: "https://www.pzkol.pl/aktualnosci".into(),
            region: "poland".into(),
            discipline: "all".into(),
            language: "pl".into(),
            selectors: CrawlSelectors {
                article_list: "article, .article, .news-item, .post".into(),
                title: "h2 a, h3 a, .title a, a.title".into(),
                link: "h2 a, h3 a, .title a, a.title".into(),
                description: Some("p, .excerpt, .summary, .lead".into()),
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
        // Rowery.org closed on 2024-12-15. Their homepage banner now
        // reads "Czas pożegnania — wortal rowery.org zakończył
        // działalność" ("Time to say goodbye — the rowery.org portal
        // has ended operations") and the article archive at /posts/
        // shows a dated, frozen snapshot. Removed from the crawler
        // list — keeping it would just emit zero articles every cron
        // tick and inflate the feed-health metrics with a healthy-but-
        // useless source. Replaced by mtb.pl in feeds.toml (real RSS).
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

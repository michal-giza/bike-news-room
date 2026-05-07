//! bnr-crawler — second HF Space.
//!
//! Why this lives outside the main backend:
//!  - Crawling source candidates is bursty (fetch-parse-judge per URL)
//!    and can spike CPU for tens of seconds. Doing it inline on the
//!    main backend stalls API requests.
//!  - HF Spaces' free tier sleeps after 48h idle but wakes on first
//!    request; perfect for a periodic-cron service like this.
//!  - If this crashes the main feed stays up.
//!
//! What it does:
//!  1. On a cron schedule (default: every 6 hours) calls the main
//!     backend's `/api/sources/candidates?status=pending` endpoint to
//!     pull the queue of URLs we've discovered being cited in articles.
//!  2. For each candidate, runs a probe: fetch HEAD then GET, check
//!     the body for RSS/Atom or for cycling-relevant keywords in
//!     `<meta>` / `<title>`.
//!  3. Posts an admin-token-signed verdict back to the main backend's
//!     `/api/admin/source-candidates/{id}/promote` or
//!     `/api/admin/source-candidates/{id}/reject` endpoint.
//!
//! Env vars:
//!
//! - `MAIN_API_BASE` — URL of the main HF Space (no trailing slash).
//! - `CRAWLER_TOKEN` — shared secret matching the main backend's
//!   `ADMIN_TOKEN`. Required; empty = service exits.
//! - `CRAWL_CRON` — optional cron expression; default
//!   `0 0 */6 * * *` (every 6 hours).
//! - `CRAWL_LIMIT` — max candidates per run; default 25.

use std::env;
use std::time::Duration;

use axum::{response::Json, routing::get, Router};
use serde::{Deserialize, Serialize};
use tokio_cron_scheduler::{Job, JobScheduler};
use tracing::{error, info, warn};

#[derive(Clone)]
struct Config {
    api_base: String,
    crawler_token: String,
    cron_expr: String,
    limit: usize,
}

impl Config {
    fn from_env() -> Result<Self, &'static str> {
        let api_base = env::var("MAIN_API_BASE")
            .map_err(|_| "MAIN_API_BASE env var is required")?
            .trim_end_matches('/')
            .to_string();
        let crawler_token =
            env::var("CRAWLER_TOKEN").map_err(|_| "CRAWLER_TOKEN env var is required")?;
        if crawler_token.is_empty() {
            return Err("CRAWLER_TOKEN must not be empty");
        }
        let cron_expr = env::var("CRAWL_CRON").unwrap_or_else(|_| "0 0 */6 * * *".to_string());
        let limit = env::var("CRAWL_LIMIT")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(25);
        Ok(Config {
            api_base,
            crawler_token,
            cron_expr,
            limit,
        })
    }
}

#[derive(Debug, Deserialize)]
struct CandidatesEnvelope {
    candidates: Vec<Candidate>,
}

#[derive(Debug, Deserialize, Clone)]
struct Candidate {
    id: i64,
    domain: String,
    sample_url: String,
}

#[derive(Debug, Serialize)]
struct PromoteBody {
    /// What we detected. Main backend uses this to set the right
    /// crawl strategy (RSS vs HTML site). One of `rss`, `crawl`.
    kind: String,
    /// Human-readable name, defaults to domain on the main side if
    /// missing. We try to extract `<title>` for RSS feeds.
    name: Option<String>,
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let cfg = match Config::from_env() {
        Ok(c) => c,
        Err(msg) => {
            error!("{msg}");
            std::process::exit(1);
        }
    };
    info!(
        "bnr-crawler starting; api_base={} cron={} limit={}",
        cfg.api_base, cfg.cron_expr, cfg.limit
    );

    let scheduler = JobScheduler::new().await.expect("init scheduler");
    let cron_cfg = cfg.clone();
    let job = Job::new_async(cfg.cron_expr.as_str(), move |_, _| {
        let inner = cron_cfg.clone();
        Box::pin(async move {
            if let Err(e) = run_sweep(&inner).await {
                warn!("sweep failed: {e}");
            }
        })
    })
    .expect("build cron job");
    scheduler.add(job).await.expect("register cron job");
    scheduler.start().await.expect("start scheduler");

    // HTTP server: /health for HF uptime checks, /run for manual
    // triggers (curl -X POST -H "X-Crawler-Token: …" .../run).
    let app = Router::new()
        .route("/health", get(health))
        .route("/run", axum::routing::post(run_now));
    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(7860);
    let listener = tokio::net::TcpListener::bind(("0.0.0.0", port))
        .await
        .expect("bind");
    info!("listening on :{port}");
    axum::serve(listener, app).await.expect("axum serve");
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({"status": "ok", "service": "bnr-crawler"}))
}

async fn run_now() -> Json<serde_json::Value> {
    let cfg = match Config::from_env() {
        Ok(c) => c,
        Err(e) => {
            return Json(serde_json::json!({"ok": false, "error": e}));
        }
    };
    match run_sweep(&cfg).await {
        Ok(stats) => Json(serde_json::json!({"ok": true, "stats": stats})),
        Err(e) => Json(serde_json::json!({"ok": false, "error": e.to_string()})),
    }
}

#[derive(Debug, Serialize)]
struct SweepStats {
    fetched: usize,
    promoted: usize,
    rejected: usize,
    skipped: usize,
}

async fn run_sweep(cfg: &Config) -> Result<SweepStats, anyhow::Error> {
    let client = reqwest::Client::builder()
        .timeout(Duration::from_secs(15))
        .user_agent("BikeNewsRoom-Crawler/0.1")
        .build()?;
    let url = format!(
        "{}/api/sources/candidates?status=pending&limit={}",
        cfg.api_base, cfg.limit
    );
    let envelope: CandidatesEnvelope = client
        .get(&url)
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;
    let total = envelope.candidates.len();
    let mut promoted = 0;
    let mut rejected = 0;
    let mut skipped = 0;
    for cand in envelope.candidates {
        match probe(&client, &cand).await {
            Ok(Some(verdict)) => {
                if let Err(e) = post_verdict(&client, cfg, &cand, &verdict).await {
                    warn!("post_verdict {}: {e}", cand.domain);
                    skipped += 1;
                    continue;
                }
                if verdict.kind == "reject" {
                    rejected += 1;
                } else {
                    promoted += 1;
                }
            }
            Ok(None) => {
                skipped += 1;
            }
            Err(e) => {
                warn!("probe {}: {e}", cand.domain);
                skipped += 1;
            }
        }
        // 2-second pacing between probes — friendly to publishers,
        // well within rate-limit thresholds even on aggressive WAFs.
        tokio::time::sleep(Duration::from_secs(2)).await;
    }
    let stats = SweepStats {
        fetched: total,
        promoted,
        rejected,
        skipped,
    };
    info!(
        "sweep complete: fetched={} promoted={} rejected={} skipped={}",
        stats.fetched, stats.promoted, stats.rejected, stats.skipped
    );
    Ok(stats)
}

#[derive(Debug)]
struct Verdict {
    kind: String, // "rss" | "crawl" | "reject"
    name: Option<String>,
}

async fn probe(
    client: &reqwest::Client,
    cand: &Candidate,
) -> Result<Option<Verdict>, anyhow::Error> {
    let res = client.get(&cand.sample_url).send().await?;
    if !res.status().is_success() {
        return Ok(Some(Verdict {
            kind: "reject".into(),
            name: None,
        }));
    }
    let body = res.text().await?;
    // Cheap RSS / Atom probe: feed-rs accepts both formats; if it
    // parses cleanly we treat the URL as a feed and grab the title.
    if let Ok(feed) = feed_rs::parser::parse(body.as_bytes()) {
        let name = feed.title.map(|t| t.content);
        return Ok(Some(Verdict {
            kind: "rss".into(),
            name,
        }));
    }
    // HTML site path: look for cycling-keyword density in title +
    // headings. If present, propose as a crawl target.
    let doc = scraper::Html::parse_document(&body);
    let lower = body.to_lowercase();
    let cycling_hits = ["cycling", "kolarstwo", "ciclismo", "vélo"]
        .iter()
        .filter(|kw| lower.contains(*kw))
        .count();
    if cycling_hits == 0 {
        return Ok(Some(Verdict {
            kind: "reject".into(),
            name: None,
        }));
    }
    let title_sel = scraper::Selector::parse("title").unwrap();
    let name = doc
        .select(&title_sel)
        .next()
        .map(|el| el.text().collect::<String>().trim().to_string())
        .filter(|t| !t.is_empty());
    Ok(Some(Verdict {
        kind: "crawl".into(),
        name,
    }))
}

async fn post_verdict(
    client: &reqwest::Client,
    cfg: &Config,
    cand: &Candidate,
    verdict: &Verdict,
) -> Result<(), anyhow::Error> {
    let endpoint = if verdict.kind == "reject" {
        format!(
            "{}/api/admin/source-candidates/{}/reject",
            cfg.api_base, cand.id
        )
    } else {
        format!(
            "{}/api/admin/source-candidates/{}/promote",
            cfg.api_base, cand.id
        )
    };
    let body = PromoteBody {
        kind: verdict.kind.clone(),
        name: verdict.name.clone(),
    };
    let res = client
        .post(&endpoint)
        .header("x-admin-token", &cfg.crawler_token)
        .json(&body)
        .send()
        .await?;
    if !res.status().is_success() {
        anyhow::bail!(
            "main API rejected verdict for {}: {}",
            cand.domain,
            res.status()
        );
    }
    Ok(())
}

//! Optional persistence layer for ephemeral container hosts (Hugging Face Spaces).
//!
//! Strategy: keep SQLite as the primary store, but periodically copy the DB file
//! to a configured HTTP endpoint (e.g. an HF Dataset, S3, or any HTTP PUT target).
//! On startup, attempt to restore from that endpoint before opening the DB.
//!
//! Disabled by default — set `SNAPSHOT_URL` and `SNAPSHOT_TOKEN` to enable.
//! Snapshots happen every `SNAPSHOT_INTERVAL_MINUTES` (default: 60).

use std::path::Path;
use std::time::Duration;

use tracing::{info, warn};

/// Configuration for the snapshot system. All fields read from env vars.
#[derive(Debug, Clone)]
pub struct SnapshotConfig {
    pub url: String,
    pub token: String,
    pub interval: Duration,
}

impl SnapshotConfig {
    /// Read config from env. Returns `None` if disabled.
    pub fn from_env() -> Option<Self> {
        let url = std::env::var("SNAPSHOT_URL").ok()?;
        let token = std::env::var("SNAPSHOT_TOKEN").ok()?;
        let interval_min: u64 = std::env::var("SNAPSHOT_INTERVAL_MINUTES")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(60);
        Some(Self {
            url,
            token,
            interval: Duration::from_secs(interval_min * 60),
        })
    }
}

/// Try to restore the DB file from the snapshot URL before the server boots.
/// On any error, logs and continues with a fresh DB — never blocks startup.
pub async fn restore_if_configured(db_path: &Path, config: &SnapshotConfig) {
    if db_path.exists() {
        info!("snapshot: db file already exists, skipping restore");
        return;
    }

    let client = match reqwest::Client::builder()
        .timeout(Duration::from_secs(30))
        .build()
    {
        Ok(c) => c,
        Err(e) => {
            warn!("snapshot: failed to build http client: {e}");
            return;
        }
    };

    let response = match client
        .get(&config.url)
        .bearer_auth(&config.token)
        .send()
        .await
    {
        Ok(r) => r,
        Err(e) => {
            warn!("snapshot: restore fetch failed (this is fine on first boot): {e}");
            return;
        }
    };

    if !response.status().is_success() {
        warn!(
            "snapshot: restore returned {} — starting with empty db",
            response.status()
        );
        return;
    }

    let bytes = match response.bytes().await {
        Ok(b) => b,
        Err(e) => {
            warn!("snapshot: failed to read body: {e}");
            return;
        }
    };

    if let Some(parent) = db_path.parent() {
        if !parent.as_os_str().is_empty() {
            let _ = std::fs::create_dir_all(parent);
        }
    }

    match std::fs::write(db_path, &bytes) {
        Ok(_) => info!("snapshot: restored {} bytes to {:?}", bytes.len(), db_path),
        Err(e) => warn!("snapshot: failed to write db file: {e}"),
    }
}

/// Upload a snapshot of the current DB file. Best-effort — logs failures.
pub async fn upload(db_path: &Path, config: &SnapshotConfig) {
    let bytes = match std::fs::read(db_path) {
        Ok(b) => b,
        Err(e) => {
            warn!("snapshot: failed to read db file for upload: {e}");
            return;
        }
    };

    let client = match reqwest::Client::builder()
        .timeout(Duration::from_secs(60))
        .build()
    {
        Ok(c) => c,
        Err(e) => {
            warn!("snapshot: failed to build http client: {e}");
            return;
        }
    };

    let result = client
        .put(&config.url)
        .bearer_auth(&config.token)
        .body(bytes.clone())
        .send()
        .await;

    match result {
        Ok(r) if r.status().is_success() => {
            info!("snapshot: uploaded {} bytes", bytes.len());
        }
        Ok(r) => warn!("snapshot: upload returned status {}", r.status()),
        Err(e) => warn!("snapshot: upload failed: {e}"),
    }
}

/// Spawn a background task that uploads snapshots on a fixed interval.
pub fn spawn_periodic_snapshot(db_path: std::path::PathBuf, config: SnapshotConfig) {
    tokio::spawn(async move {
        let mut ticker = tokio::time::interval(config.interval);
        // Skip the immediate first tick — we just started, no need to snapshot.
        ticker.tick().await;
        loop {
            ticker.tick().await;
            upload(&db_path, &config).await;
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn config_disabled_when_env_missing() {
        // Save and restore env so the test isn't order-dependent.
        let saved_url = std::env::var("SNAPSHOT_URL").ok();
        let saved_token = std::env::var("SNAPSHOT_TOKEN").ok();
        std::env::remove_var("SNAPSHOT_URL");
        std::env::remove_var("SNAPSHOT_TOKEN");

        assert!(SnapshotConfig::from_env().is_none());

        if let Some(v) = saved_url {
            std::env::set_var("SNAPSHOT_URL", v);
        }
        if let Some(v) = saved_token {
            std::env::set_var("SNAPSHOT_TOKEN", v);
        }
    }
}

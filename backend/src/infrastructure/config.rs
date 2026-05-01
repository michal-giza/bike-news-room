//! Configuration loaded from `feeds.toml`.

use std::path::Path;

use serde::Deserialize;

use crate::domain::errors::{DomainError, DomainResult};

#[derive(Debug, Deserialize, Clone)]
pub struct AppConfig {
    pub feeds: Vec<FeedSource>,
}

#[derive(Debug, Deserialize, Clone)]
pub struct FeedSource {
    pub url: String,
    pub title: String,
    pub region: String,
    pub discipline: String,
    pub language: String,
}

impl AppConfig {
    pub fn load(path: &Path) -> DomainResult<Self> {
        let content = std::fs::read_to_string(path)
            .map_err(|e| DomainError::InvalidInput(format!("read {path:?}: {e}")))?;
        toml::from_str(&content)
            .map_err(|e| DomainError::InvalidInput(format!("parse {path:?}: {e}")))
    }
}

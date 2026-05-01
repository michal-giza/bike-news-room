//! Canonical domain error type. Layers above translate this to their own concerns
//! (HTTP status codes, log levels, etc.).

use thiserror::Error;

#[derive(Debug, Error)]
pub enum DomainError {
    #[error("repository error: {0}")]
    Repository(String),

    #[error("feed fetch failed: {0}")]
    FeedFetch(String),

    #[error("feed parse failed: {0}")]
    FeedParse(String),

    #[error("crawler failed: {0}")]
    Crawler(String),

    #[error("invalid input: {0}")]
    InvalidInput(String),

    #[error("not found")]
    NotFound,
}

impl From<sqlx::Error> for DomainError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => DomainError::NotFound,
            other => DomainError::Repository(other.to_string()),
        }
    }
}

impl From<reqwest::Error> for DomainError {
    fn from(err: reqwest::Error) -> Self {
        DomainError::FeedFetch(err.to_string())
    }
}

pub type DomainResult<T> = Result<T, DomainError>;

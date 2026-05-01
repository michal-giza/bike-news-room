//! Maps `DomainError` to HTTP status codes + JSON bodies.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde_json::json;

use crate::domain::errors::DomainError;

pub struct ApiError(pub DomainError);

impl From<DomainError> for ApiError {
    fn from(err: DomainError) -> Self {
        ApiError(err)
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, message) = match &self.0 {
            DomainError::NotFound => (StatusCode::NOT_FOUND, "not found".to_string()),
            DomainError::InvalidInput(msg) => (StatusCode::BAD_REQUEST, msg.clone()),
            DomainError::Repository(msg)
            | DomainError::FeedFetch(msg)
            | DomainError::FeedParse(msg)
            | DomainError::Crawler(msg) => {
                tracing::error!("internal error: {msg}");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "internal error".to_string(),
                )
            }
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}

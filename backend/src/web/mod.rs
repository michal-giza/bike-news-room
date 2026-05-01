//! Web/HTTP layer — Axum routes, DTOs, error mapping.

pub mod crawl_targets;
pub mod dto;
pub mod errors;
pub mod routes;

pub use routes::create_router;

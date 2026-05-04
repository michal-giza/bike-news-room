//! Web/HTTP layer — Axum routes, DTOs, error mapping.

pub mod article_html;
pub mod crawl_targets;
pub mod dto;
pub mod errors;
pub mod routes;
pub mod sitemap;

pub use routes::create_router;

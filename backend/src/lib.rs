//! Clean architecture layers:
//!   domain         — entities, ports (traits), pure services, errors
//!   application    — use cases that orchestrate domain ports
//!   infrastructure — concrete adapters (SQLite, RSS, HTML crawler, config)
//!   web            — HTTP layer (Axum routes, DTOs, error mapping)

pub mod application;
pub mod domain;
pub mod infrastructure;
pub mod web;

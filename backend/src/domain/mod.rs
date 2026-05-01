//! Domain layer — pure business logic with no I/O.
//!
//! Contains entities, value objects, ports (trait abstractions for I/O),
//! domain services (pure functions), and the canonical domain error type.

pub mod entities;
pub mod errors;
pub mod ports;
pub mod services;

pub use entities::{Article, ArticleDraft, CategoryCount, Feed, FeedHealth, Race, RaceDraft};
pub use errors::DomainError;

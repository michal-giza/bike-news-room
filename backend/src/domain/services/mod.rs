//! Pure domain services — no I/O, no async, fully testable.

pub mod categorizer;
pub mod dedup;

pub use categorizer::categorize;
pub use dedup::{compute_title_hash, extract_domain, is_fuzzy_duplicate, normalize_url};

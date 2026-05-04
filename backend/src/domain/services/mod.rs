//! Pure domain services — no I/O, no async, fully testable.

pub mod categorizer;
pub mod dedup;
pub mod race_matcher;
pub mod shutdown_detector;
pub mod url_guard;

pub use categorizer::categorize;
pub use dedup::{compute_title_hash, extract_domain, is_fuzzy_duplicate, normalize_url};
pub use race_matcher::{
    normalise as normalise_for_match, RaceCatalogue, RaceMatch, RaceMatchEntry,
};
pub use shutdown_detector::detect_shutdown;
pub use url_guard::{validate as validate_url, UrlGuardError};

//! URL safety guard for user-submitted source URLs.
//!
//! Threat model: a user submits a URL via `POST /api/sources`. Without
//! protection, an attacker could submit:
//!
//!   - `http://127.0.0.1:7860/admin` — hits our own loopback
//!   - `http://169.254.169.254/...` — AWS / GCP / HF metadata endpoint
//!   - `http://10.0.0.1/...` — internal RFC1918 hosts
//!   - `javascript:` / `data:` / `file:` — non-network schemes
//!
//! Our outbound reqwest client would happily fetch any of these. This module
//! validates the URL **structurally** (scheme + host syntax) before any DNS
//! lookup. After resolution the underlying `reqwest` could still be tricked
//! by DNS-rebinding-style attacks, but we accept that residual risk for an
//! ingestion-only flow with rate limits and a content-size cap.

use std::net::IpAddr;

use thiserror::Error;
use url::{Host, Url};

#[derive(Debug, Error, PartialEq, Eq)]
pub enum UrlGuardError {
    #[error("URL is empty or unparseable")]
    Unparseable,
    #[error("only http and https schemes are accepted")]
    ForbiddenScheme,
    #[error("URL must include a host")]
    MissingHost,
    #[error("loopback / RFC1918 / link-local hosts are not allowed")]
    PrivateHost,
    #[error("URL exceeds the maximum allowed length (2048)")]
    TooLong,
}

const MAX_LEN: usize = 2048;

/// Validate a user-submitted URL. Returns the parsed [`Url`] on success.
pub fn validate(raw: &str) -> Result<Url, UrlGuardError> {
    if raw.is_empty() {
        return Err(UrlGuardError::Unparseable);
    }
    if raw.len() > MAX_LEN {
        return Err(UrlGuardError::TooLong);
    }

    let url = Url::parse(raw).map_err(|_| UrlGuardError::Unparseable)?;

    match url.scheme() {
        "http" | "https" => {}
        _ => return Err(UrlGuardError::ForbiddenScheme),
    }

    // Use the typed `Host` enum so IPv6 literals (`[::1]`) resolve to
    // `Host::Ipv6(...)` directly — `host_str()` returns the bracketed form
    // which doesn't parse as `IpAddr`.
    match url.host() {
        None => return Err(UrlGuardError::MissingHost),
        Some(Host::Ipv4(v4)) => {
            if is_private_ip(IpAddr::V4(v4)) {
                return Err(UrlGuardError::PrivateHost);
            }
        }
        Some(Host::Ipv6(v6)) => {
            if is_private_ip(IpAddr::V6(v6)) {
                return Err(UrlGuardError::PrivateHost);
            }
        }
        Some(Host::Domain(domain)) => {
            // Block obvious localhost-like names. Real DNS that resolves to
            // RFC1918 will still succeed structurally (e.g. an internal
            // corporate feed); we rely on payload-size + timeout limits +
            // unprivileged process for that residual risk.
            let lower = domain.to_ascii_lowercase();
            const BLOCKED_DOMAINS: &[&str] = &["localhost", "ip6-localhost", "ip6-loopback"];
            if BLOCKED_DOMAINS.contains(&lower.as_str()) {
                return Err(UrlGuardError::PrivateHost);
            }
        }
    }

    Ok(url)
}

/// Is this IP in a private / loopback / link-local / multicast range?
fn is_private_ip(ip: IpAddr) -> bool {
    match ip {
        IpAddr::V4(v4) => {
            v4.is_private()
                || v4.is_loopback()
                || v4.is_link_local()
                || v4.is_unspecified()
                || v4.is_broadcast()
                || v4.is_multicast()
                || v4.octets()[0] == 0 // 0.0.0.0/8
        }
        IpAddr::V6(v6) => {
            v6.is_loopback()
                || v6.is_unspecified()
                || v6.is_multicast()
                || v6.segments()[0] & 0xfe00 == 0xfc00 // unique local fc00::/7
                || v6.segments()[0] & 0xffc0 == 0xfe80 // link-local fe80::/10
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_normal_https() {
        assert!(validate("https://example.com/feed").is_ok());
        assert!(validate("https://www.cyclingnews.com/rss").is_ok());
        assert!(validate("http://feed.example.org/atom.xml").is_ok());
    }

    #[test]
    fn rejects_javascript_data_file() {
        assert_eq!(
            validate("javascript:alert(1)"),
            Err(UrlGuardError::ForbiddenScheme),
        );
        assert_eq!(
            validate("data:text/html,<script>alert(1)</script>"),
            Err(UrlGuardError::ForbiddenScheme),
        );
        assert_eq!(
            validate("file:///etc/passwd"),
            Err(UrlGuardError::ForbiddenScheme),
        );
    }

    #[test]
    fn rejects_localhost_variants() {
        assert_eq!(
            validate("http://localhost/"),
            Err(UrlGuardError::PrivateHost)
        );
        assert_eq!(
            validate("http://127.0.0.1/"),
            Err(UrlGuardError::PrivateHost)
        );
        assert_eq!(validate("http://[::1]/"), Err(UrlGuardError::PrivateHost));
    }

    #[test]
    fn rejects_rfc1918_and_metadata() {
        assert_eq!(
            validate("http://10.0.0.1/"),
            Err(UrlGuardError::PrivateHost)
        );
        assert_eq!(
            validate("http://192.168.1.1/"),
            Err(UrlGuardError::PrivateHost)
        );
        assert_eq!(
            validate("http://172.16.0.1/"),
            Err(UrlGuardError::PrivateHost)
        );
        assert_eq!(
            validate("http://169.254.169.254/latest/meta-data/"),
            Err(UrlGuardError::PrivateHost),
        );
    }

    #[test]
    fn rejects_empty_and_unparseable() {
        assert_eq!(validate(""), Err(UrlGuardError::Unparseable));
        assert_eq!(validate("not a url"), Err(UrlGuardError::Unparseable));
    }

    #[test]
    fn rejects_excessive_length() {
        let long = format!("https://example.com/{}", "a".repeat(2100));
        assert_eq!(validate(&long), Err(UrlGuardError::TooLong));
    }
}

/// URL safety helpers — whitelist `http` / `https` for any URL pulled from a
/// third-party RSS feed. Without this, a `javascript:` or `data:` URL from a
/// malicious feed could execute in our context (web) or trigger surprising
/// behaviour on mobile. Apply to every external [launchUrl] call and every
/// [Image.network] source.
library;

const _safeSchemes = {'http', 'https'};

/// `true` if the URL is parseable, has an `http` / `https` scheme, and a host.
bool isSafeWebUrl(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final uri = Uri.tryParse(raw);
  if (uri == null) return false;
  if (!_safeSchemes.contains(uri.scheme.toLowerCase())) return false;
  if (!uri.hasAuthority) return false; // must have a host
  return true;
}

/// Parsed safe URL or `null` when unsafe.
Uri? safeUri(String? raw) => isSafeWebUrl(raw) ? Uri.parse(raw!) : null;

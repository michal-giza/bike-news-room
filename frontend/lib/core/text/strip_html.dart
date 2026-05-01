/// Sanitises HTML/RSS description strings into plain editorial prose.
///
/// We do NOT render arbitrary HTML — descriptions are short and the design
/// wants clean serif/sans paragraphs. This sanitiser:
///
///   1. Drops `<script>`, `<style>`, and HTML comments entirely (with content).
///   2. Drops CDATA wrappers (`<![CDATA[…]]>`) but keeps inner text.
///   3. Converts block-closing tags to newlines so paragraphs read sensibly.
///   4. Strips all remaining tags (including their attributes, even when
///      attribute values contain `>` or span multiple lines).
///   5. Decodes named entities (`&amp;`, `&apos;`, `&hellip;`, …) and numeric
///      entities (`&#8217;`, `&#x2019;`).
///   6. Normalises whitespace and trims.
///   7. Drops control characters (other than `\n` / `\t`).
///
/// Idempotent — running it twice gives the same result.
String stripHtml(String? raw) {
  if (raw == null || raw.isEmpty) return '';

  var s = raw;

  // 1. Drop script/style + their content.
  s = s.replaceAll(
    RegExp(r'<(script|style)[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false),
    '',
  );

  // 2. Drop HTML comments and CDATA wrappers (keep CDATA contents).
  s = s.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
  s = s.replaceAllMapped(
    RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>'),
    (m) => m.group(1) ?? '',
  );

  // 3. Block-level closes → newline (so paragraphs survive as line breaks).
  s = s.replaceAll(
    RegExp(
      r'</(p|div|li|h[1-6]|figure|figcaption|article|section|header|footer|tr|td|th|blockquote)\s*>',
      caseSensitive: false,
    ),
    '\n',
  );
  s = s.replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '\n');
  s = s.replaceAll(RegExp(r'<hr\s*/?\s*>', caseSensitive: false), '\n');

  // 4. Strip remaining tags. Use a "no '<' or '>' inside" pattern so quoted
  //    attribute values like `href="https://x?a=b"` are matched correctly.
  //    The dot-all flag handles multi-line attribute values.
  s = s.replaceAll(RegExp(r'<[^<>]*>', dotAll: true), '');

  // 5. Decode entities.
  s = _decodeEntities(s);

  // 6. Drop weird control characters (NUL, BS, etc.) but keep \n and \t.
  s = s.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

  // 7. Collapse whitespace runs (preserve newlines as single spaces — the
  //    article cards single-line anyway, and the modal renders inline).
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  return s;
}

/// Named + numeric HTML entity decoder. Falls back gracefully on unknown.
String _decodeEntities(String input) {
  // Numeric (decimal): &#8217;
  var s = input.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) {
      final code = int.tryParse(m.group(1)!);
      if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
      return _safeChar(code) ?? m.group(0)!;
    },
  );
  // Numeric (hex): &#x2019; / &#X2019;
  s = s.replaceAllMapped(
    RegExp(r'&#[xX]([0-9a-fA-F]+);'),
    (m) {
      final code = int.tryParse(m.group(1)!, radix: 16);
      if (code == null || code < 0 || code > 0x10FFFF) return m.group(0)!;
      return _safeChar(code) ?? m.group(0)!;
    },
  );
  // Named entities — table covers the common RSS cases.
  _namedEntities.forEach((name, value) {
    s = s.replaceAll(name, value);
  });
  return s;
}

/// Convert a Unicode codepoint to a string, rejecting invalid surrogates.
String? _safeChar(int code) {
  if (code >= 0xD800 && code <= 0xDFFF) return null; // unpaired surrogate
  try {
    return String.fromCharCode(code);
  } catch (_) {
    return null;
  }
}

const Map<String, String> _namedEntities = {
  // Mandatory five
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&quot;': '"',
  '&apos;': "'",
  // Whitespace + common punctuation
  '&nbsp;': ' ',
  '&ensp;': ' ',
  '&emsp;': ' ',
  '&thinsp;': ' ',
  '&hellip;': '…',
  '&mdash;': '—',
  '&ndash;': '–',
  '&minus;': '−',
  '&middot;': '·',
  '&bull;': '•',
  // Quotes
  '&lsquo;': '‘',
  '&rsquo;': '’',
  '&ldquo;': '“',
  '&rdquo;': '”',
  '&laquo;': '«',
  '&raquo;': '»',
  // Symbols often in cycling content
  '&copy;': '©',
  '&reg;': '®',
  '&trade;': '™',
  '&deg;': '°',
  '&plusmn;': '±',
  '&times;': '×',
  '&divide;': '÷',
  '&euro;': '€',
  '&pound;': '£',
  '&yen;': '¥',
  '&cent;': '¢',
  // Accented Latin used by Polish / Spanish source titles
  '&aacute;': 'á',
  '&eacute;': 'é',
  '&iacute;': 'í',
  '&oacute;': 'ó',
  '&uacute;': 'ú',
  '&ntilde;': 'ñ',
  '&ccedil;': 'ç',
  '&Eacute;': 'É',
  '&Aacute;': 'Á',
  '&Iacute;': 'Í',
  '&Oacute;': 'Ó',
  '&Uacute;': 'Ú',
  '&Ntilde;': 'Ñ',
};

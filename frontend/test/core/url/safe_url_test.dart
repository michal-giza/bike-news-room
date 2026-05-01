import 'package:bike_news_room/core/url/safe_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isSafeWebUrl', () {
    test('accepts http and https with host', () {
      expect(isSafeWebUrl('https://www.cyclingnews.com/news'), isTrue);
      expect(isSafeWebUrl('http://example.com'), isTrue);
    });

    test('rejects javascript:', () {
      expect(isSafeWebUrl('javascript:alert(1)'), isFalse);
      expect(isSafeWebUrl('JAVASCRIPT:alert(1)'), isFalse);
    });

    test('rejects data:', () {
      expect(isSafeWebUrl('data:text/html,<script>alert(1)</script>'), isFalse);
    });

    test('rejects mailto: / tel: / file:', () {
      expect(isSafeWebUrl('mailto:foo@bar.com'), isFalse);
      expect(isSafeWebUrl('tel:+1234'), isFalse);
      expect(isSafeWebUrl('file:///etc/passwd'), isFalse);
    });

    test('rejects relative URLs (no host)', () {
      expect(isSafeWebUrl('/news/123'), isFalse);
    });

    test('rejects null and empty', () {
      expect(isSafeWebUrl(null), isFalse);
      expect(isSafeWebUrl(''), isFalse);
    });

    test('rejects schemeless text', () {
      // No scheme at all → not http/https → rejected.
      expect(isSafeWebUrl('not a url'), isFalse);
    });
  });

  group('safeUri', () {
    test('returns Uri for safe URLs', () {
      final uri = safeUri('https://example.com/foo');
      expect(uri, isNotNull);
      expect(uri!.host, 'example.com');
    });

    test('returns null for unsafe URLs', () {
      expect(safeUri('javascript:alert(1)'), isNull);
      expect(safeUri(null), isNull);
    });
  });
}

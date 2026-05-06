// Guards the resolved API base URL — the bug that triggered this test
// was a `localhost:7860` default in `ApiClient.create()` that left
// every Android build with a dead backend until a `--dart-define` was
// passed at build time. We now default to the production HF Space, so
// a plain `flutter run` works against live data; this test makes sure
// nobody re-introduces the old default by accident.
//
// Note: `String.fromEnvironment` is resolved at COMPILE time, so we
// cannot easily test the override path from a regular `flutter test`
// run (it has no `--dart-define`). Instead we assert the *default*
// is non-localhost and matches the documented HF URL. Override
// behaviour is verified manually + by the cloudflare-build.sh script.

import 'package:bike_news_room/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiClient', () {
    test('defaultBaseUrl points at the live HF Space, not localhost', () {
      expect(
        ApiClient.defaultBaseUrl,
        isNot(contains('localhost')),
        reason:
            'A localhost default leaves every device build with a dead '
            'backend. Production builds must default to the live HF URL.',
      );
      expect(
        ApiClient.defaultBaseUrl,
        startsWith('https://'),
        reason: 'Production base URL must be https — Android cleartext '
            'traffic is blocked by default and would silently fail.',
      );
      expect(
        ApiClient.defaultBaseUrl,
        contains('hf.space'),
        reason:
            'Default must point at the HF Space backend that hosts the '
            'live cycling-news data.',
      );
    });

    test('create() bakes the resolved base URL into the underlying Dio', () {
      final client = ApiClient.create();
      // Without a --dart-define, the test runner sees the compile-time
      // default. With one, it sees the override. Either way the URL must
      // be a valid http(s) URL the device can resolve.
      final url = client.dio.options.baseUrl;
      expect(
        url,
        anyOf(startsWith('https://'), startsWith('http://')),
        reason: 'Dio baseUrl must be a real URL, not empty or malformed',
      );
      expect(
        url,
        isNot(equals('http://localhost:7860')),
        reason:
            'If you see this fire it means someone reverted the default '
            'back to localhost — that breaks every physical-device build.',
      );
    });
  });
}

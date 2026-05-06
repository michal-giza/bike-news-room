// Live-backend smoke test — opt-in. Run with:
//
//   flutter test integration_test/live_backend_test.dart \
//     -d <device-id> \
//     --dart-define=BNR_LIVE_BACKEND=true
//
// Without that flag the file is a no-op (every test is `markTestSkipped`).
// We default to skipped because the suite must stay deterministic on CI:
// the live HF Space can be cold-starting (10–30 s wake-up), rate-limited,
// or temporarily empty between ingest cycles, all of which would flake
// a hard-asserted live test.
//
// What this catches that the MockApi suite can't:
//   1. `ApiClient.defaultBaseUrl` actually resolves and returns 200.
//   2. Android cleartext / TLS handshake works against the real host.
//   3. The live `/api/articles` payload still matches our deserialisers
//      (a backend schema drift would break the app even if MockApi tests
//      stay green).
//   4. `/api/articles?region=poland` returns a non-empty list — the
//      exact query the user reported empty when their Android build was
//      pointed at localhost.
//
// The test exercises the production code path: `ApiClient.create()`
// (no harness override), real Dio, real network. If you've forgotten a
// `--dart-define=API_BASE_URL=...` on a non-production build the first
// assertion will tell you exactly why.

import 'package:bike_news_room/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const _liveBackend =
    bool.fromEnvironment('BNR_LIVE_BACKEND', defaultValue: false);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!_liveBackend) {
    test('live-backend suite skipped (set BNR_LIVE_BACKEND=true to run)', () {
      markTestSkipped(
        'Live-backend smoke is opt-in. Pass '
        '--dart-define=BNR_LIVE_BACKEND=true to enable.',
      );
    });
    return;
  }

  group('Live HF Space backend', () {
    late ApiClient client;

    setUpAll(() {
      client = ApiClient.create();
    });

    test('default base URL resolves and returns 200 on /api/health', () async {
      final res = await client.dio.get<dynamic>('/api/health');
      expect(res.statusCode, 200,
          reason: 'live backend health check must be reachable from '
              'the device under test — if this fails on Android but '
              'works on web, your APK was built without '
              '--dart-define=API_BASE_URL=...');
    });

    test('/api/articles returns at least one article', () async {
      final res = await client.dio.get<Map<String, dynamic>>(
        '/api/articles',
        queryParameters: const {'limit': 5},
      );
      final articles = (res.data?['articles'] as List?) ?? const [];
      expect(articles, isNotEmpty,
          reason:
              'live backend must have ingested ≥1 article for the global '
              'feed — if zero, ingest cron may have stalled');
      // Sanity-check the shape so a backend schema drift fails here loudly
      // rather than crashing ArticleModel.fromJson at runtime on device.
      final first = articles.first as Map<String, dynamic>;
      expect(first.containsKey('id'), isTrue);
      expect(first.containsKey('title'), isTrue);
      expect(first.containsKey('url'), isTrue);
      expect(first.containsKey('published_at'), isTrue);
    });

    test('/api/articles?region=poland returns the Polish slice', () async {
      // The exact filter the user hit while reporting "no news on
      // Polish". With localhost-default builds this returned nothing
      // (because no request even reached a backend). Against the live
      // HF Space it must return ≥1 article — Polish coverage is sparse
      // but non-zero in the seed catalogue.
      final res = await client.dio.get<Map<String, dynamic>>(
        '/api/articles',
        queryParameters: const {'region': 'poland', 'limit': 20},
      );
      final articles = (res.data?['articles'] as List?) ?? const [];
      expect(
        articles,
        isNotEmpty,
        reason: 'region=poland should have at least one article — '
            'if zero, the Polish source feeds may all be dead. Verify '
            'with `curl /api/articles?region=poland` against the live '
            'backend before diving into the frontend.',
      );
      // Every returned article must self-tag region=poland — guards
      // against the backend ignoring the filter and silently returning
      // the global slice.
      for (final raw in articles) {
        final a = raw as Map<String, dynamic>;
        expect(
          a['region'],
          'poland',
          reason: 'every article in the region=poland response must '
              'carry region=poland — got ${a['region']} for "${a['title']}"',
        );
      }
    });

    test('/api/feeds returns the configured source list', () async {
      final res = await client.dio.get<Map<String, dynamic>>('/api/feeds');
      final feeds = (res.data?['feeds'] as List?) ?? const [];
      expect(feeds, isNotEmpty,
          reason:
              '/api/feeds must list the configured RSS sources — empty '
              'response means the catalogue table is missing from the '
              'live SQLite (ephemeral HF storage may have reset).');
    });
  });
}

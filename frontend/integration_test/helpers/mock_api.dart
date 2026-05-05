import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Tiny in-process Dio adapter that intercepts HTTP requests and
/// replays canned responses keyed by URL substring. Lets integration
/// tests run against a stable, deterministic API surface without
/// hitting the live backend (which is on a different network, may be
/// rate-limited, and would make tests flake).
///
/// Usage:
/// ```dart
/// final mock = MockApi()
///   ..onGetMatching('/api/articles', json: {
///     'articles': [<canned article>],
///     'total': 1,
///     'page': 1,
///     'has_more': false,
///   })
///   ..onGetMatching('/api/races', json: {'races': []});
///
/// // Pre-register a Dio with the mock adapter, then call app.main().
/// final dio = Dio()..httpClientAdapter = mock;
/// getIt.registerSingleton<ApiClient>(ApiClient.testWith(dio));
/// ```
///
/// The adapter matches by `request.uri.path.contains(pattern)` so
/// callers don't have to spell out exact query strings. First match
/// wins; register more-specific patterns first.
class MockApi implements HttpClientAdapter {
  final List<_Stub> _stubs = [];
  final List<RequestOptions> requestLog = [];

  /// Stub a GET request whose URI path contains [pattern]. Body returned
  /// as JSON-serialised [json].
  void onGetMatching(
    String pattern, {
    required Map<String, dynamic> json,
    int statusCode = 200,
  }) {
    _stubs.add(_Stub(
      method: 'GET',
      pattern: pattern,
      body: jsonEncode(json),
      statusCode: statusCode,
    ));
  }

  /// Stub a request that should fail with [error]. Used to test the
  /// frontend's error-state rendering — the `_ErrorState` widget on
  /// FeedPage, the `_errorState` on CalendarPage, and so on.
  void onGetMatchingFails(
    String pattern, {
    int statusCode = 500,
    String body = 'internal server error',
  }) {
    _stubs.add(_Stub(
      method: 'GET',
      pattern: pattern,
      body: body,
      statusCode: statusCode,
    ));
  }

  /// Empty fallback: any URL not explicitly stubbed returns `{}` with
  /// 200. Prevents tests from accidentally hitting the live network
  /// when a code path makes an unexpected request.
  void onAnyGet({Map<String, dynamic>? json}) {
    _stubs.add(_Stub(
      method: 'GET',
      pattern: '',
      body: jsonEncode(json ?? <String, dynamic>{}),
      statusCode: 200,
      isFallback: true,
    ));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestLog.add(options);
    final method = options.method.toUpperCase();
    final path = options.uri.path;
    final query = options.uri.query;
    final fullPath = query.isEmpty ? path : '$path?$query';

    // Walk stubs in registration order. Non-fallbacks first, then
    // fallback. We sort here rather than at registration so callers
    // get the natural "specific then generic" insertion order.
    final ordered = [..._stubs]
      ..sort((a, b) => (a.isFallback ? 1 : 0).compareTo(b.isFallback ? 1 : 0));

    for (final stub in ordered) {
      if (stub.method != method) continue;
      if (stub.pattern.isNotEmpty && !fullPath.contains(stub.pattern)) {
        continue;
      }
      final bytes = utf8.encode(stub.body);
      return ResponseBody.fromBytes(
        bytes,
        stub.statusCode,
        headers: const {
          'content-type': ['application/json; charset=utf-8'],
        },
      );
    }

    // No stub matched — return a 404 so the test sees a clear failure
    // mode instead of mysterious null bodies.
    return ResponseBody.fromString(
      '{"error": "MockApi: no stub for $method $fullPath"}',
      404,
      headers: const {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {
    // Nothing to close.
  }
}

class _Stub {
  final String method;
  final String pattern;
  final String body;
  final int statusCode;
  final bool isFallback;
  _Stub({
    required this.method,
    required this.pattern,
    required this.body,
    required this.statusCode,
    this.isFallback = false,
  });
}

/// Canned article JSON shape mirroring the live `/api/articles` payload.
/// Keep in sync with `ArticleModel.fromJson`.
Map<String, dynamic> stubArticle({
  required int id,
  String title = 'Pogačar wins stage 5',
  String? description = 'Slovenian solos to victory in the mountains.',
  String url = 'https://example.com/article',
  String? imageUrl,
  String publishedAt = '2026-05-04T12:00:00+00:00',
  String? region = 'world',
  String? discipline = 'road',
  String? category = 'results',
  int feedId = 1,
  int clusterCount = 0,
}) =>
    {
      'id': id,
      'feed_id': feedId,
      'title': title,
      'description': description,
      'url': url,
      'image_url': imageUrl,
      'published_at': publishedAt,
      'fetched_at': publishedAt,
      'category': category,
      'region': region,
      'discipline': discipline,
      'language': 'en',
      'cluster_count': clusterCount,
    };

/// Canned articles-page envelope.
Map<String, dynamic> stubArticlesPage({
  required List<Map<String, dynamic>> articles,
  int? total,
  int page = 1,
  bool? hasMore,
}) =>
    {
      'articles': articles,
      'total': total ?? articles.length,
      'page': page,
      'has_more': hasMore ?? false,
    };

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around [Dio] that bakes in the API base URL and timeouts.
///
/// Override the base URL via `--dart-define=API_BASE_URL=https://...` at
/// build time. The default points at the **production** HF Space so a
/// plain `flutter run` on a real device "just works" against live data —
/// previously the default was `http://localhost:7860`, which on a phone
/// resolves to the phone itself and means every API call silently fails
/// (no articles, no filters, no calendar — the empty state for every
/// screen). That was caught only after a user reported "no news on
/// Android" while web was fine; we now also log the resolved URL on
/// boot so future regressions are loud.
///
/// Local backend dev:
///   - Android emulator → `--dart-define=API_BASE_URL=http://10.0.2.2:7860`
///   - Physical device  → `--dart-define=API_BASE_URL=http://<lan-ip>:7860`
///   - iOS simulator    → `--dart-define=API_BASE_URL=http://localhost:7860`
class ApiClient {
  static const String defaultBaseUrl =
      'https://michal-giza-bike-news-room.hf.space';

  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient.create() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultBaseUrl,
    );
    if (kDebugMode) {
      // Loud, single-line, deliberately easy to grep in `flutter run`
      // output and `adb logcat`. If you see `localhost` here on a
      // physical device, your build is missing a dart-define.
      // ignore: avoid_print
      print('[ApiClient] API_BASE_URL=$baseUrl');
    }
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
      responseType: ResponseType.json,
    ));
    return ApiClient._(dio);
  }

  /// Test-only constructor — wraps a pre-configured [Dio] (typically
  /// with a `MockApi` HttpClientAdapter) so integration tests can
  /// inject canned responses. Production code never calls this.
  factory ApiClient.testWith(Dio dio) => ApiClient._(dio);
}

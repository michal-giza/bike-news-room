import 'package:dio/dio.dart';

/// Thin wrapper around [Dio] that bakes in the API base URL and timeouts.
///
/// Set the base URL via `--dart-define=API_BASE_URL=https://...` at build time.
/// Defaults to `http://localhost:7860` for local development.
class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient.create() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:7860',
    );
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

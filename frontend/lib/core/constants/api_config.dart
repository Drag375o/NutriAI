/// Backend address.
///
/// For phone testing over wifi, replace localhost with your PC's LAN IP
/// (e.g. http://192.168.0.12:8000). Overridable at build time:
///   flutter run --dart-define=API_BASE_URL=http://192.168.0.12:8000
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiPrefix = '/api/v1';

  static String url(String path) => '$baseUrl$apiPrefix$path';

  /// Requests that outlive this are treated as failures. Generous enough
  /// for a slow connection, short enough that the UI is never stuck.
  static const Duration timeout = Duration(seconds: 20);
}
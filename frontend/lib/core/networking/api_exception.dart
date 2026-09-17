/// A failed API call, with a message fit for the screen.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetworkError = false});

  /// Plain language, already suitable for display.
  final String message;

  final int? statusCode;

  /// True when the server could not be reached at all, as opposed to
  /// reaching it and being refused. Different problem, different advice.
  final bool isNetworkError;

  factory ApiException.network() => const ApiException(
        'Could not reach NutriAI. Check that the server is running.',
        isNetworkError: true,
      );

  factory ApiException.timeout() => const ApiException(
        'The server took too long to respond. Try again.',
        isNetworkError: true,
      );

  @override
  String toString() => message;
}
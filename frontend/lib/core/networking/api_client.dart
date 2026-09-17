import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// The single path between Flutter and FastAPI.
class ApiClient {
  ApiClient({http.Client? client, TokenStore? tokens})
      : _http = client ?? http.Client(),
        _tokens = tokens ?? TokenStore();

  final http.Client _http;
  final TokenStore _tokens;

  /// Held in memory to avoid reading storage on every request.
  String? _token;

  String? get token => _token;

  Future<void> loadToken() async => _token = await _tokens.read();

  Future<void> setToken(String token) async {
    _token = token;
    await _tokens.write(token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _tokens.clear();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> get(String path) =>
      _send(() => _http.get(Uri.parse(ApiConfig.url(path)), headers: _headers));

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) =>
      _send(() => _http.post(
            Uri.parse(ApiConfig.url(path)),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          ));

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) =>
      _send(() => _http.patch(
            Uri.parse(ApiConfig.url(path)),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          ));

  /// Runs a request and normalises every outcome into either a decoded
  /// body or an ApiException carrying a readable message.
  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    late http.Response response;

    try {
      response = await request().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException.timeout();
    } catch (_) {
      // Connection refused, DNS failure, CORS rejection: from here they are
      // the same problem, and the same advice helps.
      throw ApiException.network();
    }

    if (response.statusCode == 204 || response.body.isEmpty) {
      return const {};
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        'The server sent something unexpected.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    throw ApiException(_messageFrom(decoded), statusCode: response.statusCode);
  }

  /// FastAPI puts a string in `detail` for raised errors, and a list of
  /// field problems there for validation failures. Both end up readable.
  String _messageFrom(Map<String, dynamic> body) {
    final detail = body['detail'];

    if (detail is String) return detail;

    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        return (first['msg'] as String).replaceFirst('Value error, ', '');
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
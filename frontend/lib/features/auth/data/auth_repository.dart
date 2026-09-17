import '../../../core/networking/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthUser> register({
    required String email,
    required String name,
    required String password,
  }) async {
    final body = await _api.post('/auth/register', body: {
      'email': email,
      'name': name,
      'password': password,
    });
    return _acceptSession(body);
  }

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final body = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _acceptSession(body);
  }

  /// Confirms a stored token is still valid, used at startup.
  Future<AuthUser> me() async {
    final body = await _api.get('/auth/me');
    return AuthUser.fromJson(body);
  }

  Future<void> logout() => _api.clearToken();

  /// Stores the token before returning, so the next call is authenticated.
  Future<AuthUser> _acceptSession(Map<String, dynamic> body) async {
    await _api.setToken(body['access_token'] as String);
    return AuthUser.fromJson(body['user'] as Map<String, dynamic>);
  }
}
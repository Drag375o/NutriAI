import '../../../core/networking/api_client.dart';

class AccountRepository {
  const AccountRepository(this._api);

  final ApiClient _api;

  Future<void> changePassword({
    required String current,
    required String replacement,
  }) =>
      _api.post('/auth/change-password', body: {
        'current_password': current,
        'new_password': replacement,
      });

  /// Pauses the account. The token dies immediately, so the caller must
  /// clear the session afterwards.
  Future<void> deactivate() => _api.post('/auth/deactivate');

  /// Permanent. The password proves the person at the keyboard is the
  /// account holder, not just that the browser is signed in.
  Future<void> deleteAccount(String password) =>
      _api.post('/auth/delete', body: {'password': password});
}
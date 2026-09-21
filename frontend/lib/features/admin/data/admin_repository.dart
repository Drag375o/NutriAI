import '../../../core/networking/api_client.dart';
import 'admin_models.dart';

class AdminRepository {
  const AdminRepository(this._api);

  final ApiClient _api;

  Future<AdminStats> stats() async {
    final body = await _api.get('/admin/stats');
    return AdminStats.fromJson(body);
  }

  Future<List<AdminUser>> users() async {
    final rows = await _api.getList('/admin/users');
    return rows
        .map((r) => AdminUser.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> setActive(int userId, bool active) =>
      _api.patch('/admin/users/$userId', body: {'is_active': active});

  /// Returns a password the administrator has just generated. The user's
  /// own password is never readable.
  Future<String> resetPassword(int userId) async {
    final body = await _api.post('/admin/users/$userId/reset-password');
    return body['temporary_password'] as String;
  }

  Future<void> deleteUser(int userId) => _api.delete('/admin/users/$userId');
}
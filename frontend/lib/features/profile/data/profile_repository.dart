import '../../../core/networking/api_client.dart';
import 'profile_models.dart';

class ProfileRepository {
  const ProfileRepository(this._api);

  final ApiClient _api;

  Future<Profile> fetch() async {
    final body = await _api.get('/profile');
    return Profile.fromJson(body);
  }

  /// Sends only the fields supplied. Anything omitted is left untouched
  /// server-side, so a partial save from one onboarding step cannot wipe
  /// data entered in another.
  Future<Profile> update(Map<String, dynamic> changes) async {
    final body = await _api.patch('/profile', body: changes);
    return Profile.fromJson(body);
  }
}
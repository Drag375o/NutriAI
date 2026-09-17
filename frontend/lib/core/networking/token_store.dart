import 'package:shared_preferences/shared_preferences.dart';

/// Persists the access token across restarts.
///
/// On web this is browser local storage, which is readable by scripts on
/// the same origin. Acceptable for a development build; a production
/// deployment would use an httpOnly cookie instead. Noted in decisions.md.
class TokenStore {
  static const _key = 'nutriai.access_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
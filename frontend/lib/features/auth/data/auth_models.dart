/// A signed-in account.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.mustChangePassword,
  });

  final int id;
  final String email;
  final String name;

  /// 'user' or 'admin'. Decides which part of the app is reachable.
  final String role;

  final bool mustChangePassword;

  bool get isAdmin => role == 'admin';

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? 'user',
        mustChangePassword: json['must_change_password'] as bool? ?? false,
      );
}
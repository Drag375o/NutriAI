/// One account as the panel sees it.
///
/// Mirrors the backend's AdminUserRow: activity counts, never contents.
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.deactivatedAt,
    this.lastLoginAt,
    this.conversationCount = 0,
    this.planCount = 0,
    this.weightEntryCount = 0,
    this.profileComplete = false,
  });

  final int id;
  final String email;
  final String name;
  final String role;

  /// False when an administrator has disabled the account.
  final bool isActive;

  /// Set when the account holder paused it themselves.
  final DateTime? deactivatedAt;

  final DateTime createdAt;
  final DateTime? lastLoginAt;

  final int conversationCount;
  final int planCount;
  final int weightEntryCount;
  final bool profileComplete;

  bool get isAdmin => role == 'admin';
  bool get isSelfDeactivated => deactivatedAt != null;

  /// One word for the row's status column.
  String get status {
    if (!isActive) return 'DISABLED';
    if (isSelfDeactivated) return 'PAUSED';
    return 'ACTIVE';
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as int,
        email: json['email'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        isActive: json['is_active'] as bool? ?? true,
        deactivatedAt: json['deactivated_at'] == null
            ? null
            : DateTime.parse(json['deactivated_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        lastLoginAt: json['last_login_at'] == null
            ? null
            : DateTime.parse(json['last_login_at'] as String),
        conversationCount: json['conversation_count'] as int? ?? 0,
        planCount: json['plan_count'] as int? ?? 0,
        weightEntryCount: json['weight_entry_count'] as int? ?? 0,
        profileComplete: json['profile_complete'] as bool? ?? false,
      );
}

class AdminStats {
  const AdminStats({
    this.totalUsers = 0,
    this.activeUsers = 0,
    this.deactivatedUsers = 0,
    this.disabledUsers = 0,
    this.admins = 0,
    this.signedInThisWeek = 0,
  });

  final int totalUsers;
  final int activeUsers;
  final int deactivatedUsers;
  final int disabledUsers;
  final int admins;
  final int signedInThisWeek;

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        totalUsers: json['total_users'] as int? ?? 0,
        activeUsers: json['active_users'] as int? ?? 0,
        deactivatedUsers: json['deactivated_users'] as int? ?? 0,
        disabledUsers: json['disabled_users'] as int? ?? 0,
        admins: json['admins'] as int? ?? 0,
        signedInThisWeek: json['signed_in_this_week'] as int? ?? 0,
      );
}
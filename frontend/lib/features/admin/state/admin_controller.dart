import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(apiClientProvider)),
);

final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  ref.watch(authControllerProvider);
  return ref.watch(adminRepositoryProvider).stats();
});

class AdminUsersController extends AsyncNotifier<List<AdminUser>> {
  @override
  Future<List<AdminUser>> build() {
    ref.watch(authControllerProvider);
    return ref.read(adminRepositoryProvider).users();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(adminRepositoryProvider).users());
    ref.invalidate(adminStatsProvider);
  }

  /// Each of these returns an error message rather than throwing, so the
  /// panel can report a failure inline.

  Future<String?> setActive(int userId, bool active) async {
    try {
      await ref.read(adminRepositoryProvider).setActive(userId, active);
      await _reload();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Returns the temporary password on success, or throws on failure.
  Future<String> resetPassword(int userId) async {
    final temporary =
        await ref.read(adminRepositoryProvider).resetPassword(userId);
    await _reload();
    return temporary;
  }

  Future<String?> deleteUser(int userId) async {
    try {
      await ref.read(adminRepositoryProvider).deleteUser(userId);
      await _reload();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).users(),
    );
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersController, List<AdminUser>>(
  AdminUsersController.new,
);
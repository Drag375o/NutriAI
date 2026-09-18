import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(apiClientProvider)),
);

/// The signed-in user's profile.
///
/// AsyncNotifier gives loading, error and data states without hand-rolling
/// them, which every screen reading this needs anyway.
class ProfileController extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() {
    // Rebuilds when the session changes, so signing in as someone else
    // cannot leave the previous user's profile on screen.
    ref.watch(authControllerProvider);
    return ref.read(profileRepositoryProvider).fetch();
  }

  /// Saves a partial update and keeps the returned profile as the new state.
  ///
  /// Returns the error message on failure rather than throwing, so a form
  /// can show it inline instead of wrapping every call in try/catch.
  Future<String?> save(Map<String, dynamic> changes) async {
    try {
      final updated = await ref.read(profileRepositoryProvider).update(changes);
      state = AsyncData(updated);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).fetch(),
    );
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, Profile>(ProfileController.new);
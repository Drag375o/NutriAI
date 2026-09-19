import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../../profile/state/profile_controller.dart';
import '../data/weight_models.dart';
import '../data/weight_repository.dart';

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => WeightRepository(ref.watch(apiClientProvider)),
);

/// Weight history and its summary.
///
/// Watches auth so the cache is dropped when the session changes: without
/// it, one user's history would stay on screen after another signs in.
class WeightController extends AsyncNotifier<WeightHistory> {
  @override
  Future<WeightHistory> build() {
    ref.watch(authControllerProvider);
    return ref.read(weightRepositoryProvider).history();
  }

  /// Records a weigh-in and reloads.
  ///
  /// Returns an error message on failure rather than throwing, so a form
  /// can show it inline.
  Future<String?> log({
    required double weightKg,
    DateTime? recordedOn,
    String? note,
  }) async {
    try {
      await ref.read(weightRepositoryProvider).log(
            weightKg: weightKg,
            recordedOn: recordedOn,
            note: note,
          );

      state = AsyncData(await ref.read(weightRepositoryProvider).history());

      // The backend copies the latest weight onto the profile, so BMI and
      // the calorie target have changed too.
      ref.invalidate(profileControllerProvider);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> delete(int entryId) async {
    await ref.read(weightRepositoryProvider).delete(entryId);
    state = AsyncData(await ref.read(weightRepositoryProvider).history());
    ref.invalidate(profileControllerProvider);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(weightRepositoryProvider).history(),
    );
  }
}

final weightControllerProvider =
    AsyncNotifierProvider<WeightController, WeightHistory>(
  WeightController.new,
);
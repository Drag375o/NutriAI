import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../../profile/state/profile_controller.dart';
import '../data/plan_models.dart';
import '../data/plan_repository.dart';

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepository(ref.watch(apiClientProvider)),
);

class PlanState {
  const PlanState({
    this.plan,
    this.loading = false,
    this.generating = false,
    this.error,
  });

  /// Null means no plan exists for today yet.
  final DietPlan? plan;

  final bool loading;

  /// Separate from [loading]: generating takes seconds and needs its own
  /// treatment, while loading is a quick fetch.
  final bool generating;

  final String? error;

  PlanState copyWith({
    DietPlan? plan,
    bool? loading,
    bool? generating,
    String? error,
  }) =>
      PlanState(
        plan: plan ?? this.plan,
        loading: loading ?? this.loading,
        generating: generating ?? this.generating,
        error: error,
      );
}

class PlanController extends Notifier<PlanState> {
  @override
  PlanState build() {
    // Rebuilds when the session changes, so one user's plan never stays on
    // screen for another.
    ref.watch(authControllerProvider);
    _load();
    return const PlanState(loading: true);
  }

  PlanRepository get _repo => ref.read(planRepositoryProvider);

  Future<void> _load() async {
    try {
      final plan = await _repo.today();
      state = PlanState(plan: plan);
    } catch (e) {
      state = PlanState(error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const PlanState(loading: true);
    await _load();
  }

  Future<void> generate({String? note}) async {
    // Keeps the existing plan visible while the new one is built, so the
    // screen does not empty out for several seconds.
    state = state.copyWith(generating: true, error: null);

    try {
      final plan = await _repo.generate(note: note);
      state = PlanState(plan: plan);

      // The calorie target may have been recalculated server-side.
      ref.invalidate(profileControllerProvider);
    } catch (e) {
      state = state.copyWith(generating: false, error: e.toString());
    }
  }

  Future<void> deleteToday() async {
    final current = state.plan;
    if (current == null) return;

    await _repo.delete(current.id);
    state = const PlanState();
  }
}

final planControllerProvider =
    NotifierProvider<PlanController, PlanState>(PlanController.new);
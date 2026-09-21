import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../auth/state/auth_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/state/profile_controller.dart';

import '../../coach/state/chat_controller.dart';
import '../../coach/widgets/suggestion_chips.dart';

import '../../plan/data/plan_models.dart';
import '../../plan/state/plan_controller.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final profile = ref.watch(profileControllerProvider);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Two columns only when there is room for both to stay readable.
          final wide = constraints.maxWidth >= 900;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              _Greeting(name: name),
              const SizedBox(height: AppSpacing.xl),

              profile.when(
                loading: () => const _MetricsPlaceholder(),
                error: (e, _) => _Notice(
                  message: 'Could not load your numbers. $e',
                  actionLabel: 'Try again',
                  onAction: () =>
                      ref.read(profileControllerProvider.notifier).refresh(),
                ),
                data: (data) => data.bmi == null
                    ? _Notice(
                        message: 'Add your height, weight and goal, and '
                            'NutriAI can start tailoring its advice.',
                        actionLabel: 'Set up my profile',
                        onAction: () => context.go('/onboarding'),
                      )
                    : _MetricsBand(profile: data),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              if (wide)
                const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _PlanSection()),
                      SizedBox(width: AppSpacing.xxl),
                      Expanded(flex: 2, child: _CoachSection()),
                    ],
                  ),
                )
              else ...[
                const _PlanSection(),
                const SizedBox(height: AppSpacing.xxxl),
                const _CoachSection(),
              ],

              const SizedBox(height: AppSpacing.huge),
            ],
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------- greeting

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(now).toUpperCase(),
          style: AppTypography.mono(color: p.muted, size: 11),
        ),
        const SizedBox(height: AppSpacing.md),

        // Greeting plain, name in script — the personal detail gets the
        // warmer face.
        Text(
          '${_partOfDay(now.hour)},',
          style: text.headlineMedium,
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Text(
            name.isEmpty ? 'there' : name,
            style: AppTypography.script(color: p.turmericText, size: 46),
          ),
        ),
      ],
    );
  }

  static String _partOfDay(int hour) {
    if (hour < 5) return 'Still up';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

// --------------------------------------------------------------- metrics

class _MetricsBand extends StatelessWidget {
  const _MetricsBand({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.hair),
          bottom: BorderSide(color: p.hair),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Metric(
              first: true,
              label: 'WEIGHT',
              value: profile.weightKg?.toStringAsFixed(1) ?? '—',
              unit: 'kg',
              note: _weightNote(profile),
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Metric(
              label: 'BMI',
              value: profile.bmi!.value.toStringAsFixed(1),
              note: _categoryLabel(profile.bmi!.category),
              noteColour: _categoryColour(profile.bmi!.category, context),
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Metric(
              label: 'DAILY',
              value: profile.dailyCalories?.toString() ?? '—',
              unit: 'kcal',
              note: ProfileOptions.goals[profile.goal]?.toLowerCase(),
            ),
          ],
        ),
      ),
    );
  }

  /// Distance to the target, or nothing if no target was set. Deliberately
  /// factual: no encouragement, no judgement about the number itself.
  static String? _weightNote(Profile profile) {
    final current = profile.weightKg;
    final target = profile.targetWeightKg;
    if (current == null || target == null) return null;

    final diff = (current - target).abs();
    if (diff < 0.1) return 'at your target';
    return '${diff.toStringAsFixed(1)} kg to target';
  }

  static String _categoryLabel(String category) => switch (category) {
        'underweight' => 'below typical range',
        'healthy' => 'typical range',
        'overweight' => 'above typical range',
        _ => 'well above typical range',
      };

  static Color _categoryColour(String category, BuildContext context) {
    final p = context.palette;
    return switch (category) {
      'healthy' => p.sage,
      'underweight' || 'overweight' => p.turmericText,
      _ => p.brick,
    };
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.noteColour,
    this.first = false,
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final Color? noteColour;

  /// The leftmost metric aligns with the page margin rather than being
  /// indented, so the band lines up with the heading above it.
  final bool first;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
          left: first ? 0 : AppSpacing.lg,
          right: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.mono(color: p.muted, size: 10.5)),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: AppTypography.metric(p.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(unit!,
                      style: AppTypography.mono(color: p.muted, size: 13)),
                ],
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: noteColour ?? p.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Keeps the band's height while the profile loads, so the page does not
/// jump when data arrives.
class _MetricsPlaceholder extends StatelessWidget {
  const _MetricsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      height: 96,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: p.hair),
          bottom: BorderSide(color: p.hair),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          minHeight: 2,
          backgroundColor: p.clay,
          color: p.ember,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- sections

class _PlanSection extends ConsumerWidget {
  const _PlanSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final plan = ref.watch(planControllerProvider).plan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("TODAY'S PLAN",
                style: AppTypography.mono(color: p.muted, size: 11)),
            const Spacer(),
            if (plan != null)
              TextButton(
                onPressed: () => context.go('/plan'),
                child: const Text('Open'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (plan == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              border: Border.all(color: p.hair),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No plan for today yet', style: text.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'NutriAI can build a day around your calorie target, your '
                  'goal, and the food you actually eat.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/plan'),
                  child: const Text('Build my day'),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: p.hair),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The meals themselves, one line each: enough to know what
                // is coming without opening the full plan.
                for (final meal in plan.meals)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            meal.timeHint ?? MealSlots.label(meal.slot),
                            style: AppTypography.mono(color: p.muted, size: 11),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            meal.name,
                            style: text.bodyMedium?.copyWith(color: p.ink),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${meal.calories}',
                          style: AppTypography.mono(color: p.char, size: 12),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: p.linen,
                    border: Border(top: BorderSide(color: p.hair)),
                  ),
                  child: Row(
                    children: [
                      Text('TOTAL',
                          style: AppTypography.mono(color: p.muted, size: 10.5)),
                      const Spacer(),
                      Text(
                        '${plan.totalCalories} of ${plan.targetCalories} kcal',
                        style: AppTypography.mono(color: p.ink, size: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}




class _CoachSection extends ConsumerWidget {
  const _CoachSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ASK NUTRIAI',
            style: AppTypography.mono(color: p.muted, size: 11)),
        const SizedBox(height: AppSpacing.md),
        // Tapping one opens the coach with that question already sent, so
        // the dashboard is an entry point rather than a description of one.
        SuggestionChips(
          limit: 3,
          onSelected: (question) {
            ref.read(chatControllerProvider.notifier).startNew();
            ref.read(chatControllerProvider.notifier).send(question);
            context.go('/coach');
          },
        ),
      ],
    );
  }
}




/// An inline message with one action. Used for both the loading failure and
/// the incomplete-profile prompt, which need the same shape.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.linen,
        border: Border(left: BorderSide(color: p.turmeric, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
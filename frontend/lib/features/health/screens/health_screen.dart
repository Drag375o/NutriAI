import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/state/profile_controller.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          title: 'Could not load your health information',
          body: e.toString(),
          actionLabel: 'Try again',
          onAction: () => ref.read(profileControllerProvider.notifier).refresh(),
        ),
        data: (data) {
          if (data.bmi == null) {
            return _Message(
              title: 'Nothing to show yet',
              body: 'Add your height and weight and NutriAI can work out your '
                  'BMI and a daily calorie target.',
              actionLabel: 'Add my details',
              onAction: () => context.go('/onboarding'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              Text('Health', style: text.displayMedium),
              const SizedBox(height: AppSpacing.xxl),

              Container(
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
                        label: 'BMI',
                        value: data.bmi!.value.toStringAsFixed(1),
                        note: _categoryLabel(data.bmi!.category),
                        noteColour: _categoryColour(data.bmi!.category, context),
                      ),
                      VerticalDivider(color: p.hair, width: 1),
                      _Metric(
                        label: 'WEIGHT',
                        value: data.weightKg?.toStringAsFixed(1) ?? '—',
                        unit: 'kg',
                        note: data.targetWeightKg != null
                            ? 'target ${data.targetWeightKg!.toStringAsFixed(1)}'
                            : null,
                      ),
                      VerticalDivider(color: p.hair, width: 1),
                      _Metric(
                        label: 'DAILY',
                        value: data.dailyCalories?.toString() ?? '—',
                        unit: 'kcal',
                        note: _goalLabel(data.goal),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Text(data.bmi!.note, style: text.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              // BMI ignores muscle mass, body composition, age and ethnicity.
              // Saying so is more honest than presenting it as a verdict.
              Text(
                'BMI is one rough signal among many. It does not account for '
                'muscle, body composition, or your medical history. A doctor '
                'can give you a fuller picture.',
                style: text.bodySmall,
              ),

              const SizedBox(height: AppSpacing.xxxl),
              Text('YOUR DETAILS',
                  style: AppTypography.mono(color: p.muted, size: 11)),
              const SizedBox(height: AppSpacing.md),

              _Row('Age', data.age?.toString()),
              _Row('Sex', ProfileOptions.sexes[data.sex]),
              _Row('Height', _formatHeight(data.heightCm)),
              _Row('Activity', ProfileOptions.activityLevels[data.activityLevel]),
              _Row('Goal', ProfileOptions.goals[data.goal]),
              _Row('Diet', ProfileOptions.dietPreferences[data.dietPreference]),
              _Row('Allergies', data.allergies),

              const SizedBox(height: AppSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: () => context.go('/onboarding'),
                  child: const Text('Update my details'),
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
            ],
          );
        },
      ),
    );
  }

  /// Shows both systems, since the entry unit is a personal preference but
  /// the stored value is always centimetres.
  static String? _formatHeight(double? cm) {
    if (cm == null) return null;
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return '${cm.toStringAsFixed(0)} cm  ·  $feet ft $inches in';
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

  static String? _goalLabel(String? goal) => switch (goal) {
        'lose' => 'with a deficit',
        'gain' => 'with a surplus',
        'maintain' => 'to maintain',
        _ => null,
      };
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
        // Space on both sides of every divider, except at the page edge.
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: text.bodyMedium)),
          Expanded(
            child: Text(
              value ?? 'Not set',
              style: text.bodyLarge?.copyWith(
                color: value == null ? p.muted : p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              Text(body, style: text.bodyLarge),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}
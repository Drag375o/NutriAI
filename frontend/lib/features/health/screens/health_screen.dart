import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/page_body.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/state/profile_controller.dart';
import '../../progress/widgets/log_weight_sheet.dart';
import '../widgets/edit_field_sheet.dart';

class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return profile.when(
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

        return SplitBody(
          header: [
            Text('Health', style: text.displayMedium),
            const SizedBox(height: AppSpacing.xxl),
            _MetricsBand(profile: data),
            const SizedBox(height: AppSpacing.xl),
            Text(data.bmi!.note, style: text.bodyLarge),
            const SizedBox(height: AppSpacing.sm),
            // BMI ignores muscle mass, body composition, age and ethnicity.
            // Saying so is more honest than presenting it as a verdict.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                'BMI is one rough signal among many. It does not account for '
                'muscle, body composition, or your medical history. A doctor '
                'can give you a fuller picture.',
                style: text.bodySmall,
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],

          // What changes week to week.
          left: [
            Text('TRACKING',
                style: AppTypography.mono(color: p.muted, size: 11)),
            const SizedBox(height: AppSpacing.sm),
            _EditRow(
              label: 'Current weight',
              value: data.weightKg == null
                  ? null
                  : '${data.weightKg!.toStringAsFixed(1)} kg',
              onTap: () => showLogWeightSheet(
                context,
                currentWeight: data.weightKg,
              ),
            ),
            _EditRow(
              label: 'Target weight',
              value: data.targetWeightKg == null
                  ? null
                  : '${data.targetWeightKg!.toStringAsFixed(1)} kg',
              onTap: () => showNumberSheet(
                context,
                title: 'Target weight',
                field: 'target_weight_kg',
                label: 'Target',
                unit: 'kg',
                helper: 'What you are working towards. Change it any time as '
                    'your goal shifts.',
                initial: data.targetWeightKg,
              ),
            ),
            _EditRow(
              label: 'Goal',
              value: ProfileOptions.goals[data.goal],
              onTap: () => showChoiceSheet(
                context,
                title: 'Your goal',
                field: 'goal',
                options: ProfileOptions.goals,
                initial: data.goal,
                helper: 'This shapes your calorie target and every meal '
                    'suggestion.',
              ),
            ),
            _EditRow(
              label: 'Activity level',
              value: ProfileOptions.activityLevels[data.activityLevel],
              onTap: () => showChoiceSheet(
                context,
                title: 'How active are you?',
                field: 'activity_level',
                options: ProfileOptions.activityLevels,
                hints: ProfileOptions.activityHints,
                initial: data.activityLevel,
                helper: 'Used to work out how much energy you need.',
              ),
            ),
          ],

          // What rarely changes.
          right: [
            Text('ABOUT YOU',
                style: AppTypography.mono(color: p.muted, size: 11)),
            const SizedBox(height: AppSpacing.sm),
            _EditRow(
              label: 'Age',
              value: data.age?.toString(),
              onTap: () => showNumberSheet(
                context,
                title: 'Your age',
                field: 'age',
                label: 'Age',
                unit: 'years',
                initial: data.age?.toDouble(),
              ),
            ),
            _EditRow(
              label: 'Sex',
              value: ProfileOptions.sexes[data.sex],
              onTap: () => showChoiceSheet(
                context,
                title: 'Sex',
                field: 'sex',
                options: ProfileOptions.sexes,
                initial: data.sex,
                helper: 'Used in the formula that estimates how much energy '
                    'your body uses at rest.',
              ),
            ),
            _EditRow(
              label: 'Height',
              value: _formatHeight(data.heightCm),
              onTap: () => showNumberSheet(
                context,
                title: 'Your height',
                field: 'height_cm',
                label: 'Height',
                unit: 'cm',
                initial: data.heightCm,
                dualUnit: true,
              ),
            ),
            _EditRow(
              label: 'Diet',
              value: ProfileOptions.dietPreferences[data.dietPreference],
              onTap: () => showChoiceSheet(
                context,
                title: 'Dietary preference',
                field: 'diet_preference',
                options: ProfileOptions.dietPreferences,
                initial: data.dietPreference,
              ),
            ),
            _EditRow(
              label: 'Allergies',
              value: data.allergies,
              onTap: () => _editAllergies(context, ref, data.allergies),
            ),
          ],
        );
      },
    );
  }

  /// Allergies are free text rather than a choice, so they get a small
  /// dialog rather than reusing the number or choice sheets.
  Future<void> _editAllergies(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final p = context.palette;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.hair),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        title: Text(
          'Allergies and foods to avoid',
          style: TextStyle(
            color: p.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Sized explicitly: AlertDialog shrink-wraps its content, and a
        // multiline field left to itself renders cramped against the title.
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Everything NutriAI suggests will avoid these.',
                style: TextStyle(color: p.char, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. prawns, peanuts, dairy',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.char),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.emberText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ref
          .read(profileControllerProvider.notifier)
          .save({'allergies': controller.text.trim()});
    }
    controller.dispose();
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
}

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
              label: 'BMI',
              value: profile.bmi!.value.toStringAsFixed(1),
              note: _categoryLabel(profile.bmi!.category),
              noteColour: _categoryColour(profile.bmi!.category, context),
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Metric(
              label: 'WEIGHT',
              value: profile.weightKg?.toStringAsFixed(1) ?? '—',
              unit: 'kg',
              note: profile.targetWeightKg != null
                  ? 'target ${profile.targetWeightKg!.toStringAsFixed(1)}'
                  : null,
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Metric(
              label: 'DAILY',
              value: profile.dailyCalories?.toString() ?? '—',
              unit: 'kcal',
              note: _goalLabel(profile.goal),
            ),
          ],
        ),
      ),
    );
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

/// A tappable row showing a value, or "Not set" when it is missing.
class _EditRow extends StatelessWidget {
  const _EditRow({required this.label, required this.value, this.onTap});

  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.hair)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              child: Text(label, style: text.bodyMedium),
            ),
            Expanded(
              child: Text(
                value?.isNotEmpty == true ? value! : 'Not set',
                style: text.bodyLarge?.copyWith(
                  color: value?.isNotEmpty == true ? p.ink : p.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 18, color: p.muted),
          ],
        ),
      ),
    );
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
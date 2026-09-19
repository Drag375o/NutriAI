import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../data/plan_models.dart';

class MealRow extends StatelessWidget {
  const MealRow({super.key, required this.meal});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot and time in a fixed column, so meals align down the page.
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MealSlots.label(meal.slot).toUpperCase(),
                  style: AppTypography.mono(color: p.char, size: 10.5),
                ),
                if (meal.timeHint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meal.timeHint!,
                    style: AppTypography.mono(color: p.muted, size: 11),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name, style: text.bodyLarge),
                if (meal.portion != null) ...[
                  const SizedBox(height: 2),
                  Text(meal.portion!, style: text.bodySmall),
                ],
                if (_macros(meal).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _macros(meal),
                    style: AppTypography.mono(color: p.muted, size: 11.5),
                  ),
                ],
                if (meal.substitution != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: p.turmericText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          meal.substitution!,
                          style: text.bodySmall?.copyWith(color: p.char),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          // Calories right-aligned so the column reads as a running tally.
          Text(
            '${meal.calories}',
            style: AppTypography.mono(
              color: p.ink,
              size: 16,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Macros as one compact line, omitting anything the model left out.
  static String _macros(Meal meal) {
    final parts = <String>[];
    if (meal.proteinG != null) parts.add('P ${meal.proteinG!.round()}g');
    if (meal.carbsG != null) parts.add('C ${meal.carbsG!.round()}g');
    if (meal.fatG != null) parts.add('F ${meal.fatG!.round()}g');
    return parts.join('   ');
  }
}
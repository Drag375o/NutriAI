import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/chat_controller.dart';

/// Tappable opening questions.
///
/// Renders nothing while loading or on failure: a suggestion is a
/// convenience, and a spinner or an error where one was expected is worse
/// than an absence nobody noticed.
class SuggestionChips extends ConsumerWidget {
  const SuggestionChips({super.key, required this.onSelected, this.limit});

  final ValueChanged<String> onSelected;

  /// Cap on how many to show. Null shows everything returned.
  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(suggestionsProvider);

    return suggestions.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final shown = limit == null ? items : items.take(limit!).toList();

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final question in shown)
              _Chip(label: question, onTap: () => onSelected(question)),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        // 44 keeps the tap target usable on a phone.
        constraints: const BoxConstraints(minHeight: 44, maxWidth: 420),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: p.hair),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(color: p.ink),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(Icons.north_east, size: 14, color: p.turmericText),
          ],
        ),
      ),
    );
  }
}
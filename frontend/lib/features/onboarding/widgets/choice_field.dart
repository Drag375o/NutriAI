import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';

/// Single-select list. Rows rather than chips, so long labels and hints
/// fit without truncation at any width.
class ChoiceField<T> extends StatelessWidget {
  const ChoiceField({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hints = const {},
  });

  /// Value to display label.
  final Map<T, String> options;

  final T? value;
  final ValueChanged<T> onChanged;

  /// Optional secondary line per option.
  final Map<T, String> hints;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in options.entries)
          Semantics(
            selected: entry.key == value,
            button: true,
            child: InkWell(
              onTap: () => onChanged(entry.key),
              child: Container(
                // 56 keeps every row above the 48dp touch target minimum.
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: entry.key == value ? p.linen : Colors.transparent,
                  border: Border.all(
                    color: entry.key == value ? p.ember : p.hair,
                    width: entry.key == value
                        ? AppBorders.mark
                        : AppBorders.hairline,
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style: text.bodyLarge?.copyWith(
                              fontWeight: entry.key == value
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (hints[entry.key] != null) ...[
                            const SizedBox(height: 2),
                            Text(hints[entry.key]!, style: text.bodySmall),
                          ],
                        ],
                      ),
                    ),
                    // Selection is marked by shape and weight as well as
                    // colour, so it does not depend on colour alone.
                    if (entry.key == value)
                      Icon(Icons.check, size: 18, color: p.ember),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
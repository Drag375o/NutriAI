import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';

/// Stand-in for a screen not yet built.
///
/// Written as a real empty state rather than "coming soon", so the copy
/// carries over when the feature lands.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.message,
    this.phase,
  });

  final String title;

  /// What this screen will do, in the user's language.
  final String message;

  /// Development note, e.g. 'PHASE 5'. Removed before release.
  final String? phase;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phase != null)
                  Text(
                    phase!,
                    style: AppTypography.mono(color: p.muted, size: 11),
                  ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: text.displayMedium),
                const SizedBox(height: AppSpacing.lg),
                Text(message, style: text.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
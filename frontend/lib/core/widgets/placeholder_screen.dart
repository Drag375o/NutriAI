import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import '../../features/auth/state/auth_controller.dart';

/// Stand-in for a screen not yet built.
///
/// Written as a real empty state rather than "coming soon", so the copy
/// carries over when the feature lands.
class PlaceholderScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;

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

                // Temporary, until the Profile screen exists in Phase 9.
                if (user != null) ...[
                  const SizedBox(height: AppSpacing.xxxl),
                  Divider(color: p.hair),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Signed in as ${user.name}',
                          style: text.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
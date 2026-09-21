import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';

/// Shown for an address that does not exist.
///
/// Replaces PlaceholderScreen, which existed while screens were still
/// being built and had no remaining use once they all were.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Page not found', style: text.displayMedium),
                const SizedBox(height: AppSpacing.md),
                Text('That address does not exist.', style: text.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => context.go('/today'),
                  child: const Text('Back to Today'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
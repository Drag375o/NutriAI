import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';

/// Shared chrome for an onboarding step.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    this.onBack,
    this.onSkip,
    this.nextLabel = 'Continue',
    this.busy = false,
    this.error,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;

  /// Null disables the button, which is how a step marks itself incomplete.
  final VoidCallback? onNext;

  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final String nextLabel;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: p.paper,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'STEP $step OF $totalSteps',
                              style: AppTypography.mono(
                                color: p.muted,
                                size: 11,
                              ),
                            ),
                            const Spacer(),
                            if (onSkip != null)
                              TextButton(
                                onPressed: busy ? null : onSkip,
                                child: const Text('Skip for now'),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Progress as filled segments rather than a bar:
                        // it shows how many steps remain, not just a ratio.
                        Row(
                          children: [
                            for (var i = 1; i <= totalSteps; i++) ...[
                              Expanded(
                                child: Container(
                                  height: 3,
                                  color: i <= step ? p.ember : p.clay,
                                ),
                              ),
                              if (i < totalSteps)
                                const SizedBox(width: AppSpacing.xs),
                            ],
                          ],
                        ),

                        const SizedBox(height: AppSpacing.xxl),
                        Text(title, style: text.displayMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(subtitle, style: text.bodyLarge),
                        const SizedBox(height: AppSpacing.xxl),

                        child,

                        if (error != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: p.linen,
                              border: Border(
                                left: BorderSide(color: p.brick, width: 2),
                              ),
                            ),
                            child: Text(error!, style: text.bodyMedium),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions stay pinned so the primary control is always
                // reachable without scrolling.
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: p.hair)),
                  ),
                  child: Row(
                    children: [
                      if (onBack != null)
                        OutlinedButton(
                          onPressed: busy ? null : onBack,
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: busy ? null : onNext,
                        child: busy
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: p.onAccent,
                                ),
                              )
                            : Text(nextLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
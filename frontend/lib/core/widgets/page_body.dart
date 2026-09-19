import 'package:flutter/material.dart';

import '../../app/theme/spacing.dart';

/// The standard content column.
///
/// Fills the pane up to [AppBreakpoints.contentMax] and stops there. An
/// unbounded column looks generous on a laptop and unreadable on a wide
/// monitor, where a line of text runs past comfortable reading length and
/// a row's label and value drift to opposite ends of the screen.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        // Aligned left rather than centred: the navigation rail is on the
        // left, and content drifting away from it on a wide screen breaks
        // the connection between the two.
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.contentMax,
          ),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Two columns above [AppBreakpoints.twoColumn], stacked below it.
///
/// Used where a screen has two distinct groups that would otherwise run
/// down the page as one long list.
class SplitBody extends StatelessWidget {
  const SplitBody({
    super.key,
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
    this.header = const [],
  });

  /// Rows shown full width above both columns.
  final List<Widget> header;

  final List<Widget> left;
  final List<Widget> right;
  final int leftFlex;
  final int rightFlex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.contentMax,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.twoColumn;

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                children: [
                  ...header,
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: leftFlex,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: left,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxxl),
                        Expanded(
                          flex: rightFlex,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: right,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ...left,
                    const SizedBox(height: AppSpacing.xxxl),
                    ...right,
                  ],
                  const SizedBox(height: AppSpacing.huge),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
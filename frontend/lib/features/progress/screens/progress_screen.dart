import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../data/weight_models.dart';
import '../state/weight_controller.dart';
import '../widgets/log_weight_sheet.dart';
import '../widgets/weight_chart.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(weightControllerProvider);
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(
          title: 'Could not load your progress',
          body: e.toString(),
          actionLabel: 'Try again',
          onAction: () => ref.read(weightControllerProvider.notifier).refresh(),
        ),
        data: (data) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text('Progress', style: text.displayMedium),
                    ),
                    ElevatedButton(
                      onPressed: () => showLogWeightSheet(
                        context,
                        currentWeight: data.trend.latest,
                      ),
                      child: const Text('Record weight'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                if (!data.trend.hasHistory)
                  const _EmptyState()
                else ...[
                  _TrendBand(trend: data.trend),
                  const SizedBox(height: AppSpacing.xxl),
                  WeightChart(
                    entries: data.entries,
                    target: data.trend.target,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Text('HISTORY',
                      style: AppTypography.mono(color: p.muted, size: 11)),
                  const SizedBox(height: AppSpacing.sm),
                  // Newest first here, the reverse of the chart, because a
                  // list is read from the top and a chart from the left.
                  for (final entry in data.entries.reversed)
                    _HistoryRow(entry: entry),
                ],

                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- trend

class _TrendBand extends StatelessWidget {
  const _TrendBand({required this.trend});

  final WeightTrend trend;

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
            _Figure(
              first: true,
              label: 'NOW',
              value: trend.latest?.toStringAsFixed(1) ?? '—',
              unit: 'kg',
              note: trend.latestOn == null
                  ? null
                  : _relativeDay(trend.latestOn!),
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Figure(
              label: 'CHANGE',
              value: _signed(trend.totalChange),
              unit: trend.totalChange == null ? null : 'kg',
              note: trend.startingOn == null
                  ? null
                  : 'since ${_formatDate(trend.startingOn!)}',
            ),
            VerticalDivider(color: p.hair, width: 1),
            _Figure(
              label: 'TARGET',
              value: trend.target?.toStringAsFixed(1) ?? '—',
              unit: trend.target == null ? null : 'kg',
              note: trend.toTarget == null
                  ? 'not set'
                  : '${trend.toTarget!.toStringAsFixed(1)} kg to go',
              noteColour: trend.toTarget != null && trend.toTarget! < 0.5
                  ? p.sage
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Signed, so a loss reads as a loss without needing a colour to say so.
  static String _signed(double? value) {
    if (value == null) return '—';
    if (value == 0) return '0.0';
    return value > 0
        ? '+${value.toStringAsFixed(1)}'
        : value.toStringAsFixed(1);
  }

  static String _relativeDay(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    return _formatDate(d);
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
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

// --------------------------------------------------------------- history

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.hair)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              _formatDate(entry.recordedOn),
              style: AppTypography.mono(color: p.char, size: 11.5),
            ),
          ),
          Expanded(
            child: Text(
              entry.note ?? '',
              style: text.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.weightKg.toStringAsFixed(1)} kg',
            style: AppTypography.mono(color: p.ink, size: 13),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 15, color: p.muted),
            tooltip: 'Delete this entry',
            onPressed: () =>
                ref.read(weightControllerProvider.notifier).delete(entry.id),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year % 100}';
  }
}

// ---------------------------------------------------------------- states

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nothing recorded yet', style: text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Record your weight to see how it moves over time, against the '
            'goal you set. Two entries are enough to draw a line.',
            style: text.bodyMedium,
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
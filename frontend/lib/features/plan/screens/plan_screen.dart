import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../auth/state/auth_controller.dart';
import '../data/plan_models.dart';
import '../state/plan_controller.dart';
import '../widgets/meal_row.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _note = TextEditingController();
  bool _noteOpen = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _generate() {
    ref.read(planControllerProvider.notifier).generate(note: _note.text);
    setState(() => _noteOpen = false);
  }

  /// Opens the PDF endpoint as a plain navigation, which is how a browser
  /// download works. The token rides in the query string because a
  /// navigation cannot carry an Authorization header.
  Future<void> _download() async {
    final plan = ref.read(planControllerProvider).plan;
    final token = ref.read(apiClientProvider).token;
    if (plan == null || token == null) return;

    final url = ref.read(planRepositoryProvider).pdfUrl(plan.id);
    await launchUrl(Uri.parse('$url?token=$token'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planControllerProvider);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              _Header(
                plan: state.plan,
                generating: state.generating,
                noteOpen: _noteOpen,
                noteController: _note,
                onToggleNote: () => setState(() => _noteOpen = !_noteOpen),
                onGenerate: _generate,
                onDownload: _download,
              ),

              if (state.error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorNotice(message: state.error!),
              ],

              const SizedBox(height: AppSpacing.xxl),

              if (state.generating && state.plan == null)
                const _Generating()
              else if (state.plan == null)
                const _EmptyState()
              else
                _PlanBody(plan: state.plan!, dimmed: state.generating),

              const SizedBox(height: AppSpacing.huge),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({
    required this.plan,
    required this.generating,
    required this.noteOpen,
    required this.noteController,
    required this.onToggleNote,
    required this.onGenerate,
    required this.onDownload,
  });

  final DietPlan? plan;
  final bool generating;
  final bool noteOpen;
  final TextEditingController noteController;
  final VoidCallback onToggleNote;
  final VoidCallback onGenerate;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatDate(DateTime.now()).toUpperCase(),
          style: AppTypography.mono(color: p.muted, size: 11),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Your plan', style: text.displayMedium),
        const SizedBox(height: AppSpacing.xl),

        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: generating ? null : onGenerate,
              child: generating
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.onAccent,
                      ),
                    )
                  : Text(plan == null ? 'Build my day' : 'Build a new day'),
            ),
            TextButton(
              onPressed: generating ? null : onToggleNote,
              child: Text(noteOpen ? 'Hide note' : 'Add a note'),
            ),
            // Only offered once there is something to export.
            if (plan != null)
              TextButton(
                onPressed: generating ? null : onDownload,
                child: const Text('Download PDF'),
              ),
          ],
        ),

        if (noteOpen) ...[
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: noteController,
            maxLines: 2,
            style: text.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Anything to steer it',
              hintText:
                  'e.g. something quick, no fish, I only have rice and eggs',
            ),
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}';
  }
}

// ------------------------------------------------------------------ body

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan, required this.dimmed});

  final DietPlan plan;

  /// True while a replacement is generating, so the old plan stays visible
  /// but visibly stale.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  _Total(
                    first: true,
                    label: 'PLANNED',
                    value: '${plan.totalCalories}',
                    unit: 'kcal',
                    note: _deltaNote(plan),
                    noteColour: _deltaColour(plan, context),
                  ),
                  VerticalDivider(color: p.hair, width: 1),
                  _Total(
                    label: 'TARGET',
                    value: '${plan.targetCalories}',
                    unit: 'kcal',
                  ),
                  VerticalDivider(color: p.hair, width: 1),
                  _Total(
                    label: 'PROTEIN',
                    value: '${plan.totalProteinG.round()}',
                    unit: 'g',
                  ),
                ],
              ),
            ),
          ),

          if (plan.rationale != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(plan.rationale!, style: text.bodyLarge),
          ],

          const SizedBox(height: AppSpacing.xxl),
          Text('MEALS', style: AppTypography.mono(color: p.muted, size: 11)),
          const SizedBox(height: AppSpacing.sm),

          for (final meal in plan.meals) MealRow(meal: meal),

          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.hair)),
            ),
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              'Portions are a starting point, not a prescription. Adjust to '
              'what is available and how hungry you are.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// How far the plan lands from target, stated factually.
  static String? _deltaNote(DietPlan plan) {
    final delta = plan.calorieDelta;
    if (delta.abs() < 25) return 'on target';
    return delta > 0 ? '$delta over target' : '${delta.abs()} under target';
  }

  static Color? _deltaColour(DietPlan plan, BuildContext context) {
    final p = context.palette;
    return plan.calorieDelta.abs() < 150 ? p.sage : p.turmericText;
  }
}

class _Total extends StatelessWidget {
  const _Total({
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
          Text('No plan for today yet', style: text.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'NutriAI will build a day around your calorie target, your goal, '
            'and the food you actually eat. Add a note first if there is '
            'anything it should know.',
            style: text.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Shown while the first plan generates. No percentage, since we cannot
/// know how far along the model is.
class _Generating extends StatelessWidget {
  const _Generating();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: p.clay,
            color: p.ember,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Building your day…', style: text.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Text('This takes a few seconds.', style: text.bodySmall),
      ],
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.linen,
        border: Border(left: BorderSide(color: p.brick, width: 2)),
      ),
      child: Text(message, style: text.bodyMedium),
    );
  }
}
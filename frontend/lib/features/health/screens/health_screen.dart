import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/state/profile_controller.dart';
import '../../progress/widgets/log_weight_sheet.dart';
import '../widgets/edit_field_sheet.dart';
import '../widgets/prescription_sheet.dart';


/// Health, laid out as a bento grid.
///
/// Every value gets its own tile. Columns derive from available width and
/// row height from available height, so the grid fills the pane on a
/// desktop and reflows to a single scrolling column on a phone.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  /// Below this a tile is unreadable at more than one per row.
  static const _minTileWidth = 212.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _Message(
        title: 'Could not load your health information',
        body: e.toString(),
        actionLabel: 'Try again',
        onAction: () => ref.read(profileControllerProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.bmi == null) {
          return _Message(
            title: 'Nothing to show yet',
            body: 'Add your height and weight and NutriAI can work out your '
                'BMI and a daily calorie target.',
            actionLabel: 'Add my details',
            onAction: () => context.go('/onboarding'),
          );
        }
        return _Grid(profile: data, minTileWidth: _minTileWidth);
      },
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.profile, required this.minTileWidth});

  final Profile profile;
  final double minTileWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth - (AppSpacing.xxl * 2);
          final columns = (available / minTileWidth).floor().clamp(1, 4);

          final pattern = _patternFor(columns);

          // How many grid rows the pattern produces, so the height can be
          // divided between them rather than being a fixed guess.
          final rows = _rowsFor(pattern, columns);

          // Height left for the grid once the heading and padding are gone.
          const headingHeight = 72.0;
          const verticalPadding = AppSpacing.xxl * 2;
          final gaps = AppSpacing.md * (rows - 1);
          final forGrid =
              constraints.maxHeight - headingHeight - verticalPadding - gaps;

          // Scaled to fill the viewport, but bounded: below the floor a
          // tile cannot hold a value, a unit and a note without clipping,
          // and above the ceiling a single number floats in absurd space.
          final rowHeight = (forGrid / rows).clamp(112.0, 260.0);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Text('Health', style: text.displayMedium),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  0,
                  AppSpacing.xxl,
                  AppSpacing.xxl,
                ),
                sliver: SliverGrid(
                  gridDelegate: _QuiltDelegate(
                    crossAxisCount: columns,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    rowHeight: rowHeight,
                    pattern: pattern,
                  ),
                  delegate:
                      SliverChildListDelegate(_tiles(context, ref, columns)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Runs the same placement the delegate does, to find the grid's depth.
  ///
  /// Duplicated rather than shared because the delegate needs the row
  /// height that this result determines, so one has to come first.
  static int _rowsFor(List<_Span> pattern, int columns) {
    final tops = List<int>.filled(columns, 0);
    var deepest = 0;

    for (final span in pattern) {
      final width = span.columns.clamp(1, columns);
      var bestRow = 1 << 30;
      var bestColumn = 0;

      for (var c = 0; c + width <= columns; c++) {
        final row = tops.sublist(c, c + width).reduce((a, b) => a > b ? a : b);
        if (row < bestRow) {
          bestRow = row;
          bestColumn = c;
        }
      }

      for (var c = bestColumn; c < bestColumn + width; c++) {
        tops[c] = bestRow + span.rows;
      }
      if (bestRow + span.rows > deepest) deepest = bestRow + span.rows;
    }

    return deepest;
  }

  /// Tile spans per column count.
  ///
  /// Order here is placement order and must match the order [_tiles]
  /// returns, since the quilt fills the first position with room.
  /// Tile spans per column count.
  ///
  /// Order here is placement order and must match the order [_tiles]
  /// returns, since the quilt fills the first position with room.
  List<_Span> _patternFor(int columns) => switch (columns) {
        4 => const [
            _Span(2, 2), // BMI hero
            _Span(1, 1), // Weight
            _Span(1, 1), // Daily
            _Span(1, 1), // Target
            _Span(1, 1), // Goal
            _Span(2, 1), // Caveat
            _Span(1, 1), // Sex
            _Span(1, 1), // Height
            _Span(1, 1), // Activity
            _Span(1, 1), // Age
            _Span(2, 1), // Diet
            _Span(2, 1), // Allergies
            _Span(2, 1), // Conditions
          ],
        3 => const [
            _Span(2, 2), // BMI hero
            _Span(1, 1), // Weight
            _Span(1, 1), // Daily
            _Span(1, 1), // Target
            _Span(1, 1), // Goal
            _Span(1, 1), // Sex
            _Span(3, 1), // Caveat
            _Span(1, 1), // Height
            _Span(1, 1), // Activity
            _Span(1, 1), // Age
            _Span(1, 1), // Diet
            _Span(2, 1), // Allergies
            _Span(3, 1), // Conditions
          ],
        2 => const [
            _Span(2, 2),
            _Span(1, 1),
            _Span(1, 1),
            _Span(1, 1),
            _Span(1, 1),
            _Span(2, 1),
            _Span(1, 1),
            _Span(1, 1),
            _Span(1, 1),
            _Span(1, 1),
            _Span(2, 1),
            _Span(2, 1),
            _Span(2, 1),
          ],
        // One column: everything stacks. The caveat moves directly under
        // the hero here, so it sits beside the number it explains.
        _ => const [
            _Span(1, 2), // BMI hero
            _Span(1, 1), // Caveat
            _Span(1, 1), // Weight
            _Span(1, 1), // Daily
            _Span(1, 1), // Target
            _Span(1, 1), // Goal
            _Span(1, 1), // Sex
            _Span(1, 1), // Height
            _Span(1, 1), // Activity
            _Span(1, 1), // Age
            _Span(1, 1), // Diet
            _Span(1, 1), // Allergies
            _Span(1, 1), // Conditions
          ],
      };

  List<Widget> _tiles(BuildContext context, WidgetRef ref, int columns) {
    final p = context.palette;

    // The hero. Clay rather than ink: a solid black tile on a near-black
    // background reads as a hole rather than an anchor.
    final hero = _Tile(
      fill: p.clay,
      child: _BmiHero(profile: profile),
    );

    final caveat = _Tile(
      fill: p.linen,
      child: _Caveat(note: profile.bmi!.note),
    );

    final weight = _Tile(
      fill: p.linen,
      onTap: () => showLogWeightSheet(
        context,
        currentWeight: profile.weightKg,
      ),
      child: _Value(
        icon: Icons.monitor_weight_outlined,
        label: 'WEIGHT',
        value: profile.weightKg?.toStringAsFixed(1) ?? '—',
        unit: 'kg',
        tappable: true,
      ),
    );

    final daily = _Tile(
      child: _Value(
        icon: Icons.local_fire_department_outlined,
        label: 'DAILY',
        value: profile.dailyCalories?.toString() ?? '—',
        unit: 'kcal',
        note: _goalLabel(profile.goal),
        accent: p.turmericText,
      ),
    );

    final target = _Tile(
      onTap: () => showNumberSheet(
        context,
        title: 'Target weight',
        field: 'target_weight_kg',
        label: 'Target',
        unit: 'kg',
        helper: 'What you are working towards. Change it any time as your '
            'goal shifts.',
        initial: profile.targetWeightKg,
      ),
      child: _Value(
        icon: Icons.flag_outlined,
        label: 'TARGET',
        value: profile.targetWeightKg?.toStringAsFixed(1) ?? '—',
        unit: 'kg',
        tappable: true,
      ),
    );

    final goal = _Tile(
      fill: p.linen,
      onTap: () => showChoiceSheet(
        context,
        title: 'Your goal',
        field: 'goal',
        options: ProfileOptions.goals,
        initial: profile.goal,
        helper: 'This shapes your calorie target and every meal suggestion.',
      ),
      child: _Value(
        icon: Icons.adjust_outlined,
        label: 'GOAL',
        text: ProfileOptions.goals[profile.goal],
        tappable: true,
      ),
    );

    final sex = _Tile(
      onTap: () => showChoiceSheet(
        context,
        title: 'Sex',
        field: 'sex',
        options: ProfileOptions.sexes,
        initial: profile.sex,
        helper: 'Used in the formula that estimates how much energy your '
            'body uses at rest.',
      ),
      child: _Value(
        icon: Icons.person_outline,
        label: 'SEX',
        text: ProfileOptions.sexes[profile.sex],
        tappable: true,
      ),
    );

    final height = _Tile(
      fill: p.linen,
      onTap: () => showNumberSheet(
        context,
        title: 'Your height',
        field: 'height_cm',
        label: 'Height',
        unit: 'cm',
        initial: profile.heightCm,
        dualUnit: true,
      ),
      child: _Value(
        icon: Icons.straighten_outlined,
        label: 'HEIGHT',
        value: profile.heightCm?.toStringAsFixed(0) ?? '—',
        unit: 'cm',
        note: _feetInches(profile.heightCm),
        tappable: true,
      ),
    );

    final activity = _Tile(
      onTap: () => showChoiceSheet(
        context,
        title: 'How active are you?',
        field: 'activity_level',
        options: ProfileOptions.activityLevels,
        hints: ProfileOptions.activityHints,
        initial: profile.activityLevel,
        helper: 'Used to work out how much energy you need.',
      ),
      child: _Value(
        icon: Icons.directions_walk_outlined,
        label: 'ACTIVITY',
        text: ProfileOptions.activityLevels[profile.activityLevel],
        tappable: true,
      ),
    );

    final age = _Tile(
      fill: p.linen,
      onTap: () => showNumberSheet(
        context,
        title: 'Your age',
        field: 'age',
        label: 'Age',
        unit: 'years',
        initial: profile.age?.toDouble(),
      ),
      child: _Value(
        icon: Icons.cake_outlined,
        label: 'AGE',
        value: profile.age?.toString() ?? '—',
        unit: 'yrs',
        tappable: true,
      ),
    );

    final diet = _Tile(
      fill: p.linen,
      onTap: () => showChoiceSheet(
        context,
        title: 'Dietary preference',
        field: 'diet_preference',
        options: ProfileOptions.dietPreferences,
        initial: profile.dietPreference,
      ),
      child: _Value(
        icon: Icons.restaurant_outlined,
        label: 'DIET',
        text: ProfileOptions.dietPreferences[profile.dietPreference],
        tappable: true,
      ),
    );

    final allergies = _Tile(
      onTap: () => _editAllergies(context, ref, profile.allergies),
      child: _Value(
        icon: Icons.block_outlined,
        label: 'ALLERGIES AND FOODS TO AVOID',
        text: profile.allergies,
        accent: p.brick,
        tappable: true,
      ),
    );

    // Filled in by hand, or read from a prescription photograph. Only the
    // conditions are stored: the image is processed in memory and the
    // medication on it is deliberately not kept.
    final conditions = _Tile(
      fill: p.linen,
      onTap: () => showPrescriptionSheet(
        context,
        currentConditions: profile.conditions,
      ),
      child: _Value(
        icon: Icons.medical_information_outlined,
        label: 'HEALTH CONDITIONS',
        text: profile.conditions,
        tappable: true,
      ),
    );


    // On one column tiles appear in exactly this order, so the caveat is
    // moved up to sit directly beneath the number it explains. With more
    // columns it belongs in its own band further down.
    if (columns == 1) {
      return [
        hero,
        caveat,
        weight,
        daily,
        target,
        goal,
        sex,
        height,
        activity,
        age,
        diet,
        allergies,
        conditions,
      ];
    }

    return [
      hero,
      weight,
      daily,
      target,
      goal,
      caveat,
      sex,
      height,
      activity,
      age,
      diet,
      allergies,
      conditions,
    ];
  }

  static String? _goalLabel(String? goal) => switch (goal) {
        'lose' => 'with a deficit',
        'gain' => 'with a surplus',
        'maintain' => 'to maintain',
        _ => null,
      };

  /// Shown alongside centimetres, since the stored unit is metric but the
  /// one people think in varies.
  static String? _feetInches(double? cm) {
    if (cm == null) return null;
    final total = cm / 2.54;
    return '${total ~/ 12} ft ${(total % 12).round()} in';
  }

  Future<void> _editAllergies(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final p = context.palette;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: p.paper,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.hair),
          borderRadius: BorderRadius.circular(AppRadii.tile),
        ),
        title: Text(
          'Allergies and foods to avoid',
          style: TextStyle(
            color: p.ink,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Sized explicitly: AlertDialog shrink-wraps its content, and a
        // multiline field left to itself renders cramped against the title.
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Everything NutriAI suggests will avoid these.',
                style: TextStyle(color: p.char, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                // Grows from one line to three as needed, rather than
                // reserving three and leaving the text floating at the top.
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'e.g. prawns, peanuts, dairy',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.char),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: p.emberText),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ref
          .read(profileControllerProvider.notifier)
          .save({'allergies': controller.text.trim()});
    }
    controller.dispose();
  }
}


// ----------------------------------------------------------------- tiles

/// One bento cell.
///
/// Rounded and raised rather than hairlined, which is a deliberate
/// departure from the rest of the app while this layout is being tried.
///
/// Tappable tiles lift on hover: the fill brightens, the shadow deepens,
/// and the whole tile rises a little, so the affordance belongs to the
/// tile rather than to a control inside it.
class _Tile extends StatefulWidget {
  const _Tile({required this.child, this.fill, this.onTap});

  final Widget child;
  final Color? fill;
  final VoidCallback? onTap;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = p.brightness == Brightness.dark;
    final interactive = widget.onTap != null;

    final base = widget.fill ?? p.linen.withValues(alpha: dark ? 0.55 : 0.5);

    // Hover lightens in dark mode and darkens in light, so the change reads
    // as "raised" in both rather than always going one direction.
    final hoverFill = dark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.05), base)
        : Color.alphaBlend(Colors.black.withValues(alpha: 0.035), base);

    final lifted = interactive && _hovered && !_pressed;

    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      // Pressing settles the tile back down, so a click feels like a push.
      transform: Matrix4.translationValues(0, lifted ? -2 : 0, 0),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _hovered && interactive ? hoverFill : base,
        borderRadius: BorderRadius.circular(AppRadii.tile),
        // A faint edge keeps tiles legible where the shadow alone is not
        // enough to separate them from the background.
        border: Border.all(
          color: p.hair.withValues(
            alpha: lifted ? (dark ? 0.6 : 0.9) : (dark ? 0.35 : 0.6),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: lifted ? (dark ? 0.5 : 0.12) : (dark ? 0.32 : 0.06),
            ),
            blurRadius: lifted ? 22 : 16,
            offset: Offset(0, lifted ? 7 : 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (!interactive) return tile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: tile,
      ),
    );
  }
}

class _BmiHero extends StatelessWidget {
  const _BmiHero({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bmi = profile.bmi!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.monitor_heart_outlined, size: 16, color: p.muted),
            const SizedBox(width: AppSpacing.sm),
            Text('BODY MASS INDEX',
                style: AppTypography.mono(color: p.muted, size: 10.5)),
          ],
        ),
        // Centred in the space below the label, matching the other tiles.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  bmi.value.toStringAsFixed(1),
                  style: AppTypography.mono(
                    color: p.ink,
                    size: 52,
                    weight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _categoryLabel(bmi.category),
                style: TextStyle(
                  color: _categoryColour(bmi.category, context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // A band showing where this value sits, so the number has context
        // without needing a chart. Pinned to the foot of the tile.
        _BmiScale(value: bmi.value),
      ],
    );
  }

  static String _categoryLabel(String category) => switch (category) {
        'underweight' => 'Below the typical range',
        'healthy' => 'Within the typical range',
        'overweight' => 'Above the typical range',
        _ => 'Well above the typical range',
      };

  static Color _categoryColour(String category, BuildContext context) {
    final p = context.palette;
    return switch (category) {
      'healthy' => p.sage,
      'underweight' || 'overweight' => p.turmericText,
      _ => p.brick,
    };
  }
}


/// A scale from 15 to 40 with a marker at the current value.
class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Clamped so an extreme value still renders inside the tile.
    final position = ((value - 15) / 25).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: 16,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: p.hair,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Positioned(
              left: (constraints.maxWidth - 3) * position,
              bottom: 0,
              child: Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                  color: p.turmeric,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One value in its own tile.
///
/// Takes either a [value] with a [unit], for numbers, or [text] for a
/// label. The tile itself handles the tap; [tappable] only controls the
/// chevron.
class _Value extends StatelessWidget {
  const _Value({
    required this.icon,
    required this.label,
    this.value,
    this.unit,
    this.text,
    this.note,
    this.accent,
    this.tappable = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? unit;
  final String? text;
  final String? note;
  final Color? accent;
  final bool tappable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final theme = Theme.of(context).textTheme;
    final empty = value == null && (text == null || text!.isEmpty);


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: p.muted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.mono(color: p.muted, size: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (tappable)
              Icon(Icons.chevron_right, size: 15, color: p.muted),
          ],
        ),
        // Centred in the space below the label, so tiles of different
        // heights read as one family rather than a ragged baseline.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (value != null)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value!,
                        style: AppTypography.metric(empty ? p.muted : p.ink),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(unit!,
                          style: AppTypography.mono(color: p.muted, size: 12)),
                    ],
                  ],
                )
              else
                Text(
                  text?.isNotEmpty == true ? text! : 'Not set',
                  style: theme.titleLarge?.copyWith(
                    color: empty ? p.muted : (accent ?? p.ink),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(
                  note!,
                  style: theme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );


  }
}

class _Caveat extends StatelessWidget {
  const _Caveat({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: p.turmericText),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(note, style: text.bodyMedium?.copyWith(color: p.ink)),
              const SizedBox(height: 2),
              // BMI ignores muscle mass, body composition, age and ethnicity.
              Flexible(
                child: Text(
                  'One rough signal. It does not account for muscle, body '
                  'composition, or your medical history.',
                  style: text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ grid

/// How many columns and rows a tile occupies.
class _Span {
  const _Span(this.columns, this.rows);
  final int columns;
  final int rows;
}

/// Lays out tiles of varying span against a fixed row height.
///
/// Flutter has no built-in quilted grid, and the packages that provide one
/// bring their own layout opinions. This places each tile in the first
/// position with room, which is all a bento grid needs.
class _QuiltDelegate extends SliverGridDelegate {
  const _QuiltDelegate({
    required this.crossAxisCount,
    required this.pattern,
    required this.rowHeight,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  });

  final int crossAxisCount;
  final List<_Span> pattern;
  final double rowHeight;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final columnWidth =
        (constraints.crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1)) /
            crossAxisCount;

    final geometries = <SliverGridGeometry>[];

    // Next free row per column, so a tile drops into the first place it
    // fits rather than leaving a gap beneath a shorter neighbour.
    final columnTops = List<int>.filled(crossAxisCount, 0);
    var maxRow = 0;

    for (final span in pattern) {
      final width = span.columns.clamp(1, crossAxisCount);

      var bestColumn = 0;
      var bestRow = 1 << 30;

      for (var c = 0; c + width <= crossAxisCount; c++) {
        final row =
            columnTops.sublist(c, c + width).reduce((a, b) => a > b ? a : b);
        if (row < bestRow) {
          bestRow = row;
          bestColumn = c;
        }
      }

      geometries.add(
        SliverGridGeometry(
          scrollOffset: bestRow * (rowHeight + mainAxisSpacing),
          crossAxisOffset: bestColumn * (columnWidth + crossAxisSpacing),
          mainAxisExtent:
              span.rows * rowHeight + (span.rows - 1) * mainAxisSpacing,
          crossAxisExtent: width * columnWidth + (width - 1) * crossAxisSpacing,
        ),
      );

      for (var c = bestColumn; c < bestColumn + width; c++) {
        columnTops[c] = bestRow + span.rows;
      }
      if (bestRow + span.rows > maxRow) maxRow = bestRow + span.rows;
    }

    return _QuiltLayout(
      geometries: geometries,
      totalExtent: maxRow * (rowHeight + mainAxisSpacing),
    );
  }

  @override
  bool shouldRelayout(_QuiltDelegate old) =>
      old.crossAxisCount != crossAxisCount ||
      old.rowHeight != rowHeight ||
      old.pattern != pattern;
}

class _QuiltLayout extends SliverGridLayout {
  const _QuiltLayout({required this.geometries, required this.totalExtent});

  final List<SliverGridGeometry> geometries;
  final double totalExtent;

  @override
  double computeMaxScrollOffset(int childCount) => totalExtent;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) => 0;

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) =>
      geometries.length - 1;

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) =>
      geometries[index.clamp(0, geometries.length - 1)];
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
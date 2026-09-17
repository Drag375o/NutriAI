import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'app/theme/colors.dart';
import 'app/theme/spacing.dart';
import 'app/theme/typography.dart';

void main() => runApp(const NutriAIApp());

class NutriAIApp extends StatefulWidget {
  const NutriAIApp({super.key});

  @override
  State<NutriAIApp> createState() => _NutriAIAppState();
}

class _NutriAIAppState extends State<NutriAIApp> {
  ThemeMode _mode = ThemeMode.light;

  void _toggle() => setState(() {
        _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: ThemePreviewScreen(onToggleTheme: _toggle),
    );
  }
}

class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isDark = p.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              children: [
                Row(
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Nutri'),
                          TextSpan(
                            text: 'AI',
                            style: TextStyle(
                              color: p.turmericText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      style: text.headlineMedium,
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: onToggleTheme,
                      child: Text(isDark ? 'Light mode' : 'Dark mode'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                Divider(color: p.hair),
                const SizedBox(height: AppSpacing.xxl),
                Text('A quieter way to eat well.', style: text.displayMedium),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Design system check. If the colours, type and cut corners '
                  'below look right in both themes, every screen we build from '
                  'here inherits them automatically.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _Label('PALETTE'),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _Swatch('Paper', p.paper, p),
                    _Swatch('Linen', p.linen, p),
                    _Swatch('Clay', p.clay, p),
                    _Swatch('Ink', p.ink, p),
                    _Swatch('Turmeric', p.turmeric, p),
                    _Swatch('Ember', p.ember, p),
                    _Swatch('Sage', p.sage, p),
                    _Swatch('Brick', p.brick, p),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _Label('TYPE'),
                const SizedBox(height: AppSpacing.lg),
                Text("Today's plate", style: text.displayLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('Weight and BMI', style: text.headlineLarge),
                const SizedBox(height: AppSpacing.sm),
                Text('Dinner suggestions', style: text.headlineMedium),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Rice with dal and grilled rui keeps you close to your '
                  'protein target without going over on carbs tonight.',
                  style: text.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '71.4 kg · BMI 23.1 · 1,840 kcal',
                  style: AppTypography.mono(color: p.char),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _Label('METRICS'),
                const SizedBox(height: AppSpacing.lg),
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
                        _Metric('WEIGHT', '71.4', 'kg', '−0.6 this week',
                            p.sage, p),
                        VerticalDivider(color: p.hair, width: 1),
                        _Metric('BMI', '23.1', null, 'healthy range', p.sage, p),
                        VerticalDivider(color: p.hair, width: 1),
                        _Metric('PROTEIN', '64', 'g', '28 g to go',
                            p.turmericText, p),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                const _Label('CONTROLS'),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Generate plan'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Edit profile'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 320,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Current weight',
                      hintText: 'e.g. 71.4 kg',
                    ),
                    style: text.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.mono(color: context.palette.muted, size: 11),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.palette);
  final String name;
  final Color color;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: palette.hair),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
    this.label,
    this.value,
    this.unit,
    this.delta,
    this.deltaColor,
    this.palette,
  );

  final String label;
  final String value;
  final String? unit;
  final String delta;
  final Color deltaColor;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg)
            .copyWith(right: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.mono(color: palette.muted, size: 10.5),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppTypography.metric(palette.ink)),
                if (unit != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    unit!,
                    style: AppTypography.mono(color: palette.muted, size: 13),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              delta,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: deltaColor),
            ),
          ],
        ),
      ),
    );
  }
}
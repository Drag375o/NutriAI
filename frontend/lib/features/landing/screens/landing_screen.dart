import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/typography.dart';
import '../widgets/particle_field.dart';

/// The signed-out front page.
///
/// Type-led rather than image-led: the claims here are about handling
/// health data carefully, and a stock photograph of a salad would
/// undercut that. Structure comes from hairline rules, as everywhere
/// else in the application.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.paper,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Masthead(),
                  _Hero(wide: wide),
                  const _Features(),
                  const _Claims(),
                  const _Footer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- masthead

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hair)),
      ),
      child: Row(
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
            style: text.titleLarge,
          ),
          if (wide) ...[
            const SizedBox(width: AppSpacing.lg),
            Container(width: 1, height: 18, color: p.hair),
            const SizedBox(width: AppSpacing.lg),
            Text(
              'NUTRITION AND HEALTH',
              style: AppTypography.mono(color: p.muted, size: 10.5),
            ),
          ],
          const Spacer(),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ hero





class _Hero extends StatelessWidget {
  const _Hero({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'EAT WELL, ON YOUR TERMS',
          style: AppTypography.mono(color: p.muted, size: 11),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Nutri'),
              TextSpan(text: 'AI', style: TextStyle(color: p.turmericText)),
            ],
          ),
          style: (wide ? text.displayLarge : text.displayMedium)?.copyWith(
            height: 1.0,
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        Text(
          'Your food. Your goals. Your data.',
          style: text.bodyLarge?.copyWith(fontSize: 19, color: p.char),
        ),

        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            'NutriAI works out what your body needs, builds a day of meals '
            'around it, and answers questions about food using the profile '
            'you control. Nothing is sold, shared, or advertised against.',
            style: text.bodyMedium,
          ),
        ),

        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Get started'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/login'),
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ],
    );

    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: wide ? AppSpacing.huge : AppSpacing.xxxl,
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: copy),
                const SizedBox(width: AppSpacing.huge),
                const Expanded(flex: 4, child: _SamplePanel()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.xxxl),
                const _SamplePanel(),
              ],
            ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hair)),
      ),
      child: Stack(
        children: [
          // Behind the content, and ignoring pointer events except its own
          // hover, so the buttons on top stay clickable.
          const Positioned.fill(child: ParticleField()),
          body,
        ],
      ),
    );
  }
}








/// A specimen of what the app actually shows, rather than a photograph.
///
/// Built from the same components the dashboard uses, so it cannot drift
/// out of date the way a screenshot would.
/// 
/// 
/// 

class _SamplePanel extends StatelessWidget {
  const _SamplePanel();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: p.linen,
        border: Border.all(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('A TYPICAL DAY',
              style: AppTypography.mono(color: p.muted, size: 10.5)),
          const SizedBox(height: AppSpacing.lg),

          // No dividers between the figures: spacing alone separates them,
          // and a rule that has to stretch to an intrinsic height reads as
          // a mistake more often than as structure.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Figure(label: 'BMI', value: '22.4', note: 'typical range'),
              _Figure(label: 'DAILY', value: '2094', unit: 'kcal'),
              _Figure(label: 'TO GO', value: '4.0', unit: 'kg'),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          Text('TODAY', style: AppTypography.mono(color: p.muted, size: 10.5)),
          const SizedBox(height: AppSpacing.sm),

          for (final meal in const [
            ('BREAKFAST', 'Oats with banana and peanut butter', '420'),
            ('LUNCH', 'Chicken and rice with vegetables', '640'),
            ('SNACK', 'Yoghurt and almonds', '280'),
            ('DINNER', 'Grilled fish, potatoes, greens', '590'),
          ])
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.hair)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    child: Text(
                      meal.$1,
                      style: AppTypography.mono(color: p.muted, size: 9.5),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meal.$2,
                      style: text.bodySmall?.copyWith(color: p.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    meal.$3,
                    style: AppTypography.mono(color: p.char, size: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.unit,
    this.note,
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.mono(color: p.muted, size: 9.5)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: AppTypography.mono(
                      color: p.ink,
                      size: 22,
                      weight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(unit!,
                      style: AppTypography.mono(color: p.muted, size: 10.5)),
                ],
              ],
            ),
            if (note != null)
              Text(
                note!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11, color: p.sage),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- features

class _Features extends StatelessWidget {
  const _Features();

  static const _items = [
    (
      Icons.chat_bubble_outline,
      'COACH',
      'Ask about portions, swaps, or what to eat tonight. The answer knows '
          'your goal and your allergies.',
    ),
    (
      Icons.restaurant_outlined,
      'PLAN',
      'A day of meals built to your calorie target, in food you actually '
          'eat. Downloadable as a PDF.',
    ),
    (
      Icons.trending_down,
      'PROGRESS',
      'Record your weight and watch it move against the goal you set, not '
          'against anybody else.',
    ),
    (
      Icons.favorite_border,
      'HEALTH',
      'BMI and a daily calorie target from your own measurements, with the '
          'limitations stated.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.hair)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Four across on a desktop, two on a tablet, one on a phone.
          final columns = constraints.maxWidth >= 1000
              ? 4
              : constraints.maxWidth >= 600
                  ? 2
                  : 1;

          return Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.xxl,
            children: [
              for (final item in _items)
                SizedBox(
                  width: (constraints.maxWidth -
                          (AppSpacing.xl * (columns - 1))) /
                      columns,
                  child: _Feature(
                    icon: item.$1,
                    label: item.$2,
                    body: item.$3,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: p.turmericText),
            const SizedBox(width: AppSpacing.sm),
            Text(label, style: AppTypography.mono(color: p.muted, size: 10.5)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(body, style: text.bodyMedium),
      ],
    );
  }
}

// ---------------------------------------------------------------- claims

/// What the product does and does not do with health data.
///
/// Stated on the front page rather than in a policy, because a claim
/// nobody reads is not a commitment.
class _Claims extends StatelessWidget {
  const _Claims();

  static const _items = [
    ('YOUR DATA', 'Stored in a database on the machine running NutriAI.'),
    ('NO ADVERTISING', 'Nothing is sold, shared, or advertised against.'),
    ('LEAVE ANY TIME', 'Delete your account and everything goes with it.'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: p.linen,
        border: Border(bottom: BorderSide(color: p.hair)),
      ),
      child: Wrap(
        spacing: AppSpacing.huge,
        runSpacing: AppSpacing.xl,
        children: [
          for (final item in _items)
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.$1,
                      style: AppTypography.mono(color: p.muted, size: 10)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(item.$2, style: text.bodyMedium?.copyWith(color: p.ink)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The disclaimer sits on the front page, not buried behind a
          // link: someone deciding whether to sign up should see it.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'NutriAI gives general nutrition and wellness guidance. It is '
              'not a medical device, and no substitute for a doctor or a '
              'registered dietitian.',
              style: text.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'NUTRIAI',
            style: AppTypography.mono(color: p.muted, size: 10),
          ),
        ],
      ),
    );
  }
}
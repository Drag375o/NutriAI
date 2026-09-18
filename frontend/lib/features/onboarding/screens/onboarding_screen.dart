import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../auth/state/auth_controller.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/state/profile_controller.dart';
import '../widgets/choice_field.dart';
import '../widgets/onboarding_scaffold.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 4;

  int _step = 1;
  bool _busy = false;
  String? _error;

  final _age = TextEditingController();
  final _height = TextEditingController();
  final _feet = TextEditingController();
  final _inches = TextEditingController();
  final _weight = TextEditingController();
  final _targetWeight = TextEditingController();
  final _allergies = TextEditingController();

  String? _sex;
  String? _activity;
  String? _goal;
  String? _diet;

  /// Display unit for height only. Everything is stored and calculated in
  /// centimetres so the health formulas never see two systems.
  bool _heightInFeet = false;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _feet.dispose();
    _inches.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    _allergies.dispose();
    super.dispose();
  }

  /// Height in centimetres, whichever unit was typed.
  double? get _heightCm {
    if (!_heightInFeet) return double.tryParse(_height.text);

    final ft = double.tryParse(_feet.text);
    if (ft == null) return null;
    final inches = double.tryParse(_inches.text) ?? 0;
    return (ft * 30.48) + (inches * 2.54);
  }

  /// Whether the current step has everything it needs to continue.
  bool get _canContinue => switch (_step) {
        1 => int.tryParse(_age.text) != null && _sex != null,
        2 => _heightCm != null &&
            double.tryParse(_weight.text) != null &&
            _activity != null,
        3 => _goal != null,
        _ => true,
      };

  /// The fields belonging to the current step, ready for the API.
  Map<String, dynamic> _changesForStep() => switch (_step) {
        1 => {'age': int.parse(_age.text), 'sex': _sex},
        2 => {
            'height_cm': double.parse(_heightCm!.toStringAsFixed(1)),
            'weight_kg': double.parse(_weight.text),
            'activity_level': _activity,
          },
        3 => {
            'goal': _goal,
            if (_goal != 'maintain' &&
                double.tryParse(_targetWeight.text) != null)
              'target_weight_kg': double.parse(_targetWeight.text),
          },
        _ => {
            if (_diet != null) 'diet_preference': _diet,
            if (_allergies.text.trim().isNotEmpty)
              'allergies': _allergies.text.trim(),
          },
      };

  Future<void> _next() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    // Saved per step rather than all at once, so closing the tab halfway
    // through does not lose what was already entered.
    final changes = _changesForStep();
    final error = changes.isEmpty
        ? null
        : await ref.read(profileControllerProvider.notifier).save(changes);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    if (_step < _totalSteps) {
      setState(() {
        _step++;
        _busy = false;
      });
    } else {
      context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(authControllerProvider).user?.name ?? 'there';

    return OnboardingScaffold(
      step: _step,
      totalSteps: _totalSteps,
      title: switch (_step) {
        1 => 'Hello, $name',
        2 => 'Your measurements',
        3 => 'What are you working towards?',
        _ => 'Anything to avoid?',
      },
      subtitle: switch (_step) {
        1 => 'A few details so NutriAI can work out what your body needs.',
        2 => 'These give your BMI and a daily calorie target.',
        3 => 'This shapes every meal suggestion you get.',
        _ => 'Optional, but it stops NutriAI suggesting food you cannot eat.',
      },
      busy: _busy,
      error: _error,
      onNext: _canContinue ? _next : null,
      onBack: _step > 1 ? () => setState(() => _step--) : null,
      onSkip: () => context.go('/today'),
      nextLabel: _step == _totalSteps ? 'Finish' : 'Continue',
      child: switch (_step) {
        1 => _StepBasics(
            age: _age,
            sex: _sex,
            onSexChanged: (v) => setState(() => _sex = v),
            onChanged: () => setState(() {}),
          ),
        2 => _StepMeasurements(
            height: _height,
            feet: _feet,
            inches: _inches,
            inFeet: _heightInFeet,
            onUnitChanged: (v) => setState(() => _heightInFeet = v),
            weight: _weight,
            activity: _activity,
            onActivityChanged: (v) => setState(() => _activity = v),
            onChanged: () => setState(() {}),
          ),
        3 => _StepGoal(
            goal: _goal,
            targetWeight: _targetWeight,
            onGoalChanged: (v) => setState(() => _goal = v),
          ),
        _ => _StepPreferences(
            diet: _diet,
            allergies: _allergies,
            onDietChanged: (v) => setState(() => _diet = v),
          ),
      },
    );
  }
}

// ------------------------------------------------------------------ steps

class _StepBasics extends StatelessWidget {
  const _StepBasics({
    required this.age,
    required this.sex,
    required this.onSexChanged,
    required this.onChanged,
  });

  final TextEditingController age;
  final String? sex;
  final ValueChanged<String> onSexChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: age,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => onChanged(),
          style: text.bodyLarge,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'In years',
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text('Sex', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        // Used for the BMR formula, which has sex-specific constants.
        ChoiceField<String>(
          options: ProfileOptions.sexes,
          value: sex,
          onChanged: onSexChanged,
        ),
      ],
    );
  }
}

class _StepMeasurements extends StatelessWidget {
  const _StepMeasurements({
    required this.height,
    required this.feet,
    required this.inches,
    required this.inFeet,
    required this.onUnitChanged,
    required this.weight,
    required this.activity,
    required this.onActivityChanged,
    required this.onChanged,
  });

  final TextEditingController height;
  final TextEditingController feet;
  final TextEditingController inches;
  final bool inFeet;
  final ValueChanged<bool> onUnitChanged;
  final TextEditingController weight;
  final String? activity;
  final ValueChanged<String> onActivityChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Height', style: text.bodySmall),
            const Spacer(),
            _UnitToggle(
              inFeet: inFeet,
              onChanged: (v) {
                onUnitChanged(v);
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        if (inFeet)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: feet,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  style: text.bodyLarge,
                  decoration: const InputDecoration(suffixText: 'ft'),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: inches,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => onChanged(),
                  style: text.bodyLarge,
                  decoration: const InputDecoration(suffixText: 'in'),
                ),
              ),
            ],
          )
        else
          TextField(
            controller: height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            style: text.bodyLarge,
            decoration: const InputDecoration(suffixText: 'cm'),
          ),

        const SizedBox(height: AppSpacing.xl),
        Text('Weight', style: text.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => onChanged(),
          style: text.bodyLarge,
          decoration: const InputDecoration(suffixText: 'kg'),
        ),

        const SizedBox(height: AppSpacing.xxl),
        Text('How active are you?', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        ChoiceField<String>(
          options: ProfileOptions.activityLevels,
          hints: ProfileOptions.activityHints,
          value: activity,
          onChanged: onActivityChanged,
        ),
      ],
    );
  }
}

/// Two-state unit switch, styled as a hairline segmented control.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.inFeet, required this.onChanged});

  final bool inFeet;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, 'cm', !inFeet, () => onChanged(false)),
          Container(width: 1, height: 28, color: p.hair),
          _segment(context, 'ft / in', inFeet, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final p = context.palette;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        color: selected ? p.ink : Colors.transparent,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? p.paper : p.char,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}

class _StepGoal extends StatelessWidget {
  const _StepGoal({
    required this.goal,
    required this.targetWeight,
    required this.onGoalChanged,
  });

  final String? goal;
  final TextEditingController targetWeight;
  final ValueChanged<String> onGoalChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceField<String>(
          options: ProfileOptions.goals,
          value: goal,
          onChanged: onGoalChanged,
        ),
        // Only asked when it means something.
        if (goal != null && goal != 'maintain') ...[
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: targetWeight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: text.bodyLarge,
            decoration: const InputDecoration(
              labelText: 'Target weight',
              suffixText: 'kg',
              helperText: 'Optional. You can set this later.',
            ),
          ),
        ],
      ],
    );
  }
}

class _StepPreferences extends StatelessWidget {
  const _StepPreferences({
    required this.diet,
    required this.allergies,
    required this.onDietChanged,
  });

  final String? diet;
  final TextEditingController allergies;
  final ValueChanged<String> onDietChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dietary preference', style: text.bodySmall),
        const SizedBox(height: AppSpacing.md),
        ChoiceField<String>(
          options: ProfileOptions.dietPreferences,
          value: diet,
          onChanged: onDietChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: allergies,
          maxLines: 2,
          style: text.bodyLarge,
          decoration: const InputDecoration(
            labelText: 'Allergies or foods to avoid',
            hintText: 'e.g. prawns, peanuts, dairy',
          ),
        ),
      ],
    );
  }
}
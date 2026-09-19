import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../../onboarding/widgets/choice_field.dart';
import '../../profile/state/profile_controller.dart';

/// Edits one numeric profile field.
///
/// [field] is the API key, e.g. 'target_weight_kg'. The value is sent
/// through PATCH /profile, which accepts partial updates, so nothing else
/// on the profile is touched.
///
/// [dualUnit] offers a cm / ft-in switch. Stored and sent as centimetres
/// either way, so the health formulas never see two unit systems.
Future<bool> showNumberSheet(
  BuildContext context, {
  required String title,
  required String field,
  required String label,
  String? unit,
  String? helper,
  double? initial,
  bool dualUnit = false,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EditSheet(
        title: title,
        field: field,
        label: label,
        unit: unit,
        helper: helper,
        initialNumber: initial,
        dualUnit: dualUnit,
      ),
    ),
  );
  return result ?? false;
}

/// Edits one choice field, e.g. goal or activity level.
Future<bool> showChoiceSheet(
  BuildContext context, {
  required String title,
  required String field,
  required Map<String, String> options,
  Map<String, String> hints = const {},
  String? initial,
  String? helper,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => _EditSheet(
      title: title,
      field: field,
      label: '',
      helper: helper,
      options: options,
      hints: hints,
      initialChoice: initial,
    ),
  );
  return result ?? false;
}

class _EditSheet extends ConsumerStatefulWidget {
  const _EditSheet({
    required this.title,
    required this.field,
    required this.label,
    this.unit,
    this.helper,
    this.initialNumber,
    this.dualUnit = false,
    this.options,
    this.hints = const {},
    this.initialChoice,
  });

  final String title;
  final String field;
  final String label;
  final String? unit;
  final String? helper;
  final double? initialNumber;
  final bool dualUnit;

  /// Present for a choice field, absent for a number field.
  final Map<String, String>? options;

  final Map<String, String> hints;
  final String? initialChoice;

  @override
  ConsumerState<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends ConsumerState<_EditSheet> {
  late final TextEditingController _value;
  final _feet = TextEditingController();
  final _inches = TextEditingController();

  String? _choice;
  bool _imperial = false;
  bool _busy = false;
  String? _error;

  bool get _isChoice => widget.options != null;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(
      text: widget.initialNumber?.toStringAsFixed(1) ?? '',
    );
    _choice = widget.initialChoice;

    // Prefill the imperial fields too, so switching units mid-edit does
    // not lose the value already on screen.
    if (widget.dualUnit && widget.initialNumber != null) {
      final total = widget.initialNumber! / 2.54;
      _feet.text = (total ~/ 12).toString();
      _inches.text = (total % 12).round().toString();
    }
  }

  @override
  void dispose() {
    _value.dispose();
    _feet.dispose();
    _inches.dispose();
    super.dispose();
  }

  /// The value in the field's stored unit, whichever way it was typed.
  double? get _resolved {
    if (!_imperial) return double.tryParse(_value.text.trim());

    final ft = double.tryParse(_feet.text.trim());
    if (ft == null) return null;
    final inches = double.tryParse(_inches.text.trim()) ?? 0;
    return (ft * 30.48) + (inches * 2.54);
  }

  Future<void> _save() async {
    final Object? payload;

    if (_isChoice) {
      if (_choice == null) {
        setState(() => _error = 'Choose one to continue.');
        return;
      }
      payload = _choice;
    } else {
      final parsed = _resolved;
      if (parsed == null) {
        setState(() => _error = 'Enter a number.');
        return;
      }
      // Age is an integer server-side; sending 23.0 would be rejected.
      payload = widget.field == 'age'
          ? parsed.round()
          : double.parse(parsed.toStringAsFixed(1));
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref
        .read(profileControllerProvider.notifier)
        .save({widget.field: payload});

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          // The sheet is full width, but the form inside it is not: a
          // field stretched across a desktop window is harder to use, not
          // easier.
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: text.headlineMedium),
                if (widget.helper != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.helper!, style: text.bodySmall),
                ],
                const SizedBox(height: AppSpacing.xl),

                if (_isChoice)
                  ChoiceField<String>(
                    options: widget.options!,
                    hints: widget.hints,
                    value: _choice,
                    onChanged: (v) => setState(() => _choice = v),
                  )
                else ...[
                  if (widget.dualUnit) ...[
                    Row(
                      children: [
                        Text(widget.label, style: text.bodySmall),
                        const Spacer(),
                        _UnitToggle(
                          imperial: _imperial,
                          onChanged: (v) => setState(() => _imperial = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  if (widget.dualUnit && _imperial)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _feet,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: text.bodyLarge,
                            decoration: const InputDecoration(suffixText: 'ft'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: TextField(
                            controller: _inches,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: text.bodyLarge,
                            decoration: const InputDecoration(suffixText: 'in'),
                          ),
                        ),
                      ],
                    )
                  else
                    TextField(
                      controller: _value,
                      autofocus: true,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: text.bodyLarge,
                      decoration: InputDecoration(
                        labelText: widget.dualUnit ? null : widget.label,
                        suffixText: widget.unit,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: p.linen,
                      border:
                          Border(left: BorderSide(color: p.brick, width: 2)),
                    ),
                    child: Text(_error!, style: text.bodyMedium),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    TextButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: p.onAccent,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-state unit switch, styled as a hairline segmented control.
class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.imperial, required this.onChanged});

  final bool imperial;
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
          _segment(context, 'cm', !imperial, () => onChanged(false)),
          Container(width: 1, height: 28, color: p.hair),
          _segment(context, 'ft / in', imperial, () => onChanged(true)),
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
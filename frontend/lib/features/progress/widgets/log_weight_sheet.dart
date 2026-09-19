import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/weight_controller.dart';

/// Opens the log-weight form. Returns true if something was recorded.
Future<bool> showLogWeightSheet(
  BuildContext context, {
  double? currentWeight,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => Padding(
      // Lifts the sheet above the keyboard on a phone.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: _LogWeightForm(currentWeight: currentWeight),
    ),
  );
  return result ?? false;
}

class _LogWeightForm extends ConsumerStatefulWidget {
  const _LogWeightForm({this.currentWeight});

  final double? currentWeight;

  @override
  ConsumerState<_LogWeightForm> createState() => _LogWeightFormState();
}

class _LogWeightFormState extends ConsumerState<_LogWeightForm> {
  late final TextEditingController _weight;
  final _note = TextEditingController();

  DateTime _date = DateTime.now();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefilled with the last known weight: most weigh-ins are a small
    // change from the previous one, so this is usually a quick edit.
    _weight = TextEditingController(
      text: widget.currentWeight?.toStringAsFixed(1) ?? '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      // No future dates: you cannot have weighed yourself tomorrow.
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final value = double.tryParse(_weight.text.trim());
    if (value == null) {
      setState(() => _error = 'Enter a weight in kilograms.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref.read(weightControllerProvider.notifier).log(
          weightKg: value,
          recordedOn: _date,
          note: _note.text,
        );

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
    final isToday = _isSameDay(_date, DateTime.now());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record your weight', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.xl),

            TextField(
              controller: _weight,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: text.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date', style: text.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        isToday ? 'Today' : _formatDate(_date),
                        style: text.bodyLarge,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : _pickDate,
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            TextField(
              controller: _note,
              style: text.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional — e.g. morning, before food',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: p.linen,
                  border: Border(left: BorderSide(color: p.brick, width: 2)),
                ),
                child: Text(_error!, style: text.bodyMedium),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context, false),
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
                      : const Text('Record'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
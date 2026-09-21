import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/account_controller.dart';

/// Edits the account name.
Future<bool> showEditNameSheet(BuildContext context, String current) =>
    _show(
      context,
      title: 'Your name',
      label: 'Name',
      helper: 'What NutriAI calls you, and how you appear in the app.',
      initial: current,
      field: _Field.name,
    );

/// Edits the account email.
Future<bool> showEditEmailSheet(BuildContext context, String current) =>
    _show(
      context,
      title: 'Your email',
      label: 'Email',
      helper: 'This is what you sign in with. Changing it changes your login.',
      initial: current,
      field: _Field.email,
    );

enum _Field { name, email }

Future<bool> _show(
  BuildContext context, {
  required String title,
  required String label,
  required String helper,
  required String initial,
  required _Field field,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _EditAccountForm(
        title: title,
        label: label,
        helper: helper,
        initial: initial,
        field: field,
      ),
    ),
  );
  return result ?? false;
}

class _EditAccountForm extends ConsumerStatefulWidget {
  const _EditAccountForm({
    required this.title,
    required this.label,
    required this.helper,
    required this.initial,
    required this.field,
  });

  final String title;
  final String label;
  final String helper;
  final String initial;
  final _Field field;

  @override
  ConsumerState<_EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends ConsumerState<_EditAccountForm> {
  late final TextEditingController _value;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entered = _value.text.trim();

    if (entered.isEmpty) {
      setState(() => _error = 'This cannot be empty.');
      return;
    }
    if (widget.field == _Field.email &&
        (!entered.contains('@') || !entered.contains('.'))) {
      setState(() => _error = 'That does not look like an email address.');
      return;
    }
    // Nothing changed: close rather than sending a pointless request.
    if (entered == widget.initial) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref.read(accountControllerProvider.notifier).updateDetails(
          name: widget.field == _Field.name ? entered : null,
          email: widget.field == _Field.email ? entered : null,
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

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: text.headlineMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(widget.helper, style: text.bodySmall),
                const SizedBox(height: AppSpacing.xl),

                TextField(
                  controller: _value,
                  autofocus: true,
                  keyboardType: widget.field == _Field.email
                      ? TextInputType.emailAddress
                      : TextInputType.name,
                  style: text.bodyLarge,
                  decoration: InputDecoration(labelText: widget.label),
                  onSubmitted: (_) => _save(),
                ),

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
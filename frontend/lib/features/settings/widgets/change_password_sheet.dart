import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/account_controller.dart';

Future<bool> showChangePasswordSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: context.palette.paper,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: const _ChangePasswordForm(),
    ),
  );
  return result ?? false;
}

class _ChangePasswordForm extends ConsumerStatefulWidget {
  const _ChangePasswordForm();

  @override
  ConsumerState<_ChangePasswordForm> createState() =>
      _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<_ChangePasswordForm> {
  final _current = TextEditingController();
  final _replacement = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _replacement.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_replacement.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (_replacement.text != _confirm.text) {
      setState(() => _error = 'The new passwords do not match.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await ref.read(accountControllerProvider.notifier).changePassword(
          current: _current.text,
          replacement: _replacement.text,
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change your password', style: text.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            // Says plainly why the current password is needed, rather than
            // leaving it as an unexplained hurdle.
            Text(
              'Your current password confirms it is you. Nobody, including '
              'an administrator, can read it.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),

            TextField(
              controller: _current,
              obscureText: true,
              autofocus: true,
              style: text.bodyLarge,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _replacement,
              obscureText: true,
              style: text.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'At least 8 characters.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _confirm,
              obscureText: true,
              style: text.bodyLarge,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              onSubmitted: (_) => _save(),
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
                      : const Text('Change password'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
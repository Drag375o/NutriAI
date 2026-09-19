import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/spacing.dart';
import '../state/account_controller.dart';

/// Asks before pausing the account. Returns true if it was deactivated.
Future<bool> confirmDeactivate(BuildContext context, WidgetRef ref) async {
  final p = context.palette;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      title: Text(
        'Deactivate your account?',
        style: TextStyle(
          color: p.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        'Your profile and data stay saved, but the account is hidden and '
        "you'll be signed out. Sign in again any time to restore it.",
        style: TextStyle(color: p.char, fontSize: 15, height: 1.5),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: p.char),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: p.brick),
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Deactivate',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;

  final error = await ref.read(accountControllerProvider.notifier).deactivate();
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return false;
  }
  return true;
}

/// Asks before deleting, requiring the password. Returns true if deleted.
Future<bool> confirmDelete(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => const _DeleteDialog(),
  );
  return result ?? false;
}

class _DeleteDialog extends ConsumerStatefulWidget {
  const _DeleteDialog();

  @override
  ConsumerState<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends ConsumerState<_DeleteDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your password to confirm.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final error =
        await ref.read(accountControllerProvider.notifier).deleteAccount(
              _password.text,
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

    return AlertDialog(
      backgroundColor: p.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.hair),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      title: Text(
        'Delete your account?',
        style: TextStyle(
          color: p.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This removes your profile, conversations, plans and weight '
            'history permanently. There is no way to undo it.',
            style: TextStyle(color: p.char, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          // The password is asked for here rather than a typed phrase: it
          // proves identity, not just attention.
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Your password',
            ),
            onSubmitted: (_) => _delete(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: TextStyle(color: p.brick, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: p.char),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: p.brick),
          onPressed: _busy ? null : _delete,
          child: Text(
            _busy ? 'Deleting…' : 'Delete',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
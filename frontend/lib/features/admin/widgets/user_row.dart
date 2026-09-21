import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin_theme.dart';
import '../data/admin_models.dart';
import '../state/admin_controller.dart';

/// One account as a table row.
///
/// Columns are fixed-width so ids, emails and counts line up down the page,
/// which is the whole reason for a monospace face here.
class UserRow extends ConsumerWidget {
  const UserRow({super.key, required this.user, required this.isSelf});

  final AdminUser user;

  /// True for the signed-in administrator's own account, which cannot be
  /// disabled or deleted from here.
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Admin.line)),
      ),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('${user.id}', style: Admin.mono(color: Admin.faint))),
          SizedBox(
            width: 240,
            child: Text(
              user.email,
              style: Admin.mono(),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              user.name,
              style: Admin.mono(color: Admin.dim),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 72, child: _RoleTag(user: user)),
          SizedBox(width: 96, child: _StatusTag(user: user)),
          SizedBox(
            width: 110,
            child: Text(
              user.profileComplete ? 'complete' : 'incomplete',
              style: Admin.mono(
                size: 11.5,
                color: user.profileComplete ? Admin.dim : Admin.faint,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '${user.conversationCount}c ${user.planCount}p '
              '${user.weightEntryCount}w',
              style: Admin.mono(size: 11.5, color: Admin.faint),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              user.lastLoginAt == null
                  ? 'never'
                  : _relative(user.lastLoginAt!),
              style: Admin.mono(size: 11.5, color: Admin.faint),
            ),
          ),
          const Spacer(),
          if (!isSelf) _Actions(user: user) else Text('you', style: Admin.mono(size: 11.5, color: Admin.faint)),
        ],
      ),
    );
  }

  static String _relative(DateTime d) {
    final days = DateTime.now().difference(d).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 30) return '${days}d ago';
    return '${(days / 30).floor()}mo ago';
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    if (!user.isAdmin) {
      return Text('user', style: Admin.mono(size: 11.5, color: Admin.faint));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: Admin.dim)),
      child: Text('ADMIN', style: Admin.mono(size: 9.5, spacing: 0.5)),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final colour = switch (user.status) {
      'DISABLED' => Admin.alert,
      'PAUSED' => Admin.dim,
      _ => Admin.ok,
    };

    return Row(
      children: [
        Container(width: 5, height: 5, color: colour),
        const SizedBox(width: 7),
        Text(user.status, style: Admin.mono(size: 10.5, color: colour, spacing: 0.4)),
      ],
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Action(
          label: user.isActive ? 'disable' : 'enable',
          onTap: () => ref
              .read(adminUsersProvider.notifier)
              .setActive(user.id, !user.isActive),
        ),
        _Action(
          label: 'reset pw',
          onTap: () => _resetPassword(context, ref),
        ),
        _Action(
          label: 'delete',
          destructive: true,
          onTap: () => _confirmDelete(context, ref),
        ),
      ],
    );
  }

  /// The temporary password is shown once and cannot be retrieved again,
  /// so the dialog says so and offers it for copying.
  Future<void> _resetPassword(BuildContext context, WidgetRef ref) async {
    try {
      final temporary =
          await ref.read(adminUsersProvider.notifier).resetPassword(user.id);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Admin.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Admin.line),
          ),
          title: Text('TEMPORARY PASSWORD', style: Admin.mono(size: 13, spacing: 0.8)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For ${user.email}. Shown once. They must change it at '
                  'next sign-in.',
                  style: Admin.body,
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Admin.raised,
                  child: SelectableText(
                    temporary,
                    style: Admin.mono(size: 16, spacing: 1),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Admin.text),
              onPressed: () => Navigator.pop(context),
              child: Text('DONE', style: Admin.mono(size: 12, spacing: 0.6)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Admin.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Admin.line),
        ),
        title: Text('DELETE ACCOUNT', style: Admin.mono(size: 13, spacing: 0.8)),
        content: SizedBox(
          width: 380,
          child: Text(
            'Removes ${user.email} and everything it owns: profile, '
            'conversations, plans and weight history. This cannot be undone.',
            style: Admin.body,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Admin.dim),
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: Admin.mono(size: 12, spacing: 0.6)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Admin.alert),
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: Admin.mono(size: 12, spacing: 0.6)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error =
          await ref.read(adminUsersProvider.notifier).deleteUser(user.id);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }
}

class _Action extends StatefulWidget {
  const _Action({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colour = widget.destructive ? Admin.alert : Admin.dim;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? Admin.raised : Colors.transparent,
            border: Border.all(color: _hovered ? colour : Admin.line),
          ),
          child: Text(
            widget.label,
            style: Admin.mono(size: 11, color: colour),
          ),
        ),
      ),
    );
  }
}
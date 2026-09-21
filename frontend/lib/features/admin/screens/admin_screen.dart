import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/state/auth_controller.dart';
import '../admin_theme.dart';
import '../data/admin_models.dart';
import '../state/admin_controller.dart';
import '../widgets/user_row.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).user;
    final users = ref.watch(adminUsersProvider);
    final stats = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: Admin.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Bar(name: me?.name ?? ''),

            stats.maybeWhen(
              orElse: () => const SizedBox(height: 1),
              data: (s) => _Stats(stats: s),
            ),

            Expanded(
              child: users.when(
                loading: () => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Admin.dim,
                    ),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('ERROR  $e', style: Admin.mono(color: Admin.alert)),
                ),
                // Scrolls sideways rather than clipping on a narrow window.
                // For a data tool that is the right failure: a truncated
                // column is worse than one you have to scroll to.


                data: (rows) => LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // Fills the window, but never narrower than the
                      // columns need: below 1280 the table scrolls sideways
                      // rather than clipping, which is the right failure
                      // for a data tool.
                      width: constraints.maxWidth < 1280
                          ? 1280
                          : constraints.maxWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HeaderRow(),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              itemBuilder: (context, i) => UserRow(
                                user: rows[i],
                                isSelf: rows[i].id == me?.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),


          ],
        ),
      ),
    );
  }
}

/// The top bar. Deliberately plain: a title, a count, and the way out.
class _Bar extends ConsumerWidget {
  const _Bar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Admin.surface,
        border: Border(bottom: BorderSide(color: Admin.line)),
      ),
      child: Row(
        children: [
          Text('NUTRIAI', style: Admin.mono(size: 14, weight: FontWeight.w600, spacing: 1.5)),
          const SizedBox(width: 10),
          Text('ADMIN', style: Admin.mono(size: 14, color: Admin.faint, spacing: 1.5)),
          const Spacer(),
          Text(name.toUpperCase(), style: Admin.mono(size: 11.5, color: Admin.faint, spacing: 0.5)),
          const SizedBox(width: 16),
          _BarAction(
            label: 'refresh',
            onTap: () => ref.read(adminUsersProvider.notifier).refresh(),
          ),
          // The way back to the app itself, since an administrator is also
          // an ordinary user with their own profile and plans.
          _BarAction(label: 'exit', onTap: () => context.go('/today')),
        ],
      ),
    );
  }
}

class _BarAction extends StatefulWidget {
  const _BarAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_BarAction> createState() => _BarActionState();
}

class _BarActionState extends State<_BarAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? Admin.raised : Colors.transparent,
            border: Border.all(color: _hovered ? Admin.dim : Admin.line),
          ),
          child: Text(
            widget.label,
            style: Admin.mono(size: 11, color: Admin.dim),
          ),
        ),
      ),
    );
  }
}




class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final AdminStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Admin.line)),
      ),
      // Scrolls sideways on a narrow window, matching the table below it.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Stat(label: 'ACCOUNTS', value: stats.totalUsers),
            _Stat(label: 'ACTIVE', value: stats.activeUsers),
            _Stat(label: 'PAUSED', value: stats.deactivatedUsers),
            _Stat(
              label: 'DISABLED',
              value: stats.disabledUsers,
              colour: stats.disabledUsers > 0 ? Admin.alert : null,
            ),
            _Stat(label: 'ADMINS', value: stats.admins),
            _Stat(label: 'SEEN 7D', value: stats.signedInThisWeek),
          ],
        ),
      ),
    );
  }
}




class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.colour});

  final String label;
  final int value;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Admin.label),
          const SizedBox(height: 4),
          Text('$value', style: Admin.figure.copyWith(color: colour ?? Admin.text)),
        ],
      ),
    );
  }
}

/// Column headings, matching the widths in UserRow.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Admin.surface,
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('ID', style: Admin.label)),
          SizedBox(width: 240, child: Text('EMAIL', style: Admin.label)),
          SizedBox(width: 150, child: Text('NAME', style: Admin.label)),
          SizedBox(width: 72, child: Text('ROLE', style: Admin.label)),
          SizedBox(width: 96, child: Text('STATUS', style: Admin.label)),
          SizedBox(width: 110, child: Text('PROFILE', style: Admin.label)),
          SizedBox(width: 120, child: Text('ACTIVITY', style: Admin.label)),
          SizedBox(width: 110, child: Text('LAST SEEN', style: Admin.label)),
          
          Expanded(child: Text('ACTIONS', style: Admin.label)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/typography.dart';
import 'destinations.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  /// The current screen, supplied by go_router.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (AppBreakpoints.isCompact(width)) {
      return _CompactShell(child: child);
    }
    return _RailShell(child: child, extended: AppBreakpoints.isExpanded(width));
  }
}

/// Which destination matches the current URL.
int _selectedIndex(BuildContext context, List<AppDestination> list) {
  final location = GoRouterState.of(context).uri.path;
  final index = list.indexWhere((d) => location.startsWith(d.path));
  return index < 0 ? 0 : index;
}

// ---------------------------------------------------------------- compact

class _CompactShell extends StatelessWidget {
  const _CompactShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final list = primaryDestinations;
    final selected = _selectedIndex(context, list);

    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.hair)),
        ),
        child: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => context.go(list[i].path),
          backgroundColor: p.paper,
          surfaceTintColor: Colors.transparent,
          indicatorColor: p.linen,
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final d in list)
              NavigationDestination(
                icon: Icon(d.icon, color: p.muted),
                selectedIcon: Icon(d.selectedIcon, color: p.ember),
                label: d.label,
                tooltip: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- rail

class _RailShell extends StatelessWidget {
  const _RailShell({required this.child, required this.extended});

  final Widget child;

  /// True on wide screens: labels sit beside icons.
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = _selectedIndex(context, appDestinations);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: extended ? 196 : 76,
            decoration: BoxDecoration(
              color: p.linen,
              border: Border(right: BorderSide(color: p.hair)),
            ),
            child: SafeArea(
              right: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RailHeader(extended: extended),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        for (var i = 0; i < appDestinations.length; i++)
                          _RailItem(
                            destination: appDestinations[i],
                            selected: i == selected,
                            extended: extended,
                            onTap: () => context.go(appDestinations[i].path),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _RailHeader extends StatelessWidget {
  const _RailHeader({required this.extended});
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: extended
          ? Text.rich(
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
            )
          : Text(
              'N',
              textAlign: TextAlign.center,
              style: text.titleLarge?.copyWith(color: p.ink),
            ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(
            horizontal: extended ? AppSpacing.lg : 0,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? p.ember : Colors.transparent,
                width: AppBorders.mark,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment:
                extended ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 20,
                color: selected ? p.ink : p.muted,
              ),
              if (extended) ...[
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    destination.label,
                    style: text.bodyMedium?.copyWith(
                      color: selected ? p.ink : p.char,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
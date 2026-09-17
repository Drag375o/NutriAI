import 'package:flutter/material.dart';

/// One navigable area of the app.
class AppDestination {
  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.primary,
  });

  /// URL path, e.g. `/coach`. Visible in the browser address bar on web.
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Whether this appears in the compact bottom bar.
  ///
  /// Bottom bars hold four items comfortably. Health and Profile are
  /// reached from inside Today on small screens instead.
  final bool primary;
}

/// Order matters: it is the order shown in the rail and the bottom bar.
const List<AppDestination> appDestinations = [
  AppDestination(
    path: '/today',
    label: 'Today',
    icon: Icons.wb_twilight_outlined,
    selectedIcon: Icons.wb_twilight,
    primary: true,
  ),
  AppDestination(
    path: '/plan',
    label: 'Plan',
    icon: Icons.restaurant_outlined,
    selectedIcon: Icons.restaurant,
    primary: true,
  ),
  AppDestination(
    path: '/coach',
    label: 'Coach',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
    primary: true,
  ),
  AppDestination(
    path: '/progress',
    label: 'Progress',
    icon: Icons.show_chart_outlined,
    selectedIcon: Icons.show_chart,
    primary: true,
  ),
  AppDestination(
    path: '/health',
    label: 'Health',
    icon: Icons.favorite_outline,
    selectedIcon: Icons.favorite,
    primary: false,
  ),
  AppDestination(
    path: '/profile',
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    primary: false,
  ),
];

/// The primary destinations, for the compact bottom bar.
List<AppDestination> get primaryDestinations =>
    appDestinations.where((d) => d.primary).toList();
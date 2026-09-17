import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's light/dark setting.
///
/// Defaults to [ThemeMode.system] so NutriAI matches the user's OS until
/// they choose otherwise. Persistence to disk arrives with Settings in
/// Phase 8; for now the choice lasts for the session.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;

  /// Flips between light and dark. If currently following the system,
  /// flips away from whatever the system is showing.
  void toggle(Brightness current) {
    state = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
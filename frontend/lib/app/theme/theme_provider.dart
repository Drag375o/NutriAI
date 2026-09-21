import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's light/dark setting, remembered across restarts.
///
/// The stored value is read in main() before the first frame and injected
/// here, rather than loaded asynchronously afterwards: reading it later
/// meant the app painted in system mode and repainted a moment after,
/// which flashed on every load.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier({this.initial = ThemeMode.system});

  /// The mode to start in, supplied by main().
  final ThemeMode initial;

  static const storageKey = 'nutriai.theme_mode';

  /// Turns a stored string back into a mode. Anything unrecognised, or
  /// nothing stored at all, falls back to following the system.
  static ThemeMode parse(String? stored) => switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  ThemeMode build() => initial;

  Future<void> set(ThemeMode mode) async {
    state = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, mode.name);
  }

  /// Flips between light and dark. If currently following the system,
  /// flips away from whatever the system is showing.
  void toggle(Brightness current) =>
      set(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
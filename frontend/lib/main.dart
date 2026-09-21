import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme/theme_provider.dart';

Future<void> main() async {
  // Required before touching platform channels ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // The stored theme is read before the first frame rather than after it.
  // Reading it inside the provider meant painting once in system mode and
  // again when the value arrived, which flashed on every load.
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(ThemeModeNotifier.storageKey);

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(initial: ThemeModeNotifier.parse(stored)),
        ),
      ],
      child: const NutriAIApp(),
    ),
  );
}
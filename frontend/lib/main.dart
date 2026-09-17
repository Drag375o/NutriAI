import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(
    // ProviderScope holds all Riverpod state for the app.
    const ProviderScope(child: NutriAIApp()),
  );
}
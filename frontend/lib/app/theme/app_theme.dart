import 'package:flutter/material.dart';

import 'colors.dart';
import 'shapes.dart';
import 'spacing.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(AppPalette.light);
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final textTheme = AppTypography.textTheme(p);

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.paper,
      canvasColor: p.paper,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness: p.brightness,
        primary: p.ember,
        onPrimary: p.onAccent,
        secondary: p.turmeric,
        onSecondary: p.onAccent,
        error: p.brick,
        onError: p.onAccent,
        surface: p.paper,
        onSurface: p.ink,
        surfaceContainerHighest: p.linen,
        outline: p.hair,
        outlineVariant: p.clay,
      ),
      dividerTheme: DividerThemeData(
        color: p.hair,
        thickness: AppBorders.hairline,
        space: AppBorders.hairline,
      ),
      // Primary action: solid ember, cut corners, no shadow.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.ember,
          foregroundColor: p.onAccent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: const ChamferedBorder(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: textTheme.labelLarge?.copyWith(color: p.onAccent),
          minimumSize: const Size(0, 48),
        ),
      ),
      // Secondary action: hairline box, near-square corners.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.ink,
          side: BorderSide(color: p.hair, width: AppBorders.hairline),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.md)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          textStyle: textTheme.labelLarge,
          minimumSize: const Size(0, 48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.emberText,
          textStyle: textTheme.labelLarge?.copyWith(color: p.emberText),
          minimumSize: const Size(0, 44),
        ),
      ),
      // Inputs are underlines, not boxes. Less chrome, same affordance.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        labelStyle: textTheme.bodySmall?.copyWith(color: p.char),
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.muted),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: p.hair, width: AppBorders.hairline),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: p.ember, width: AppBorders.mark),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: p.brick, width: AppBorders.hairline),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.paper,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: p.hair, width: AppBorders.hairline),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.ember,
        linearTrackColor: p.clay,
        linearMinHeight: 6,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: p.paper),
        behavior: SnackBarBehavior.floating,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
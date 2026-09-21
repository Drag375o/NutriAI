import 'package:flutter/material.dart';

import 'colors.dart';

/// Type for the whole app.
///
/// Fonts are bundled in pubspec.yaml rather than fetched at runtime, so
/// these are plain family names. Flutter picks the right file from the
/// weight, which is why only the weights declared there can be used.
abstract final class AppTypography {
  static const _sans = 'Archivo';
  static const _mono = 'IBMPlexMono';
  static const _script = 'Sacramento';

  /// Numerals, units, timestamps, metric readouts.
  static TextStyle mono({
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: _mono,
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.2,
      height: 1.4,
    );
  }

  /// Large metric values, e.g. a weight on the dashboard.
  static TextStyle metric(Color color) => TextStyle(
        fontFamily: _mono,
        color: color,
        fontSize: 27,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
        height: 1.2,
      );

  /// Script accent. Used sparingly — a greeting, an occasional food moment.
  /// Never for anything the reader has to work through.
  static TextStyle script({
    required Color color,
    double size = 34,
  }) {
    return TextStyle(
      fontFamily: _script,
      color: color,
      fontSize: size,
      height: 1.1,
    );
  }

  static TextTheme textTheme(AppPalette palette) {
    return TextTheme(
      // Screen titles and hero moments.
      displayLarge: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 49,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.05,
      ),
      displayMedium: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 39,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      // Section headings.
      headlineLarge: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 31,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 25,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      // Reading text.
      bodyLarge: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        fontFamily: _sans,
        color: palette.char,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      // Captions and field labels.
      bodySmall: TextStyle(
        fontFamily: _sans,
        color: palette.muted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _sans,
        color: palette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: mono(color: palette.muted, size: 11),
    );
  }
}
import 'package:flutter/material.dart';

/// A complete NutriAI colour set. Two instances exist: [light] and [dark].
///
/// Fill colours (turmeric, ember) are for backgrounds, borders and marks.
/// Text colours (turmericText, emberText) are darkened variants that meet
/// WCAG AA contrast when used for words on [paper].
@immutable
class AppPalette {
  const AppPalette({
    required this.paper,
    required this.linen,
    required this.clay,
    required this.ink,
    required this.char,
    required this.muted,
    required this.hair,
    required this.turmeric,
    required this.turmericText,
    required this.ember,
    required this.emberText,
    required this.sage,
    required this.brick,
    required this.onAccent,
    required this.brightness,
  });

  /// Page background.
  final Color paper;

  /// Raised surface: navigation rail, selected rows, quiet panels.
  final Color linen;

  /// Recessed surface: progress track, disabled fill.
  final Color clay;

  /// Primary text and dark blocks.
  final Color ink;

  /// Secondary text. Still fully readable.
  final Color char;

  /// Tertiary text: captions, units, timestamps.
  final Color muted;

  /// Hairline borders and dividers.
  final Color hair;

  /// Data highlights, chart lines, marks. Not for text on [paper].
  final Color turmeric;

  /// Accessible turmeric, for text.
  final Color turmericText;

  /// Primary action fill.
  final Color ember;

  /// Accessible ember, for text and links.
  final Color emberText;

  /// On track, healthy range, success.
  final Color sage;

  /// Needs attention, destructive, error.
  final Color brick;

  /// Text drawn on top of [ember] or [ink].
  final Color onAccent;

  final Brightness brightness;

  static const AppPalette light = AppPalette(
    paper: Color(0xFFF2EFE6),
    linen: Color(0xFFE7E1D2),
    clay: Color(0xFFD8D0BC),
    ink: Color(0xFF1C1A15),
    char: Color(0xFF4A4639),
    muted: Color(0xFF6B6555),
    hair: Color(0xFFCFC7B2),
    turmeric: Color(0xFFC8912F),
    turmericText: Color(0xFF8A6318),
    ember: Color(0xFFB8501F),
    emberText: Color(0xFF9A3F15),
    sage: Color(0xFF5E7247),
    brick: Color(0xFFA33A28),
    onAccent: Color(0xFFFBF8F1),
    brightness: Brightness.light,
  );

  static const AppPalette dark = AppPalette(
    paper: Color(0xFF131210),
    linen: Color(0xFF1C1A16),
    clay: Color(0xFF24211B),
    ink: Color(0xFFEDE7DA),
    char: Color(0xFFC4BDAC),
    muted: Color(0xFF8C8676),
    hair: Color(0xFF35312A),
    turmeric: Color(0xFFDCAD52),
    turmericText: Color(0xFFDCAD52),
    ember: Color(0xFFD9673A),
    emberText: Color(0xFFD9673A),
    sage: Color(0xFF8AA36C),
    brick: Color(0xFFC85A46),
    onAccent: Color(0xFF15130F),
    brightness: Brightness.dark,
  );
}

/// Reads the palette matching the current theme.
///
/// Usage inside a widget: `context.palette.ember`
extension PaletteAccess on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}
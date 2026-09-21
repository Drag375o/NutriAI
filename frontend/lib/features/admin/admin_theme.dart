import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colours and type for the administration panel.
///
/// Kept entirely separate from AppPalette: the panel is a different tool
/// for a different job, and it should not look like the app it manages.
/// Black, white, and one red for anything destructive.
abstract final class Admin {
  static const bg = Color(0xFF0A0A0A);
  static const surface = Color(0xFF141414);
  static const raised = Color(0xFF1C1C1C);
  static const line = Color(0xFF2A2A2A);

  static const text = Color(0xFFE8E8E8);
  static const dim = Color(0xFF8A8A8A);
  static const faint = Color(0xFF585858);

  /// The only colour in the panel, and only for destructive actions or
  /// states that need attention.
  static const alert = Color(0xFFD64545);

  static const ok = Color(0xFF6FA86F);

  /// Everything is monospace: this is a data tool, and columns of numbers
  /// and emails are easier to scan when the characters align.
  static TextStyle mono({
    double size = 13,
    Color color = text,
    FontWeight weight = FontWeight.w400,
    double spacing = 0,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: spacing,
        height: 1.45,
      );

  static TextStyle get title =>
      mono(size: 20, weight: FontWeight.w600, spacing: -0.3);

  static TextStyle get label =>
      mono(size: 10.5, color: faint, spacing: 0.8);

  static TextStyle get body => mono(size: 13, color: dim);

  static TextStyle get figure => mono(size: 26, weight: FontWeight.w500);
}
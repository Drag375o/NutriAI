import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

abstract final class AppTypography {
  /// Numerals, units, timestamps, metric readouts.
  static TextStyle mono({
    required Color color,
    double size = 14,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.ibmPlexMono(
      color: color,
      fontSize: size,
      fontWeight: weight,
      letterSpacing: 0.2,
      height: 1.4,
    );
  }

  /// Large metric values, e.g. a weight on the dashboard.
  static TextStyle metric(Color color) => GoogleFonts.ibmPlexMono(
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
    return GoogleFonts.sacramento(
      color: color,
      fontSize: size,
      height: 1.1,
    );
  }

  static TextTheme textTheme(AppPalette palette) {
    final base = GoogleFonts.archivoTextTheme();

    return base.copyWith(
      // Screen titles and hero moments.
      displayLarge: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 49,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 39,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      // Section headings.
      headlineLarge: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 31,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineMedium: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 25,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      titleLarge: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      // Reading text.
      bodyLarge: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.archivo(
        color: palette.char,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      // Captions and field labels.
      bodySmall: GoogleFonts.archivo(
        color: palette.muted,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.archivo(
        color: palette.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelSmall: mono(color: palette.muted, size: 11),
    );
  }
}
/// Spacing scale. Every margin, padding and gap uses one of these.
/// Multiples of 4, per the UI/UX guidelines.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

/// Corner radii. NutriAI stays close to square on purpose.
abstract final class AppRadii {
  static const double sm = 2;
  static const double md = 3;
  static const double lg = 4;

  /// Size of the cut corner on primary buttons. The signature shape.
  static const double chamfer = 10;
}

abstract final class AppBorders {
  /// Standard hairline. Structure comes from these, not from shadows.
  static const double hairline = 1;

  /// Emphasis edge on a marked tile or selected rail item.
  static const double mark = 2;
}

/// Layout breakpoints, named by intent rather than by device.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 1000;

  static bool isCompact(double width) => width < compact;
  static bool isMedium(double width) => width >= compact && width < medium;
  static bool isExpanded(double width) => width >= medium;
}
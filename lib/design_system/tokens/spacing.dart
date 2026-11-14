abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Shared floor for touch targets. Android asks for 48 dp; iOS asks for 44 pt.
abstract final class AppTouch {
  static const minimum = 48.0;
}

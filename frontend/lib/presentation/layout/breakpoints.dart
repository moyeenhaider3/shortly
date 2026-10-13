import 'package:flutter/widgets.dart';

enum Breakpoint {
  compact, // < 600: phones
  medium, // 600–1023: tablets, narrow windows
  expanded, // 1024–1439: laptops
  large; // ≥ 1440: desktops

  static Breakpoint fromWidth(double width) {
    if (width < 600) return compact;
    if (width < 1024) return medium;
    if (width < 1440) return expanded;
    return large;
  }

  bool operator >=(Breakpoint other) => index >= other.index;
  bool operator <(Breakpoint other) => index < other.index;
}

extension BreakpointContext on BuildContext {
  /// Uses `MediaQuery.sizeOf` so callers only rebuild on size changes.
  Breakpoint get breakpoint => Breakpoint.fromWidth(MediaQuery.sizeOf(this).width);
  bool get isCompact => breakpoint == Breakpoint.compact;
  bool get isDesktop => breakpoint >= Breakpoint.expanded;
}

/// Picks a value per breakpoint, falling back to the nearest smaller one.
T responsiveValue<T>(Breakpoint bp, {required T compact, T? medium, T? expanded, T? large}) {
  return switch (bp) {
    Breakpoint.compact => compact,
    Breakpoint.medium => medium ?? compact,
    Breakpoint.expanded => expanded ?? medium ?? compact,
    Breakpoint.large => large ?? expanded ?? medium ?? compact,
  };
}
